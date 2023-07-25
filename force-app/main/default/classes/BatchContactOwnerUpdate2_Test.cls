@isTest
public class BatchContactOwnerUpdate2_Test {
    
    
    Private static testMethod void AssignAccount_Test() {
          	User usr = [Select id from User where Id = :UserInfo.getUserId()];          
          
            AD_State_Assignment__c  ADAss = new  AD_State_Assignment__c ( State__c = 'BB', User__c = '0050V000006Y1EqQAK');
            insert ADAss;
            AD_State_Assignment__c  ADAss2 = new  AD_State_Assignment__c ( State__c = 'CC', User__c = '0050V000006Y1EqQAK');
            insert ADAss2;
              
              
            Contact  AddCon = new  Contact ( firstname = 'AA test', lastname= 'aatest', Contact_Status__c= 'Active', mailingstate = 'BB',ownerid = '005d0000005MIA9');
            insert AddCon;
        
            Contact  AddCon2 = new  Contact ( firstname = 'BA test',lastname ='assignment1',Contact_Status__c= 'Active',mailingstate = 'CC',ownerid = '005d0000005MIA9');
            insert AddCon2;
           
          
 //         String	OState = 'AA';
    //      String	OOwnerid  = usr.Id;
 //         string   OOwnerid = '0050V000006Y1EqQAK';
           {
            Test.startTest();
           // insertTestTerritory(ADAss.Id);
            BatchContactOwnerUpdate2 sh1 = new BatchContactOwnerUpdate2();      
            String sch = '0 0 23 * * ?';
            system.schedule('Test check', sch, sh1);
            Test.stopTest();
            }
           
         //   List<AD_State_Assignment__c> ADA = (List<AD_State_Assignment__c>);    
            //This Query gets ad and state assignments
            List<AD_State_Assignment__c> ADA = [select user__c, State__c  from AD_State_Assignment__c ];
                
             for(AD_State_Assignment__c OwnerCriteria: ADA) {
                    String	OState = OwnerCriteria.State__c;
                    String	OOwnerid  = OwnerCriteria.User__c;
        
        
             List<Contact> ReCon = [select id,ownerid,name, mailingstate 
                                      from Contact where Mailingstate = :Ostate and ownerid <> :OOwnerid
                                   AND Preferred_Language__c <> 'spanish' ];
             List<Contact> listToUpdate = new List<Contact>(); 
             
                  for(Contact ReContact: ReCon) {  
                 //     ReContact.ownerid = OOwnerid;
                      ReContact.ownerid = OOwnerid;
                      listToUpdate.add(ReContact);
                      update listToUpdate;  
                }  		 
        
        		 
        	update listToUpdate;  
 
     }
    
            }
    

}