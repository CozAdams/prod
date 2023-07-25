/*********************************************************************************************
Created By: Brandon McLArty
Created: 09/10/2022 
Notes: This is a batch job to update the ' Prospect ' accounts owner based on Billing state of account and the AD State Assignment table.
*********************************************************************************************/
global class BatchAccountOwnerUpdate3 implements Schedulable, Database.Batchable<sObject> {
    
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
               List<Account> ReCon = [select id,ownerid from Account where BillingState = :Ostate and ownerid <> :OOwnerid and 
                                      type = 'Prospect' and npe01__SYSTEMIsIndividual__c = false];

             List<Account> listToUpdate = new List<Account>(); 
             	listToUpdate.clear();
                  for(Account ReAcct: ReCon) {  
                      ReAcct.ownerid = OOwnerid;
                      listToUpdate.add(ReAcct);
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