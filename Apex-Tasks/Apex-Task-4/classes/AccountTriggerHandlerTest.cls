/**
 * AccountTriggerHandlerTest
 * ---------------------------
 * These tests DO need Test.startTest()/Test.stopTest(): they perform real
 * DML, which fires the actual AccountTrigger. Test.startTest() resets
 * governor limits for the code inside the block, which matters here
 * because we insert 200 records at once to prove the trigger is
 * bulk-safe (a trigger that only works "one record at a time" is one of
 * the most common - and most heavily penalised - mistakes in Salesforce
 * development).
 */
@isTest
private class AccountTriggerHandlerTest {

    @isTest
    static void testBeforeInsert_bulkSetsTierAndRatingForEveryRecord() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            // Sweep revenue/employees across every tier boundary in one shot
            accounts.add(new Account(
                Name = 'Bulk Account ' + i,
                AnnualRevenue = i * 6000000,
                NumberOfEmployees = i * 60
            ));
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> inserted = [
            SELECT AnnualRevenue, NumberOfEmployees, Account_Tier__c, Rating
            FROM Account
        ];
        System.assertEquals(200, inserted.size());

        for (Account acc : inserted) {
            String expectedTier = AccountTierRatingService.calculateTier(acc.AnnualRevenue, acc.NumberOfEmployees);
            String expectedRating = AccountTierRatingService.calculateRating(expectedTier);
            System.assertEquals(expectedTier, acc.Account_Tier__c);
            System.assertEquals(expectedRating, acc.Rating);
        }
    }

    @isTest
    static void testBeforeUpdate_ignoresUnrelatedFieldChanges() {
        Account acc = new Account(Name = 'Update Me', AnnualRevenue = 0, NumberOfEmployees = 0);
        insert acc; // trigger sets this to Small / Cold on insert

        Test.startTest();
        acc.Phone = '555-1234'; // NOT a tier-driving field
        update acc;
        Test.stopTest();

        Account result = [SELECT Account_Tier__c, Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTierRatingService.TIER_SMALL, result.Account_Tier__c);
        System.assertEquals(AccountTierRatingService.RATING_COLD, result.Rating);
    }

    @isTest
    static void testBeforeUpdate_recalculatesWhenRevenueChanges() {
        Account acc = new Account(Name = 'Grows Up', AnnualRevenue = 0, NumberOfEmployees = 0);
        insert acc; // Small / Cold

        Test.startTest();
        acc.AnnualRevenue = 200000000; // crosses into Large
        update acc;
        Test.stopTest();

        Account result = [SELECT Account_Tier__c, Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTierRatingService.TIER_LARGE, result.Account_Tier__c);
        System.assertEquals(AccountTierRatingService.RATING_HOT, result.Rating);
    }

    @isTest
    static void testBeforeUpdate_tierDowngradeCascadesRatingDown() {
        Account acc = new Account(Name = 'Shrinks', AnnualRevenue = 500000000, NumberOfEmployees = 0); // Large/Hot
        insert acc;

        Test.startTest();
        acc.AnnualRevenue = 500000; // drops all the way to Small
        acc.NumberOfEmployees = 5;
        update acc;
        Test.stopTest();

        Account result = [SELECT Account_Tier__c, Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTierRatingService.TIER_SMALL, result.Account_Tier__c);
        System.assertEquals(AccountTierRatingService.RATING_COLD, result.Rating);
    }
}
