/**
 * AccountTrigger
 * ---------------
 * "Thin trigger" - one trigger per object, no business logic here at all.
 * This is a Salesforce best practice: if you ever add a second Account
 * trigger for something unrelated, you end up with two triggers racing
 * each other with no guaranteed order. Keeping exactly one trigger per
 * object and delegating to a handler class avoids that entirely.
 */
trigger AccountTrigger on Account (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
