public with sharing class CurrencyConversionQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> opportunityIds;

    public CurrencyConversionQueueable(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> opps = [
            SELECT Id, Amount, Expected_Currency_Type__c, Expected_Currency_Amount__c, Currency_Update_Status__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        if (!opps.isEmpty()) {
            CurrencyConversionService.processOpportunities(opps);
        }
    }
}
