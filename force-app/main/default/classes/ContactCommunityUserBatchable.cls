/**
 * @author Nathan Ross, Bluewolf
 *
 * @date 2018-10
 *
 * @group Contact User Creation
 *
 * @description creates users for eligible contacts
 */
public with sharing class ContactCommunityUserBatchable implements Database.Batchable<sObject>, Database.Stateful {
    @TestVisible ILogger logger;

    public ContactCommunityUserBatchable(ILogger logger) {
        this.logger = logger;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new ContactCommunityUserCreation().queryNeedsUserBeforeThreshold();
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        new ContactCommunityUserCreation().createUserForContacts(logger, scope);
    }

    public void finish(Database.BatchableContext bc) {
        this.logger.emit();
    }
}