/**
 * AccountTierRatingService
 * -------------------------
 * All the actual BUSINESS LOGIC for Task 04 lives here, and nowhere else.
 *
 * Why a separate "service" class instead of putting this logic straight
 * into the trigger?
 *   1. Testability - these methods take plain values in, return plain
 *      values out. No SOQL, no DML, no trigger context. That means the
 *      unit tests below don't need to insert a single record to test the
 *      tier boundaries - which makes them fast and precise.
 *   2. Reuse - the exact same logic is called from:
 *        - AccountTriggerHandler (real-time, one record or a small batch
 *          of records saved together)
 *        - AccountTierBatch (bulk, up to 100,000+ existing records)
 *      If the business rule changes later (e.g. management adds a
 *      "Global" tier), you change it in ONE place.
 *   3. Separation of concerns - triggers should be thin "traffic
 *      directors". Business rules belong in a service/helper class. This
 *      is the standard Salesforce trigger design pattern.
 */
public with sharing class AccountTierRatingService {

    // Centralising the picklist values as constants avoids "magic strings"
    // scattered across triggers, batches and tests. If a value ever needs
    // to change, it changes here once.
    public static final String TIER_ENTERPRISE = 'Enterprise';
    public static final String TIER_LARGE      = 'Large';
    public static final String TIER_MEDIUM     = 'Medium';
    public static final String TIER_SMALL      = 'Small';

    public static final String RATING_HOT  = 'Hot';
    public static final String RATING_WARM = 'Warm';
    public static final String RATING_COLD = 'Cold';

    /**
     * Requirement 1 logic.
     * Order matters: we check Enterprise first, then Large, then Medium,
     * falling through to Small. Because each rule is an OR (revenue OR
     * employees), checking from the top down and returning immediately
     * on the first match is both correct and efficient - we don't need
     * to evaluate every rule for every record.
     */
    public static String calculateTier(Decimal annualRevenue, Integer numberOfEmployees) {
        // Treat blank fields as zero rather than letting a null pointer
        // exception happen on a comparison - real-world Account data will
        // absolutely have blank AnnualRevenue / NumberOfEmployees.
        Decimal revenue = annualRevenue == null ? 0 : annualRevenue;
        Integer employees = numberOfEmployees == null ? 0 : numberOfEmployees;

        if (revenue >= 1000000000 || employees >= 10000) {
            return TIER_ENTERPRISE;
        }
        if (revenue >= 100000000 || employees >= 1000) {
            return TIER_LARGE;
        }
        if (revenue >= 1000000 || employees >= 100) {
            return TIER_MEDIUM;
        }
        return TIER_SMALL;
    }

    /**
     * Requirement 2 logic: Tier -> Rating mapping.
     * Any unrecognised/blank tier safely defaults to Cold instead of
     * throwing - defensive coding, since Rating is a standard field other
     * automations may also touch.
     */
    public static String calculateRating(String tier) {
        if (tier == TIER_ENTERPRISE) { return RATING_HOT;  }
        if (tier == TIER_LARGE)      { return RATING_HOT;  }
        if (tier == TIER_MEDIUM)     { return RATING_WARM; }
        return RATING_COLD;
    }

    /**
     * Bulk-safe helper used by BOTH the trigger handler and the batch job.
     * It mutates the sObjects IN MEMORY only - it deliberately does not
     * perform any DML. That decision belongs to the caller:
     *   - the trigger just lets the platform save Trigger.new for it
     *     (because this runs in a "before" context)
     *   - the batch job explicitly calls Database.update() on only the
     *     records that changed
     *
     * Returns the number of records that were actually changed, which is
     * how callers implement "don't update records that are already
     * correct" (Requirement 1's "unnecessary updates avoided" rule and
     * the batch's efficiency requirement).
     */
    public static Integer applyTierAndRating(List<Account> accounts) {
        Integer changedCount = 0;

        for (Account acc : accounts) {
            String newTier = calculateTier(acc.AnnualRevenue, acc.NumberOfEmployees);
            String newRating = calculateRating(newTier);

            Boolean tierChanged = acc.Account_Tier__c != newTier;
            Boolean ratingChanged = acc.Rating != newRating;

            if (tierChanged) {
                acc.Account_Tier__c = newTier;
            }
            if (ratingChanged) {
                acc.Rating = newRating;
            }
            if (tierChanged || ratingChanged) {
                changedCount++;
            }
        }

        return changedCount;
    }
}
