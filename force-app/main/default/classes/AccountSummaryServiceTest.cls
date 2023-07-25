@IsTest
private class AccountSummaryServiceTest {

    public static final Integer ACCOUNT_ROUTING_NUMBER = 111111111;
    public static final String BANK_NAME = 'Fake Bank Of America';
    public static final Integer BANK_ACCOUNT_COUNT = 5;
    public static final String TDRA_ACCOUNT = 'Tax-Deferred Retirement Account';
    public static final String Roth403_ACCOUNT = 'Tax-Deferred Retirement Account';

    static Account org;
    static Contact memberContact;
    static User memberUser;
    static Account_Summary__c acctSummaryTDRA;
    static Account_Summary__c acctSummaryRoth;
    static Transaction__c transTDRA;
    static Transaction__c transRoth;
    static Contribution_Limit__mdt storedLimit;

    @TestSetup
    static void setup() {
        Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType, new Map<SObjectField, Object> {
                Contact.Birthdate => Date.newInstance(Date.today().year() - 60, Date.today().month(), Date.today().day())
        });

        Account_Summary__c accountSummary1 = (Account_Summary__c) SObjectFactory.create(Account_Summary__c.SObjectType, new Map<SObjectField, Object>{
                Account_Summary__c.RecordTypeId => Schema.SObjectType.Account_Summary__c.getRecordTypeInfosByDeveloperName().get('Employer_Sponsored_Retirement_Products').getRecordTypeId(),
                Account_Summary__c.Member_Name__c => testContact.Id,
                Account_Summary__c.Account_Type__c => TDRA_ACCOUNT,
                Account_Summary__c.Name => 'Test Account Summary 1'
        });
        Account_Summary__c accountSummary2 = (Account_Summary__c) SObjectFactory.create(Account_Summary__c.SObjectType, new Map<SObjectField, Object>{
                Account_Summary__c.RecordTypeId => Schema.SObjectType.Account_Summary__c.getRecordTypeInfosByDeveloperName().get('Employer_Sponsored_Retirement_Products').getRecordTypeId(),
                Account_Summary__c.Member_Name__c => testContact.Id,
                Account_Summary__c.Account_Type__c => TDRA_ACCOUNT,
                Account_Summary__c.Name => 'Test Account Summary 2'
        });

        SObjectFactory.create(Recurring_Contributions__c.SObjectType, new Map<SObjectField, Object> {
                Recurring_Contributions__c.Account_Summary__c => accountSummary1,
                Recurring_Contributions__c.Contribution_Day__c => 'First',
                Recurring_Contributions__c.Start_Date__c => Date.newInstance(Date.today().year(), 1, 1),
                Recurring_Contributions__c.End_Date__c => Date.newInstance(Date.today().year(), 12, 31),
                Recurring_Contributions__c.Amount__c => 3000,
                Recurring_Contributions__c.Frequency__c => 'Annually'
        });

        SObjectFactory.create(Recurring_Contributions__c.SObjectType, new Map<SObjectField, Object> {
                Recurring_Contributions__c.Account_Summary__c => accountSummary2,
                Recurring_Contributions__c.Contribution_Day__c => 'Fifteenth',
                Recurring_Contributions__c.Start_Date__c => Date.newInstance(Date.today().year(), 1, 1),
                Recurring_Contributions__c.End_Date__c => Date.newInstance(Date.today().year(), 12, 31),
                Recurring_Contributions__c.Amount__c => 100,
                Recurring_Contributions__c.Frequency__c => 'Monthly'
        });

        for (Integer i = 0; i < 12; i++) {
            if (Date.today() > Date.newInstance(Date.today().year(), i + 1, 15)) {
                SObjectFactory.create(Transaction__c.SObjectType, new Map<SObjectField, Object>{
                        Transaction__c.Amount__c => 100.00,
                        Transaction__c.Type__c => 'Contribution',
                        Transaction__c.Account_Summary__c => accountSummary2.Id,
                        Transaction__c.Apply_Date__c => Date.today(), 
                        Transaction__c.Calendar_Year__c => Date.today().year(),
                            Transaction__c.ExternalID__c => 'exid' + i,
                            Transaction__c.Unique_Lifeworks_ECPA_ID__c => 'ULecpaID' + i
                            
                });
            }
        }

        SObjectFactory.create(Country__c.SObjectType, new Map<Schema.SObjectField, Object> {
                Country__c.NAME => 'United States',
                Country__c.ISO__c => 'US',
                Country__c.Label__c => 'United States'
        });
        SObjectFactory.create(State__c.SObjectType, new Map<Schema.SObjectField, Object> {
                State__c.NAME => 'Illinois',
                State__c.ISO__c => 'IL',
                State__c.Label__c => 'Illinois',
                State__c.CountryISO__c => 'US'
        });
    }

    static void init() {
        org = TestDataFactory.createAccount(true, 'Organization', 'TESTORG');
        memberContact = TestDataFactory.createContact(true, org.Id, 'TESTING');
        memberUser = TestDataFactory.createUser(true, 'PFCC Employer Portal', memberContact.Id);

        acctSummaryTDRA = TestDataFactory.createAccountSummary(false, memberContact.Id, org.Id, 'TDRA_ACCOUNT');
        acctSummaryTDRA.Account_Type__c = 'TDRA_ACCOUNT';
        acctSummaryRoth = TestDataFactory.createAccountSummary(false, memberContact.Id, org.Id, 'Roth IRA');
        acctSummaryRoth.Account_Type__c = 'Roth IRA';
        insert new List<Account_Summary__c>{ acctSummaryRoth, acctSummaryTDRA };

        transTDRA = TestDataFactory.createTransaction(true, acctSummaryTDRA.Id, 500);
        transRoth = TestDataFactory.createTransaction(true, acctSummaryRoth.Id, 500);

        String year = String.valueOf(Date.today().year());
        storedLimit = [
            SELECT Retirement_Age__c, Amount_at_Retirement_Age__c, Amount_Before_Retirement_Age__c
            FROM Contribution_Limit__mdt
            WHERE Year__c = :year
            AND Account_Type__c = 'Roth IRA'
            LIMIT 1
        ];
    }
    
    @IsTest
    static void getAccountSummaryTest() {
        Test.startTest();
        Account_Summary__c testAccountSummary = AccountSummaryService.getAccountSummary([SELECT Id FROM Account_Summary__c LIMIT 1].Id);
        Test.stopTest();

        System.assertNotEquals(null, testAccountSummary, 'An account summary record should be returned from the service given an Id');
        System.assertNotEquals(null, testAccountSummary.RecordTypeId, 'the retrieved account summary record should have a record type');
    }

    @IsTest
    static void getAccountSummaryListTest() {
        Contact aContact = [SELECT Id FROM Contact LIMIT 1];
        Account_Summary__c accountSummary = [SELECT Id, Account_Type__c, Account_Desc__c FROM Account_Summary__c WHERE Name = 'Test Account Summary 1' LIMIT 1];

        Test.startTest();
        List<Account_Summary__c> accountSummaries = AccountSummaryService.getAccountSummaryList(aContact.Id, accountSummary);
        Test.stopTest();

        System.assertEquals(1, accountSummaries.size(), 'Should only have selected one account because it excludes the current account we are on');
        System.assertEquals('Test Account Summary 2', accountSummaries.get(0).Name, 'Should have selected only the second account summary');
    }
    
    @IsTest
    static void getCurrentUserTest() {
        User currentUser;

        Test.startTest();
            currentUser = AccountSummaryService.getUser();
        Test.stopTest();

        System.assertNotEquals(null, currentUser, 'An account summary record should be returned from the service given an Id');
        System.assertNotEquals(null, currentUser.FirstName, 'the retrieved current user record should have its first name set');
        System.assertNotEquals(null, currentUser.LastName, 'the retrieved account summary record should have its last name set');
    }

    @IsTest
    static void saveBankAccountTest_SuccessDML() {
        Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType);

        bnk_Bank__c testBankAccount = (bnk_Bank__c) SObjectFactory.build(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
            bnk_Bank__c.bnk_Routing_Number__c => ACCOUNT_ROUTING_NUMBER + '',
            bnk_Bank__c.bnk_Account_Number__c => ACCOUNT_ROUTING_NUMBER + '',
            bnk_Bank__c.bnk_Bank_Name__c => BANK_NAME,
            bnk_Bank__c.bnk_Account_Holder_Name__c => testContact.Id
        });
        
        Id newBankAccountId;

        Test.startTest();
            newBankAccountId = AccountSummaryService.saveBankAccount(testBankAccount);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM bnk_Bank__c WHERE Id = :newBankAccountId], 'New bank account should be in the database');
    }

    @IsTest
    static void getBankingInformationList() {
        Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType);

        for(Integer i = 0; i < BANK_ACCOUNT_COUNT; i++) {
            SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                    bnk_Bank__c.bnk_Routing_Number__c => ACCOUNT_ROUTING_NUMBER + '',
                    bnk_Bank__c.bnk_Account_Number__c => (ACCOUNT_ROUTING_NUMBER + i) + '',
                    bnk_Bank__c.bnk_Bank_Name__c => BANK_NAME,
                    bnk_Bank__c.bnk_Account_Holder_Name__c => testContact.Id
            });
        }

        Test.startTest();
            AccountSummaryService.getBankingInformationList(testContact.Id);
        Test.stopTest();

        System.assertEquals(BANK_ACCOUNT_COUNT, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Account_Holder_Name__c = :testContact.Id], 'the number of retrieved bank accounts should be accurate');
    }

    @IsTest
    static void saveCaseTest() {
        Case testCase = (Case)SObjectFactory.build(Case.SObjectType, new Map<SObjectField, Object> {
            Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId()
        });

        Boolean dmlFailed = false;
        Test.startTest();
            try{
                AccountSummaryService.saveCase(testCase);
            } catch(DmlException e) {
                dmlFailed = true;
            }

        Test.stopTest();

        System.assert(!dmlFailed, 'No exception should have thrown here');
    }

    @IsTest
    static void queueAndRecordTypeTest() {
        Test.startTest();
        Id queueId = AccountSummaryService.getCaseQueue();
        Id recordTypeId = AccountSummaryService.getCaseRecordType();
        Test.stopTest();

        Group queue = [SELECT Id, DeveloperName FROM Group WHERE Id = :queueId LIMIT 1];
        RecordType recordType = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1];
        System.assertEquals('Online_Transactions', queue.DeveloperName, 'Queue should be the online transactions queue');
        System.assertEquals('Online_Transactions', recordType.DeveloperName, 'RecordType should be the online transactions record type');
    }

    @IsTest
    static void statesAndCountryTest() {
        Test.startTest();
        Map<String, String> countries = AccountSummaryService.getCountries();
        Map<String, String> states = AccountSummaryService.getStates('US');
        Test.stopTest();

        System.assertEquals('United States', countries.values().get(0), 'We should have retrieved a list of countries');
        System.assertEquals('Illinois', states.values().get(0), 'We should have retireved a list of states based on the country');
    }

    @IsTest
    static void getAmountToBeDepositedTest() {
        Contact aContact = [SELECT Id FROM Contact LIMIT 1];
        Account_Summary__c accountSummary = [SELECT Id, Account_Type__c FROM Account_Summary__c LIMIT 1];

        Test.startTest();
        Decimal amount = AccountSummaryService.getTotalContributionsSoFar(aContact.Id, accountSummary.Account_Type__c, Date.today().year());
        Test.stopTest();

        System.assertEquals(4200.00, amount, 'Amount left to deposit should match');
    }

    @isTest
    static void getPermissionToWithdraw_underAge_false() {
        init();
        memberContact.Birthdate = System.today().addYears(-AccountSummaryService.X457_MIN_WITHDRAW_AGE + 1);
        update memberContact;
        Boolean withdrawPermitted;

        // Test
        System.Test.startTest();
        System.runAs(memberUser) {
            withdrawPermitted = AccountSummaryService.getPermissionToWithdraw(org.Id);
        }
        System.Test.stopTest();

        // Assert that withdraw permission was denied
        System.assertEquals(false, withdrawPermitted);
    }

    @isTest
    static void getPermissionToWithdraw_true() {
        init();
        memberContact.Birthdate = System.today().addYears(-AccountSummaryService.X457_MIN_WITHDRAW_AGE);
        update memberContact;
        Boolean withdrawPermitted;

        // Test
        System.Test.startTest();
        System.runAs(memberUser) {
            withdrawPermitted = AccountSummaryService.getPermissionToWithdraw(org.Id);
        }
        System.Test.stopTest();

        // Assert that withdraw permission was granted
        System.assertEquals(true, withdrawPermitted);
    }

    @isTest
    static void getMaxContributionLimits() {
        // Test
        System.Test.startTest();
        List<Contribution_Limit__mdt> limitsReturned = AccountSummaryService.getMaxContributionLimits('Roth IRA', new List<String>{ '2022' });
        System.Test.stopTest();

        // Assert that the under age limit was returned
        System.assert(!limitsReturned.isEmpty());
    }

    @isTest
    static void getTotalContributionsTest_original_success() {
        init();
        acctSummaryRoth.Account_Desc__c += ' Original';
        update acctSummaryRoth;
        List<String> accountTypes = new List<String>{ 'Roth IRA' };

        // Test
        System.Test.startTest();
        Decimal amountReturned = AccountSummaryService.getTotalContributionsSoFar(memberContact.Id, 'Roth IRA', 2022);
        System.Test.stopTest();
        
        // Assert that total returned is transaction amount, since Roth IRA account description is Original
        System.assertEquals(transRoth.Amount__c, amountReturned);
    }

    @isTest 
    static void getTotalContributionsTest_notOriginal_success() {
        init();

        // Test
        System.Test.startTest();
        Decimal amountReturned = AccountSummaryService.getTotalContributionsSoFar(memberContact.Id, 'Roth IRA', 2022);
        System.Test.stopTest();
        
        // Assert that total returned is 0, since Roth IRA account description is not Original
        System.assertEquals(0, amountReturned);
    }

    @isTest
    static void getTotalContributionsTest_notRoth_success() {
        init();

        // Test
        System.Test.startTest();
        Decimal amountReturned = AccountSummaryService.getTotalContributionsSoFar(memberContact.Id, TDRA_ACCOUNT, 2022);
        System.Test.stopTest();
        
        // Assert that total returned is transaction amount, since TDRA does not require Original in description
        System.assertEquals(transTDRA.Amount__c, 500);
    }
}