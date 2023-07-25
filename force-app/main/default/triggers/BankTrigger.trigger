trigger BankTrigger on bnk_Bank__c (before insert, before update) {

    BankTriggerHandler triggerHandler = new BankTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            triggerHandler.onBeforeInsert();
        } else if (Trigger.isUpdate) {
            triggerHandler.onBeforeUpdate();
        }
    }
}