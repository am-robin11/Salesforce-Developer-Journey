/**
 * AccountTierRatingServiceTest
 * ------------------------------
 * Because AccountTierRatingService has NO SOQL/DML, these tests don't
 * need Test.startTest()/stopTest() at all (there's no async work or
 * governor-limit reset to bracket) - they just call the static methods
 * directly with hand-picked values. This is the fastest and most precise
 * way to test business rules: hit every boundary exactly.
 */
@isTest
private class AccountTierRatingServiceTest {

    @isTest
    static void testCalculateTier_everyBoundary() {
        // Nothing at all -> Small. Also proves nulls don't throw.
        System.assertEquals(AccountTierRatingService.TIER_SMALL,
            AccountTierRatingService.calculateTier(null, null));

        // Just below the Medium revenue threshold, and few employees -> Small
        System.assertEquals(AccountTierRatingService.TIER_SMALL,
            AccountTierRatingService.calculateTier(999999, 99));

        // Exactly AT the Medium threshold (revenue side)
        System.assertEquals(AccountTierRatingService.TIER_MEDIUM,
            AccountTierRatingService.calculateTier(1000000, 0));

        // Exactly AT the Medium threshold (employee side, revenue below it)
        System.assertEquals(AccountTierRatingService.TIER_MEDIUM,
            AccountTierRatingService.calculateTier(0, 100));

        // Exactly AT the Large threshold (revenue side)
        System.assertEquals(AccountTierRatingService.TIER_LARGE,
            AccountTierRatingService.calculateTier(100000000, 0));

        // Exactly AT the Large threshold (employee side)
        System.assertEquals(AccountTierRatingService.TIER_LARGE,
            AccountTierRatingService.calculateTier(0, 1000));

        // Exactly AT the Enterprise threshold (revenue side)
        System.assertEquals(AccountTierRatingService.TIER_ENTERPRISE,
            AccountTierRatingService.calculateTier(1000000000, 0));

        // Exactly AT the Enterprise threshold (employee side) - proves the
        // OR logic: tiny revenue, huge headcount still wins Enterprise
        System.assertEquals(AccountTierRatingService.TIER_ENTERPRISE,
            AccountTierRatingService.calculateTier(1, 10000));
    }

    @isTest
    static void testCalculateRating_mapping() {
        System.assertEquals(AccountTierRatingService.RATING_HOT,
            AccountTierRatingService.calculateRating(AccountTierRatingService.TIER_ENTERPRISE));
        System.assertEquals(AccountTierRatingService.RATING_HOT,
            AccountTierRatingService.calculateRating(AccountTierRatingService.TIER_LARGE));
        System.assertEquals(AccountTierRatingService.RATING_WARM,
            AccountTierRatingService.calculateRating(AccountTierRatingService.TIER_MEDIUM));
        System.assertEquals(AccountTierRatingService.RATING_COLD,
            AccountTierRatingService.calculateRating(AccountTierRatingService.TIER_SMALL));

        // Defensive default: an unexpected/blank tier should not throw
        System.assertEquals(AccountTierRatingService.RATING_COLD,
            AccountTierRatingService.calculateRating(null));
        System.assertEquals(AccountTierRatingService.RATING_COLD,
            AccountTierRatingService.calculateRating('SomeUnknownValue'));
    }

    @isTest
    static void testApplyTierAndRating_onlyCountsRealChanges() {
        Account alreadyCorrect = new Account(
            Name = 'Already Correct',
            AnnualRevenue = 5000000,
            NumberOfEmployees = 50,
            Account_Tier__c = AccountTierRatingService.TIER_MEDIUM,
            Rating = AccountTierRatingService.RATING_WARM
        );
        Account wrongTierAndRating = new Account(
            Name = 'Needs Fixing',
            AnnualRevenue = 5000000,
            NumberOfEmployees = 50,
            Account_Tier__c = AccountTierRatingService.TIER_SMALL,
            Rating = AccountTierRatingService.RATING_COLD
        );
        Account rightTierWrongRating = new Account(
            Name = 'Rating Out Of Sync',
            AnnualRevenue = 5000000,
            NumberOfEmployees = 50,
            Account_Tier__c = AccountTierRatingService.TIER_MEDIUM,
            Rating = AccountTierRatingService.RATING_COLD // stale/manually overridden
        );

        Integer changed = AccountTierRatingService.applyTierAndRating(
            new List<Account>{ alreadyCorrect, wrongTierAndRating, rightTierWrongRating }
        );

        System.assertEquals(2, changed, 'Two of the three records actually needed a change');
        System.assertEquals(AccountTierRatingService.TIER_MEDIUM, wrongTierAndRating.Account_Tier__c);
        System.assertEquals(AccountTierRatingService.RATING_WARM, wrongTierAndRating.Rating);
        System.assertEquals(AccountTierRatingService.RATING_WARM, rightTierWrongRating.Rating);
    }
}
