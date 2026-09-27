@isTest
private class ExchangeRateApiClientTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":"success","base_code":"BDT","target_code":"USD","conversion_rate":0.0082}');
            return res;
        }
    }

    private class UnsupportedCodeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            res.setBody('{"result":"error","error-type":"unsupported-code"}');
            return res;
        }
    }

    private class InvalidKeyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            res.setBody('{"result":"error","error-type":"invalid-key"}');
            return res;
        }
    }

    private class MalformedJsonMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{not valid json');
            return res;
        }
    }

    @isTest
    static void testSuccessfulConversion() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        ExchangeRateApiClient.RateResult result = ExchangeRateApiClient.getConversionRate('BDT', 'USD');
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Expected success for a valid pair');
        System.assertEquals(0.0082, result.conversionRate, 'Conversion rate should match mock response');
        System.assertEquals(200, result.httpStatusCode);
    }

    @isTest
    static void testUnsupportedCurrencyCode() {
        Test.setMock(HttpCalloutMock.class, new UnsupportedCodeMock());

        Test.startTest();
        ExchangeRateApiClient.RateResult result = ExchangeRateApiClient.getConversionRate('BDT', 'SGD');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Unsupported code should not be a success');
        System.assertEquals('unsupported-code', result.errorType);
    }

    @isTest
    static void testInvalidKey() {
        Test.setMock(HttpCalloutMock.class, new InvalidKeyMock());

        Test.startTest();
        ExchangeRateApiClient.RateResult result = ExchangeRateApiClient.getConversionRate('BDT', 'USD');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess);
        System.assertEquals('invalid-key', result.errorType);
    }

    @isTest
    static void testMalformedJsonResponse() {
        Test.setMock(HttpCalloutMock.class, new MalformedJsonMock());

        Test.startTest();
        ExchangeRateApiClient.RateResult result = ExchangeRateApiClient.getConversionRate('BDT', 'USD');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess);
        System.assertEquals('parse-error', result.errorType);
    }

    @isTest
    static void testBlankCurrencyInput() {
        Test.startTest();
        ExchangeRateApiClient.RateResult result = ExchangeRateApiClient.getConversionRate('', 'USD');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Blank base currency should fail fast without a callout');
        System.assertEquals('invalid-input', result.errorType);
    }
}
