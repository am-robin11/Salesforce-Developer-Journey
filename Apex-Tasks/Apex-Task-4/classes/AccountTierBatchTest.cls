/**
 * AccountTierBatchTest
 * ----------------------
 * Testing Batch Apex has one special rule: everything you want the batch
 * to iterate over must exist BEFORE Test.startTest(). Code inside
 * Test.startTest()/stopTest() runs the batch job SYNCHRONOUSLY (all of
 * start/execute/finish complete before stopTest() returns), which is what
 * lets us assert on the results immediately afterwards - in a real org
 * the job would run asynchronously and you'd check Setup > Apex Jobs.
 *
 * @TestSetup runs once and its data is visible (via a fresh transaction
 * rollback point) to every @isTest method in this class, so we don't
 * have to recreate the 160-record dataset in every single test method.
 */
@isTest
private class AccountTierBatchTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 40; i++) {
            accounts.add(new Account(Name = 'Enterprise ' + i, AnnualRevenue = 2000000000, NumberOfEmployees = 20000));
        }
        for (Integer i = 0; i < 40; i++) {
            accounts.add(new Account(Name = 'Large ' + i, AnnualRevenue = 200000000, NumberOfEmployees = 2000));
        }
        for (Integer i = 0; i < 40; i++) {
            accounts.add(new Account(Name = 'Medium ' + i, AnnualRevenue = 5000000, NumberOfEmployees = 500));
        }
        for (Integer i = 0; i < 40; i++) {
            accounts.add(new Account(Name = 'Small ' + i, AnnualRevenue = 0, NumberOfEmployees = 0));
        }
        // The insert trigger correctly computes Tier/Rating for all 160
        // records right now - so on their own they'd all already be
        // correct, and the batch would have nothing to fix.
        insert accounts;

        // To realistically simulate the ~100,000 LEGACY records this
        // task describes (created before this automation existed, so
        // Account_Tier__c/Rating are wrong or blank), we deliberately
        // corrupt half of them with a follow-up update. Crucially, this
        // update only touches Account_Tier__c/Rating - NOT
        // AnnualRevenue/NumberOfEmployees - so AccountTriggerHandler's
        // "only recalculate when driver fields change" rule means the
        // trigger leaves our corrupted values alone. That's what lets us
        // prove the BATCH (not the trigger) is what fixes them.
        List<Account> toCorrupt = new List<Account>();
        for (Integer i = 0; i < accounts.size(); i++) {
            if (Math.mod(i, 2) == 0) {
                accounts[i].Account_Tier__c = AccountTierRatingService.TIER_SMALL;
                accounts[i].Rating = AccountTierRatingService.RATING_COLD;
                toCorrupt.add(accounts[i]);
            }
        }
        update toCorrupt;
    }

    @isTest
    static void testBatch_fixesAllTiersAndCountsMatch() {
        Test.startTest();
        Database.executeBatch(new AccountTierBatch(), 50);
        Test.stopTest();

        List<AggregateResult> summary = [
            SELECT Account_Tier__c tier, COUNT(Id) total
            FROM Account
            GROUP BY Account_Tier__c
        ];
        Map<String, Integer> counts = new Map<String, Integer>();
        for (AggregateResult ar : summary) {
            counts.put((String) ar.get('tier'), (Integer) ar.get('total'));
        }

        System.assertEquals(40, counts.get('Enterprise'));
        System.assertEquals(40, counts.get('Large'));
        System.assertEquals(40, counts.get('Medium'));
        System.assertEquals(40, counts.get('Small'));

        // Requirement 2 spot-check: Rating followed Tier for the group
        // that was deliberately corrupted
        for (Account a : [SELECT Rating FROM Account WHERE Account_Tier__c = 'Enterprise']) {
            System.assertEquals('Hot', a.Rating);
        }
    }

    @isTest
    static void testBatch_skipsRecordsThatAreAlreadyCorrect() {
        AccountTierBatch batchJob = new AccountTierBatch();

        Test.startTest();
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        // 160 total records went through the batch
        System.assertEquals(160, batchJob.recordsProcessed);
        // Only the 80 we deliberately corrupted in @TestSetup should have
        // triggered an actual DML update - proving unnecessary updates
        // really are avoided, not just claimed in a comment.
        System.assertEquals(80, batchJob.recordsUpdated);
    }
}
