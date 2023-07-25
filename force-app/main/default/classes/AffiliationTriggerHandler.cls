public with sharing class AffiliationTriggerHandler {
    final List<npe5__Affiliation__c> newRecords;
    final Map<Id, npe5__Affiliation__c> oldRecordsMap;

    public AffiliationTriggerHandler(List<npe5__Affiliation__c> newRecords, Map<Id, npe5__Affiliation__c> oldRecordsMap) {
        this.newRecords = newRecords;
        this.oldRecordsMap = oldRecordsMap;
    }

    public void afterInsert() {
        ParentRelatedListGenerateServices relatedListServices = new ParentRelatedListGenerateServices();
        relatedListServices.populateOrganizationOnContact(this.newRecords);
    }

    public void beforeInsert() {
        AffiliationService.gateHandleDuplicates(this.newRecords, null);
    }

    public void beforeUpdate() {
        AffiliationService.gateHandleDuplicates(this.newRecords, this.oldRecordsMap);
    }
}