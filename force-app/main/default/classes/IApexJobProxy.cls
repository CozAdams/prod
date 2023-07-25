/**
 * @author Nathan Ross, Bluewolf LLC
 * @date 2017-11
 *
 * @group ProxyPattern
 *
 * @description proxy interface for standard methods that schedule, enqueue, abort, or query apex jobs
 */
public interface IApexJobProxy {

    /**
     * @description
     * proxy for System.database.executeBatch
     * Submits a batch Apex job for execution using the specified class and scope.
     *
     * We do not use Database.Batchable<Sobject> as a parameter because the stub API does not allow
     * stubbing interfaces which use that as a parameter
     */
    void executeBatch(Object batchClassObject, Integer scope);


    /**
     * @description
     * proxy for System.enqueueJob
     * Submits a Queueable job for execution
     *
     * @param job queueable job to enqueue
     */
    Id enqueueJob(Queueable job);

    /**
     * @description
     * Database Access proxy for crontrigger records
     *
     * @param cronTriggerId id of cronTrigger to query
     */
    CronTrigger queryCronTrigger(Id cronTriggerId);
}