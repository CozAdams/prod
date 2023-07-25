/**
 * @author Nathan Ross, Bluewolf
 *
 * @date 2018-10
 *
 * @group ContactUserCreation
 *
 * @description tests for ContactCommunityUserSchedulable
 */

@isTest
private class ContactCommunityUserSchedulableTest {
    public static String PREDEFINED_SCHEDULE = '0 0 0 * * ?';
    public static String ACCOUNT_ROLLUP_SCHEDULE = 'ContactCommunityUserSchedulableTest';

    @isTest static void testExecute() {
        ContactCommunityUserSchedulable schedulable = new ContactCommunityUserSchedulable();
        ApexJobProxyMock mockApexJobProxy = new ApexJobProxyMock();
        ContactCommunityUserSchedulable.apexJobProxy = mockApexJobProxy;

        Test.startTest();
            String jobId = System.schedule(ACCOUNT_ROLLUP_SCHEDULE,
                PREDEFINED_SCHEDULE,
                schedulable);
        Test.stopTest();

        System.assertEquals(1, mockApexJobProxy.executeBatchCalls.size(),
            'Expecting that executing the schedulable will execute a batch');
        List<Object> arguments = mockApexJobProxy.executeBatchCalls[0];
        Object batchable = arguments[0];
        System.assert(batchable instanceof Database.Batchable<Sobject>,
            'Expecting a batchable class taking in sobjects to be executed');
        System.assert(batchable instanceof ContactCommunityUserBatchable,
            'Expecting the executed batchable to be ContactCommunityUserBatchable');
        ContactCommunityUserBatchable castedBatchable = (ContactCommunityUserBatchable) batchable;
        System.assertEquals(ContactCommunityUserSchedulable.SCOPE_SIZE, arguments[1],
            'A user should be able to set the batch scope size from the schedulable class');
    }
}