/*******************************************************************************************************
* @author Lev
* @date 2021
*
* @description 	Batch for triggering inactive community user actions
*/
global class CommunityInactivityBatch implements Database.Batchable<sObject>, Schedulable {
	private static List<String> COMMUNITY_PROFILES = new List<String>{ 'PFCC Employer Portal', 'PFCC Customer CPL - Member', 'PFCC Customer Community Plus' };
    private Map<String, User_Deactivation_Step__c> DEACTIVATION_STEPS;
	private List<Date> WARNING_DATES;
	private Date START_COUNTDOWN_CUTOFF;
	private Date STOP_COUNTDOWN_CUTOFF;
	private Date NO_LOGIN_CUTOFF_DATE;
	
	private String query = 'SELECT Id, LastLoginDate, IsActive, Profile.Name, ContactId, Contact.AccountId, Contact.OwnerId' +
	 	' FROM User' +
		' WHERE' + 
			' (DAY_ONLY(LastLoginDate) IN :WARNING_DATES AND Profile.Name = \'PFCC Employer Portal\')' + // Inactive warnings, create Tasks
			' OR (Profile.Name IN :COMMUNITY_PROFILES' +
				' AND IsActive = true' +
				' AND (' +
					' (LastLoginDate < :START_COUNTDOWN_CUTOFF AND Deactivation_Date__c = null)' + 		// Last login overdue, set deactivation date  
					' OR (LastLoginDate = null AND CreatedDate <= :NO_LOGIN_CUTOFF_DATE)' +				// No login, deactivate immediately
					' OR (LastLoginDate >= :STOP_COUNTDOWN_CUTOFF AND Deactivation_Date__c != null)))';	// Logged in during deactivation, clear deactivation date
	
	/** BATCHABLE METHODS **/ 
	global CommunityInactivityBatch() {
		// Get Deactivation Steps and map by name for easier retrieval
		DEACTIVATION_STEPS = new Map<String, User_Deactivation_Step__c>();
		for (User_Deactivation_Step__c step : [
			SELECT Name, Trigger_Date__c, Action_Date__c, Email_Template_Name__c, Trigger_Number_of_Days__c 
			FROM User_Deactivation_Step__c
			WHERE Batch_Process__c = 'Inactivity'
		]) {
			DEACTIVATION_STEPS.put(step.Name, step);
		}
		
		// Set query dates 
		WARNING_DATES = new List<Date>{ 
			DEACTIVATION_STEPS.get('Inactivity Warning 1').Trigger_Date__c,
			DEACTIVATION_STEPS.get('Inactivity Warning 2').Trigger_Date__c
		};

        START_COUNTDOWN_CUTOFF = DEACTIVATION_STEPS.get('Start Deactivation Countdown').Trigger_Date__c;
		STOP_COUNTDOWN_CUTOFF = DEACTIVATION_STEPS.get('Stop Deactivation Countdown').Trigger_Date__c;
		NO_LOGIN_CUTOFF_DATE = DEACTIVATION_STEPS.get('No Login Deactivation').Trigger_Date__c;

        if (Test.isRunningTest()) {
			query += ' LIMIT 50';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext bc, List<User> scope) {
		List<User> usersToWarn = new List<User>();
		List<User> usersToUpdate = new List<User>();
        
		// Separate User records into related groups for processing
		for (User inactiveUser : scope) {
			// Get last login date
			Date lastLogin;
			if (inactiveUser.LastLoginDate != null) {
				lastLogin = Date.newInstance(inactiveUser.LastLoginDate.year(), inactiveUser.LastLoginDate.month(), inactiveUser.LastLoginDate.day());
            }
			
			// Add to appropriate user list for processing actions
            if (lastLogin != null && WARNING_DATES.contains(lastLogin)) {
				usersToWarn.add(inactiveUser);
			}
			else {
				usersToUpdate.add(inactiveUser);
			}
		}

		// Create Tasks for warning users 
		if (!usersToWarn.isEmpty()) {
			List<Task> followupTasks = createFollowupTasks(usersToWarn, DEACTIVATION_STEPS);
            if (!followupTasks.isEmpty()) {
				Database.insert(followupTasks, false);
			}
		}
		
		// Update Users for deactivation
		Date DEACTIVATION_DATE = DEACTIVATION_STEPS.get('Start Deactivation Countdown').Action_Date__c;
		for (User inactiveUser : usersToUpdate) {
			// Deactivate user now
			if (inactiveUser.LastLoginDate == null) {
				inactiveUser.IsActive = false;
			}
			// Set deactivation date
			else if (inactiveUser.LastLoginDate < START_COUNTDOWN_CUTOFF) {
				inactiveUser.Deactivation_Date__c = DEACTIVATION_DATE;
			}
			// Clear deactivation date
			else {
				inactiveUser.Deactivation_Date__c = null;
			}
		}
		if (!usersToUpdate.isEmpty()) {
			Database.update(usersToUpdate, false);
		}
	}
	
	global void finish(Database.BatchableContext bc) {
		Database.executeBatch(new CommunityDeactivationBatch());
	}

	/** SCHEDULABLE METHOD **/ 
	global void execute(SchedulableContext sc) {
		CommunityInactivityBatch batch = new CommunityInactivityBatch();
		Database.executeBatch(batch);
	}

	/*******************************************************************************************************
	* @description  Create Task records to notify owners of inactive EP users
	* @param        usersToWarn - inactive EP users
	* @param		deactivationSteps - configured deactivation steps for activity due date
	* @return       Task records to insert
	*/
	@TestVisible 
	private static List<Task> createFollowupTasks(List<User> usersToWarn, Map<String, User_Deactivation_Step__c> deactivationSteps) {
		List<Task> followupTasks = new List<Task>();
		String subject =  'Inactive EP User';

		// Map deactivation steps to set the correct task due date
		Map<Decimal, Date> deactivationDaysToDate = new Map<Decimal, Date>();
		for (User_Deactivation_Step__c step : deactivationSteps.values()) {
			deactivationDaysToDate.put(step.Trigger_Number_of_Days__c, step.Action_Date__c);
		}

		// Create a new Task record for each user
		for (User inactiveUser : usersToWarn) {
			String taskSubject = subject;
			Date lastLogin;
			Date taskDueDate = System.today();

			// Set last login related task details
			if (inactiveUser.LastLoginDate != null) {
				lastLogin = Date.newInstance(inactiveUser.LastLoginDate.year(), inactiveUser.LastLoginDate.month(), inactiveUser.LastLoginDate.day());
				Integer warningDays = lastLogin.daysBetween(System.today());
				subject += ' - ' + warningDays + ' days';
				taskDueDate = deactivationDaysToDate.get(warningDays);
			}

			// Build the task record
			Task followupTask = buildFollowupTask(inactiveUser, subject, taskDueDate);
			followupTasks.add(followupTask);
		}
		return followupTasks;	
	}
	
	/*******************************************************************************************************
	* @description  Create Task record to notify owner of inactive EP user
	* @param        inactiveUser - inactive EP user
	* @param		taskDueDate - activity date based on deactivation step configuration
	* @return       Task records to insert
	*/
	private static Task buildFollowupTask(User inactiveUser, String subject, Date taskDueDate) {
		Task followupTask = new Task();
		followupTask.Subject = subject;
		followupTask.ActivityDate = taskDueDate;
		followupTask.WhoId = inactiveUser.ContactId;
		followupTask.WhatId = inactiveUser.Contact.AccountId;
		followupTask.Status = 'Not Started';
		followupTask.OwnerId = inactiveUser.Contact.OwnerId;
		followupTask.Type = 'Other';
		return followupTask;
	}
}