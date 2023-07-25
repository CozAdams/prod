public with sharing class BeneficiaryListWrapper {
    @AuraEnabled public String id {get; set;}
    @AuraEnabled public Contact contact {get; set;}
    @AuraEnabled public Beneficiary__c beneficiary {get; set;}
    @AuraEnabled public npe4__Relationship__c relationship {get; set;}

    public BeneficiaryListWrapper() { }
}