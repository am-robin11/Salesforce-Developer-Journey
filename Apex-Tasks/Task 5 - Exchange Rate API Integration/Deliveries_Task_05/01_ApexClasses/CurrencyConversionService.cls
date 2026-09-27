public with sharing class CurrencyConversionService {

    private static final String BASE_CURRENCY = 'BDT';
    private static final Set<String> SUPPORTED_CURRENCIES = new Set<String>{
        'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'
    };

    public class ConversionOutcome {
        public Integer successCount = 0;
        public Integer failedCount = 0;
        public Integer skippedCount = 0;
        public Integer apiCallCount = 0;
    }

    public class InsufficientAccessException extends Exception {}

    private static void enforceFieldLevelSecurity() {
        Boolean canReadOpportunityFields =
            Schema.sObjectType.Opportunity.fields.Amount.isAccessible() &&
            Schema.sObjectType.Opportunity.fields.Expected_Currency_Type__c.isAccessible() &&
            Schema.sObjectType.Opportunity.fields.Expected_Currency_Amount__c.isAccessible();

        Boolean canUpdateOpportunityFields =
            Schema.sObjectType.Opportunity.fields.Expected_Currency_Amount__c.isUpdateable() &&
            Schema.sObjectType.Opportunity.fields.Exchange_Rate__c.isUpdateable() &&
            Schema.sObjectType.Opportunity.fields.Currency_Last_Updated__c.isUpdateable() &&
            Schema.sObjectType.Opportunity.fields.Currency_Update_Status__c.isUpdateable() &&
            Schema.sObjectType.Opportunity.fields.Currency_Error_Message__c.isUpdateable();

        Boolean canCreateHistoryRecords = Schema.sObjectType.Exchange_Rate_History__c.isCreateable();
        Boolean canCreateTrackingRecords = Schema.sObjectType.Opportunity_Currency_Update__c.isCreateable();

        if (!canReadOpportunityFields || !canUpdateOpportunityFields ||
            !canCreateHistoryRecords || !canCreateTrackingRecords) {
            throw new InsufficientAccessException(
                'The running user lacks the field-level or object-level permissions required for ' +
                'currency conversion processing. Verify the "Currency Integration Access" permission ' +
                'set is assigned.');
        }
    }

    public static ConversionOutcome processOpportunities(List<Opportunity> opps) {
        enforceFieldLevelSecurity();

        ConversionOutcome outcome = new ConversionOutcome();

        Map<String, List<Opportunity>> byCurrency = new Map<String, List<Opportunity>>();

        for (Opportunity opp : opps) {
            String currencyCode = opp.Expected_Currency_Type__c;

            if (String.isBlank(currencyCode)) {
                outcome.skippedCount++;
                continue;
            }

            currencyCode = currencyCode.trim().toUpperCase();
            if (!byCurrency.containsKey(currencyCode)) {
                byCurrency.put(currencyCode, new List<Opportunity>());
            }
            byCurrency.get(currencyCode).add(opp);
        }

        Map<String, ExchangeRateApiClient.RateResult> rateCache = new Map<String, ExchangeRateApiClient.RateResult>();
        for (String currencyCode : byCurrency.keySet()) {
            if (SUPPORTED_CURRENCIES.contains(currencyCode)) {
                ExchangeRateApiClient.RateResult rate = ExchangeRateApiClient.getConversionRate(BASE_CURRENCY, currencyCode);
                rateCache.put(currencyCode, rate);
                outcome.apiCallCount++;
            }
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Exchange_Rate_History__c> rateHistoryRecords = new List<Exchange_Rate_History__c>();
        List<Opportunity_Currency_Update__c> currencyUpdateRecords = new List<Opportunity_Currency_Update__c>();
        DateTime nowTs = DateTime.now();

        for (String currencyCode : byCurrency.keySet()) {
            ExchangeRateApiClient.RateResult rate = rateCache.get(currencyCode);

            if (SUPPORTED_CURRENCIES.contains(currencyCode)) {
                Exchange_Rate_History__c historyRec = new Exchange_Rate_History__c();
                historyRec.Base_Currency__c = BASE_CURRENCY;
                historyRec.Target_Currency__c = currencyCode;
                historyRec.Retrieved_Date_Time__c = nowTs;

                if (rate.isSuccess) {
                    historyRec.API_Status__c = 'Success';
                    historyRec.Exchange_Rate__c = rate.conversionRate;
                } else {
                    historyRec.API_Status__c = 'Failed';
                    historyRec.Error_Details__c = rate.errorMessage;
                }
                rateHistoryRecords.add(historyRec);
            }

            for (Opportunity opp : byCurrency.get(currencyCode)) {
                Opportunity oppUpdate = new Opportunity(Id = opp.Id);
                Decimal previousAmount = opp.Expected_Currency_Amount__c;

                if (opp.Amount == null) {
                    oppUpdate.Currency_Update_Status__c = 'Failed';
                    oppUpdate.Currency_Error_Message__c = 'Opportunity Amount is blank.';
                    outcome.failedCount++;

                } else if (!SUPPORTED_CURRENCIES.contains(currencyCode)) {
                    oppUpdate.Currency_Update_Status__c = 'Failed';
                    oppUpdate.Currency_Error_Message__c = 'Unsupported currency: ' + currencyCode +
                        '. Supported currencies are USD, EUR, GBP, JPY, AUD, CAD.';
                    outcome.failedCount++;

                } else if (!rate.isSuccess) {
                    oppUpdate.Currency_Update_Status__c = 'Failed';
                    oppUpdate.Currency_Error_Message__c = rate.errorMessage;
                    outcome.failedCount++;

                } else {
                    Decimal newAmount = (opp.Amount * rate.conversionRate).setScale(2, System.RoundingMode.HALF_UP);
                    oppUpdate.Expected_Currency_Amount__c = newAmount;
                    oppUpdate.Exchange_Rate__c = rate.conversionRate;
                    oppUpdate.Currency_Last_Updated__c = nowTs;
                    oppUpdate.Currency_Update_Status__c = 'Success';
                    oppUpdate.Currency_Error_Message__c = null;
                    outcome.successCount++;

                    Opportunity_Currency_Update__c trackingRec = new Opportunity_Currency_Update__c();
                    trackingRec.Opportunity__c = opp.Id;
                    trackingRec.Opportunity_Amount_BDT__c = opp.Amount;
                    trackingRec.Expected_Currency_Type__c = currencyCode;
                    trackingRec.Exchange_Rate_Used__c = rate.conversionRate;
                    trackingRec.Previous_Expected_Currency_Amount__c = previousAmount;
                    trackingRec.New_Expected_Currency_Amount__c = newAmount;
                    trackingRec.Updated_Date_Time__c = nowTs;
                    currencyUpdateRecords.add(trackingRec);
                }

                oppsToUpdate.add(oppUpdate);
            }
        }

        if (!rateHistoryRecords.isEmpty()) {
            Database.insert(rateHistoryRecords, false);
        }
        if (!oppsToUpdate.isEmpty()) {
            Database.update(oppsToUpdate, false);
        }
        if (!currencyUpdateRecords.isEmpty()) {
            Database.insert(currencyUpdateRecords, false);
        }

        return outcome;
    }
}
