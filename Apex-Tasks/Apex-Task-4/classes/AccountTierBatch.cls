/**
 * AccountTierBatch
 * -----------------
 * Handles Requirement 1's "update ~100,000 EXISTING records" and
 * Requirement 3's record-count summary.
 *
 * WHY BATCH APEX AND NOT A TRIGGER, A SIMPLE LOOP, OR QUEUEABLE?
 *   - A trigger only ever fires on records that are being inserted or
 *     updated RIGHT NOW. It cannot reach back and fix 100,000 records
 *     that already exist and aren't being touched.
 *   - A plain `for` loop with one big SOQL query would try to load all
 *     100,000 records into heap memory at once (heap limit ~6MB
 *     synchronous / 12MB async) and would hit the 10,000-row DML limit
 *     the moment you tried to update them all in one `update` statement.
 *   - Queueable Apex is great for a SMALL number of records that need
 *     async/callout work (see the Integration section of the report),
 *     but it does not automatically chunk a huge record set into
 *     governor-limit-safe pieces the way Batch Apex does.
 *   - Batch Apex is purpose-built for exactly this: "run this logic
 *     against a huge number of records, safely, in chunks." It gets its
 *     OWN fresh set of governor limits for every `execute()` call, and
 *     Database.QueryLocator can stream up to 50 million records without
 *     ever loading them all into memory at once.
 *
 * Implements Database.Stateful so that tierCounts/recordsProcessed/
 * recordsUpdated survive across every execute() call - without
 * Database.Stateful, instance variables reset to their default value
 * before every single batch chunk, and we'd only ever see the totals
 * from the LAST chunk in finish().
 */
public with sharing class AccountTierBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Map<String, Integer> tierCounts = new Map<String, Integer>{
        AccountTierRatingService.TIER_ENTERPRISE => 0,
        AccountTierRatingService.TIER_LARGE      => 0,
        AccountTierRatingService.TIER_MEDIUM     => 0,
        AccountTierRatingService.TIER_SMALL      => 0
    };
    public Integer recordsProcessed = 0;
    public Integer recordsUpdated = 0;

    /**
     * start() runs ONCE, defines the full scope of the job. Returning a
     * Database.QueryLocator (instead of an Iterable<Account>) is what
     * lets this scale to 100,000+ rows - the platform streams the query
     * results in chunks rather than materialising them all up front.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, AnnualRevenue, NumberOfEmployees, Account_Tier__c, Rating
            FROM Account
        ]);
    }

    /**
     * execute() runs once PER CHUNK ("scope"). Default chunk size is 200
     * records; we call Database.executeBatch(new AccountTierBatch(), 2000)
     * when kicking this off (see the report / anonymous Apex script) to
     * use a larger chunk size, since this logic is lightweight (no
     * callouts, no complex validation) - fewer, bigger chunks means fewer
     * execute() invocations and fewer Apex Job log entries for the same
     * 100,000 records.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> toUpdate = new List<Account>();

        for (Account acc : scope) {
            String tier = AccountTierRatingService.calculateTier(acc.AnnualRevenue, acc.NumberOfEmployees);
            String rating = AccountTierRatingService.calculateRating(tier);

            recordsProcessed++;
            tierCounts.put(tier, tierCounts.get(tier) + 1);

            // This is the "unnecessary record updates are avoided" rule
            // in practice: a record that is already correct never gets
            // added to the DML list at all, saving both DML rows and,
            // just as importantly, not triggering Account update
            // automations (workflow, other triggers, flows) for no
            // reason on records that didn't actually change.
            if (acc.Account_Tier__c != tier || acc.Rating != rating) {
                acc.Account_Tier__c = tier;
                acc.Rating = rating;
                toUpdate.add(acc);
            }
        }

        if (!toUpdate.isEmpty()) {
            // allOrNone = false: one bad record (e.g. a validation rule
            // conflict) should not roll back the other 1,999 good ones
            // in the same chunk.
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    recordsUpdated++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'AccountTierBatch failed to update ' + sr.getId() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }

    /**
     * finish() runs ONCE, after every chunk has completed. This is where
     * Requirement 3's summary gets produced. In a real org you would
     * likely also email this to the running user (Messaging.SingleEmailMessage) -
     * left here as debug logs plus the accompanying verification script,
     * since that's what the deliverables ask to be shown as evidence.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('=== AccountTierBatch summary ===');
        System.debug('Total Accounts processed: ' + recordsProcessed);
        System.debug('Total Accounts updated:   ' + recordsUpdated);
        System.debug('Accounts left unchanged:  ' + (recordsProcessed - recordsUpdated));
        for (String tier : new List<String>{
            AccountTierRatingService.TIER_ENTERPRISE,
            AccountTierRatingService.TIER_LARGE,
            AccountTierRatingService.TIER_MEDIUM,
            AccountTierRatingService.TIER_SMALL
        }) {
            System.debug(tier + ': ' + tierCounts.get(tier));
        }
    }
}
