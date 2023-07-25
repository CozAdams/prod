/**
* @author Nathan Ross
* @date 10/20/2018
*
* @group Trigger handlers
*
* @description Contact Trigger handler for routing logic
*/

public with sharing class ContactTriggerHandler{
    final List<Contact> newRecords;
    final Map<Id, Contact> oldRecordsMap;
    final ContactCommunityUserCreation communityUserCreation = new ContactCommunityUserCreation();
    String SBC_API_USER = System.Label.SBC_API_User;
    String runningUserID = UserInfo.getUserId();

    public ContactTriggerHandler(List<Contact> newRecords, Map<Id, Contact> oldRecords) {
        this.newRecords = newRecords;
        this.oldRecordsMap = oldRecords;
    }

    public void beforeInsert() {
        system.debug('IN insert');
        this.communityUserCreation.beforeContactInsert(this.newRecords);
        
        if(runningUserID.substring(0,15) != SBC_API_USER.substring(0,15)) {
            validateDuplicateSSN();
        }
    }

    public void beforeUpdate() {
        system.debug('IN updade');
        this.communityUserCreation.beforeContactUpdate(this.newRecords, this.oldRecordsMap);
        
        if(runningUserID.substring(0,15) != SBC_API_USER.substring(0,15)) {
            validateDuplicateSSN();
        }
    }
    
    //JS SE-2927
    public void validateDuplicateSSN() {
        Set<String> existingSSNSet = new Set<String>();
        Set<String> existingSINSet = new Set<String>();
        Set<String> checkSSNList = new Set<String>();
        Set<Decimal> checkSINList = new Set<Decimal>();
        List<Contact> existingContactList = new List<Contact>();
        
        
        for(Contact con : this.newRecords) {
            if((con.Contact_Type__c == 'Member' || con.Contact_Type__c == 'Non-Member') && con.Contact_Sub_Type__c != 'Estate/Trust') {
                Contact oldCon;
                
                if(con.Id != null && this.oldRecordsMap.containsKey(con.Id))
                    oldCon = this.oldRecordsMap.get(con.Id);
                    
            if(String.valueOf(con.Social_Insurance_Number__c) != null && String.valueOf(con.Social_Insurance_Number__c) != '' || (oldCon != null && String.valueOf(con.Social_Insurance_Number__c) != String.valueOf(oldCon.Social_Insurance_Number__c)))
                    checkSINList.add(con.Social_Insurance_Number__c);
                
                if(con.Social_Security_Number__c != null && con.Social_Security_Number__c != '' || (oldCon != null && con.Social_Security_Number__c != oldCon.Social_Security_Number__c))
                    checkSSNList.add(con.Social_Security_Number__c);
            } 
        }
        
        system.debug('checkSINList ' + checkSINList);
        system.debug('checkSSNList ' + checkSSNList);
        
        existingContactList = [SELECT Id, Social_Security_Number__c, Social_Insurance_Number__c, Contact_Sub_Type__c FROM Contact WHERE (Social_Security_Number__c IN :checkSSNList OR Social_Insurance_Number__c IN :checkSINList) AND Id NOT IN :this.newRecords];
        
        for(Contact con : existingContactList) {
            if(con.Social_Security_Number__c != null && con.Social_Security_Number__c != '' && con.Contact_Sub_Type__c != 'Estate/Trust')
                existingSSNSet.add(con.Social_Security_Number__c);
            
            if(String.valueOf(con.Social_Insurance_Number__c) != null && String.valueOf(con.Social_Insurance_Number__c) != '' && con.Contact_Sub_Type__c != 'Estate/Trust')
                existingSINSet.add(String.valueOf(con.Social_Insurance_Number__c));
        }
        
        system.debug('existingSSNSet ' + existingSSNSet);
        system.debug('existingSINSet ' + existingSINSet);
        
        for(Contact con : this.newRecords) {
            system.debug('>>>>> con ' + con.Contact_Type__c + ' ' + con.Contact_Sub_Type__c);
            if((con.Contact_Type__c == 'Member' || con.Contact_Type__c == 'Non-Member') && con.Contact_Sub_Type__c != 'Estate/Trust') {
                if(String.valueOf(con.Social_Insurance_Number__c) != null && String.valueOf(con.Social_Insurance_Number__c) != '' && existingSINSet.contains(String.valueOf(con.Social_Insurance_Number__c)))
                    con.addError('SSN or SIN exists on another contact, please check for duplicates and enter the correct SSN or SIN.');
                
                if(con.Social_Security_Number__c != null && con.Social_Security_Number__c != '' && existingSSNSet.contains(con.Social_Security_Number__c))
                    con.addError('SSN or SIN exists on another contact, please check for duplicates and enter the correct SSN or SIN.');
            }
        }
    }
}