public class EmpPortal_ContactRecordAccessV1 implements
     Database.Batchable<sObject>, Database.Stateful {

    public Integer AcctrecordsProcessed = 0;
    public Integer AcctrecordsExposed = 0;
         
    private String strParameter;
    public EmpPortal_ContactRecordAccessV1(String strParam) {
        strParameter = strParam;
    } 
        
           
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
   //       'SELECT ID, name from contact where name like \'T%\''
          'SELECT ID, name from contact'
        );
    }
                
    public void execute(Database.BatchableContext bc, List<Contact> scope){
        // process each batch of records
       for (Contact Contact : scope) {            
        string    AcId = Contact.id;
        string    AcName = Contact.name;
        //string UID = '0050V0000079em2';
           string UID = strparameter;
            
             List<UserRecordAccess> Aacct = [select MaxAccessLevel,RecordId from UserRecordAccess where  UserId =: UID AND RecordID =: AcId ];
          
            for(UserRecordAccess URA: Aacct ) { 
 //           System.debug('Account ID and Name and ID' + AcId + '	' + AcName);
           if(URA.MaxAccessLevel <> 'None'){
            	System.debug('HAS ACCESS--->>' + AcId + '	' + AcName);
               
               Employer_Portal_Exposed_Record__c er =  new Employer_Portal_Exposed_Record__c (
                   	   Record_Name__c= AcName, 
                       RecordID__c = AcID,
                       User__c = UID,
                       MaxAccessLevel__c = URA.MaxAccessLevel,
                   		Contact__c = AcID,
                       Object__c = 'Contact');
                 insert(er);
              AcctrecordsExposed = AcctRecordsExposed + 1;
            }                   
             AcctrecordsProcessed = AcctrecordsProcessed + 1;
           }
        }   
     
    }
     
    public void finish(Database.BatchableContext bc){
        System.debug(AcctrecordsProcessed + ' Account records exposed ');
       
    }
}