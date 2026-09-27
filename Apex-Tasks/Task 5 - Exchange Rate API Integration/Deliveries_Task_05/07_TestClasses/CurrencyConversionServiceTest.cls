@isTest
private class CurrencyConversionServiceTest {

    private class MultiCurrencyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            if (endpoint.endsWith('/USD')) {
                res.setStatusCode(200);
                res.setBody('{"result":"success","conversion_rate":0.0082}');
            } else if (endpoint.endsWith('/EUR')) {
                res.setStatusCode(200);
                res.setBody('{"result":"success","conversion_rate":0.0076}');
            } else {
                res.setStatusCode(403);
                res.setBody('{"result":"error","error-type":"unsupported-code"}');
            }
            return res;
        }
    }

    @TestSetup
    static void setup() {
        OpportunityCurrencyTriggerHandler.bypassTrigger = true;

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(Name = 'USD Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = 100000, Expected_Currency_Type__c = 'USD'));
        opps.add(new Opportunity(Name = 'EUR Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = 200000, Expected_Currency_Type__c = 'EUR'));
        opps.add(new Opportunity(Name = 'Unsupported Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = 50000, Expected_Currency_Type__c = 'SGD'));
        opps.add(new Opportunity(Name = 'Blank Amount Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = null, Expected_Currency_Type__c = 'USD'));
        opps.add(new Opportunity(Name = 'Blank Currency Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = 75000, Expected_Currency_Type__c = null));
        insert opps;

        OpportunityCurrencyTriggerHandler.bypassTrigger = false;
    }

    @isTest
    static void testFullConversionBatch() {
        Test.setMock(HttpCalloutMock.class, new MultiCurrencyMock());
        List<Opportunity> opps = [SELECT Id, Amount, Expected_Currency_Type__c, Expected_Currency_Amount__c
                                   FROM Opportunity];

        Test.startTest();
        CurrencyConversionService.ConversionOutcome outcome = CurrencyConversionService.processOpportunities(opps);
        Test.stopTest();

        System.assertEquals(2, outcome.successCount, 'USD and EUR opps should succeed');
        System.assertEquals(2, outcome.failedCount, 'Unsupported currency and blank amount should fail');
        System.assertEquals(1, outcome.skippedCount, 'Blank currency should be skipped');
        System.assertEquals(2, outcome.apiCallCount, 'Should call API once each for USD and EUR only; SGD is skipped since it is outside the supported currency list');

        Opportunity usdOpp = [SELECT Expected_Currency_Amount__c, Currency_Update_Status__c
                              FROM Opportunity WHERE Name = 'USD Opp'];
        System.assertEquals('Success', usdOpp.Currency_Update_Status__c);
        System.assertEquals(820.00, usdOpp.Expected_Currency_Amount__c);

        Opportunity blankCurrencyOpp = [SELECT Currency_Update_Status__c
                                         FROM Opportunity WHERE Name = 'Blank Currency Opp'];
        System.assertEquals('Pending', blankCurrencyOpp.Currency_Update_Status__c, 'Skipped opp should remain at default Pending status');

        List<Exchange_Rate_History__c> historyRecs = [SELECT Target_Currency__c, API_Status__c
                                                        FROM Exchange_Rate_History__c];
        System.assertEquals(2, historyRecs.size(), 'One history record per supported currency actually queried; unsupported currencies are never queried');

        List<Opportunity_Currency_Update__c> trackingRecs = [SELECT Id FROM Opportunity_Currency_Update__c];
        System.assertEquals(2, trackingRecs.size(), 'One tracking record per successful conversion');
    }
}
