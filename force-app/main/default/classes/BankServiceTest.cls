@IsTest
private class BankServiceTest {

    public static final Integer ACCOUNT_ROUTING_NUMBER = 111111111;
    public static final String BANK_NAME = 'Fake Bank Of America';
    public static final Integer BANK_ACCOUNT_COUNT = 5;

    @TestSetup
    static void setup() {
        // Domestic
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic',
                bnk_Bank__c.Bank_Account_Country__c => 'US',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456789'
        });
        // Domestic
        // Domestic
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic',
                bnk_Bank__c.Bank_Account_Country__c => 'US',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456789'
        });
        // Domestic
        // Domestic
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic',
                bnk_Bank__c.Bank_Account_Country__c => 'US',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456789'
        });
        // Domestic
        // Domestic
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic',
                bnk_Bank__c.Bank_Account_Country__c => 'US',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456789'
        });
        // Domestic
        // International
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'International',
                bnk_Bank__c.Bank_Account_Country__c => 'AF',
                bnk_Bank__c.SWIFT_Code__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456789'
        });

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
        
        List<Group> groupList = new List<Group>();
        Group memberServiceCenter = new Group();
        memberServiceCenter.Name = 'Member Service Center';
        
        Group treasury = new Group();
        treasury.Name = 'Treasury Associate State Changes/Tasks';
        
        groupList.add(memberServiceCenter);
        groupList.add(treasury);
        insert groupList;
    }

    @IsTest
    static void testDomesticAccountSuccess() {
        Test.startTest();
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic2',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456780'
        });
        Test.stopTest();

        System.assertEquals(5, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Routing_Number__c != NULL], 'There should now be 5 domestic bank account in the system');
    }
    @IsTest
    static void testMultipleDomesticAccountSuccess() {
        Integer count = 200;
        List<bnk_Bank__c> bankAccounts =(List<bnk_Bank__c>)SObjectFactory.build(count,bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'Domestic2',
                bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456780'
        });
        for(Integer i=0;i<bankAccounts.size();i++){
            String numerator = String.Valueof(i) + '996780';
            bankAccounts[i].bnk_Account_Number__c =numerator.leftPad(9, '0'); 
        }
        Test.startTest();
        insert bankAccounts;
        Test.stopTest();

        System.assertEquals(count + 4, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Routing_Number__c != NULL], 'There should now be 5 domestic bank account in the system');
    }


    @IsTest
    static void testDomesticAccountFail() {
        Test.startTest();
        Boolean anExceptionOccurred = false;
        try {
            SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object>{
                    bnk_Bank__c.bnk_Bank_Name__c => 'Domestic2',
                    bnk_Bank__c.bnk_Routing_Number__c => '123456789',
                    bnk_Bank__c.bnk_Account_Number__c => '123456789'
            });
        } catch (Exception e) {
            anExceptionOccurred = true;
        }
        Test.stopTest();

        System.assert(anExceptionOccurred, 'An exception should have occurred when inserting a duplicate bank Account');
        System.assertEquals(4, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Routing_Number__c != NULL], 'There should only be 4 domestic bank accounts in the system');
    }

    @IsTest
    static void testInternationalAccountSuccess() {
        Test.startTest();
        SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'International2',
                bnk_Bank__c.Bank_Account_Country__c => 'AF',
                bnk_Bank__c.SWIFT_Code__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456780'
        });
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM bnk_Bank__c WHERE SWIFT_Code__c != NULL], 'There should now be 2 international bank accounts in the system');
    }
     @IsTest
    static void testInternationalAccountSuccessUpdate() {
        bnk_Bank__c bankAccount = (bnk_Bank__c) SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Bank_Name__c => 'International2',
                bnk_Bank__c.Bank_Account_Country__c => 'AF',
                bnk_Bank__c.SWIFT_Code__c => '123456789',
                bnk_Bank__c.bnk_Account_Number__c => '123456780'
        });
        Test.startTest(); 
        bankAccount.bnk_Account_Number__c = '923456780';
        update bankAccount;
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM bnk_Bank__c WHERE SWIFT_Code__c != NULL], 'There should now be 2 international bank accounts in the system');
    }
    
    @IsTest
    static void testInternationalAccountFail() {
        Test.startTest();
        Boolean anExceptionOccurred = false;
        try {
            Integer count = 5;
            List<bnk_Bank__c> bankAccounts =(List<bnk_Bank__c>)SObjectFactory.build(count,bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                    bnk_Bank__c.bnk_Bank_Name__c => 'International2',
                    bnk_Bank__c.SWIFT_Code__c => '123456789',
                    bnk_Bank__c.bnk_Account_Number__c => '123456789'
            });
            
            insert bankAccounts;
        } catch (Exception e) {
            anExceptionOccurred = true;
        }
        Test.stopTest();

        System.assert(anExceptionOccurred, 'An exception should have occurred when inserting a duplicate bank Account');
        System.assertEquals(1, [SELECT COUNT() FROM bnk_Bank__c WHERE SWIFT_Code__c != NULL], 'There should only be 4 international bank account in the system');
    }

    @IsTest
    static void testInsertingMultipleBankAccountsThatAreTheSame() {
        Test.startTest();
        Boolean anExceptionOccurred = false;
        try {
            SObjectFactory.create(5, bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                    bnk_Bank__c.bnk_Bank_Name__c => 'NewBankName',
                    bnk_Bank__c.bnk_Routing_Number__c => '987654321',
                    bnk_Bank__c.bnk_Account_Number__c => '987654321'
            });
        } catch (Exception e) {
            anExceptionOccurred = true;
        }
        Test.stopTest();

        System.assert(anExceptionOccurred, 'An exception should have occurred when inserting duplicate bank Accounts');
        System.assertEquals(4, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Routing_Number__c != NULL], 'There should only be 4 domestic bank account in the system');
    }

    @IsTest
    static void statesAndCountryTest() {
        Test.startTest();
        Map<String, String> countries = BankService.getCountries();
        Map<String, String> states = BankService.getStates('US');
        Test.stopTest();

        System.assertEquals('United States', countries.values().get(0), 'We should have retrieved a list of countries');
        System.assertEquals('Illinois', states.values().get(0), 'We should have retireved a list of states based on the country');
    }

    @IsTest
    static void saveBankAccountTest_SuccessDML() {
        Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType, new Map<SObjectField, Object> {
                Contact.Email => 'test@test.com'
        });

        bnk_Bank__c testBankAccount = (bnk_Bank__c) SObjectFactory.build(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                bnk_Bank__c.bnk_Routing_Number__c => ACCOUNT_ROUTING_NUMBER + '',
                bnk_Bank__c.bnk_Account_Number__c => ACCOUNT_ROUTING_NUMBER + '',
                bnk_Bank__c.bnk_Bank_Name__c => BANK_NAME,
                bnk_Bank__c.bnk_Account_Holder_Name__c => testContact.Id
        });

        Id newBankAccountId;

        Test.startTest();
        newBankAccountId = BankService.saveBankAccount(testBankAccount);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM bnk_Bank__c WHERE Id = :newBankAccountId], 'New bank account should be in the database');
    }

    @IsTest
    static void getBankingInformationList() {
        Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType, new Map<SobjectField, Object> {
                Contact.Email => 'test@test.com'
        });

        for(Integer i = 0; i < BANK_ACCOUNT_COUNT; i++) {
            SObjectFactory.create(bnk_Bank__c.SObjectType, new Map<SObjectField, Object> {
                    bnk_Bank__c.bnk_Routing_Number__c => ACCOUNT_ROUTING_NUMBER + '',
                    bnk_Bank__c.bnk_Account_Number__c => (ACCOUNT_ROUTING_NUMBER + i) + '',
                    bnk_Bank__c.bnk_Bank_Name__c => BANK_NAME,
                    bnk_Bank__c.bnk_Account_Holder_Name__c => testContact.Id
            });
        }

        Test.startTest();
        BankService.getBankingInformationList(testContact.Id);
        Test.stopTest();

        System.assertEquals(BANK_ACCOUNT_COUNT, [SELECT COUNT() FROM bnk_Bank__c WHERE bnk_Account_Holder_Name__c = :testContact.Id], 'the number of retrieved bank accounts should be accurate');
    }

    @IsTest
    static void getCurrentContactTest() {
        Contact currentUser;
        Contact currentUser1 = (Contact) SObjectFactory.create(Contact.SObjectType, new Map<SObjectField, Object> {
                Contact.FirstName => 'First',
                Contact.LastName => 'Last',
                Contact.Email => 'test@test.com'
        });
        Contact currentUser2;

        Test.startTest();
        currentUser = BankService.getContact(null);
        currentUser2 = BankService.getContact(currentUser1.Id);
        Test.stopTest();

        System.assertNotEquals(null, currentUser, 'An account summary record should be returned from the service given an Id');
        System.assertEquals(null, currentUser.FirstName, 'the retrieved current user record should have its first name set');
        System.assertEquals(null, currentUser.LastName, 'the retrieved account summary record should have its last name set');
        System.assertEquals(currentUser1.Id, currentUser2.Id, 'An account summary record should be returned from the service given an Id');
        System.assertEquals(currentUser1.FirstName, currentUser2.FirstName, 'the retrieved current user record should have its first name set');
        System.assertEquals(currentUser1.LastName, currentUser2.LastName, 'the retrieved account summary record should have its last name set');
    }
    
    @IsTest
    static void createBankAccountReportsTest() {
        Case newCase = new Case();
        //insert newCase;
         
        BankService.createBankAccountReports(newCase);
    }
    
    @IsTest
    static void saveBankAccountTest() {
        bnk_Bank__c newBankAccount = new bnk_Bank__c();
        BankService.saveBankAccount(newBankAccount);
    }
}