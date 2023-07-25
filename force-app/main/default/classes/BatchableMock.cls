/**
 * @author Nathan Ross, Bluewolf LLC
 * @date 2017-11
 *
 * @group ProxyPattern
 *
 * @description
 * a mock batchable which can be used for testing behavior of classes that schedule or enqueue batchables.
 * batchables, unlike schedulables and queueables, can only be top level classes as of writing (API v41.0)
 * so tests for such behavior need to have a top level batchable class they can reference that is only for
 * testing - so that business logic changes will not introduce new test data setup requirements.
 */
@isTest
global class BatchableMock implements Database.Batchable<sObject>, Database.Stateful {

    public Integer expectedScopeSize = 200;
    public static Integer scopeSize;

    global BatchableMock() {}
    global BatchableMock(Integer expectedScopeSize) {
        this.expectedScopeSize = expectedScopeSize;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator('SELECT ID FROM USER LIMIT ' + expectedScopeSize);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
       scopeSize = scope.size();
   }

   global void finish(Database.BatchableContext BC){

   }
}