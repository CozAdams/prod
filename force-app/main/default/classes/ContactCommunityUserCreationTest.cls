/**
* @author Nathan Ross
* @date 10/20/2018
*
* @group Enrollment
*
* @description tests for ContactCommunityUserCreation
*/
@isTest
private class ContactCommunityUserCreationTest {
    static List<Contact> contacts;
    static List<Opportunity> opptys;
    static final Integer RECORD_COUNT = 2; //ContactCommunityUserSchedulable.SCOPE_SIZE;

    @TestSetup
    static void setup() {
        List<Contact> contacts = buildSomeContacts();
        // avoid hitting dupeblocker on test that inserts contacts
        for (Contact contactSobj : contacts) {
            contactSobj.LastName += 'jones';
            contactSobj.Email += 'jones';
        }
        insert contacts;
        insert buildSomeOpportunities(contacts);
    }

    static List<Contact> buildSomeContacts() {
        List<Contact> contacts = 
            SobjectFactory.build(RECORD_COUNT, Contact.SobjectType, new Map<SObjectField, Object>{
                    Contact.Email => new SobjectFieldProviders.UniqueStringProvider('a@b.com'),
                    Contact.FirstName => new SObjectFieldProviders.UniqueStringProvider('first')
            });
        for (Contact contactSobj : contacts) {
            contactSobj.LastName = 'Test' + contactSobj.LastName;
        }
        return contacts;
    }

    static List<opportunity> buildSomeOpportunities(List<Contact> contacts) {
        return SobjectFactory.build(RECORD_COUNT, Opportunity.SobjectType,
            Opportunity.Contact_Name__c, new SobjectFieldProviders.ListProvider(
                new List<Id>(pluck.ids(contacts))));
    }

    static void assertPlannedUserCreation(List<Contact> contacts) {
        List<Contact> contactsNow = [ SELECT User_Needed_Datetime__c FROM Contact WHERE Id IN : contacts ];
        for (Contact contact : contactsNow) {
            System.assert(contact.User_Needed_Datetime__c <= System.now() &&
                contact.User_Needed_Datetime__c >= System.now().addMinutes(-1),
                'as a marketing user, if a contact is made eligible for a community user and does not already have one, i expect it to be planned for user creation');
        }
    }

    static void assertNoPlannedUserCreation(List<Contact> contacts) {
        List<Contact> contactsNow = [ SELECT User_Needed_Datetime__c FROM Contact WHERE Id IN : contacts ];
        for (Contact contact : contactsNow) {
            System.assertEquals(null, contact.User_Needed_Datetime__c,
                'As a marketing user, I only want to grant customer community user access to customers who have completed enrollment');
        }
    }

    @isTest
    static void testInsertContacts_positive() {
        List<Contact> contacts = buildSomeContacts();
        for (Contact contactSobj: contacts) {
            contactSobj.Member_Portal_User__c = true;
        }

        Test.startTest();
            insert contacts;
        Test.stopTest();

        assertPlannedUserCreation(contacts);
        ContactCommunityUserCreation.createUserForContacts(contacts);
    }

    @isTest
    static void testInsertContacts_negative() {
        List<Contact> contacts = buildSomeContacts();

        Test.startTest();
            insert contacts;
        Test.stopTest();

        assertNoPlannedUserCreation(contacts);
    }

    @isTest
    static void testUpdateContacts_positive() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        for (Contact contactSobj : contacts) {
            contactSobj.Member_Portal_User__c = true;
        }

        Test.startTest();
            update contacts;
        Test.stopTest();

        assertPlannedUserCreation(contacts);
    }

    @isTest
    static void testUpdateContacts_negative() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];

        Test.startTest();
            update contacts;
        Test.stopTest();

        assertNoPlannedUserCreation(contacts);
    }

    @isTest
    static void testInsertOpportunities_positive() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        List<Opportunity> opportunities = buildSomeOpportunities(contacts);
        for (Opportunity oppty : opportunities) {
            oppty.StageName = ContactCommunityUserCreation.STAGE_ENROLLMENT_COMPLETE;
        }

        Test.startTest();
            insert opportunities;
        Test.stopTest();

        assertPlannedUserCreation(contacts);
    }

    @isTest
    static void testInsertOpportunities_negative() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        List<Opportunity> opportunities = buildSomeOpportunities(contacts);

        Test.startTest();
            insert opportunities;
        Test.stopTest();

        assertNoPlannedUserCreation(contacts);
    }

    @isTest
    static void testUpdateOpportunities_positive() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        List<Opportunity> opportunities = buildSomeOpportunities(contacts);
        insert opportunities;
        for (Opportunity oppty : opportunities) {
            oppty.StageName = ContactCommunityUserCreation.STAGE_ENROLLMENT_COMPLETE;
        }

        Test.startTest();
            update opportunities;
        Test.stopTest();

        assertPlannedUserCreation(contacts);
    }

    @isTest
    static void testUpdateOpportunities_negative() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        List<Opportunity> opportunities = [ SELECT Id FROM Opportunity ];
        for (Opportunity oppty : opportunities) {
            oppty.Description = 'hi i am an oppty';
        }

        Test.startTest();
            update opportunities;
        Test.stopTest();

        assertNoPlannedUserCreation(contacts);
    }

    @isTest
    static void testQueryNeedsUserBeforeThreshold() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        List<Contact> expected = new List<Contact>();
        for (Integer i=0; i<RECORD_COUNT/2; i++) {
            contacts[i].User_Needed_Datetime__c =
                System.now().addHours(-2 * ContactCommunityUserCreation.USER_CREATION_DELAY_HOURS);
            expected.add(contacts[i]);
        }
        update expected;

        Test.startTest();
            List<Contact> contactsToCreateUsersFor = Database.query(
                new ContactCommunityUserCreation().queryNeedsUserBeforeThreshold().getQuery());
        Test.stopTest();

        System.assertEquals(pluck.ids(expected), pluck.ids(contactsToCreateUsersFor),
            'We expect when automatically creating community users to find contacts that were made eligible long enough ago that any marketing emails have been sent');
    }

    @isTest
    static void testUserCreation_positive() {
        List<Contact> contacts = [ SELECT Id FROM Contact ];
        for (Contact contactSobj : contacts) {
            contactSobj.User_Needed_Datetime__c =
                System.now().addHours(-2 * ContactCommunityUserCreation.USER_CREATION_DELAY_HOURS);
        }
        update contacts;
        LoggerMock mockLogger = new LoggerMock();
        IContactCommunityUserCreation impl = new ContactCommunityUserCreation();


        Test.startTest();
            // we are also testing here that queryNeedsUserBeforeThreshold queries the fields needed for user creation
            List<Contact> contactsToCreateUsersFor = Database.query(
                new ContactCommunityUserCreation().queryNeedsUserBeforeThreshold().getQuery());
            impl.createUserForContacts(mockLogger, contactsToCreateUsersFor);
        Test.stopTest();

        System.assert(mockLogger.loggedEvents.isEmpty(),
            'We expect no errors to be logged when users can be created without issue, instead what was logged :' + JSON.serialize(mockLogger.loggedEvents));
        System.assertEquals(pluck.ids(contacts), pluck.ids(User.ContactId, [ SELECT ContactId FROM User WHERE ContactId IN : Contacts ]),
            'As a marketing user, I need community users to be created automatically for enrolled contacts on a delay');
        System.assert([ SELECT id FROM Contact WHERE User_Needed_Datetime__c != null ].isEmpty(),
            'We expect that if we are able to successfully create a user for a contact, we mark them as no longer needing a user');
    }
}