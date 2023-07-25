/**
 * @author Nathan Ross, Bluewolf
 *
 * @date 2018-10
 *
 * @group ContactUserCreation
 *
 * @description test class for ContactCommunityUserBatchable
 */
@isTest
private class ContactCommunityUserBatchableTest {
    static Integer SCOPE_SIZE = 100;
    static final Integer RECORD_COUNT = 100;

    @testSetup static void setup() {
        SobjectFactory.create(RECORD_COUNT, Contact.SobjectType, new Map<SobjectField, Object> {
                Contact.Member_Portal_User__c => true,
                Contact.User_Needed_Datetime__c => System.now().addHours(-2),
                Contact.FirstName => new SObjectFieldProviders.UniqueStringProvider('first'),
                Contact.Email => new SObjectFieldProviders.UniqueStringProvider('test_xyz=exmaple@example.com')
        });
    }

    @isTest static void testBatch() {
        String queryString = 'Select Id From Contact';
        List<Contact> expected = Database.query(queryString);

        Test.startTest();
        Database.executeBatch(new ContactCommunityUserBatchable(new LoggerMock()), SCOPE_SIZE);
        Test.stopTest();

        Integer userCount = [SELECT COUNT() FROM User WHERE ContactId IN :Pluck.ids(expected)];
        System.assertEquals(pluck.ids(expected).size(), userCount,
            'As a marketing user, I need e-mails sent out to new contacts I enroll in the community, even if contacts are brought in from an external system');
    }
}