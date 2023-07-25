/**
* @author Lev
* @date 2021
*
* @description Test class for CommunityInactivityBatch
*/
@isTest
private with sharing class CommunityInactivityBatchTest {
    static Account userOrg;
    static Contact employerContact;
    static Contact memberContact;
    static User employerUser;
    static User memberUser;
    static Map<String, User_Deactivation_Step__c> deactivationSteps;

    // Test data initialization
    static void init() {
        userOrg = TestDataFactory.createAccount(true, 'Organization', 'Community Org');
        employerContact = TestDataFactory.createContact(true, userOrg.Id, 'Last');
        memberContact = TestDataFactory.createContact(true, userOrg.Id, 'Last');
        employerUser = TestDataFactory.createUser(true, 'PFCC Employer Portal', employerContact.Id);
        memberUser = TestDataFactory.createUser(true, 'PFCC Customer Community Plus', memberContact.Id);
        deactivationSteps = TestDataFactory.createUserDeactivationSteps(true);
    }
    
    // Coverage only, since logic is based on community user LastLoginDate (which can't be set programmatically in test)
    @isTest
    static void testBatch_coverageOnly() {
        init();

        // Test
        System.Test.startTest();
        Database.executeBatch(new CommunityInactivityBatch());
        System.Test.stopTest();
    }

    @isTest
    static void testCreateFollowupTasks() {
        init();
        employerUser = [ SELECT Id, LastLoginDate, ContactId, Contact.OwnerId, Contact.AccountId FROM User WHERE Id = :employerUser.Id ];
        Id contactOwnerId = [ SELECT OwnerId FROM Contact WHERE Id = :employerContact.Id ].OwnerId;

        // Test
        System.Test.startTest();
        Task newTask = CommunityInactivityBatch.createFollowupTasks(new List<User>{ employerUser }, deactivationSteps)[0];
        System.Test.stopTest();

        // Assert that a new Task is created with the correct field values
        System.assertEquals('Inactive EP User', newTask.Subject);
        System.assertEquals(System.today(), newTask.ActivityDate);
        System.assertEquals(employerUser.ContactId, newTask.WhoId);
        System.assertEquals('Not Started', newTask.Status);
        System.assertEquals(contactOwnerId, newTask.OwnerId);
    }

    @isTest 
    static void testSchedulable() {
        init();

        // Test
        System.Test.startTest();
        CommunityInactivityBatch batch = new CommunityInactivityBatch();
        String sched = '0 0 23 * * ?';
        String jobId = System.schedule('Test Batch', sched, batch); 
        System.Test.stopTest();

        CronTrigger cron = [ SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId ];
        System.assertEquals(sched, cron.CronExpression);
    }
}