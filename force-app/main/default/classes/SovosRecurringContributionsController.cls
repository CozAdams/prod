public class SovosRecurringContributionsController {
    
    @AuraEnabled(cacheable=true)
    public static String getData(String userId) {
        system.debug('>>>>>userId ' + userId);
        User userRecord = [SELECT Id, ContactId FROM User WHERE Id =: userId LIMIT 1];
        system.debug('>>>>>userId ' + userRecord.ContactId);
    /*    Account_Summary__c accountSummaryRecord = [SELECT Id, Member_Name__c, Member_Pin__c, Account_Type_display__c, Status_display__c
                                                   FROM Account_Summary__c 
                                                   WHERE Member_Name__c =: userRecord.ContactId
                                                   AND Status_display__c = 'Active' 
                                                   ORDER BY CreatedDate DESC LIMIT 1];
    */

        Account_Summary__c accountSummaryRecord = [SELECT Id, Member_Name__c, Member_Pin__c, Account_Type_display__c, Status_display__c
                                                   FROM Account_Summary__c 
                                                   WHERE Member_Name__c =: userRecord.ContactId
                                                    AND Status_display__c = 'Active'                                          
                                                    AND   Plan_ID__c IN ( 'IRATRAD', 'IRALEG', 'IRAROTH', 'BENACC' )    
                                                    AND   Account_Desc__c != 'Supplemental Savings Inherited Account'   
                                                    AND   RecordTypeId IN ( '0120V000001tbgdQAA', '0120V000001tb7PQAQ', 
                                                                    '0120V000001tb7UQAQ', '0120V000001tbgbQAA' )      
                                                   LIMIT 1];                                           
                                                   
        system.debug('>>>>>accountSummaryRecord ' + accountSummaryRecord);
        if(accountSummaryRecord != null) {
            return accountSummaryRecord.Id;
        }
        
        return '';
    }

}