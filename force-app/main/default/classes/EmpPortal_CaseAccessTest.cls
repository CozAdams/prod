@isTest 
private class EmpPortal_CaseAccessTest {

    public static testmethod void test_CasecodeCoverageOnly() {        

        User u = [SELECT Id FROM User WHERE Name = 'Matt Millns'][0];
        System.runAs(u) {            
     	 Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('New Enrollment Case').getRecordTypeId();
         Case newCase = new Case();
     	 newCase.RecordTypeId = recordTypeId;
       //     newCase.case_org_pin__c = u.organization__c;
         insert newCase;

        }
        
             // Test  CAse 		  
		System.Test.startTest();
       EmpPortal_CaseRecordAccessV1 batchCase = new EmpPortal_CaseRecordAccessV1(u.id);
        Database.executeBatch(batchCase);
		System.Test.stopTest();            
	}

}