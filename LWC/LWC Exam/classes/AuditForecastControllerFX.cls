public with sharing class AuditForecastControllerFX {

    // Everything the exam says to EXCLUDE — advanced/closed stages.
    private static final List<String> EXCLUDED_STAGES = new List<String>{
        'Proposal/Price Quote', 'Negotiation/Review', 'Closed Won', 'Closed Lost'
    };

    // ------------------------------------------------------------------
    // READ (SOQL) — cacheable=true, correctly attached to the METHOD
    // (this was the very first bug: the annotation was sitting on top of
    // two unrelated fields instead of a method).
    // ------------------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getForecastOpportunities() {
        // THIS_MONTH covers the whole current calendar month automatically —
        // no addMonths/addDays math needed, and no risk of only matching
        // the single last day of the month.
        return [
            SELECT Id, Name, Amount, Probability, Expected_Revenue_Overridden__c
            FROM Opportunity
            WHERE CloseDate = THIS_MONTH
              AND StageName NOT IN :EXCLUDED_STAGES
            ORDER BY Amount DESC
        ];
    }

    // ------------------------------------------------------------------
    // WRITE (DML: update) — one record at a time, matching the "button
    // next to each row" requirement. NOT cacheable, since it writes data.
    // ------------------------------------------------------------------
    @AuraEnabled
    public static Opportunity setExpectedRevenueLogic(Id recordId) {
        try {
            Opportunity opp = [
                SELECT Id, Amount, Probability
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];

            // Tier 1: Amount > $2,000,000 AND Probability > 50 -> 15%
            // Tier 2: everything else -> 10%
            // Note: Probability is stored as a plain number (50 means 50%),
            // not a decimal fraction (0.5) — so ">50" is correct, not ">0.5".
            if (opp.Amount != null && opp.Amount > 2000000
                    && opp.Probability != null && opp.Probability > 50) {
                opp.Expected_Revenue_Overridden__c = opp.Amount * 0.15;
            } else {
                opp.Expected_Revenue_Overridden__c = (opp.Amount == null ? 0 : opp.Amount) * 0.10;
            }

            update opp;
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to set expected revenue: ' + e.getMessage());
        }
    }
}
