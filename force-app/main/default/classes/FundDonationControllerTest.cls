@IsTest
private class FundDonationControllerTest {

    @TestSetup
    static void setup() {
        RecordType customDonationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Fund_Donation_Page' LIMIT 1];
        pymt__Settings__c paymentConnectSetup = (pymt__Settings__c) SObjectFactory.create(pymt__Settings__c.SObjectType);
        pymt__Processor_Connection__c paypalProcessor = (pymt__Processor_Connection__c) SObjectFactory.create(
                pymt__Processor_Connection__c.SObjectType, new Map<SObjectField, Object> {
                pymt__Processor_Connection__c.Name => 'PayPal',
                pymt__Processor_Connection__c.pymt__Processor_Id__c => 'PayPal',
                pymt__Processor_Connection__c.pymt__PaymentConnect_Setup__c => paymentConnectSetup.Id
            }
        );
        SObjectFactory.create(dn8n__Donation_Page__c.SObjectType, new Map<SObjectField, Object> {
                dn8n__Donation_Page__c.RecordTypeId => customDonationRecordType.Id,
                dn8n__Donation_Page__c.dn8n__Donation_Options__c => 'One Time;Monthly;Annual',
                dn8n__Donation_Page__c.dn8n__Status__c => 'Published',
                dn8n__Donation_Page__c.dn8n__Publication_Date__c => Date.today(),
                dn8n__Donation_Page__c.dn8n__Expiration_Date__c => Date.today().addDays(1),
                dn8n__Donation_Page__c.dn8n__Suggested_Donation_Amounts__c => '50.00;20.00;10.00;?',
                dn8n__Donation_Page__c.dn8n__Currency_ISO_Code__c => 'USD',
                dn8n__Donation_Page__c.dn8n__Minimum_Donation__c => 5.00,
                dn8n__Donation_Page__c.dn8n__Processor_Connection__c => paypalProcessor.Id
        });
        SObjectFactory.create(Country__c.SObjectType, new Map<Schema.SObjectField, Object> {
                Country__c.Name => 'US',
                Country__c.ISO__c => 'US',
                Country__c.Label__c => 'United States'
        });
        SObjectFactory.create(State__c.SObjectType, new Map<Schema.SObjectField, Object> {
                State__c.Name => 'US-AK',
                State__c.CountryISO__c => 'US',
                State__c.ISO__c => 'AK',
                State__c.Label__c => 'Alaska'
        });
        SObjectFactory.create(Currency__c.SObjectType, new Map<Schema.SObjectField, Object> {
                Currency__c.Name => 'USD',
                Currency__c.Symbol__c => '$'
        });
        RecordType masterFundType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Master_Funds' AND SObjectType = 'Product2' LIMIT 1];
        RecordType namedFundType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Named_Funds' AND SObjectType = 'Product2' LIMIT 1];
        SObjectFactory.create(Product2.SObjectType, new Map<Schema.SObjectField, Object>{
                Product2.RecordTypeId => masterFundType.Id,
                Product2.Name => 'TestMaster'
        });
        SObjectFactory.create(Product2.SObjectType, new Map<Schema.SObjectField, Object>{
                Product2.RecordTypeId => namedFundType.Id,
                Product2.Name => 'TestNamed'
        });
    }

    @IsTest
    static void testNoDonations() {
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller.processDonation();
        Test.stopTest();

        System.assertEquals(FundDonationController.NO_PRODUCTS_SELECTED, ApexPages.getMessages().get(0).getDetail(), 'No products selected message should be displayed');
    }

    @IsTest
    static void testNoAmount() {
        Product2 masterProduct = [SELECT Id FROM Product2 WHERE Name = 'TestMaster' LIMIT 1];
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller.selectedProductId = masterProduct.Id;
        controller.toggleFund();
        controller.processDonation();
        Test.stopTest();

        System.assertEquals(FundDonationController.DONATION_ERROR + FundDonationService.getCurrencySymbol(donationPage.dn8n__Currency_ISO_Code__c)
                + donationPage.dn8n__Minimum_Donation__c, ApexPages.getMessages().get(0).getDetail(), 'Donation error should have occurred if nothing donated');
    }

    @IsTest
    static void testNoOtherDonation() {
        Product2 masterProduct = [SELECT Id FROM Product2 WHERE Name = 'TestMaster' LIMIT 1];
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller.selectedProductId = masterProduct.Id;
        controller.toggleFund();
        controller.selectedProductWrappersByProductId.values().get(0).selectedDonationOption = FundDonationController.OTHER_DONATION_OPTION;
        controller.processDonation();
        Test.stopTest();

        System.assertEquals(FundDonationController.DONATION_ERROR + FundDonationService.getCurrencySymbol(donationPage.dn8n__Currency_ISO_Code__c)
                + donationPage.dn8n__Minimum_Donation__c, ApexPages.getMessages().get(0).getDetail(), 'Donation error should have occurred if nothing donated');
    }

    @IsTest
    static void testOneDonation() {
        Product2 masterProduct = [SELECT Id FROM Product2 WHERE Name = 'TestMaster' LIMIT 1];
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller = setContactFields(controller);
        controller.selectedProductId = masterProduct.Id;
        controller.toggleFund();
        controller.selectedProductWrappersByProductId.values().get(0).selectedDonationOption = FundDonationController.OTHER_DONATION_OPTION;
        controller.selectedProductWrappersByProductId.values().get(0).donationAmount = donationPage.dn8n__Minimum_Donation__c + 1;
        controller.processDonation();
        Test.stopTest();

        List<pymt__PaymentX__c> payments = [SELECT Id FROM pymt__PaymentX__c];
        List<Account> accs = [SELECT Id, Name FROM Account LIMIT 1];
        List<Contact> cons = [SELECT Id, AccountId FROM Contact LIMIT 1];
        System.assertEquals(0, ApexPages.getMessages().size(), 'There should not be a page message: ' + (ApexPages.getMessages().size() > 0 ? ApexPages.getMessages()[0].getDetail() : ''));
        System.assertEquals(1, payments.size(), 'There should have been a payment created');
        System.assertEquals(1, accs.size(), 'Account should have been created');
        System.assertEquals('TestCompany', accs[0].Name, 'Account should have been created with specified name');
        System.assertEquals(1, cons.size(), 'Contact should have been created');
        System.assertEquals(accs[0].Id, cons[0].AccountId, 'Contact should have been created with account reference');
    }

    @IsTest
    static void testOneRecurringDonation() {
        Product2 namedProduct = [SELECT Id FROM Product2 WHERE Name = 'TestNamed' LIMIT 1];
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller.isRecurring = true;
        controller.recurringFundValidation();
        System.assertEquals(0, ApexPages.getMessages().size(), 'Should be no page msgs after recurringFundValidation() ' + (ApexPages.getMessages().size() > 0 ? ApexPages.getMessages()[0].getDetail() : ''));
        controller = setContactFields(controller);
        controller.selectedProductId = namedProduct.Id;
        controller.selectFund();
        controller.selectedProductWrappersByProductId.values().get(0).selectedDonationOption = FundDonationController.OTHER_DONATION_OPTION;
        controller.selectedProductWrappersByProductId.values().get(0).donationAmount = donationPage.dn8n__Minimum_Donation__c + 1;
        controller.processDonation();
        Test.stopTest();

        List<pymt__Payment_Profile__c> paymentProfile = [SELECT Id, Donation_Product__c FROM pymt__Payment_Profile__c];
        System.assertEquals(0, ApexPages.getMessages().size(), 'There should not be a page message: ' + (ApexPages.getMessages().size() > 0 ? ApexPages.getMessages()[0].getDetail() : ''));
        System.assertEquals(1, paymentProfile.size(), 'There should have been a payment profile created');
        System.assertNotEquals(null, paymentProfile[0].Donation_Product__c, 'The donation product field should be populated from the selection on the page');
    }

    @IsTest
    static void testMultipleRecurringDonations() {
        Product2 masterProduct = [SELECT Id FROM Product2 WHERE Name = 'TestMaster' LIMIT 1];
        Product2 namedProduct = [SELECT Id FROM Product2 WHERE Name = 'TestNamed' LIMIT 1];
        dn8n__Donation_Page__c donationPage = getTestDonationPage();
        Test.startTest();
        FundDonationController controller = new FundDonationController(new ApexPages.StandardController(donationPage));
        controller = setContactFields(controller);
        controller.selectedProductId = namedProduct.Id;
        controller.selectFund();
        controller.selectedProductId = masterProduct.Id;
        controller.toggleFund();
        controller.selectedProductWrappersByProductId.values().get(0).selectedDonationOption = FundDonationController.OTHER_DONATION_OPTION;
        controller.selectedProductWrappersByProductId.values().get(0).donationAmount = donationPage.dn8n__Minimum_Donation__c + 1;
        controller.selectedProductWrappersByProductId.values().get(1).selectedDonationOption = '20.00';
        controller.selectedProductWrappersByProductId.values().get(1).donationAmount = donationPage.dn8n__Minimum_Donation__c + 1;
        controller.isRecurring = true;
        controller.recurringFundValidation();
        Test.stopTest();

        System.assertEquals(FundDonationController.RECURRING_DONATION_ERROR, ApexPages.getMessages().get(0).getDetail(), 'Should not select recurring if multiple products are selected.');
    }

    static FundDonationController setContactFields(FundDonationController controller) {
        controller.salutation = 'Mr';
        controller.firstName = 'TestFirst';
        controller.lastName = 'TestLast';
        controller.emailAddress = 'TestEmail@email.com';
        controller.companyName = 'TestCompany';
        controller.address = 'TestStreet';
        controller.city = 'TestCity';
        controller.billingState = 'IL';
        controller.billingPostalCode = 'TestPostal';
        controller.billingCountry = 'US';
        return controller;
    }

    static dn8n__Donation_Page__c getTestDonationPage(){
        return [SELECT Id, dn8n__Donation_Options__c, dn8n__Status__c, dn8n__Publication_Date__c,
                dn8n__Expiration_Date__c, dn8n__Suggested_Donation_Amounts__c, dn8n__Currency_ISO_Code__c, dn8n__Minimum_Donation__c,
                dn8n__Processor_Connection__c, dn8n__Payment_Record_Name__c, dn8n__Processor_Connection__r.pymt__Processor_Id__c, dn8n__Confirmation_URL__c FROM dn8n__Donation_Page__c LIMIT 1][0];
    }
}