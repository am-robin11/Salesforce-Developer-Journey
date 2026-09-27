Sample Failed Processing Result
==================================
Query used:

List<Opportunity> failedSamples = [
    SELECT Name, Expected_Currency_Type__c, Currency_Update_Status__c,
           Currency_Error_Message__c
    FROM Opportunity
    WHERE Currency_Update_Status__c = 'Failed'
    LIMIT 5
];

Screenshot shows 5 records with a currency outside the supported list
(INR, CHF, SGD), each with a clear, specific error message naming the
currency that failed and which currencies ARE supported.
