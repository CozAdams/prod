@isTest 
public class BatchAccountOwnerUpdate3_Test {
    
    
    Private static testMethod void AssignAccount_Test() {
          	User usr = [Select id from User where Id = :UserInfo.getUserId()];          
          
            AD_State_Assignment__c  ADAss = new  AD_State_Assignment__c ( State__c = 'BB', User__c = '0050V000006Y1EqQAK');
            insert ADAss;
            AD_State_Assignment__c  ADAss2 = new  AD_State_Assignment__c ( State__c = 'CC', User__c = '0050V000006Y1EqQAK');
            insert ADAss2;
              
              
            Account  AddAcct1 = new  Account ( Name = 'AA test',   billingstate = 'BB',
                                             type = 'Prospect', npe01__SYSTEMIsIndividual__c = false,
                                            ownerid = '005d0000005MIA9');
            insert AddAcct1;
        
            Account  AddAcct2 = new  Account ( Name = 'BA test',billingstate = 'CC',
                                              type = 'Prospect', npe01__SYSTEMIsIndividual__c = false,
                                             ownerid = '005d0000005MIA9');
            insert AddAcct2;
        
            Account  AddAcct3 = new  Account ( Name = 'CC test',billingstate = 'CC',
                                             type = 'Prospect', npe01__SYSTEMIsIndividual__c = false, ownerid = '005d0000005MIA9' );
            insert AddAcct3;
           
          
 //         String	OState = 'AA';
    //      String	OOwnerid  = usr.Id;
 //         string   OOwnerid = '0050V000006Y1EqQAK';
           {
            Test.startTest();
           // insertTestTerritory(ADAss.Id);
            BatchAccountOwnerUpdate3 sh1 = new BatchAccountOwnerUpdate3();      
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
        
        
             List<Account> ReCon = [select id,ownerid,name, Billingstate 
                                      from Account where Billingstate = :Ostate and ownerid <> :OOwnerid
                                   AND type != 'Vendor' and npe01__SYSTEMIsIndividual__c = false  ];
             List<Account> listToUpdate = new List<Account>(); 
             
                  for(Account ReContact: ReCon) {  
                 //     ReContact.ownerid = OOwnerid;
                      ReContact.ownerid = OOwnerid;
                      listToUpdate.add(ReContact);
                      update listToUpdate;  
                }  		 
        
        		 
        	update listToUpdate;  
 
     }
    
            }
}