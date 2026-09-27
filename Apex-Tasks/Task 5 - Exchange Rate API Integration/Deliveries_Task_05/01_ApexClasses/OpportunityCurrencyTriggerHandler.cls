public with sharing class OpportunityCurrencyTriggerHandler {

    public static Boolean bypassTrigger = false;

    public static void handle(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (bypassTrigger) {
            return;
        }

        Set<Id> idsToProcess = new Set<Id>();

        for (Opportunity opp : newOpps) {
            if (String.isBlank(opp.Expected_Currency_Type__c) || opp.Amount == null) {
                continue;
            }

            if (oldMap == null) {
                idsToProcess.add(opp.Id);
            } else {
                Opportunity oldOpp = oldMap.get(opp.Id);
                Boolean amountChanged = opp.Amount != oldOpp.Amount;
                Boolean currencyChanged = opp.Expected_Currency_Type__c != oldOpp.Expected_Currency_Type__c;
                if (amountChanged || currencyChanged) {
                    idsToProcess.add(opp.Id);
                }
            }
        }

        if (!idsToProcess.isEmpty()) {
            System.enqueueJob(new CurrencyConversionQueueable(idsToProcess));
        }
    }
}
