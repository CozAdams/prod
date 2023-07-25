/**
* @author Lev
* @date 2021
*
* @description Test class for CommunityDeactivationBatch
*/
@isTest
private with sharing class CommunityDeactivationBatchTest {
    static Account userOrg;
    static Contact userContact;
    static User commUser;
    static Map<String, User_Deactivation_Step__c> deactivationSteps;

    // Test data initialization
    static void init() {
        deactivationSteps = TestDataFactory.createUserDeactivationSteps(true);
        userOrg = TestDataFactory.createAccount(true, 'Organization', 'Community Org');

        userContact = TestDataFactory.createContact(true, userOrg.Id, 'Last');
        commUser = TestDataFactory.createUser(false, 'PFCC Customer Community Plus', userContact.Id);
        commUser.Deactivation_Date__c = System.today();
        insert commUser;
    }
    
    // Coverage only, since logic is based on community user LastLoginDate (which can't be set programmatically in test)
    // @isTest
    // static void testBatch_coverageOnly() {
    //     init();

    //     // Test
    //     System.Test.startTest();
    //     Database.executeBatch(new CommunityDeactivationBatch());
    //     System.Test.stopTest();
    // }

    @isTest
    static void testDeactivate() {
        init();
        commUser = [ SELECT Id, LastLoginDate, ContactId, Contact.OwnerId, Contact.AccountId FROM User WHERE Id = :commUser.Id ];
        Id contactOwnerId = [ SELECT OwnerId FROM Contact WHERE Id = :userContact.Id ].OwnerId;

        // Test
        System.Test.startTest();
        Database.executeBatch(new CommunityDeactivationBatch());
        System.Test.stopTest();

        commUser = [ SELECT IsActive FROM User WHERE Id = :commUser.Id ];
        userContact = [ SELECT Member_Portal_User__c FROM Contact WHERE Id = :userContact.Id ];

        // Assert that the user and contact were deactivated
        System.assertEquals(false, commUser.IsActive);
        System.assertEquals(false, userContact.Member_Portal_User__c);
    }
}