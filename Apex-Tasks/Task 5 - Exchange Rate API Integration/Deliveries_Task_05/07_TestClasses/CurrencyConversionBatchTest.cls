@isTest
private class CurrencyConversionBatchTest {

    private class BatchMultiCurrencyMock implements HttpCalloutMock {
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
        for (Integer i = 0; i < 50; i++) {
            opps.add(new Opportunity(
                Name = 'Batch Test Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000 + i,
                Expected_Currency_Type__c = (Math.mod(i, 2) == 0) ? 'USD' : 'EUR'
            ));
        }
        opps.add(new Opportunity(Name = 'Unsupported Batch Opp', StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Amount = 5000, Expected_Currency_Type__c = 'SGD'));
        insert opps;

        OpportunityCurrencyTriggerHandler.bypassTrigger = false;
    }

    @isTest
    static void testFullBatchRun() {
        Test.setMock(HttpCalloutMock.class, new BatchMultiCurrencyMock());

        Test.startTest();
        CurrencyConversionBatch batch = new CurrencyConversionBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Opportunity> updated = [SELECT Currency_Update_Status__c FROM Opportunity
                                      WHERE Expected_Currency_Type__c IN ('USD', 'EUR')];
        for (Opportunity opp : updated) {
            System.assertEquals('Success', opp.Currency_Update_Status__c);
        }

        Opportunity unsupportedOpp = [SELECT Currency_Update_Status__c FROM Opportunity
                                       WHERE Name = 'Unsupported Batch Opp'];
        System.assertEquals('Failed', unsupportedOpp.Currency_Update_Status__c);
    }

    @isTest
    static void testReprocessFilteredBatch() {
        Test.setMock(HttpCalloutMock.class, new BatchMultiCurrencyMock());

        Test.startTest();
        Database.executeBatch(new CurrencyConversionBatch(), 200);
        Test.stopTest();

        List<Opportunity> failedOpps = [SELECT Id FROM Opportunity WHERE Currency_Update_Status__c = 'Failed'];
        System.assertEquals(1, failedOpps.size(), 'Only the unsupported currency opp should be Failed');
    }
}
