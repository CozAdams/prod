/**
* @author Lev
* @date 2020
*
* @description Test class for Account Trigger
*/
@isTest
private class AccountTriggerTest {
    @isTest
    private static void testUpdateAccount_success() {
        Account organization = TestDataFactory.createAccount(true, 'Organization', 'Test Org');
        organization.Active_Members_Average_Age__c = 40;
        
        // Test
        System.Test.startTest();
        update organization;
        System.Test.stopTest();
        
        // No errors
    }
    
    @isTest
    private static void testDeleteAccount_success() {
        Account organization = TestDataFactory.createAccount(true, 'Organization', 'Test Org');
        
        // Test
        System.Test.startTest();
        delete organization;
        System.Test.stopTest();
        
        // No errors
    }
    
    @isTest
    private static void testUpdateAccount_error() {
        Account organization = TestDataFactory.createAccount(true, 'Organization', 'Test Org');
        organization.Internal_System_Account__c = true;
        String errorMsg;
        
        // Test
        System.Test.startTest();
        try {
            update organization;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();
        
        // Error thrown 
        System.assertNotEquals(null, errorMsg);
    }
    
    @isTest
    private static void testDeleteAccount_error() {
        Account organization = TestDataFactory.createAccount(false, 'Organization', 'Test Org');
        organization.Internal_System_Account__c = true;
        insert organization;
        String errorMsg;
        
        // Test
        System.Test.startTest();
        try {
            delete organization;
        }
        catch(Exception e) {
            errorMsg = e.getMessage();
        }
        System.Test.stopTest();
        
        // Error thrown 
        System.assertNotEquals(null, errorMsg);
    }
}