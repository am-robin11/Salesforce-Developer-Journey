Sample Successfully Converted Opportunities
==============================================
Query used (see full script list in the Technical Explanation, item 14):

List<Opportunity> successSamples = [
    SELECT Name, Amount, Expected_Currency_Type__c, Exchange_Rate__c,
           Expected_Currency_Amount__c, Currency_Last_Updated__c
    FROM Opportunity
    WHERE Currency_Update_Status__c = 'Success'
    LIMIT 5
];

Screenshot shows 5 Opportunities successfully converted across JPY, CAD,
USD, and GBP, with the applied rate and resulting converted amount, e.g.
123000.00 BDT at rate 1.2868 -> 158276.40 JPY.
