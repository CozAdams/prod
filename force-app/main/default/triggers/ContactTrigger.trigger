trigger ContactTrigger on Contact (before insert, before update) {
    ContactTriggerHandler handler = new ContactTriggerHandler(Trigger.new, Trigger.oldMap);
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert();
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate();
        }
    }
}