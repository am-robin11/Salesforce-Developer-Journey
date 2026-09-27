trigger OpportunityCurrencyTrigger on Opportunity (after insert, after update) {
    OpportunityCurrencyTriggerHandler.handle(Trigger.new, Trigger.oldMap);
}
