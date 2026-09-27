Opportunity Currency-Update History Evidence
===============================================
Query used (2 samples pulled explicitly per currency, for a
representative spread):

List<Opportunity_Currency_Update__c> trackingRecs = new List<...>();
for (String curr : new List<String>{'USD','EUR','GBP','JPY','AUD','CAD'}) {
    trackingRecs.addAll([
        SELECT Opportunity__r.Name, Opportunity_Amount_BDT__c,
               Expected_Currency_Type__c, Exchange_Rate_Used__c,
               Previous_Expected_Currency_Amount__c,
               New_Expected_Currency_Amount__c
        FROM Opportunity_Currency_Update__c
        WHERE Expected_Currency_Type__c = :curr
        LIMIT 2
    ]);
}

Screenshot shows 12 tracking records, 2 for each of the 6 supported
currencies, each with the original BDT amount, the rate used, and the
Previous -> New converted amount.
