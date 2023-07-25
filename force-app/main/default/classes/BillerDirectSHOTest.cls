@IsTest
public with sharing class BillerDirectSHOTest {
    public BillerDirectSHOTest() {

        

    }

    @isTest
    public static void testGetFieldValues(){
        Account testAccount = TestDataFactory.createAccount(true, 'Household Account' ,'testAccount');
        Contact testContact = TestDataFactory.createContact(true, testAccount.Id, 'test Name');
        Account_Summary__c testAccountSummary = TestDataFactory.createAccountSummary(true, testContact.Id, testAccount.Id, 'test');

        Object returnedObject = BillerDirectSHO.getFieldValues(testAccountSummary.Id, 'testemail@email.com', '200', '2021');

    }
}