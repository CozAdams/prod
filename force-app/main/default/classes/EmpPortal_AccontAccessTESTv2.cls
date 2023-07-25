@isTest
private class EmpPortal_AccontAccessTESTv2 {  
    
    @isTest 
	static void test_codeCoverageOnly() {
        Account testAccount = TestDataFactory.createAccount(false, 'Employer', 'TESTACCT');
        testAccount.Stone_Campbell_Affiliations__c = 'DOC';

        User u = [SELECT Id FROM User WHERE Name = 'Matt Millns'][0];
        System.runAs(u) {
           insert testAccount; 
        }
		
		// Test Account
		System.Test.startTest();
        EmpPortal_recordAccessV6 batch = new EmpPortal_recordAccessV6(u.id);
        Database.executeBatch(batch);
		System.Test.stopTest();
	}
    
  
    
    /*
		//public void
         Private static testMethod void EmpPortal_recordAccessV6() {
             Test.startTest();
//    Private static testMethod void find_accountRecords_test(){     
     
            Integer AcctrecordsProcessed = 0;
        	Integer AcctrecordsExposed = 0;        
             
             AcctrecordsExposed = AcctRecordsExposed + 1;       
             
                Account  acct = new  Account ( name = 'Tex');
                insert acct;
     
                Contact  AddCon = new  Contact ( firstname = 'AA test', lastname= 'aatest', Contact_Status__c= 'Active', mailingstate = 'BB',ownerid = '005d0000005MIA9');
                insert AddCon;
            
                npe5__Affiliation__c aff   = new npe5__Affiliation__c (npe5__Contact__c = addcon.id, npe5__Organization__c = acct.id );
                 insert aff;
                 
                case  Addcase = new  case ( recordtypeid = '0120V000001pOnyQAE',account_type__c = 'Tax-Deferred 403(b) Retirement Account',
                                          Submitted_Date__c =	system.today(), 
                                           AccountId = acct.id, ContactId = addcon.id);
                insert Addcase;
             
             // add new employer access record 
             //     string      UID = '0050V0000079em2';
   		string      AcID = '001d000000BXwRsAAL';  //001d000000BXwX7AAL
    	string      AcName = 'Texas Christian University';
        string MaxAccess = 'Read';
        string Affid = 'a09d000000DzLgmAAF';
        string obj ='Account';
        string UID = '0050V0000079em2';  
     

             Employer_Portal_Exposed_Record__c  EPER1 = new  Employer_Portal_Exposed_Record__c ( 
                  Record_Name__c= AcName, 
                       RecordID__c = AcID,
                       User__c = UID,
                       MaxAccessLevel__c = MaxAccess,
                   		Affiliation__c = AffID,
                       Object__c = obj);
                insert EPER1;


             
     List<Account> scope = [select ID, NAme  from Account ];
           
       for (Account account : scope) {            
  //      string    AcId = account.id;
  //      string    AcName = account.name;
            
             List<UserRecordAccess> Aacct = [select MaxAccessLevel,RecordId from UserRecordAccess where  UserId =: UID AND RecordID =: AcId ];
          
            for(UserRecordAccess URA: Aacct ) { 
          System.debug('Account ID and Name and ID' + AcId + '	' + AcName);
           if(URA.MaxAccessLevel <> 'None'){
            	System.debug('HAS ACCESS--->>' + AcId + '	' + AcName);
               
               Employer_Portal_Exposed_Record__c er =  new Employer_Portal_Exposed_Record__c (
                   		Record_Name__c= AcName, 
                       RecordID__c = AcID,
                       User__c = UID,
                       MaxAccessLevel__c = URA.MaxAccessLevel,
                   		Organization__c = AcID,
                       Object__c = 'Account');
            
                 insert(er);
              
              AcctrecordsExposed = AcctRecordsExposed + 1;
            }                   
             AcctrecordsProcessed = AcctrecordsProcessed + 1;
           }
        }   
     
  		test.stopTest();
         }
    */
}