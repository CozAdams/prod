/**
* @author Nathan Ross
* @date 10/20/2018
*
* @group Trigger handlers
*
* @description Opportunity Trigger handler for routing logic
*/

public with sharing class OpportunityTriggerHandler{
    final List<Opportunity> newRecords;
    final Map<Id, Opportunity> oldRecordsMap;
    final ContactCommunityUserCreation communityUserCreation = new ContactCommunityUserCreation();

    public OpportunityTriggerHandler(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecords) {
        this.newRecords = newRecords;
        this.oldRecordsMap = oldRecords;
    }

    public void afterInsert() {
        this.communityUserCreation.afterOpportunityInsert(this.newRecords);
    }

    public void afterUpdate() {
        this.communityUserCreation.afterOpportunityUpdate(this.newRecords, this.oldRecordsMap);
    }
}