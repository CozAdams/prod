/*******************************************************************************************************
* @author JSarion
* @date 2022
*
* @description Trigger for Product RMD
*/
trigger ProductRmdTrigger on RMD_Account_Type__c (before insert, before update, before delete, after insert, after update, after delete) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            
        }
        when BEFORE_UPDATE {
            
        }
        when BEFORE_DELETE {
            
        }
        when AFTER_INSERT {
            ProductRmdTriggerHandler.handleAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE {
            ProductRmdTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            
        }
        when else {
            // Do nothing
        }
    }
}