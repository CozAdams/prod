/**
* @author LevDigital
* @date 2019
*
* @description Test class for AffiliationService
*/
@IsTest
public with sharing class AffiliationServiceTest {
    /* TEST DATA */
    private static User userRecord;
    private static Account organization;
    private static Account contactAccount;
    private static Contact contactRecord;
    private static npe5__Affiliation__c affiliation;
    private static Account_Summary__c acctSummary;

    //* TEST DATA INITIALIZATION *//
    static void init() {
        userRecord = TestDataFactory.createUser(true, 'System Administrator', null);

        contactAccount = TestDataFactory.createAccount(true, 'Member Portal', 'TESTACCOUNT');
        contactRecord = TestDataFactory.createContact(true, contactAccount.Id, 'CONTACT');

        organization = TestDataFactory.createAccount(true, 'Organization', 'TESTORGANIZATION');
        affiliation = TestDataFactory.createAffiliation(true, organization.Id, contactRecord.Id);
        acctSummary = TestDataFactory.createAccountSummary(true, contactRecord.Id, organization.Id);
    }

    /* TEST METHODS */
    @isTest 
    private static void testInit() {
        init();
    }

    @isTest
    private static void testHandleDuplicatesInsert_differentContact_success() {
        init();
        Contact newContact = TestDataFactory.createContact(true, contactAccount.Id, 'CONTACT2');
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        newAffiliation.npe5__Contact__c = newContact.Id;
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest
    private static void testHandleDuplicatesInsert_differentOrg_success() {
        init();
        Account newOrganization = TestDataFactory.createAccount(true, 'Organization', 'TESTORGANIZATION2');
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        newAffiliation.npe5__Organization__c = newOrganization.Id;
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest
    private static void testHandleDuplicatesInsert_noStartDateOnNewRecord_success() {
        init();
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        newAffiliation.npe5__StartDate__c = null;
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest 
    private static void testHandleDuplicatesInsert_noStartDateOnExistingRecord_success() {
        init();
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        affiliation.npe5__StartDate__c = null;
        update affiliation;
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest
    private static void testHandleDuplicatesInsert_endDateOnNewRecord_success() {
        init();
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        newAffiliation.npe5__EndDate__c = System.today().addDays(7);
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest
    private static void testHandleDuplicatesInsert_endDateOnExistingRecord_success() {
        init();
        npe5__Affiliation__c newAffiliation = affiliation.clone(false, false, false, false);
        affiliation.npe5__EndDate__c = System.today().addDays(30);
        update affiliation;
        String errorMsg;

        // Test 
        System.Test.startTest();
        try {
            insert newAffiliation;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();

        // Assert that record was inserted successfully and without error
        System.assertNotEquals(null, newAffiliation.Id);
        System.assertEquals(null, errorMsg);
    }

    @isTest 
    private static void testHandleDuplicatesInsert_fullCopy_error() {
        init();
        List<Database.SaveResult> results;
        Integer countBefore = [SELECT COUNT() FROM npe5__Affiliation__c];

        // Duplicates
        npe5__Affiliation__c dupe1 = affiliation.clone(false, false, false, false);
        npe5__Affiliation__c dupe2 = affiliation.clone(false, false, false, false);
        List<npe5__Affiliation__c> affiliationList = new List<npe5__Affiliation__c>{ dupe1, dupe2 };
        List<Id> affiliationIds = new List<Id>{ dupe1.Id, dupe2.Id };

        // Test
        System.Test.startTest();
        results = Database.insert(affiliationList, false);
        System.Test.stopTest();

        Integer countAfter = [SELECT COUNT() FROM npe5__Affiliation__c];

        // Assert that all new records had duplicates found and had errors
        System.assertEquals(2, results.size());
        for (Database.SaveResult result : results) {
            String errorMsg = result.getErrors()[0].getMessage();
            System.assert(errorMsg.contains('already exists'));
            System.assert(errorMsg.contains(organization.Id));
            System.assert(errorMsg.contains(contactRecord.Id));
        }

        // Assert that the new affiliation records were not inserted
        System.assertEquals(countBefore, countAfter);
    }

    @isTest 
    private static void testHandleDuplicatesUpdate_addStartDate_error() {
        init();
        List<Database.SaveResult> results;

        // Copy but with no start date
        npe5__Affiliation__c newAffiliation = TestDataFactory.createAffiliation(false, organization.Id, contactRecord.Id);
        newAffiliation.npe5__StartDate__c = null;
        insert newAffiliation;

        newAffiliation.npe5__StartDate__c = System.today();

        // Test
        System.Test.startTest();
        results = Database.update(new List<npe5__Affiliation__c>{ newAffiliation }, false);
        System.Test.stopTest();

        // Assert that all new records had duplicates found and had errors
        for (Database.SaveResult result : results) {
            String errorMsg = result.getErrors()[0].getMessage();
            System.assert(errorMsg.contains('already exists'));
            System.assert(errorMsg.contains(organization.Id));
            System.assert(errorMsg.contains(contactRecord.Id));
        }
    }

    @isTest 
    private static void testHandleDuplicatesUpdate_removeEndDate_error() {
        init();
        List<Database.SaveResult> results;

        // Copy but with no start date
        npe5__Affiliation__c newAffiliation = TestDataFactory.createAffiliation(false, organization.Id, contactRecord.Id);
        newAffiliation.npe5__EndDate__c = System.today().addDays(7);
        insert newAffiliation;

        newAffiliation.npe5__EndDate__c = null;

        // Test
        System.Test.startTest();
        results = Database.update(new List<npe5__Affiliation__c>{ newAffiliation }, false);
        System.Test.stopTest();

        // Assert that all new records had duplicates found and had errors
        for (Database.SaveResult result : results) {
            String errorMsg = result.getErrors()[0].getMessage();
            System.assert(errorMsg.contains('already exists'));
            System.assert(errorMsg.contains(organization.Id));
            System.assert(errorMsg.contains(contactRecord.Id));
        }
    }

    @isTest
    private static void testGetRelatedAccountSummaries_success() {
        init();
        acctSummary = [ SELECT Id, Name, Account_Type_display__c, Balance__c FROM Account_Summary__c WHERE Id = :acctSummary.Id];

        // Test
        System.Test.startTest();
        List<Account_Summary__c> acctSummaryResults = AffiliationService.getRelatedAccountSummaries(affiliation);
        System.Test.stopTest();

        // Assert that the matching account summary was returned
        System.assertEquals(1, acctSummaryResults.size());
        System.assertEquals(acctSummary.Id, acctSummaryResults[0].Id);
        System.assertEquals(acctSummary.Name, acctSummaryResults[0].Name);
        System.assertEquals(acctSummary.Account_Type_display__c, acctSummaryResults[0].Account_Type_display__c);
        System.assertEquals(acctSummary.Balance__c, acctSummaryResults[0].Balance__c);
    }

    @isTest
    private static void testGetRelatedAccountSummaries_noMatchOnContact() {
        init();
        Contact contact2 = TestDataFactory.createContact(true, contactAccount.Id, 'CONTACT2');
        acctSummary.Member_Name__c = contact2.Id;
        update acctSummary;

        // Test
        System.Test.startTest();
        List<Account_Summary__c> acctSummaryResults = AffiliationService.getRelatedAccountSummaries(affiliation);
        System.Test.stopTest();

        // Assert that no matches were found
        System.assertEquals(0, acctSummaryResults.size());
    }

    @isTest
    private static void testGetRelatedAccountSummaries_noMatchOnOrganization() {
        init();
        Account org2 = TestDataFactory.createAccount(true, 'Organization', 'ORG2');
        acctSummary.Organization__c = org2.Id;
        update acctSummary;

        // Test
        System.Test.startTest();
        List<Account_Summary__c> acctSummaryResults = AffiliationService.getRelatedAccountSummaries(affiliation);
        System.Test.stopTest();

        // Assert that no matches were found
        System.assertEquals(0, acctSummaryResults.size());
    }
}