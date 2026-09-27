Exchange-Rate History Evidence
=================================
Query used:

List<Exchange_Rate_History__c> historyRecs = [
    SELECT Base_Currency__c, Target_Currency__c, Exchange_Rate__c,
           Retrieved_Date_Time__c, API_Status__c, Error_Details__c
    FROM Exchange_Rate_History__c
    ORDER BY Retrieved_Date_Time__c DESC
];

Screenshot shows Exchange_Rate_History__c records for every retrieved
rate, all API_Status__c = Success, across all six supported currencies
(BDT -> EUR, GBP, USD, JPY, AUD, CAD).

Note: the total record count reflects the full development and
correction cycle (multiple batch executions during testing and a
mid-development bug fix), not a single production run. A fresh run
against untouched data produces exactly one history record per distinct
supported currency present in each batch chunk.
