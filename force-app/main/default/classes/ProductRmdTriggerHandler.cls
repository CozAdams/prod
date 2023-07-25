/*******************************************************************************************************
* @author JSarion
* @date 2022
*
* @description Handler for Product RMD trigger
*/
public with sharing class ProductRmdTriggerHandler {
    public static void handleAfterInsert(List<RMD_Account_Type__c> triggerNew) {
        RMDService.updateAccountRMDDetails(triggerNew, null);
    }

    public static void handleAfterUpdate(List<RMD_Account_Type__c> triggerNew, Map<Id, RMD_Account_Type__c> oldMap) {
        RMDService.updateAccountRMDDetails(triggerNew, oldMap);
    }
}