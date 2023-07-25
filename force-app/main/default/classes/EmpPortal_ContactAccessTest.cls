@isTest public class EmpPortal_ContactAccessTest {
     
      public static testmethod void test_ContactcodeCoverageOnly() {        

        User u = [SELECT Id FROM User WHERE Name = 'Matt Millns'][0];
        System.runAs(u) {            
     	 Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PFCC Client').getRecordTypeId();
            
       //     Contact testContact = TestDataFactory.createCOntact(false, 'Employer', 'TESTACCT');
            
         Contact newContact = new Contact();
     	 newContact.RecordTypeId = recordTypeId;
          newContact.lastname = 'Test';
         insert newContact;

        }
        
             // Test  CAse 		  
		System.Test.startTest();
       EmpPortal_ContactRecordAccessV1 batchCase = new EmpPortal_ContactRecordAccessV1(u.id);
        Database.executeBatch(batchCase);
		System.Test.stopTest();            
	}

}