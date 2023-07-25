@IsTest
public with sharing class BillerDirectSSOTest {
    public BillerDirectSSOTest() {

    }

    @IsTest
    public static void RedirectToBillerIQTest(){

        Account testAccount = TestDataFactory.createAccount(true, 'Household Account' ,'testAccount');
        Contact testContact = TestDataFactory.createContact(true, testAccount.Id, 'test Name');
        Account_Summary__c testAccountSummary = TestDataFactory.createAccountSummary(true, testContact.Id, testAccount.Id, 'test');

        String returnValue = BillerDirectSSO.RedirectToBillerIQ(testAccountSummary.Id);

    }
}