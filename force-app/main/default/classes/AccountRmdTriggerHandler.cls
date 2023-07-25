/*******************************************************************************************************
* @author 
* @date 2020
*
* @description Handler for Account_RMD__c trigger
*/
public with sharing class AccountRmdTriggerHandler {
    /*
    public static void handleBeforeInsert(List<Account_RMD__c> triggerNew) {
        RMDService.recalcRmdAccountType(triggerNew, null, 'insert');
    }

    public static void handleBeforeUpdate(List<Account_RMD__c> triggerNew, Map<Id, Account_RMD__c> oldMap) {
        RMDService.recalcRmdAccountType(triggerNew, oldMap, 'update');
    }

    public static void handleBeforeDelete(List<Account_RMD__c> triggerOld) {
        RMDService.recalcRmdAccountType(triggerOld, null, 'delete');
    }
    */
    /*
    public static void handleBeforeInsert(List<Account_RMD__c> triggerNew) {
        RMDService2.recalcProductRMD(triggerNew, null);
    }

    public static void handleBeforeUpdate(List<Account_RMD__c> triggerNew, Map<Id, Account_RMD__c> oldMap) {
        RMDService2.recalcProductRMD(triggerNew, oldMap);
    }

    public static void handleBeforeDelete(List<Account_RMD__c> triggerOld) {
        RMDService2.recalcProductRMD(triggerOld, null);
    }
    */
    public static void handleAfterInsert(List<Account_RMD__c> triggerNew) {
        RMDService.recalcProductRMD(triggerNew, null);
    }

    public static void handleAfterUpdate(List<Account_RMD__c> triggerNew, Map<Id, Account_RMD__c> oldMap) {
        RMDService.recalcProductRMD(triggerNew, oldMap);

    }
    
    public static void handleAfterDelete(List<Account_RMD__c> triggerOld) {
        RMDService.recalcProductRMD(triggerOld, null);
    }
}