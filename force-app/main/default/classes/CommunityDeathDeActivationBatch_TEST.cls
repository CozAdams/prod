/**
* @author Brandon 
* @date 06-2021
*
* @description Test class for CommunityDeathDeActivationBatch
*/
@isTest

public class CommunityDeathDeActivationBatch_TEST {
   
    static Account userOrg;
    static Contact userContact;
    static User commUser;
//    static Map<String, User_Deactivation_Step__c> deactivationSteps;

    // Test data initialization
    static void init() {
//        deactivationSteps = TestDataFactory.createUserDeactivationSteps(true);
        userOrg = TestDataFactory.createAccount(true, 'Organization', 'Community Org');
system.debug('user Org : ' + userorg);
        
        userContact = TestDataFactory.createContact(true, userOrg.Id, 'Last');
system.debug('user userContact: ' + userContact);     
        
        userContact.Death_Date__c = System.today() ;
        system.debug('user today: ' + System.today());
        update userContact;
        
        commUser = TestDataFactory.createUser(false, 'PFCC Customer Community Plus', userContact.Id);
        insert commUser;
    }
    
    // Coverage only, since logic is based on community user LastLoginDate (which can't be set programmatically in test)
    @isTest
     static void testBatch_coverageOnly() {
         init();

         // Test
         System.Test.startTest();
         Database.executeBatch(new CommunityDeathDeActivationBatch());
         System.Test.stopTest();
     }
    
   
      
static void execute(Database.BatchableContext bc, List<User> scope) {
    System.Test.startTest();
         List<User> DeactList = [select id from user where  IsActive = true and  Contact.Death_date__c != null limit 2];    
        system.debug('users to update : ' + deactlist);
        
          List<User> listToUpdate = new List<User>(); 
                listToUpdate.clear();
                  for(User DeactU: DeactList) {  
                      DeactU.isactive = false;
                      listToUpdate.add(DeactU);
                   }
              update listToUpdate;
    System.Test.stopTest();
    }
    
    
    
    

  
    static void testDeactivate() {
        date deathdate = System.today();
//     @isTest     init();
                List<Contact> getDeathDeactcontactList = [select id,Death_date__c from contact where  death_date__c != null]; 
         system.debug('users to update : ' + getDeathDeactcontactList);
            
//           contact.death_date__c = deathdate;
        update getDeathDeactcontactList;
        
    //     Id contactId = [ select id,Death_date__c from contact where  id = '003d000000CIhXrAAL' ];
  //      Death_date__c = System.today();
  //          update contactid;
        
   
/*        for(Contact DeathDeactU:getDeathDeactcontactList) {  
                      DeathDeactU.Death_date__c = System.today();
                      listToUpdateDeath.add(DeathDeactU);
                   }
              update listToUpdateDeath;
 */     
        
      commUser = [ SELECT Id, username FROM User WHERE  isactive = true and contact.death_date__c != null   ];        
        
         List<User> DeactList = [select id from user where  IsActive = true and  Contact.Death_date__c != null limit 2];    
        system.debug('users to update : ' + deactlist);
        
          List<User> listToUpdate = new List<User>(); 
                listToUpdate.clear();
                  for(User DeactU: DeactList) {  
                      DeactU.isactive = false;
                      listToUpdate.add(DeactU);
                   }
              update listToUpdate;
        
        // Test
        // 
        // 
     {
            Test.startTest();
           // insertTestTerritory(ADAss.Id);
            CommunityDeathDeActivationBatch sh1 = new CommunityDeathDeActivationBatch();      
            String sch = '0 0 23 * * ?';
            system.schedule('Test check', sch, sh1);
            Test.stopTest();
    }
        
        
        
        System.Test.startTest();
        Database.executeBatch(new CommunityDeathDeActivationBatch());
        
          
       CommunityDeathDeActivationBatch batch = new CommunityDeathDeActivationBatch();
        
        
        System.Test.stopTest();
        
        commUser = [ SELECT IsActive FROM User WHERE Id = :commUser.Id ];
        userContact = [ SELECT Member_Portal_User__c FROM Contact WHERE Id = :userContact.Id ];

        // Assert that the user and contact were deactivated
        System.assertEquals(false, commUser.IsActive);
        System.assertEquals(false, userContact.Member_Portal_User__c);
    }
    
}