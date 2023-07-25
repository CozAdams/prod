/*******************************************************************************************************
* @author Lev
* @date 2020
*
* @description Test class for RMDService and related methods in AccountSummaryTrigger
*/
@isTest 
private class InternalRmdServiceTest {
    static Account org;
    static Contact testContact;
    static Account_Summary__c acctSummary;
    static Account_Summary__c acctSummaryCopy;
    static RMD_Account_Type__c acctType;
    static Account_RMD__c accntRmd;

    static void init() {
        org = TestDataFactory.createAccount(true, 'Organization', 'Night Vale');
        testContact = TestDataFactory.createContact(true, org.Id, 'Intern Jodi');
        acctSummary = TestDataFactory.createAccountSummary(false, testContact.Id, org.Id, 'Traditional IRA');
        acctSummaryCopy = TestDataFactory.createAccountSummary(false, testContact.Id, org.Id);
        acctSummaryCopy.RMD_Account_Type__c = null;
        acctType = TestDataFactory.createRmdAccountType(false, testContact.Id, 'IRA');
        acctType.Federal_percentage__c = 15;
        acctType.Remainder_BAA__c = false;
        acctType.Remainder_Check_ACH__c = true;
        acctType.BAA_Amount__c  = 0;
        insert acctType;
    }

   
    @isTest
    static void testInternalRmdMethods() {
        init();
        //acctSummary.RMD_Account_Type__c = acctType.Id;
        acctSummaryCopy.RMD_Account_Type__c =acctType.Id;
        insert acctSummary;
        insert acctSummaryCopy;
        accntRmd = TestDataFactory.createAccountRMD(false, acctType.Id, acctSummary.Id, 2022);
        insert accntRmd;
        
        Account_RMD__c accntRmd2 = TestDataFactory.createAccountRMD(false, acctType.Id, acctSummary.Id, 2022);
        insert accntRmd2;

        acctType = [SELECT Id, Name, Tax_Year__c, Total_RMD_Amount__c, Total_RMD_Remaining__c FROM RMD_Account_Type__c WHERE Id = :acctType.Id ];

        System.Test.startTest();
        InternalRmdService.processProRataDistribution(acctType.Id);
        System.assertEquals('Pro Rata', [SELECT Id, Distribution_Option__c FROM RMD_Account_Type__c WHERE Id = :acctType.Id].Distribution_Option__c, 'RMD account type distribution is wrong');
        System.assertEquals(-20, [SELECT Id, RMD_Planned_Distribution__c FROM Account_Summary__c WHERE Id = :acctSummary.Id].RMD_Planned_Distribution__c, 'Account summary planned distribution is wrong');

        InternalRmdService.processSingleAccountDistribution(acctType.Id, accntRmd.Id);
        System.assertEquals('Single Account', [SELECT Id, Distribution_Option__c FROM RMD_Account_Type__c WHERE Id = :acctType.Id].Distribution_Option__c, 'RMD account type distribution is wrong');
        System.assertEquals(-20, [SELECT Id, RMD_Planned_Distribution__c FROM Account_Summary__c WHERE Id = :acctSummaryCopy.Id].RMD_Planned_Distribution__c, 'RMD account type distribution is wrong');

      //  System.assertEquals(950, [SELECT Id, RMD_Planned_Distribution__c FROM Account_Summary__c WHERE Id = :acctSummary.Id].RMD_Planned_Distribution__c, 'RMD account type distribution is wrong');

        InternalRmdService.retrieveAccounts(acctType.Id);
        InternalRmdService.processDeferOption(acctType.Id, 'Differing - still employed');
        InternalRmdService.getDeferringPicklistValues();
        System.Test.stopTest();


    }
}