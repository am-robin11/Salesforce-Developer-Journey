/**
 * AccountTriggerHandler
 * ----------------------
 * This is the "handler" half of the thin-trigger / fat-handler pattern.
 * AccountTrigger.trigger itself contains almost no logic - it just routes
 * to one of the methods below based on which trigger event fired. That
 * makes the trigger itself trivial to read, and makes this class unit
 * testable without needing DML tricks to fire specific trigger contexts.
 *
 * KEY CONCEPT - why "before" and not "after":
 * We run in BEFORE INSERT / BEFORE UPDATE. In a before-trigger you are
 * allowed to modify the fields on the records in Trigger.new directly,
 * and the platform will include those changes in the SAME save that's
 * already happening - no second DML statement, no extra trigger
 * recursion, no hitting the 150-DML-per-transaction governor limit. If
 * we had used an AFTER trigger, we would have had to run a separate
 * `update` inside the trigger, which re-fires the trigger (recursion risk)
 * and burns an extra DML statement for every single save.
 */
public with sharing class AccountTriggerHandler {

    /**
     * Requirement 1 + 2 for brand-new Accounts: every newly inserted
     * Account should get a Tier and a matching Rating, unconditionally,
     * since it has no prior value to compare against.
     */
    public static void handleBeforeInsert(List<Account> newAccounts) {
        AccountTierRatingService.applyTierAndRating(newAccounts);
    }

    /**
     * Requirement 1 + 2 for updates. This is the more interesting case:
     * we deliberately do NOT recalculate on every single update to an
     * Account - only when the fields that actually DRIVE the tier
     * (AnnualRevenue, NumberOfEmployees) have changed. This satisfies the
     * "unnecessary updates avoided" expected behaviour and also avoids
     * wasting CPU time on every Account save (editing a Phone number
     * should not re-run tier math).
     *
     * Trigger.oldMap gives us the "before" version of every record so we
     * can compare old vs. new - this is only available in update/delete
     * contexts, never in insert (there is no "old" version of a new
     * record).
     */
    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Account> accountsNeedingRecalculation = new List<Account>();

        for (Account newAcc : newAccounts) {
            Account oldAcc = oldMap.get(newAcc.Id);

            Boolean revenueChanged = newAcc.AnnualRevenue != oldAcc.AnnualRevenue;
            Boolean employeesChanged = newAcc.NumberOfEmployees != oldAcc.NumberOfEmployees;

            if (revenueChanged || employeesChanged) {
                accountsNeedingRecalculation.add(newAcc);
            }
        }

        if (!accountsNeedingRecalculation.isEmpty()) {
            AccountTierRatingService.applyTierAndRating(accountsNeedingRecalculation);
        }
    }
}
