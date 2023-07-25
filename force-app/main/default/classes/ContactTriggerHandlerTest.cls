@isTest 
public class ContactTriggerHandlerTest {
    
    final static Id CON_PFCC_CLIENT_REC_ID = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PFCC Client').getRecordTypeId();



    @TestSetup
    static void setup() {
        List<Contact> conList = new List<Contact>();
        
        Contact  estateContact = new  Contact (
            RecordTypeId = CON_PFCC_CLIENT_REC_ID,
            LastName = 'Test',
            Contact_Sub_Type__c = 'Estate/Trust',
            Social_Insurance_Number__c = 11111,
            Social_Security_Number__c = '11111111111'
        );
        
        Contact  nonEstateContact = new  Contact (
            RecordTypeId = CON_PFCC_CLIENT_REC_ID,
            LastName = 'Test',
            Contact_Sub_Type__c = 'Other',
            Social_Insurance_Number__c = 22222,
            Social_Security_Number__c = '2222222222'
        );
        
        conList.add(estateContact);
        conList.add(nonEstateContact);
        insert conList;
        update conList;
    }
    
    static testMethod void checkDuplicateNonEstate () {
        Contact  nonEstateContact = new  Contact (
            RecordTypeId = CON_PFCC_CLIENT_REC_ID,
            LastName = 'Test',
            Contact_Sub_Type__c = 'Other',
            Social_Insurance_Number__c = 22222,
            Social_Security_Number__c = '2222222222'
        );
        
        database.insert(nonEstateContact, false);
    }
}