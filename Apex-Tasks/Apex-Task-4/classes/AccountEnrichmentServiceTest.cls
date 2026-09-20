/**
 * AccountEnrichmentServiceTest
 * ------------------------------
 * Demonstrates the standard way to unit test Apex callouts: implement
 * HttpCalloutMock, register it with Test.setMock() inside
 * Test.startTest()/stopTest(), and the platform routes the "callout" to
 * your fake response instead of hitting the real network. This is the
 * ONLY way to get test coverage on callout code, since real callouts are
 * blocked entirely inside test context.
 */
@isTest
private class AccountEnrichmentServiceTest {

    // A minimal fake HTTP response standing in for the real API
    private class MockCompanyInfoResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('GET', req.getMethod());
            System.assert(req.getEndpoint().contains('lookup?domain='));

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"estimatedAnnualRevenue": 250000000, "estimatedEmployeeCount": 1500}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockFailedResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @isTest
    static void testGetCompanySizeEstimate_success() {
        Test.setMock(HttpCalloutMock.class, new MockCompanyInfoResponse());

        Test.startTest();
        AccountEnrichmentService.CompanySizeEstimate estimate =
            AccountEnrichmentService.getCompanySizeEstimate('example.com');
        Test.stopTest();

        System.assertNotEquals(null, estimate);
        System.assertEquals(250000000, estimate.annualRevenue);
        System.assertEquals(1500, estimate.numberOfEmployees);
    }

    @isTest
    static void testGetCompanySizeEstimate_handlesFailureGracefully() {
        Test.setMock(HttpCalloutMock.class, new MockFailedResponse());

        Test.startTest();
        AccountEnrichmentService.CompanySizeEstimate estimate =
            AccountEnrichmentService.getCompanySizeEstimate('example.com');
        Test.stopTest();

        System.assertEquals(null, estimate, 'A non-200 response should return null, not throw');
    }

    @isTest
    static void testEnrichAccountsQueueable_updatesAccountAndCascadesTier() {
        Account acc = new Account(Name = 'Enrich Me', Website = 'example.com');
        insert acc; // Small/Cold via the trigger, since no revenue/employees yet

        Test.setMock(HttpCalloutMock.class, new MockCompanyInfoResponse());

        Test.startTest();
        System.enqueueJob(new AccountEnrichmentService.EnrichAccountsQueueable(new Set<Id>{ acc.Id }));
        Test.stopTest(); // queueable jobs run synchronously once stopTest() is called

        Account result = [SELECT AnnualRevenue, NumberOfEmployees, Account_Tier__c, Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals(250000000, result.AnnualRevenue);
        System.assertEquals(1500, result.NumberOfEmployees);
        // Proves the two pieces of automation compose: enrichment sets
        // Revenue/Employees, which the trigger then turns into Tier/Rating
        System.assertEquals(AccountTierRatingService.TIER_LARGE, result.Account_Tier__c);
        System.assertEquals(AccountTierRatingService.RATING_HOT, result.Rating);
    }
}
