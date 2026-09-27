@isTest
private class OpportunityCurrencyTriggerTest {

    private class TriggerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":"success","conversion_rate":0.0082}');
            return res;
        }
    }

    @isTest
    static void testInsertTriggersConversion() {
        Test.setMock(HttpCalloutMock.class, new TriggerMock());

        Test.startTest();
        Opportunity opp = new Opportunity(
            Name = 'Trigger Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 100000,
            Expected_Currency_Type__c = 'USD'
        );
        insert opp;
        Test.stopTest();

        Opportunity result = [SELECT Currency_Update_Status__c, Expected_Currency_Amount__c
                               FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Success', result.Currency_Update_Status__c);
        System.assertEquals(820.00, result.Expected_Currency_Amount__c);
    }

    @isTest
    static void testUpdateAmountTriggersConversion() {
        Test.setMock(HttpCalloutMock.class, new TriggerMock());

        Opportunity opp = new Opportunity(
            Name = 'Trigger Update Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 50000,
            Expected_Currency_Type__c = 'USD'
        );
        insert opp;

        Test.startTest();
        opp.Amount = 75000;
        update opp;
        Test.stopTest();

        Opportunity result = [SELECT Currency_Update_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Success', result.Currency_Update_Status__c);
    }

    @isTest
    static void testUnrelatedFieldUpdateDoesNotTrigger() {
        Test.setMock(HttpCalloutMock.class, new TriggerMock());

        Opportunity opp = new Opportunity(
            Name = 'No Trigger Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 30000,
            Expected_Currency_Type__c = 'USD'
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Opportunity result = [SELECT Currency_Update_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Success', result.Currency_Update_Status__c,
            'The initial insert triggers conversion; the later StageName-only update should not trigger a second one, but status remains Success from the insert');
    }

    @isTest
    static void testBypassFlagPreventsProcessing() {
        OpportunityCurrencyTriggerHandler.bypassTrigger = true;

        Test.startTest();
        Opportunity opp = new Opportunity(
            Name = 'Bypassed Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 40000,
            Expected_Currency_Type__c = 'USD'
        );
        insert opp;
        Test.stopTest();

        OpportunityCurrencyTriggerHandler.bypassTrigger = false;

        Opportunity result = [SELECT Currency_Update_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', result.Currency_Update_Status__c,
            'Bypassed insert should stay at default Pending with no callout made');
    }
}
