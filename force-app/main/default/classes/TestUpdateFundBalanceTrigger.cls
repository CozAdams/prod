/****************************************************************************************************  
Name : TestUpdateFundBalanceTrigger
Created By : Kristen Oliphant, Revelant Technologies
Email: kristen.oliphant@revelanttech.com 
Created Date : January 2013
Description : This test class tests the UpdateFundBalance trigger
Changes:
****************************************************************************************************/ 

@isTest
private class TestUpdateFundBalanceTrigger {

    static testMethod void myUnitTest() {
        
        /*Id rtFundId = [SELECT Id, Name FROM RecordType WHERE Name='Master Funds' and SObjectType='Fund__c' limit 1].Id;
        
        Fund__c f1 = new Fund__c(RecordTypeId = rtFundId, Name = 'Test Fund 1', Beginning_Balance__c = 100.00);
        Fund__c f2 = new Fund__c(RecordTypeId = rtFundId, Name = 'Test Fund 2', Beginning_Balance__c = 100.00);
        Fund__c f3 = new Fund__c(RecordTypeId = rtFundId, Name = 'Test Fund 3', Beginning_Balance__c = 100.00);
        Fund__c f4 = new Fund__c(RecordTypeId = rtFundId, Name = 'Test Fund 4');
        
        insert f1;
        insert f2;
        insert f3;
        insert f4;
        
        Account a = new Account(Name = 'Test Account', Eligibility__c = 'QCCO');
        insert a;
        
        Id rtOpptyId = [SELECT Id, Name FROM RecordType WHERE Name='Individual Donations' and SObjectType='Opportunity' limit 1].Id;
        
        Opportunity o = new Opportunity();
        
        o.RecordTypeId = rtOpptyId;
        o.Name = 'Test Oppty 1';
        o.AccountId = a.Id;
        o.Amount = 400.00;
        
        Date close = date.today();
        close = close.addDays(7);
        
        o.CloseDate = close;
        o.StageName = 'Posted';
        o.Assigned_Fund_1__c = f1.Id;
        o.Assigned_Fund_2__c = f2.Id;
        o.Assigned_Fund_3__c = f3.Id;
        o.Assigned_Fund_4__c = f4.Id;
        o.Amount_1__c = 100.00;
        o.Amount_2__c = 100.00;
        o.Amount_3__c = 100.00;
        o.Amount_4__c = 100.00;
        
        insert o;
        
        Fund__c f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f1.Id];
        system.assertEquals(f5.Target_Balance__c, 200.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f2.Id];
        system.assertEquals(f5.Target_Balance__c, 200.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f3.Id];
        system.assertEquals(f5.Target_Balance__c, 200.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f4.Id];
        system.assertEquals(f5.Target_Balance__c, 100.00);
        
        o.Assigned_Fund_1__c = f2.Id;
        o.Assigned_Fund_2__c = f1.Id;
        o.Assigned_Fund_3__c = f4.Id;
        o.Assigned_Fund_4__c = f3.Id;
        o.Amount_1__c = 50.00;
        o.Amount_2__c = 50.00;
        o.Amount_3__c = 150.00;
        o.Amount_4__c = 150.00;
        
        update o;
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f1.Id];
        system.assertEquals(f5.Target_Balance__c, 150.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f2.Id];
        system.assertEquals(f5.Target_Balance__c, 150.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f3.Id];
        system.assertEquals(f5.Target_Balance__c, 250.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f4.Id];
        system.assertEquals(f5.Target_Balance__c, 150.00);
        
        delete o;
        
                f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f1.Id];
        system.assertEquals(f5.Target_Balance__c, 100.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f2.Id];
        system.assertEquals(f5.Target_Balance__c, 100.00);
        
        f5 = [SELECT Target_Balance__c FROM Fund__c WHERE Id = :f3.Id];
        system.assertEquals(f5.Target_Balance__c, 100.00);*/
    }
}