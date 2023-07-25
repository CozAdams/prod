/**
 * @author Nathan Ross, Bluewolf LLC
 * @date 2017-11
 *
 * @group ProxyPattern
 *
 * @description proxy for standard methods that schedule, enqueue, abort, or query apex jobs
 */
public class ApexJobProxyDefault implements IApexJobProxy {

    public void executeBatch(Object batchable, Integer scopeSize) {
        Database.executeBatch((Database.Batchable<sObject>) batchable, scopeSize);
    }

    public Id enqueueJob(Queueable job) {
        return System.enqueueJob(job);
    }

    public CronTrigger queryCronTrigger(Id cronTriggerId) {
        return [
            SELECT PreviousFireTime, StartTime 
            FROM CronTrigger WHERE Id =: cronTriggerId
        ];
    }
}