/*********************************************************************************************
Created By: John Wrightsman
Email: john.wrightsman@revelanttech.com
Created: 12/08/2017
Notes: Unit Test class for CaseFetchPaymentsHelper
*********************************************************************************************/
@isTest
private class CaseFetchPaymentsHelper_Test {

    @isTest static void test_method_one() {
        Contact oContact = new Contact(
            LastName = 'Test',
            Member_Type__c = 'Lay',
            Contact_Type__c = 'Member',
            Contact_Sub_Type__c = 'Original',
            Contact_Status__c = 'Active',
            Gender__c = 'F',
            Social_Security_Number__c = '111-22-3334',
            SSN_Verification_Required__c = FALSE,
            Email = (String) new SObjectFieldProviders.UniqueStringProvider('test_xyz=example@example.com').getValue()
        );
        insert oContact;

        Account_Summary__c accSumm = new Account_Summary__c(
            Name = 'DB-test',
            Status__c = 'A',
            Origin__c = 'Original',
            Member_Name__c = oContact.Id,
            Account_Type__c = 'US Pension Plan',
            Account_Desc__c = 'Original'
        );
        insert accSumm;

        System.assertEquals(oContact.Id, accSumm.Member_Name__c, 'these should match');
        Id disabilityRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Disability').getRecordTypeId();
        Case oCase = new Case(
            RecordTypeId = disabilityRecTypeId,
            Status = 'Open',
            Origin = 'Phone',
            Reason = 'US Disability',
            ContactId = oContact.Id,
            Disability_Date__c = Date.today()
        );
        insert oCase;

        
        Transaction__c trans = new Transaction__c(
            Account_Summary__c = accSumm.Id,
            Amount__c = 10.00,
            Apply_Date__c = Date.today(),
            Option__c = 'EMPLOYEE',
            Period_Begin_Date__c = Date.today(),
            Period_End_Date__c = Date.today(),
            Type__c = 'transfer',
            externalID__c = '234abc567'
        );
        insert trans;

        // This pension contribution should get deleted when fetchPayments() runs
        Pension_Contribution__c pensionContrib = new Pension_Contribution__c(
            Case__c = oCase.Id,
            Account_Summary__c = accSumm.Id,
            Amount__c = 10.00,
            Apply_Date__c = Date.today(),
            Option__c = 'EMPLOYEE',
            Period_Begin_Date__c = Date.today(),
            Period_End_Date__c = Date.today(),
            Type__c = 'transfer'
        );
        insert pensionContrib;

        // Call fetchPayments
        CaseFetchPaymentsHelper.fetchPayments(oCase.Id);

        oCase = [
            SELECT Payment_Fetch_Date__c
            FROM Case
            WHERE Id = :oCase.Id
        ];
        System.assertNotEquals(null, oCase.Payment_Fetch_Date__c); // Payment Fetch Date should be populated now

        pensionContrib = [
            SELECT Account_Summary__c, Amount__c, Apply_Date__c, Option__c,
                Period_Begin_Date__c, Period_End_Date__c, Type__c
            FROM Pension_Contribution__c
            LIMIT 1
        ];

        // Verify that the fields on the Pension Contribution match the Transaction
        System.assertEquals(trans.Account_Summary__c, pensionContrib.Account_Summary__c);
        System.assertEquals(trans.Amount__c, pensionContrib.Amount__c);
        System.assertEquals(trans.Apply_Date__c, pensionContrib.Apply_Date__c);
        System.assertEquals(trans.Option__c, pensionContrib.Option__c);
        System.assertEquals(trans.Period_Begin_Date__c, pensionContrib.Period_Begin_Date__c);
        System.assertEquals(trans.Period_End_Date__c, pensionContrib.Period_End_Date__c);
        System.assertEquals(trans.Type__c, pensionContrib.Type__c);
    }

}