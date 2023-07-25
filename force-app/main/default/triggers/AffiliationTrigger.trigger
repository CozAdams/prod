trigger AffiliationTrigger on npe5__Affiliation__c (before insert, after insert, before update) {
    AffiliationTriggerHandler handler = new AffiliationTriggerHandler(Trigger.new, Trigger.oldMap);

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        }
        when AFTER_INSERT {
            handler.afterInsert();
        }
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }
    }
}