/*******************************************************************************************************
* @author Lev
* @date 2021
*
* @description 	Batch for deactivating community users when triggered by CommunityInactivityBatch
*/
public class CommunityDeactivationBatch implements Database.Batchable<sObject>, Database.Stateful {
    private static List<String> MEMBER_COMMUNITY_PROFILES = new List<String>{ 'PFCC Customer CPL - Member', 'PFCC Customer Community Plus' };
    private static List<String> COMMUNITY_PROFILES = new List<String>{ 'PFCC Employer Portal', 'PFCC Customer CPL - Member', 'PFCC Customer Community Plus' };
    private final String QUERY = 'SELECT Id, Deactivation_Date__c, IsActive, Profile.Name, ContactId FROM User'
		+ ' WHERE IsActive = true AND Deactivation_Date__c IN :DEACTIVATION_DATES';

    private Map<String, User_Deactivation_Step__c> DEACTIVATION_STEPS;
	private List<Date> DEACTIVATION_DATES;
	
	public CommunityDeactivationBatch() {
		// Get Deactivation Steps and map by name for easier retrieval
		DEACTIVATION_STEPS = new Map<String, User_Deactivation_Step__c>();
		for (User_Deactivation_Step__c step : [
			SELECT Name, Trigger_Date__c, Action_Date__c, Email_Template_Name__c 
			FROM User_Deactivation_Step__c
			WHERE Batch_Process__c = 'Deactivation'
		]) {
			DEACTIVATION_STEPS.put(step.Name, step);
		}
		
		// Set query dates 
		DEACTIVATION_DATES = new List<Date>{ 
            DEACTIVATION_STEPS.get('Deactivate').Trigger_Date__c/*, 
			DEACTIVATION_STEPS.get('Deactivation Warning 1').Trigger_Date__c,
			DEACTIVATION_STEPS.get('Deactivation Warning 1').Trigger_Date__c*/
		};
	}
	
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(QUERY);
	}
	
	public void execute(Database.BatchableContext bc, List<User> scope) {
		List<User> usersToWarn = new List<User>();
		List<User> usersToDeactivate = new List<User>();
		
		// Separate User records into related groups for processing
		for (User inactiveUser : scope) {
			if (inactiveUser.Deactivation_Date__c == System.today() && inactiveUser.IsActive) {
				usersToDeactivate.add(inactiveUser);
			}
			// else {
				// usersToWarn.add(inactiveUser);
			// }
		}
		
		// Deactivate users
        if (!usersToDeactivate.isEmpty()) {
            for (User inactiveUser : usersToDeactivate) {
                inactiveUser.IsActive = false;
            }
            Database.update(usersToDeactivate, false);
        }

        // if (!usersToWarn.isEmpty()) {
            // Send warning email notifications to users 
        // }
	}
	
	public void finish(Database.BatchableContext bc) {
		// Empty
	}
}