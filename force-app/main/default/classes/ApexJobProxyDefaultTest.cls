/**
 * @author Nathan Ross, Bluewolf LLC
 * @date 2017-11
 *
 * @group ProxyPattern
 *
 * @description tests for ApexJobProxyDefault
 */
@isTest
private class ApexJobProxyDefaultTest {

    static IApexJobProxy service;

    static void setup() {
        service = new ApexJobProxyDefault();
    }

    static TestMethod void testExecuteBatchWithScope() {

        setup();

        Integer someScopeSize = 2;
        BatchableMock mockBatchableInstance = new BatchableMock(someScopeSize);
        final ApexClass passedInClass = [SELECT Id FROM ApexClass WHERE Name=:'BatchableMock'];

        Test.startTest();
            service.executeBatch(mockBatchableInstance, someScopeSize);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT Count()
            FROM AsyncApexJob
            WHERE JobType='BatchApex' AND ApexClassId = :passedInClass.Id
        ],
            'we expect that the batch is passed into a Database.ExecuteBatch call');
        System.assertEquals(someScopeSize, BatchableMock.scopeSize,
            'we expect that the method calls database.executeBatch with the provided batch and scopesize');
    }
    
    static TestMethod void testEnqueueJob() {
    
        setup();
    
        Test.startTest();
            service.enqueueJob(new MockQueueable());
        Test.stopTest();

        System.assertEquals(1, [
            SELECT Count()
            FROM AsyncApexJob
            WHERE JobType='Queueable'
        ],
            'we expect that the queueable is passed into a System.enqueueJob call');
    }

    
    static TestMethod void testQueryCronTrigger() {
    
        setup();
        
        String JOB_NAME = 'BatchableMock';
        System.scheduleBatch(new BatchableMock(), JOB_NAME, 10);
        CronTrigger someCronTrigger = [ SELECT StartTime FROM CronTrigger WHERE CronJobDetail.Name=:JOB_NAME ]; 
        
        Test.startTest();
            CronTrigger returned = service.queryCronTrigger(someCronTrigger.Id);
        Test.stopTest();

        System.assertEquals(someCronTrigger.Id, returned.Id,
            'we expect that a cron trigger sobject is returned with the provided id');
        System.assertEquals(someCronTrigger.StartTime, returned.StartTime,
            'we expect it includes queried information about the crontrigger with that id');
    }
    
    class MockQueueable implements Queueable {
        public void execute(QueueableContext context) {}
    }
}