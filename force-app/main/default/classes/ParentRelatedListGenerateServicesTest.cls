@isTest
private class ParentRelatedListGenerateServicesTest {
    final static Integer RECORD_COUNT = 20;
    final static String FIRST_NAME = 'John';
    @isTest static void populateOrganizationOnContact_InsertAffiliation_NamePopulate() {
        Contact parentContact = (Contact) new SobjectBuilder(Contact.SobjectType)
            .create().getRecord();

        List<Account> organizations = new SobjectBuilder(Account.SobjectType)
        .put(Account.Name, new SObjectFieldProviders.UniqueStringProvider(FIRST_NAME))
        .count(RECORD_COUNT).create().getRecords();

        List<npe5__Affiliation__c> affiliations = new SobjectBuilder(npe5__Affiliation__c.SObjectType)
        .put(npe5__Affiliation__c.Npe5__Contact__c, parentContact.Id)
        .put(npe5__Affiliation__c.Npe5__Organization__c, organizations)
        .put(npe5__Affiliation__c.Npe5__StartDate__c, Date.today())
        .count(RECORD_COUNT).build().getRecords();

        Test.startTest();
            insert affiliations;
        Test.stopTest();

        String orgPINs = [SELECT Organization_Names__c FROM Contact LIMIT 1].Organization_Names__c;
        affiliations = [SELECT Npe5__Organization__r.PIN__c FROM Npe5__Affiliation__c];

        for(Npe5__Affiliation__c affiliation : affiliations) {
            System.assert(orgPINs.contains(affiliation.Npe5__Organization__r.PIN__c),
                'The organization PIN should be populated onto the parent contact for related list generation');
        }
    }
}