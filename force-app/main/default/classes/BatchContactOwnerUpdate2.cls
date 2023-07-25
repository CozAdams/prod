/*********************************************************************************************
Created By: Brandon McLArty
Created: 09/10/2020 
Notes: This is a batch job to update the account & contact owner based on the AD State Assignment table.
*********************************************************************************************/

global class BatchContactOwnerUpdate2 implements Schedulable, Database.Batchable<sObject> {
    
        global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.Querylocator query;
        query = Database.getQueryLocator([ select user__c, State__c  from AD_State_Assignment__c ]);  

        return query;            
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {         
      List<AD_State_Assignment__c> ADA = (List<AD_State_Assignment__c>)scope;    
            //This Query gets ad and state assignments
  //    List<AD_State_Assignment__c> CriteriaList = [select user__c, State__c  from AD_State_Assignment__c ];

         for(AD_State_Assignment__c OwnerCriteria: ADA) {
        	  	String	OState = OwnerCriteria.State__c;
         		String	OOwnerid  = OwnerCriteria.User__c;

		// ADD NAPAD to Gabe Lopez here when available
               List<Contact> ReCon = [select id,ownerid from Contact where Mailingstate = :Ostate and ownerid <> :OOwnerid  AND Preferred_Language__c <> 'spanish' ];

             List<Contact> listToUpdate = new List<Contact>(); 
             	listToUpdate.clear();
                  for(Contact ReContact: ReCon) {  
                      ReContact.ownerid = OOwnerid;
                      listToUpdate.add(ReContact);
                   }
              update listToUpdate;
         }        
    }            

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 100);
    }    
}