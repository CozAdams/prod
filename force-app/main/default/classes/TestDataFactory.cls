@isTest
public class TestDataFactory {
    // Account
    public static Account createAccount(Boolean isInsert, String recordTypeName, String acctName) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        Account acct = new Account();
        acct.Name = acctName;
        acct.RecordTypeId = recordTypeId;
    
        if (isInsert) insert acct;
        return acct;
    }

    // Account Summary
    public static Account_Summary__c createAccountSummary(Boolean isInsert, Id contactId, Id organizationId, String acctType) {
        String randomNumString_acctsum1 = String.valueOf(Math.random() * 10000);
        Account_Summary__c acctSummary = new Account_Summary__c();
        acctSummary.Member_Name__c = contactId;
        acctSummary.Organization__c = organizationId;
        acctSummary.Balance__c = 3000;
        acctSummary.Account_Desc__c = 'TEST';
        acctSummary.RMD_Amount__c = 500;
        acctSummary.RMD_Withdrawal__c = -10;
        acctSummary.RMD_Scheduled_Withdrawal__c = -15;
        acctSummary.RMD_Planned_Distribution__c = -20;
        acctSummary.Plan_ID__c = 'IRATRAD';
        acctSummary.Account_Type__c = acctType;
        acctSummary.externalid__c = randomNumString_acctsum1;
        

        if (isInsert) insert acctSummary;
        return acctSummary;
    }
    
    // Account Summary

    public static Account_Summary__c createAccountSummary(Boolean isInsert, Id contactId, Id organizationId) {
        String randomNumString_acctsum2 = String.valueOf(Math.random() * 10000);
        Account_Summary__c acctSummary = new Account_Summary__c();
        acctSummary.Member_Name__c = contactId;
        acctSummary.Organization__c = organizationId;
        acctSummary.Balance__c = 3000;
        acctSummary.Account_Desc__c = 'TEST';
        acctSummary.RMD_Amount__c = 500;
        acctSummary.RMD_Withdrawal__c = -10;
        acctSummary.RMD_Scheduled_Withdrawal__c = -15;
        acctSummary.RMD_Planned_Distribution__c = -20;
        acctSummary.Plan_ID__c = 'IRATRAD';
        acctSummary.externalid__c = randomNumString_acctsum2;

        if (isInsert) insert acctSummary;
        return acctSummary;
    }
    

    // Affiliation
    public static npe5__Affiliation__c createAffiliation(Boolean isInsert, Id orgId, Id contactId) {
        npe5__Affiliation__c affiliation = new npe5__Affiliation__c();
        affiliation.npe5__Contact__c = contactId;
        affiliation.npe5__Organization__c = orgId;
        affiliation.npe5__StartDate__c = System.today().addDays(-7);

        if (isInsert) insert affiliation;
        return affiliation;
    }

    // Case
    public static Case createCase(Boolean isInsert) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard').getRecordTypeId();

        Case newCase = new Case();
        newCase.RecordTypeId = recordTypeId;

        if (isInsert) insert newCase;
        return newCase;
    }

    // Contact
    public static Contact createContact(Boolean isInsert, Id acctId, String lastName) {
        Contact testContact = new Contact();
        testContact.AccountId = acctId;
        testcontact.LastName = lastName;
    
        if (isInsert) insert testContact;
        return testContact;
    }

    // Enrollment Form
    public static Enrollment_Form__c createEnrollmentForm(Boolean isInsert, String formType, Id contactId) {
        Id recordTypeId = Schema.SObjectType.Enrollment_Form__c.getRecordTypeInfosByName().get('Submitted').getRecordTypeId();

        Enrollment_Form__c newForm = new Enrollment_Form__c();
        newForm.Type__c = formType;
        newForm.Community_Contact__c = contactId;
        newForm.RecordTypeId = recordTypeId;
        newForm.Status__c = 'In Progress';

        if (isInsert) insert newForm;
        return newForm;
    }

    // RMD Account Type
    public static RMD_Account_Type__c createRmdAccountType(Boolean isInsert, Id contactId, String payCode) {
        RMD_Account_Type__c acctType = new RMD_Account_Type__c();
        acctType.Contact__c = contactId;
        acctType.Tax_Year__c = String.valueOf(System.today().year());
        acctType.Pay_Code__c = payCode;

        if (isInsert) insert acctType;
        return acctType;
    }
    
    // Account RMD
    public static Account_RMD__c createAccountRMD(Boolean isInsert, Id productRMDId, Id accountSummaryId, Integer year) {
        Account_RMD__c acctRMD = new Account_RMD__c();
        acctRMD.Name = 'Test Account RMD';
        acctRMD.Product_RMD__c = productRMDId;
        acctRMD.Account_Summary__c = accountSummaryId;
        acctRMD.Year__c = year;

        if (isInsert) insert acctRMD;
        return acctRMD;
    }

    // Transaction
    public static Transaction__c createTransaction(Boolean isInsert, Id acctSummaryId, Decimal amount) {
        String randomNumString_uniqID = String.valueOf(Math.random() * 10000);
        Transaction__c trans = new Transaction__c();
        trans.Account_Summary__c = acctSummaryId;
        trans.Amount__c = amount;
        trans.Calendar_Year__c = 2022;
        trans.Type__c = 'Contribution';
          trans.ExternalID__c = randomNumString_uniqID;
        trans.Unique_Lifeworks_ECPA_ID__c = randomNumString_uniqID;

        if (isInsert) insert trans;
        return trans;
    }

    // User
    public static User createUser(Boolean isInsert, String userType, Id contactId) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = :userType].Id;
        String randomNumString = String.valueOf(Math.random() * 10000);
    
        User stUser = new User();
        stUser.LastName = 'Testing';
        stUser.Alias = 'Testing';
        stUser.Email = 'testing@test.com';
        stUser.Username = randomNumString + '@test' + randomNumString + '.com';
        stUser.CommunityNickname = stUser.LastName + randomNumString;
        stUser.EmailEncodingKey = 'UTF-8';
        stUser.ProfileId = profileId;
        stUser.LanguageLocaleKey = 'en_US';
        stUser.TimeZoneSidKey = 'America/Phoenix';
        stUser.LocaleSidKey = 'en_US';

        if (contactId != null) {
            stUser.ContactId = contactId;
        }
    
        if (isInsert) insert stUser;
        return stUser;
    }

    // User Deactivation Step
    public static Map<String, User_Deactivation_Step__c> createUserDeactivationSteps(Boolean isInsert) {
        Map<String, User_Deactivation_Step__c> steps = new Map<String, User_Deactivation_Step__c>();
        
        User_Deactivation_Step__c step1 = new User_Deactivation_Step__c();
        step1.Name = 'Inactivity Warning 1';
        step1.Trigger_Number_of_Days__c = 0;
        step1.Action_Number_of_Days__c = 1;
        step1.Batch_Process__c = 'Inactivity';
        step1.Email_Template_Name__c = null;
        steps.put(step1.Name, step1);

        User_Deactivation_Step__c step2 = new User_Deactivation_Step__c();
        step2.Name = 'Inactivity Warning 2';
        step2.Trigger_Number_of_Days__c = 0;
        step2.Action_Number_of_Days__c = 2;
        step2.Batch_Process__c = 'Inactivity';
        step2.Email_Template_Name__c = null;
        steps.put(step2.Name, step2);

        User_Deactivation_Step__c step3 = new User_Deactivation_Step__c();
        step3.Name = 'Start Deactivation Countdown';
        step3.Trigger_Number_of_Days__c = 0;
        step3.Action_Number_of_Days__c = 2;
        step3.Batch_Process__c = 'Inactivity';
        step3.Email_Template_Name__c = null;
        steps.put(step3.Name, step3);

        User_Deactivation_Step__c step4 = new User_Deactivation_Step__c();
        step4.Name = 'No Login Deactivation';
        step4.Trigger_Number_of_Days__c = 4;
        step4.Action_Number_of_Days__c = 0;
        step4.Batch_Process__c = 'Inactivity';
        step4.Email_Template_Name__c = null;
        steps.put(step4.Name, step4);

        User_Deactivation_Step__c step5 = new User_Deactivation_Step__c();
        step5.Name = 'Deactivate';
        step5.Trigger_Number_of_Days__c = 0;
        step5.Action_Number_of_Days__c = 0;
        step5.Batch_Process__c = 'Deactivation';
        step5.Email_Template_Name__c = null;
        steps.put(step5.Name, step5);

        User_Deactivation_Step__c step6 = new User_Deactivation_Step__c();
        step6.Name = 'Stop Deactivation Countdown';
        step6.Trigger_Number_of_Days__c = 0;
        step6.Action_Number_of_Days__c = 0;
        step6.Batch_Process__c = 'Inactivity';
        step6.Email_Template_Name__c = null;
        steps.put(step6.Name, step6);

        if (isInsert) insert steps.values();
        return steps;
    }
}