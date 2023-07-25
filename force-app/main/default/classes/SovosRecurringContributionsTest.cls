@isTest
public class SovosRecurringContributionsTest {
    
    @isTest
    public static void getDataTest() {
        Test.setMock(HttpCalloutMock.class, new SovosCalloutMock());
        Account testAccount = createAccount();
        Contact testContact = createContact(testAccount.Id);
        User portalUser = createUser(testContact, 'newuser1');
        Account_Summary__c accSummary = createAccountSummary(testContact.Id);
        
        test.startTest();
        SovosRecurringContributionsController.getData(portalUser.Id);
        test.stopTest();
    }
    
    // Create Portal User
    private static User createUser(Contact cont, String username) {
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'PFCC Customer CPL - Member' LIMIT 1];
        
        User user = new User();
        user.ProfileId = profile.Id;
        user.ContactId = cont.Id;
        user.FirstName = cont.FirstName;
        user.LastName = cont.LastName;
        user.Email = cont.Email;
        user.Emailencodingkey = 'UTF-8';
        user.Username = cont.Email+username;
        user.Alias = username;
        user.Localesidkey = 'en_US';
        user.Languagelocalekey = 'en_US';
        user.Timezonesidkey = 'America/Los_Angeles';
        user.CommunityNickName = user.Alias + String.valueOf(DateTime.now().getTime());
        user.SpringCMEos__SpringCM_User__c = true;
        insert user;
        return user;
    }
    
    // Create Account
    private static Account createAccount(){
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Account account = new Account();
        account.OwnerId = currentUser.Id;
        account.Name = 'Test Account';
        insert account;
        return account;
    }
    
    // Create Contact
    private static Contact createContact(Id accountId){
        Contact contact = new Contact();
        contact.AccountId = accountId;
        contact.FirstName = 'Juan';
        contact.LastName = 'Dela Cruz';
        contact.Email = 'test@email.com';
        contact.MailingCountry = 'United States';
        contact.Social_Security_Number__c = '026385036';
        insert contact;
        return contact;
    }

    //Create Account Summary
    private static Account_Summary__c createAccountSummary(String conId) {
        Id recTypeId = Schema.getGlobalDescribe().get('Account_Summary__c').getDescribe().getRecordTypeInfosByName().get('Supplemental Savings Account PFE').getRecordTypeId();
        Account_Summary__c accSummary = new Account_Summary__c();
        accSummary.Name = 'Test';
        accSummary.Member_Name__c = conId;
        accSummary.Status__c = 'A';
        accSummary.RecordTypeId = recTypeId;
        accSummary.Plan_ID__c = 'IRATRAD';
        insert accSummary;
        return accSummary;
        
    }
}