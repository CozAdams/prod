trigger OpportunityTrigger on Opportunity (after insert, after update) {
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler(Trigger.new, Trigger.oldMap);
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert();
        } else if (Trigger.isUpdate) {
            handler.afterUpdate();
        }
    }
}