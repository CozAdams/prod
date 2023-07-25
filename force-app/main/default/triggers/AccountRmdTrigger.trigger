/*******************************************************************************************************
* @author 
* @date 2020
*
* @description Trigger for Account_RMD__c
*/
trigger AccountRmdTrigger on Account_RMD__c (before insert, before update, before delete, after insert, after update, after delete) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            //AccountRmdTriggerHandler.handleBeforeInsert(Trigger.new);
            //AccountRmdTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            //AccountRmdTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
            //AccountRmdTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);

        }
        when BEFORE_DELETE {
            //AccountRmdTriggerHandler.handleBeforeDelete(Trigger.old);
            //AccountRmdTriggerHandler.handleBeforeDelete(Trigger.old);
        }
        when AFTER_INSERT {
            AccountRmdTriggerHandler.handleAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            AccountRmdTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            AccountRmdTriggerHandler.handleAfterDelete(Trigger.old);
        }
        when else {
            // Do nothing
        }
    }
}