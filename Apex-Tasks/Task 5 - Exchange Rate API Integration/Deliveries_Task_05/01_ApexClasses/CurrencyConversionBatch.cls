public with sharing class CurrencyConversionBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    private String queryFilter;

    public Integer totalSuccess = 0;
    public Integer totalFailed = 0;
    public Integer totalSkipped = 0;
    public Integer totalApiCalls = 0;

    public CurrencyConversionBatch() {
        this.queryFilter = null;
    }

    public CurrencyConversionBatch(String queryFilter) {
        this.queryFilter = queryFilter;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String baseQuery = 'SELECT Id, Amount, Expected_Currency_Type__c, Expected_Currency_Amount__c, ' +
                            'Currency_Update_Status__c FROM Opportunity';
        if (String.isNotBlank(queryFilter)) {
            baseQuery += ' WHERE ' + queryFilter;
        }
        return Database.getQueryLocator(baseQuery);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        CurrencyConversionService.ConversionOutcome outcome = CurrencyConversionService.processOpportunities(scope);
        totalSuccess += outcome.successCount;
        totalFailed += outcome.failedCount;
        totalSkipped += outcome.skippedCount;
        totalApiCalls += outcome.apiCallCount;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('=== Currency Conversion Batch Complete ===');
        System.debug('Success: ' + totalSuccess);
        System.debug('Failed: ' + totalFailed);
        System.debug('Skipped: ' + totalSkipped);
        System.debug('Total API Calls: ' + totalApiCalls);
    }
}
