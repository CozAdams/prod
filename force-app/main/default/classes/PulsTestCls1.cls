@isTest 
private class PulsTestCls1 
{

    @future
    public static void insertuser(list<Id> contactId)
    {
        //Create portal account owner
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'CustomerPortal' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'PFCC Community User'];
        list<user> users = new list<user> ();
        users.add(new User(
                           ProfileId = profile1.Id,
                           Username = System.now().millisecond() + 'testblahblah2@test.com',
                           Alias = 'batman',
                           Email = 'portalUser@wayneenterprises.com',
                           EmailEncodingKey = 'UTF-8',
                           Firstname = 'Bruce',
                           Lastname = 'Wayne',
                           LanguageLocaleKey = 'en_US',
                           LocaleSidKey = 'en_US',
                           TimeZoneSidKey = 'America/Chicago',
                           contactId = contactId[0]
        ));

        Database.insert(users);

    }

    @testSetup static void loadData() {
            Account ac = new Account(name ='Test PFCC Account') ;
            insert ac;

        //insert contact
        list<contact> tsps = new list<contact> ();
        tsps.add(new contact(accountid=ac.id,firstname = 'John Doe', lastname = 'DOe', email = 'portalUser@wayneenterprises.com', 
        Contact_Status__c = 'Active',Contact_Type__c = 'Non-Member',Member_Type__c = 'LAY'));
        insert tsps;
        
        
        /*list<id> contactIds = new list<id> ();
        contactIds.add(tsps[0].id);
        test.startTest();
        instuser(contactIds);
        test.stopTesert();
        
        list<user> users= new list<user>();
        users = [select id from user where email=''];*/
        
        //insert AcctSummry
        list<Account_Summary__c> AcctSummry= new list<Account_Summary__c> ();
             Id tspRecordtypeId = Schema.SObjectType.Account_Summary__c.getRecordTypeInfosByName().get('Standard Record').getRecordTypeId();
        AcctSummry.add(new Account_Summary__c(
            Name = System.now().millisecond() + 'Testclass', 
            Account_Number__c = 'Test Acct Summ',
            Member_Name__c=tsps[0].id,
            recordtypeid = tspRecordtypeId, 
            ExternalID__c = 'abc123def567'
            ));     
        insert AcctSummry;


        //insert Transactions
        list<Transaction__c> Transactions = new list<Transaction__c> ();
        Transactions.add(new Transaction__c
            (
            Account_Summary__c= AcctSummry[0].id,
            Amount__c=99.99,
            ContactId__c=tsps[0].id,
            ExternalID__c='test1'
            ));
            insert Transactions;
        
        }
        
    @isTest static void UserTestONPublicSite() {
        
            PageReference pageRef = Page.PulsChkVFpageList;    
            test.setCurrentPage(pageref);
            test.startTest();
            PulsChkClsList obj = new PulsChkClsList();
            test.stopTest();
        
        
        
        }
}