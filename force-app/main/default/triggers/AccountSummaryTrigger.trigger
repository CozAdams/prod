/*******************************************************************************************************
* @author Lev
* @date 2020
*
* @description Trigger for Account_Summary__c
*/

trigger AccountSummaryTrigger on Account_Summary__c (before insert, before update, before delete) {
    /*switch on Trigger.operationType {
        when BEFORE_INSERT {
            AccountSummaryTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            AccountSummaryTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when BEFORE_DELETE {
            AccountSummaryTriggerHandler.handleBeforeDelete(Trigger.old);
        }
        when else {
            // Do nothing
        }
    }*/
}