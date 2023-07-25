/*******************************************************************************************************
* @author Lev
* @date 2021
*
* @description Service methods for RMD Account Type and RMD Distribution
*/
public with sharing class RMDService {

    
    /*******************************************************************************************************
    * @description  Recalculate Product RMD records when Account RMD records change
    * @param        acctRMDList - records triggering the recalculation
    * @param        oldMap - Account RMD old values 
    */
    public static void recalcProductRMD(List<Account_RMD__c> acctRMDList, Map<Id, Account_RMD__c> oldMap) {
        Set<Id> accountSummaryIdSet = new Set<Id>();
        Set<Id> productRMDIdSet = new Set<Id>();
        Set<String> yearSet = new Set<String>();
        Set<Id> contactIdSet = new Set<Id>();
        Map<String, RMD_Account_Type__c> keyToProductRMDMap = new Map<String, RMD_Account_Type__c>();
        Map<Id, Account_Summary__c> idToAccountSummaryMap;
        List<RMD_Account_Type__c> productRMDList = new List<RMD_Account_Type__c>();

        for(Account_RMD__c acctRMD : acctRMDList) {
            accountSummaryIdSet.add(acctRMD.Account_Summary__c);
        }
        system.debug('DEBUG accountSummaryIdSet ' + accountSummaryIdSet);
        idToAccountSummaryMap = new Map<Id, Account_Summary__c>([SELECT Id, Plan_ID__c, Member_Name__c, Member_Name__r.MailingState, Status_display__c FROM Account_Summary__c WHERE Id IN :accountSummaryIdSet]);
        system.debug('DEBUG idToAccountSummaryMap ' + accountSummaryIdSet);
        for(Account_RMD__c acctRMD : acctRMDList) {
            //idToAccountSummaryMap.get(acctRMD.Account_Summary__c).Status_display__c != 'Closed' 
            //JS SE-2836 Removed exclusion of Closed Accounts
            if(idToAccountSummaryMap.containsKey(acctRMD.Account_Summary__c) && acctRmd.Product_RMD__c != null) {
                Account_RMD__c oldRec = oldMap != null ? oldMap.get(acctRMD.Id) : null;
                    productRMDIdSet.add(acctRmd.Product_RMD__c);
                    
                    if(acctRMD.RMD_Year__c != null)
                        yearSet.add(acctRMD.RMD_Year__c);
            }
        }
        system.debug('DEBUG productRMDIdSet ' + productRMDIdSet);
        system.debug('DEBUG yearSet ' + yearSet);
        /*
        for(RMD_Account_Type__c RMD productRMD : [SELECT Id, Tax_Year__c, Pay_Code__c, Total_RMD_Amount__c, Withdrawal_Total__c, Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c, Contact__c FROM RMD_Account_Type__c WHERE Tax_Year__c IN :yearSet AND Id IN :productRMDIdSet]) {
            String key = productRMD.Tax_year__c + '|' + productRMD.Id;
            keyToProductRMDMap.put(key, productRMD);
        }
        */
        
        for(Account_RMD__c acctRMD : [SELECT Account_Summary__r.Plan_ID__c, Account_Summary__c, Account_Summary__r.Member_Name__c, Account_Summary__r.Member_Name__r.MailingState, RMD_Year__c, Product_RMD__c, RMD_Amount__c, RMD_Withdrawal__c, RMD_Planned_Distribution__c, RMD_Scheduled_Withdrawal__c FROM Account_RMD__c WHERE Product_RMD__c IN :productRMDIdSet AND RMD_Year__c IN :yearSet]) {
            String key = acctRMD.RMD_Year__c + '|' + acctRMD.Product_RMD__c;
            RMD_Account_Type__c productRMD = new RMD_Account_Type__c(
                Total_RMD_Amount__c = 0,
                Scheduled_Withdrawal_Total__c = 0,
                Total_Planned_Distributions__c = 0,
                Withdrawal_Total__c = 0,
                Id = acctRMD.Product_RMD__c
            );
            system.debug('DEBUG key ' + key);

            if(keyToProductRMDMap.containsKey(key)) 
                productRMD = keyToProductRMDMap.get(key);
                
            system.debug('DEBUG Id ' + acctRMD.Id);
            system.debug('DEBUG RMD_Amount__c ' + acctRMD.RMD_Amount__c );
            system.debug('DEBUG RMD_Scheduled_Withdrawal__c ' + acctRMD.RMD_Scheduled_Withdrawal__c);
            system.debug('DEBUG RMD_Planned_Distribution__c ' + acctRMD.RMD_Planned_Distribution__c );
            system.debug('DEBUG RMD_Withdrawal__c ' + acctRMD.RMD_Withdrawal__c );
                
            system.debug('DEBUG 1');
            system.debug('DEBUG RMD_Amount__c ' + productRMD.Total_RMD_Amount__c);
            system.debug('DEBUG RMD_Scheduled_Withdrawal__c ' + productRMD.Scheduled_Withdrawal_Total__c);
            system.debug('DEBUG RMD_Planned_Distribution__c ' + productRMD.Total_Planned_Distributions__c);
            system.debug('DEBUG RMD_Withdrawal__c ' + productRMD.Withdrawal_Total__c);


            if(acctRMD.RMD_Amount__c != null) 
                productRMD.Total_RMD_Amount__c += acctRMD.RMD_Amount__c;
            if(acctRMD.RMD_Scheduled_Withdrawal__c != null)
                productRMD.Scheduled_Withdrawal_Total__c += acctRMD.RMD_Scheduled_Withdrawal__c;
            if(acctRMD.RMD_Planned_Distribution__c != null)
                productRMD.Total_Planned_Distributions__c += acctRMD.RMD_Planned_Distribution__c;
            if(acctRMD.RMD_Withdrawal__c != null)
                productRMD.Withdrawal_Total__c += acctRMD.RMD_Withdrawal__c;

            keyToProductRMDMap.put(key, productRMD);
            
            system.debug('DEBUG 2');
            system.debug('DEBUG RMD_Amount__c ' + productRMD.Total_RMD_Amount__c);
            system.debug('DEBUG RMD_Scheduled_Withdrawal__c ' + productRMD.Scheduled_Withdrawal_Total__c);
            system.debug('DEBUG RMD_Planned_Distribution__c ' + productRMD.Total_Planned_Distributions__c);
            system.debug('DEBUG RMD_Withdrawal__c ' + productRMD.Withdrawal_Total__c);

        }
        system.debug('DEBUG ' + keyToProductRMDMap.keySet());

        for(RMD_Account_Type__c productRMD : [SELECT Id, Pay_Code__c, Tax_Year__c, Total_RMD_Amount__c, Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c, Withdrawal_Total__c FROM RMD_Account_Type__c WHERE Id IN :productRMDIdSet AND Tax_Year__c IN :yearSet]) {
            String key = productRMD.Tax_Year__c + '|' + productRMD.Id;
            RMD_Account_Type__c productRMD1;

            system.debug('DEBUG key ' + key + ' ' + keyToProductRMDMap.containsKey(key) );
            if(keyToProductRMDMap.containsKey(key)) {
                productRMD1 = keyToProductRMDMap.get(key);

                if((productRMD.Total_RMD_Amount__c != productRMD1.Total_RMD_Amount__c || 
                    productRMD.Scheduled_Withdrawal_Total__c != productRMD1.Scheduled_Withdrawal_Total__c || 
                    productRMD.Total_Planned_Distributions__c != productRMD1.Total_Planned_Distributions__c || 
                    productRMD.Withdrawal_Total__c != productRMD1.Withdrawal_Total__c))
                    productRMDList.add(productRMD1);
            }
            
        }
        
        for(RMD_Account_Type__c rmd : productRMDList) {
            system.debug('>>>>>state ' + rmd.State_Abbreviation__c);
        }
        
        if(!productRMDList.isEmpty())
            upsert productRMDList;
    }
    
    /*******************************************************************************************************
    * @description  Update Account RMD details based on Product RMD values
    * @param        RMD_Account_Type__c - records triggering the recalculation
    * @param        oldMap - Product RMD old values
    */
    public static void updateAccountRMDDetails(List<RMD_Account_Type__c> productRMDList, Map<Id, RMD_Account_Type__c> oldMap) {
        Set<Id> productRMDIdSet = new Set<Id>();
        Set<Id> takeMyRmdProductRMDIdSet = new Set<Id>();
        Set<String> yearSet = new Set<String>();
        List<Account_RMD__c> acctRMDList = new List<Account_RMD__c>();
        
        for(RMD_Account_Type__c productRMD : productRMDList) {
            RMD_Account_Type__c oldRec = oldMap != null ? oldMap.get(productRMD.Id) : null;
            
            if(oldMap != null && productRMD.RMD_Met__c && productRMD.RMD_Met__c != oldRec.RMD_Met__c)
                productRMDIdSet.add(productRMD.Id);
            else if(productRMD.RMD_Met__c)
                productRMDIdSet.add(productRMD.Id);

            if(oldMap != null && !productRMD.RMD_Met__c && productRMD.RMD_Met__c != oldRec.RMD_Met__c)
                takeMyRmdProductRMDIdSet.add(productRMD.Id);
        }
        
        for(RMD_Account_Type__c productRMD : productRMDList) {
            yearSet.add(productRMD.Tax_Year__c);
        }
        
        for(Account_RMD__c acctRMD : [SELECT Id, RMD_Deferred__c FROM Account_RMD__c WHERE Product_RMD__c IN :productRMDIdSet AND RMD_Deferred__c != 'RMD Met' AND RMD_Year__c IN :yearSet]) {
            acctRMD.RMD_Deferred__c = 'RMD Met';
            acctRMDList.add(acctRMD);
        }

        for(Account_RMD__c acctRMD : [SELECT Id, RMD_Deferred__c, Account_Summary__c, Product_RMD__r.Distribution_Option__c, Product_RMD__r.Single_Account__c FROM Account_RMD__c WHERE Product_RMD__c IN :takeMyRmdProductRMDIdSet AND RMD_Deferred__c = 'RMD Met' AND RMD_Year__c IN :yearSet]) {
            if(acctRMD.Product_RMD__r.Distribution_Option__c == 'Single Account') {
                acctRMD.RMD_Deferred__c = acctRMD.Id == acctRMD.Product_RMD__r.Single_Account__c ? 'Take My RMD' : 'Taking From Another Account';
            }
            else
                acctRMD.RMD_Deferred__c = 'Take My RMD';
            
            acctRMDList.add(acctRMD);
        }
        
        if(!acctRMDList.isEmpty())
            update acctRMDList;
    }
}