public with sharing class ExchangeRateApiClient {

    public class RateResult {
        public Boolean isSuccess;
        public Decimal conversionRate;
        public String errorType;
        public String errorMessage;
        public Integer httpStatusCode;
    }

    public class ExchangeRateApiException extends Exception {}

    private static final String NAMED_CREDENTIAL = 'callout:ExchangeRateAPI';

    public static RateResult getConversionRate(String baseCurrency, String targetCurrency) {
        RateResult result = new RateResult();

        if (String.isBlank(baseCurrency) || String.isBlank(targetCurrency)) {
            result.isSuccess = false;
            result.errorType = 'invalid-input';
            result.errorMessage = 'Base or target currency code is blank.';
            return result;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/pair/' + baseCurrency.trim() + '/' + targetCurrency.trim());
        req.setMethod('GET');
        req.setTimeout(10000);

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);
        } catch (System.CalloutException ce) {
            result.isSuccess = false;
            result.errorType = 'callout-exception';
            result.errorMessage = ce.getMessage();
            return result;
        }

        result.httpStatusCode = res.getStatusCode();

        Map<String, Object> body;
        try {
            body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        } catch (Exception je) {
            result.isSuccess = false;
            result.errorType = 'parse-error';
            result.errorMessage = 'Could not parse API response: ' + je.getMessage();
            return result;
        }

        String apiResult = (String) body.get('result');

        if (res.getStatusCode() == 200 && apiResult == 'success') {
            result.isSuccess = true;
            Object rateObj = body.get('conversion_rate');
            result.conversionRate = (rateObj != null) ? Decimal.valueOf(String.valueOf(rateObj)) : null;
        } else {
            result.isSuccess = false;
            result.errorType = (String) body.get('error-type');
            result.errorMessage = String.isNotBlank(result.errorType)
                ? 'API error: ' + result.errorType
                : 'Unexpected response, HTTP ' + res.getStatusCode();
        }

        return result;
    }
}
