/*******************************************************************************************************
* @author Brandon
* @date 06/2022*
* @description  Batch for triggering deactivation of commuity users with a death date
*/
global class CommunityDeathDeActivationBatch implements Database.Batchable<sObject>, Schedulable {
  //  private static List<String> COMMUNITY_PROFILES = new List<String>{ 'PFCC Employer Portal', 'PFCC Customer CPL - Member', 'PFCC Customer Community Plus', 'PFCC Employer Portal' };
     private static List<String> COMMUNITY_PROFILES = new List<String>{'PFCC Customer CPL - Member' };
    
    private String query = 'SELECT Id,  IsActive, Profile.Name, ContactId, Contact.Death_date__c' +
        ' FROM User' +
        ' WHERE IsActive = true' +
                ' AND (Contact.Death_date__c != null) limit 2';  // Find active users with a death date.
            //' Profile.Name IN :COMMUNITY_PROFILES  and' +    
    
    /** BATCHABLE METHODS **/ 
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);      
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
         List<User> DeactList = [select id from user where  IsActive = true and  Contact.Death_date__c != null limit 2];    
        system.debug('users to update : ' + deactlist);
        
          List<User> listToUpdate = new List<User>(); 
                listToUpdate.clear();
                  for(User DeactU: DeactList) {  
                      DeactU.isactive = false;
                      listToUpdate.add(DeactU);
                   }
              update listToUpdate;
    }

    global void finish(Database.BatchableContext bc) {
     }
    
  
      global void execute(SchedulableContext sc) {
       CommunityDeathDeActivationBatch batch = new CommunityDeathDeActivationBatch();
        Database.executeBatch(this, 100);
        }
  }