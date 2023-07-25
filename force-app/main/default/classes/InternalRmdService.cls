public with sharing class InternalRmdService {
    public InternalRmdService() {


        
    }

    @AuraEnabled
    public static List<Id> processSingleAccountDistribution (Id rmdTypeId, Id accountRmdId ){
        List<Id> lstIds = processDistribution(rmdTypeId, accountRmdId ,false );

        return lstIds;
    }
    
    //SE-2837 JS Defer button
    @AuraEnabled
    public static DeferWrapper processDeferOption(Id rmdTypeId, String selectedDeferOption ){
        DeferWrapper wrapper = processDefer(rmdTypeId, selectedDeferOption);
        return wrapper;
    }
    //SE-2837 JS Defer button

    @AuraEnabled
    public static List<Id> processProRataDistribution (Id rmdTypeId){

        List<Id> lstIds =  processDistribution(rmdTypeId ,null, true );

        return lstIds;
    }
    
    @AuraEnabled
    public static List<String> getDeferringPicklistValues (){

        List<String> deferringValuesList =  new List<String>{
            'Deferring - Still Employed',
            'Deferring - Different Institution',
            'Deferring - 1st Time/Subsequent April',
            'Deferring - processing as one-off'
        };

        return deferringValuesList;
    }

    //SE-2837 JS Defer button
    private static DeferWrapper processDefer(Id rmdTypeId, String selectedDeferOption) {
        List<Account_RMD__c> accRMDList = new List<Account_RMD__c>();
        DeferWrapper wrapper = new DeferWrapper();
        
        try {
            wrapper.recIdList.add(rmdTypeId);
            RMD_Account_Type__c productRMD = new RMD_Account_Type__c(
                Id = rmdTypeId,
                Distribution_Option__c = null,
                Single_Account__c = null
            );
            
            update productRMD;
            
            for(Account_RMD__c accRMD : [SELECT Id, RMD_Deferred__c FROM Account_RMD__c WHERE Product_RMD__c = :rmdTypeId]) {
                accRMD.RMD_Deferred__c = selectedDeferOption;
                accRMDList.add(accRMD);
                wrapper.recIdList.add(accRMD.Id);
            }
            
            if(!accRMDList.isEmpty())
                update accRMDList;
        }
        catch(DMLException e) {
            system.debug('error ' + e.getMessage());
            wrapper.errorMessage = e.getMessage();
        }
        
        return wrapper;
    }
    //SE-2837 JS Defer button
    
    private static List<Id> processDistribution (Id rmdTypeId,Id accountRmdId , boolean isProRata){

        List<Account_RMD__c> acctRmdsToUpdate = new List<Account_RMD__c>();
        List<Id> acctRmdsToUpdateIds = new List<Id>();
        Double totalDistributionAmount = 0;

        //can this work?? would nested records be updated?
        //should picklist value be pulled from SF in this case
        RMD_Account_Type__c selectedRmdAccountType = [SELECT Id,Distribution_Option__c,Name,Total_RMD_Remaining__c, (SELECT Id, Name, Product_RMD__c, Product_RMD__r.RMD_Met__c, RMD_Remaining__c, Account_Summary__c FROM Account_RMDs__r ) FROM RMD_Account_Type__c WHERE Id = :rmdTypeId ]; //JS SE-2784 Set Account Summary
        selectedRmdAccountType.Distribution_Option__c = isProRata ?  'Pro Rata':  'Single Account';

        if(selectedRmdAccountType.Account_RMDs__r.size() > 0 ){
            acctRmdsToUpdateIds.add(selectedRmdAccountType.Id);

            for(Account_RMD__c acctRmd : selectedRmdAccountType.Account_RMDs__r ){

                if(isProRata){

                    acctRmd.RMD_Planned_Distribution__c = acctRmd.RMD_Remaining__c;
                    acctRmd.RMD_Deferred__c = acctRmd.Product_RMD__r.RMD_Met__c ? 'RMD Met' : 'Take My RMD';
                    acctRmdsToUpdate.add(acctRmd);
                    acctRmdsToUpdateIds.add(acctRmd.Id);
                    selectedRmdAccountType.Single_Account__c = null;
                    system.debug(acctRmd.RMD_Planned_Distribution__c +'' + acctRmd.RMD_Remaining__c + '' + acctRmd.RMD_Deferred__c +'' + 'from 1st loop');
                }else{


                    if(acctRmd.Id == accountRmdId){

                        acctRmd.RMD_Deferred__c = acctRmd.Product_RMD__r.RMD_Met__c ? 'RMD Met' : 'Take My RMD';
                        acctRmd.RMD_Planned_Distribution__c = selectedRmdAccountType.Total_RMD_Remaining__c;
                        acctRmdsToUpdate.add(acctRmd);
                        acctRmdsToUpdateIds.add(acctRmd.Id);
                        System.debug('from 2nd loop' + acctRmd.RMD_Planned_Distribution__c +'' + acctRmd.RMD_Remaining__c + '' + acctRmd.RMD_Deferred__c +''  );
                        selectedRmdAccountType.Single_Account__c = acctRmd.Account_Summary__c; //JS SE-2784 Set Account Summary
                    }else{

                        acctRmd.RMD_Deferred__c = acctRmd.Product_RMD__r.RMD_Met__c ? 'RMD Met' : 'Taking From Another Account';
                        acctRmd.RMD_Planned_Distribution__c = 0;
                        acctRmdsToUpdate.add(acctRmd);
                        acctRmdsToUpdateIds.add(acctRmd.Id);
                        System.debug('from 3rd loop' + acctRmd.RMD_Planned_Distribution__c +'' + acctRmd.RMD_Remaining__c + '' + acctRmd.RMD_Deferred__c +'' );

                    }
                    
                }

            }            
        }


        Update selectedRmdAccountType;
        System.debug('---------acctRmdsToUpdate1---- '+ acctRmdsToUpdate);
        Update acctRmdsToUpdate;
        System.debug('---------acctRmdsToUpdate2---- '+ acctRmdsToUpdate);

        return acctRmdsToUpdateIds;
    }


    @AuraEnabled(cacheable=true)
    public static List<Account_RMD__c> retrieveAccounts(Id rmdTypeId){
        try {
            return [SELECT Id, Name FROM Account_RMD__c WHERE Product_RMD__c = :rmdTypeId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DeferWrapper {
        @AuraEnabled
        public String errorMessage = '';
        
        @AuraEnabled
        public List<Id> recIdList = new List<Id>();
    }
}