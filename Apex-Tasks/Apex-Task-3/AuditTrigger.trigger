trigger AuditTrigger on Opportunity (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
           AuditEditor.createAuditRecords(Trigger.new, Trigger.oldMap);
    }
}