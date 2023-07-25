@isTest
public with sharing class SovosOptInOutControllerTest {
    static Account testAccount;
    static Contact testContact;
    static User portalUser;

    private static void init(){
        testAccount = createAccount();
        testContact = createContact(testAccount.Id);
        portalUser = createUser(testContact, 'newuser1');

        SovosIntegration__c setting = new SovosIntegration__c();
        setting.Domain__c = 'CC0793TP';
        setting.Alias__c = 'PROD';
        insert setting;

        
    }
 
    @isTest
    public static void getData() {
        init();
        Test.startTest();
        SovosOptInOutController.getData(portalUser.Id);
        Test.stopTest();
    }

    @IsTest
    public static void updateOptInout(){
        init();
        Test.setMock(HttpCalloutMock.class, new SovosOptInOutMock());
        SovosOptInOutController.updateOptInOutForUser(portalUser.id,false);
    }

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
        account.Name = 'Sovos Account';
        insert account;
        return account;
    }
    
    // Create Contact
    private static Contact createContact(Id accountId){
        Contact contact = new Contact();
        contact.AccountId = accountId;
        contact.FirstName = 'Micheal';
        contact.LastName = 'John';
        contact.Email = 'mich@email.com';
        contact.MailingCountry = 'United States';
        contact.Social_Security_Number__c = '98098765';
        contact.Stop_receiving_paper_tax_statements__c = false;
        contact.Opt_Out_Prompted_All_Paper_Tax_Forms__c = false;
        insert contact;
        return contact;
    }
}