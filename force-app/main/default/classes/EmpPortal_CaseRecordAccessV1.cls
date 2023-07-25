public class EmpPortal_CaseRecordAccessV1 implements
     Database.Batchable<sObject>, Database.Stateful {

    public Integer AcctrecordsProcessed = 0;
    public Integer AcctrecordsExposed = 0;
         
    private String strParameter;
    public EmpPortal_CaseRecordAccessV1(String strParam) {
        strParameter = strParam;
    }
        
           
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
   //       'SELECT ID, casenumber, recordtype.name,reason, Submitted_Date__c from case'
          'SELECT ID, casenumber, recordtype.name,reason, Submitted_Date__c from case'
        );
    }
                
    public void execute(Database.BatchableContext bc, List<Case> scope){
        // process each batch of records
       for (Case cases : scope) {            
        string    AcId = cases.id;
        string    AcName = cases.casenumber + '	' + cases.recordtype.name + '	' + cases.reason + '	' + cases.Submitted_Date__c ;
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
                   		Case__c = AcID,
                       Object__c = 'Case');
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