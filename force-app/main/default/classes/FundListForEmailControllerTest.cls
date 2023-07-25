@IsTest
public with sharing class FundListForEmailControllerTest {
	@TestSetup
	static void setup() {
		Contact testContact = (Contact) SObjectFactory.create(Contact.SObjectType);

		pymt__Payment_Profile__c paymentProfile = (pymt__Payment_Profile__c) SObjectFactory.create(pymt__Payment_Profile__c.SObjectType, new Map<SObjectField, Object> {
			pymt__Payment_Profile__c.pymt__Period__c => 'Month',
			pymt__Payment_Profile__c.pymt__Contact__c => testContact.Id,
            pymt__Payment_Profile__c.Name_and_Address__c => 'recurring honoree name',
            pymt__Payment_Profile__c.In_Honor_Of_or_In_Memory_Of__c => 'In Honor Of'
		});

		pymt__PaymentX__c payment1 = (pymt__PaymentX__c) SObjectFactory.create(pymt__PaymentX__c.SObjectType, new Map<SObjectField, Object> {
			pymt__PaymentX__c.pymt__Payment_Profile__c => paymentProfile.Id,
			pymt__PaymentX__c.Name_and_Address__c => 'honoree name',
			pymt__PaymentX__c.In_Honor_Of_or_In_Memory_Of__c => 'In Honor Of'
		});

		SObjectFactory.create(pymt__Shopping_Cart_Item__c.SObjectType, new Map<SObjectField, Object> {
			pymt__Shopping_Cart_Item__c.pymt__Quantity__c => 5,
			pymt__Shopping_Cart_Item__c.pymt__Unit_Price__c => 10.00,
			pymt__Shopping_Cart_Item__c.Name => 'Test1',
			pymt__Shopping_Cart_Item__c.pymt__Payment__c => payment1.Id
		});

		SObjectFactory.create(pymt__Shopping_Cart_Item__c.SObjectType, new Map<SObjectField, Object> {
			pymt__Shopping_Cart_Item__c.pymt__Quantity__c => 3,
			pymt__Shopping_Cart_Item__c.pymt__Unit_Price__c => 10.00,
			pymt__Shopping_Cart_Item__c.Name => 'Test2',
			pymt__Shopping_Cart_Item__c.pymt__Payment__c => payment1.Id
		});
	}

	@IsTest
	static void getCurrentPaymentTest() {
		FundListForEmailController controller = new FundListForEmailController();
		controller.currentPaymentId = [SELECT Id FROM pymt__PaymentX__c LIMIT 1].Id;

		Test.startTest();
        String honoree = controller.donationHonoree;
        String inMemoryOf = controller.inHonorMemoryOf;
		Test.stopTest();

		System.assertEquals(controller.currentPayment.pymt__Payment_Profile__r.Name_and_Address__c, honoree, 'The donation honoree name field from the controller should match the tests payment');
		System.assertEquals(controller.currentPayment.pymt__Payment_Profile__r.In_Honor_Of_or_In_Memory_Of__c, inMemoryOf, 'The donation in honor field from the controller should match the tests payment');
	}

    @IsTest
    static void getCurrentPaymentWithoutRecurringTest() {
        pymt__PaymentX__c testPayment = [SELECT Id FROM pymt__PaymentX__c LIMIT 1];
        testPayment.pymt__Payment_Profile__c = null;
        update testPayment;

        FundListForEmailController controller = new FundListForEmailController();
        controller.currentPaymentId = testPayment.Id;

        Test.startTest();
        String honoree = controller.donationHonoree;
        String inMemoryOf = controller.inHonorMemoryOf;
        Test.stopTest();

        System.assertEquals(controller.currentPayment.Name_and_Address__c, honoree, 'The donation honoree name field from the controller should match the tests payment');
        System.assertEquals(controller.currentPayment.In_Honor_Of_or_In_Memory_Of__c, inMemoryOf, 'The donation in honor field from the controller should match the tests payment');
    }

	@IsTest
	static void getShoppingCartItemsTest() {
		FundListForEmailController controller = new FundListForEmailController();
		controller.currentPaymentId = [SELECT Id FROM pymt__PaymentX__c LIMIT 1].Id;

		Test.startTest();
           List<pymt__Shopping_Cart_Item__c> controllerCartItems = controller.shoppingCartItems;
		Test.stopTest();

		System.assertEquals([SELECT COUNT() FROM pymt__Shopping_Cart_Item__c WHERE pymt__Payment__c = :controller.currentPaymentId], controllerCartItems.size(), 'The number of shopping cart items returned from controller should match the tests cart item count');
	}

	@IsTest
	static void getCurrentFrequency() {
		FundListForEmailController controller = new FundListForEmailController();
		controller.currentPaymentId = [SELECT Id FROM pymt__PaymentX__c LIMIT 1].Id;

		Test.startTest();
			String controllerPaymentFrequency = controller.frequency;
		Test.stopTest();

		System.assertEquals('Monthly', controllerPaymentFrequency, 'The payment frequency variable from the controller should match the tests payment profiles frequency');
	}

	@IsTest
	static void getCurrentFrequency_noRecurring() {
		pymt__PaymentX__c testPayment = [SELECT Id FROM pymt__PaymentX__c LIMIT 1];
		testPayment.pymt__Payment_Profile__c = null;
		update testPayment;

		FundListForEmailController controller = new FundListForEmailController();
		controller.currentPaymentId = testPayment.Id;

		Test.startTest();
			String controllerPaymentFrequency = controller.frequency;
		Test.stopTest();

		System.assertEquals('One Time', controllerPaymentFrequency, 'The payment frequency variable from the controller should be 1, since a payment profile doesnt exist');
	}



}