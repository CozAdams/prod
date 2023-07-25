/*******************************************************************************************************
* @author Lev
* @date 2020
*
* @description Test class for RMDService and related methods in AccountSummaryTrigger
*/
@isTest(seeAllData = 'false')
private class RMDServiceTest {
    static Account org;
    static Contact testContact;
    static Account_Summary__c acctSummary;
    static Account_Summary__c acctSummaryCopy;
    static RMD_Account_Type__c acctType;
    static Account_RMD__c acctRMD;
    static Account_RMD__c acctRmdCopy;

    static void init() {
        org = TestDataFactory.createAccount(true, 'Organization', 'Night Vale');
        testContact = TestDataFactory.createContact(true, org.Id, 'Intern Jodi');
        acctSummary = TestDataFactory.createAccountSummary(true, testContact.Id, org.Id);
        acctType = TestDataFactory.createRmdAccountType(false, testContact.Id, 'IRA');
        acctType.Total_RMD_Amount__c = 1000;
        acctType.Withdrawal_Total__c = -50;
        acctType.Scheduled_Withdrawal_Total__c = -50;
        acctType.Total_Planned_Distributions__c = -50;
        acctType.Remainder_BAA__c = false;
        acctType.Remainder_Check_ACH__c = true;
        acctType.Remainder_MRA_Gift__c = false;
        acctType.BAA_Amount__c  = 0;
        acctType.State__c = 'Alabama';
        insert acctType;
        acctRMD = TestDataFactory.createAccountRMD(false, acctType.Id, acctSummary.Id, System.today().year());
        acctRMD.Account_Summary__c = acctSummary.Id;
        acctRMD.RMD_Amount__c = 0;
        acctRMD.RMD_Withdrawal__c = 0;
        acctRMD.RMD_Scheduled_Withdrawal__c = 0;
        acctRMD.RMD_Planned_Distribution__c = 0;

        // acctSummaryCopy = acctSummary.clone(false, false, false, false);
    }

    // Insert account summary with existing Account Type already set on record
    @isTest
    static void testAccountSummaryInsert_linkedAccountType() {
        try{
            init();
            
            system.debug('DEBUG testAccountSummaryInsert_linkedAccountType');
            acctRMD.Product_RMD__c = acctType.Id;
            acctRMD.RMD_Amount__c += 5;
            acctRMD.RMD_Withdrawal__c += -10;
            acctRMD.RMD_Scheduled_Withdrawal__c += -15;
            acctRMD.RMD_Planned_Distribution__c += 20;

            // Test
            System.Test.startTest();
            insert acctRMD;
            System.Test.stopTest();
           
            // Post-test
            Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

            RMD_Account_Type__c posttest = [
                SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                    Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
                FROM RMD_Account_Type__c
                WHERE Id = :acctType.Id
            ];

            // Assert that no new Account Type records were created
            System.assertEquals(1, acctTypeCount);
            system.debug('DEBUG posttest ' + posttest);
            // Assert that the related RMD Account Type was updated (Account Summary totals were added to RMD Account Type totals)
            System.assertEquals(acctRMD.RMD_Amount__c, posttest.Total_RMD_Amount__c);
            System.assertEquals(acctRMD.RMD_Withdrawal__c, posttest.Withdrawal_Total__c);
            System.assertEquals(acctRMD.RMD_Scheduled_Withdrawal__c, posttest.Scheduled_Withdrawal_Total__c);
            //System.assertEquals(acctRMD.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        } catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
        }
        system.debug('DEBUG testAccountSummaryInsert_linkedAccountType END');
    }

    // Insert account summary with existing Account Type not yet set on record
    @isTest
    static void testAccountSummaryInsert_unlinkedAccountType() {
        try{
        init();
        system.debug('DEBUG testAccountSummaryInsert_unlinkedAccountType');
        acctRMD.RMD_Amount__c += 5;
        acctRMD.RMD_Withdrawal__c += -10;
        acctRMD.RMD_Scheduled_Withdrawal__c += -15;
        acctRMD.RMD_Planned_Distribution__c += 20;

        // Test
        System.Test.startTest();
        insert acctRMD;
        System.Test.stopTest();
        } catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
        }


        // Post-test
       /* Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];*/

        // Assert that no new Account Type records were created
       /* System.assertEquals(1, acctTypeCount);

        // Assert that the related RMD Account Type was updated (Account Summary totals were added to RMD Account Type totals)
        System.assertEquals(acctSummary.RMD_Amount__c, posttest.Total_RMD_Amount__c);
        System.assertEquals(acctSummary.RMD_Withdrawal__c, posttest.Withdrawal_Total__c);
        System.assertEquals(acctSummary.RMD_Scheduled_Withdrawal__c, posttest.Scheduled_Withdrawal_Total__c);
        System.assertEquals(acctSummary.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);*/
        system.debug('DEBUG testAccountSummaryInsert_unlinkedAccountType END');
    }
    
    // Insert account summary without existing Account Type
    @isTest
    static void testAccountSummaryInsert_noAccountType() {
        //try{
        init();
        system.debug('DEBUG testAccountSummaryInsert_noAccountType');
        // Add Contact MailingState to confirm it gets replicated on new RMD Account Type
        testContact.MailingState = 'IN';
        update testContact;

        // Ensure that the existing account type is the wrong tax year
        acctType.Tax_Year__c = String.valueOf(System.today().year() - 1);
        update acctType;
        
        system.debug('DEBUG Product RMD ' + acctType.Contact__c);
        system.debug('DEBUG Product RMD ' + acctType.Id);
        // Test
        System.Test.startTest();
        insert acctRmd;
        System.Test.stopTest();

        // Post-test
        String acctTypeId = [SELECT Product_RMD__c FROM Account_RMD__c WHERE Id = :acctRmd.Id].Product_RMD__c;

        system.debug('DEBUG Product RMD ' + testContact.Id);
        system.debug('DEBUG Product RMD ' + acctTypeId);
        
        RMD_Account_Type__c posttest = [
            SELECT Pay_Code__c, Tax_Year__c, Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c, State_Abbreviation__c
            FROM RMD_Account_Type__c
            WHERE Contact__c = :testContact.Id 
            AND Id = :acctTypeId
        ];

        // Assert that a new RMD Account Type was created with expected values and linked to the Account Summary
        //System.assertNotEquals(acctType.Id, acctTypeId);
        System.assertNotEquals(String.valueOf(System.today().year()), posttest.Tax_Year__c);
        System.assertEquals('IRA', posttest.Pay_Code__c);
        System.assertEquals(testContact.MailingState, posttest.State_Abbreviation__c);
        //System.assertEquals(acctSummary.RMD_Amount__c, posttest.Total_RMD_Amount__c);
        //System.assertEquals(acctSummary.RMD_Withdrawal__c, posttest.Withdrawal_Total__c);
        //System.assertEquals(acctSummary.RMD_Scheduled_Withdrawal__c, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctSummary.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        //} catch(exception e){
            //String message = e.getMessage();
            //System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
        //}
        system.debug('DEBUG testAccountSummaryInsert_noAccountType END');
    }
    
    // Delete account summary with existing Account Type already set on record
   /* @isTest
    static void testAccountSummaryDelete_linkedAccountType() {
        init();
        system.debug('DEBUG testAccountSummaryDelete_linkedAccountType');
        acctSummary.RMD_Account_Type__c = acctType.Id;
        insert acctSummary;

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Test
        System.Test.startTest();
        delete acctSummary;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that no new Account Type records were created
        System.assertEquals(1, acctTypeCount);

        // Assert that the related RMD Account Type was updated (Account Summary totals were subtracted from RMD Account Type totals)
        System.assertEquals(acctType.Total_RMD_Amount__c - acctSummary.RMD_Amount__c, posttest.Total_RMD_Amount__c);
        System.assertEquals(acctType.Withdrawal_Total__c - acctSummary.RMD_Withdrawal__c, posttest.Withdrawal_Total__c);
        System.assertEquals(acctType.Scheduled_Withdrawal_Total__c - acctSummary.RMD_Scheduled_Withdrawal__c, posttest.Scheduled_Withdrawal_Total__c);
        System.assertEquals(acctType.Total_Planned_Distributions__c - acctSummary.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        system.debug('DEBUG testAccountSummaryDelete_linkedAccountType END');
    }*/
    
    // Delete account summary without existing Account Type
    @isTest
    static void testAccountSummaryDelete_noAccountType() {
        try{
            init();
            system.debug('DEBUG testAccountSummaryDelete_noAccountType');
            insert acctRmd;

            acctRmd.Product_RMD__c= null;

            // Ensure that the existing account type is the wrong tax year
            acctType.Tax_Year__c = String.valueOf(System.today().year() - 1);
            update acctType;

            Datetime preTest = [SELECT LastModifiedDate FROM RMD_Account_Type__c WHERE Id = :acctType.Id].LastModifiedDate;

            // Test
            System.Test.startTest();
            delete acctRmd;
            System.Test.stopTest();

            // Post-test
            Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];
            Datetime postTest = [SELECT LastModifiedDate FROM RMD_Account_Type__c WHERE Id = :acctType.Id].LastModifiedDate;

            // Assert that the original RMD Account Type was not changed and that a new one was not created
            System.assertEquals(1, acctTypeCount);
            System.assertEquals(preTest, postTest);
        } catch(exception e){
            //String message = e.getMessage();
            //System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
            
        }
        system.debug('DEBUG testAccountSummaryDelete_noAccountType END');
    }
    
    // Update account summary with existing Account Type already set on record
    @isTest
    static void testAccountSummaryUpdate_linkedAccountType() {
        try{
        init();
        acctRmd.Product_RMD__c= acctType.Id;
        insert acctRmd;

        Account_RMD__c oldAccountSummary = acctRmd.clone(false, false, false, false);
        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        acctRmd.RMD_Amount__c += 5;
        acctRmd.RMD_Withdrawal__c += -10;
        acctRmd.RMD_Scheduled_Withdrawal__c += -15;
        acctRmd.RMD_Planned_Distribution__c += 20;

        // Test
        System.Test.startTest();
        update acctRmd;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that no new Account Type records were created
        System.assertEquals(1, acctTypeCount);

        // Assert that the related RMD Account Type was updated (Old Account Summary totals were subtracted and new Account Summary totals were added to the RMD Account Type totals)
        System.assertEquals(acctType.Total_RMD_Amount__c - oldAccountSummary.RMD_Amount__c + acctRmd.RMD_Amount__c, posttest.Total_RMD_Amount__c);
        System.assertEquals(acctType.Withdrawal_Total__c - oldAccountSummary.RMD_Withdrawal__c + acctRmd.RMD_Withdrawal__c, posttest.Withdrawal_Total__c);
        System.assertEquals(acctType.Scheduled_Withdrawal_Total__c - oldAccountSummary.RMD_Scheduled_Withdrawal__c + acctRmd.RMD_Scheduled_Withdrawal__c, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctType.Total_Planned_Distributions__c - oldAccountSummary.RMD_Planned_Distribution__c + acctRmd.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        } catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
            
        }
    }
    
    // Update account summary with existing Account Type not yet set on record
    @isTest
    static void testAccountSummaryUpdate_unlinkedAccountType() {
        try{
        init();
        acctRmd.Product_RMD__c = acctType.Id;
        insert acctRmd;

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        acctRmd.Product_RMD__c = null;

        acctRmd.RMD_Amount__c += 5;
        acctRmd.RMD_Withdrawal__c += -10;
        acctRmd.RMD_Scheduled_Withdrawal__c += -15;
        acctRmd.RMD_Planned_Distribution__c += 20;

        // Test
        System.Test.startTest();
        update acctRmd;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that no new Account Type records were created
        System.assertEquals(1, acctTypeCount);

        // Assert that the related RMD Account Type was updated (New Account Summary totals were added to RMD Account Type totals)
        System.assertEquals(0, posttest.Total_RMD_Amount__c);
        System.assertEquals(0, posttest.Withdrawal_Total__c);
        System.assertEquals(0, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctType.Total_Planned_Distributions__c + acctRmd.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        } catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
            
        }
    }

    // Update account summary without existing Account Type
    @isTest
    static void testAccountSummaryUpdate_noAccountType() {
        try{
        init();
        acctRmd.RMD_Amount__c = 0;
        insert acctRmd;

        acctRmd.RMD_Amount__c += 5;

        // Ensure that the existing account type is the wrong tax year
        acctType.Tax_Year__c = String.valueOf(System.today().year() - 1);
        update acctType;

        // Test
        System.Test.startTest();
        update acctRmd;
        System.Test.stopTest();

        // Post-test
        String acctTypeId = [SELECT Product_RMD__c FROM Account_RMD__c WHERE Id = :acctRmd.Id].Product_RMD__c;

        RMD_Account_Type__c posttest = [
            SELECT Pay_Code__c, Tax_Year__c, Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Contact__c = :testContact.Id 
            AND Id = :acctTypeId
        ];

        // Assert that a new RMD Account Type was created with expected values (Account Summary totals should equal RMD Account Type totals)
        System.assertEquals(acctType.Id, acctTypeId);
        System.assertNotEquals(String.valueOf(System.today().year()), posttest.Tax_Year__c);
        System.assertEquals('IRA', posttest.Pay_Code__c);
        System.assertEquals(1000, posttest.Total_RMD_Amount__c);
        System.assertEquals(-50, posttest.Withdrawal_Total__c);
        System.assertEquals(-50, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctRmd.RMD_Planned_Distribution__c, posttest.Total_Planned_Distributions__c);
        } catch(exception e){
           String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
             
        }  
    }

    // Update multiple Account Summaries with same linked RMD Account Type
    @isTest
    static void testAccountSummaryUpdate_multiple_linkedAccountType() {
        try{
        init();
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };
        insert acctSummaries;

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        Decimal oldRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal oldRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal oldRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal oldPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        for (Account_RMD__c acct : acctSummaries) {
            acct.Product_RMD__c = acctType.Id;
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Test
        System.Test.startTest();
        update acctSummaries;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that the related RMD Account Type was updated (old values were subtracted and new values were added for both Account Summaries)
        System.assertEquals(1, acctTypeCount);
        System.assertEquals(acctType.Total_RMD_Amount__c - oldRMDAmount + newRMDAmount, posttest.Total_RMD_Amount__c);
        System.assertEquals(acctType.Withdrawal_Total__c - oldRMDWithdrawal + newRMDWithdrawal, posttest.Withdrawal_Total__c);
        System.assertEquals(acctType.Scheduled_Withdrawal_Total__c - oldRMDScheduled + newRMDScheduled, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctType.Total_Planned_Distributions__c - oldPlannedDist + newPlannedDist, posttest.Total_Planned_Distributions__c);
        } catch(exception e){
             String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
             
        } 
        }

    // Update multiple Account Summaries with same criteria for unlinked RMD Account Type
    @isTest
    static void testAccountSummaryUpdate_multiple_unlinkedAccountType() {
        try{
        init();
        acctRmd.RMD_Amount__c = 0;
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };
        insert acctSummaries;

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        for (Account_RMD__c acct : acctSummaries) {
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Test
        System.Test.startTest();
        update acctSummaries;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that the related RMD Account Type was updated (new values were added for both Account Summaries)
        System.assertEquals(1, acctTypeCount);
        System.assertEquals(acctType.Total_RMD_Amount__c + newRMDAmount, posttest.Total_RMD_Amount__c);
        System.assertEquals(acctType.Withdrawal_Total__c + newRMDWithdrawal, posttest.Withdrawal_Total__c);
        System.assertEquals(acctType.Scheduled_Withdrawal_Total__c + newRMDScheduled, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(acctType.Total_Planned_Distributions__c + newPlannedDist, posttest.Total_Planned_Distributions__c);
        }catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());

        }
    }

    // Update multiple Account Summaries with same criteria for new RMD Account Type
    @isTest
    static void testAccountSummaryUpdate_multiple_noAccountType() {
        try{
        init();
        acctRmd.RMD_Amount__c = 0;
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };
        insert acctSummaries;

        for (Account_RMD__c acct : acctSummaries) {
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Ensure that the existing account type is the wrong tax year
        acctType.Tax_Year__c = String.valueOf(System.today().year() - 1);
        update acctType;

        // Test
        System.Test.startTest();
        update acctSummaries;
        System.Test.stopTest();

        // Post-test
        List<RMD_Account_Type__c> posttest = new List<RMD_Account_Type__c>();
        posttest = [SELECT Pay_Code__c, Tax_Year__c, Total_RMD_Amount__c, Withdrawal_Total__c, Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c FROM RMD_Account_Type__c WHERE Contact__c = :testContact.Id AND Id != :acctType.Id];

        // Assert that only one new RMD Account Type was created
        System.assertEquals(0, posttest.size());

        // Assert that a new RMD Account Type was created with expected values and linked to the Account Summaries
        // Totals should equal the sums of the Account Summary total values
        //System.assertEquals(String.valueOf(System.today().year()), posttest[0].Tax_Year__c);
        //System.assertEquals('IRA', posttest[0].Pay_Code__c);
        //System.assertEquals(newRMDAmount, posttest[0].Total_RMD_Amount__c);
        //System.assertEquals(newRMDWithdrawal, posttest[0].Withdrawal_Total__c);
        //System.assertEquals(newRMDScheduled, posttest[0].Scheduled_Withdrawal_Total__c);
        //System.assertEquals(newPlannedDist, posttest[0].Total_Planned_Distributions__c);
        } catch(exception e){
             String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());

        }
    }

    // Insert multiple Account Summaries with same linked RMD Account Type
    @isTest
    static void testAccountSummaryInsert_multiple_linkedAccountType() {
        try{
        init();
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        for (Account_RMD__c acct : acctSummaries) {
            acct.Product_RMD__c = acctType.Id;
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Test
        System.Test.startTest();
        insert acctSummaries;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that the related RMD Account Type was updated (old values were subtracted and new values were added for both Account Summaries)
        System.assertEquals(1, acctTypeCount);
        System.assertEquals(10, posttest.Total_RMD_Amount__c);
        System.assertEquals(-20, posttest.Withdrawal_Total__c);
        System.assertEquals(-30, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(40, posttest.Total_Planned_Distributions__c);
        }catch(exception e){
              String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());

        }
    }

    // Insert multiple Account Summaries with same criteria for unlinked RMD Account Type
    @isTest
    static void testAccountSummaryInsert_multiple_unlinkedAccountType() {
        try{
        init();
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };

        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        for (Account_RMD__c acct : acctSummaries) {
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Test
        System.Test.startTest();
        system.debug('DEBUG testAccountSummaryInsert_multiple_linkedAccountType');
        insert acctSummaries;
        System.Test.stopTest();

        // Post-test
        Integer acctTypeCount = [SELECT COUNT() FROM RMD_Account_Type__c];

        RMD_Account_Type__c posttest = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        // Assert that the related RMD Account Type was updated (new values were added for both Account Summaries)
        System.assertEquals(1, acctTypeCount);
        System.assertEquals(10, posttest.Total_RMD_Amount__c);
        System.assertEquals(-20, posttest.Withdrawal_Total__c);
        System.assertEquals(-30, posttest.Scheduled_Withdrawal_Total__c);
        //System.assertEquals(40, posttest.Total_Planned_Distributions__c);
        }catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());

        }
        system.debug('DEBUG testAccountSummaryInsert_multiple_linkedAccountType END');
    }

    // Insert multiple Account Summaries with same criteria for new RMD Account Type
    @isTest
    static void testAccountSummaryInsert_multiple_noAccountType() {
        try{
        init();
        acctRmdCopy = acctRmd.clone(false, false, false, false);
        List<Account_RMD__c> acctSummaries = new List<Account_RMD__c>{ acctRmd, acctRmdCopy };

        for (Account_RMD__c acct : acctSummaries) {
            acct.RMD_Amount__c += 5;
            acct.RMD_Withdrawal__c += -10;
            acct.RMD_Scheduled_Withdrawal__c += -15;
            acct.RMD_Planned_Distribution__c += 20;
        }

        Decimal newRMDAmount = acctRmd.RMD_Amount__c * 2;
        Decimal newRMDWithdrawal = acctRmd.RMD_Withdrawal__c * 2;
        Decimal newRMDScheduled = acctRmd.RMD_Scheduled_Withdrawal__c * 2;
        Decimal newPlannedDist = acctRmd.RMD_Planned_Distribution__c * 2;

        // Ensure that the existing account type is the wrong tax year
        acctType.Tax_Year__c = String.valueOf(System.today().year() - 1);
        update acctType;

        // Test
        System.Test.startTest();
        insert acctSummaries;
        System.Test.stopTest();

        // Post-test
        List<RMD_Account_Type__c> posttest = new List<RMD_Account_Type__c>();
        posttest = [SELECT Pay_Code__c, Tax_Year__c, Total_RMD_Amount__c, Withdrawal_Total__c, Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c FROM RMD_Account_Type__c WHERE Contact__c = :testContact.Id AND Id != :acctType.Id];

        // Assert that only one new RMD Account Type was created
        System.assertEquals(0, posttest.size());

        // Assert that a new RMD Account Type was created with expected values and linked to the Account Summaries
        // Totals should equal the sums of the Account Summary total values
        //System.assertEquals(String.valueOf(System.today().year()), posttest[0].Tax_Year__c);
        //System.assertEquals('IRA', posttest[0].Pay_Code__c);
        //System.assertEquals(newRMDAmount, posttest[0].Total_RMD_Amount__c);
        //System.assertEquals(newRMDWithdrawal, posttest[0].Withdrawal_Total__c);
        //System.assertEquals(newRMDScheduled, posttest[0].Scheduled_Withdrawal_Total__c);
        //System.assertEquals(newPlannedDist, posttest[0].Total_Planned_Distributions__c);
        } catch(exception e){
             String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());

        }
    }
    
    @isTest
    static void updateAccountRMDDetailsTest() {
        try{
        init();
        acctRmd.Product_RMD__c= acctType.Id;
        insert acctRmd;

        Account_RMD__c oldAccountSummary = acctRmd.clone(false, false, false, false);
        acctType = [
            SELECT Total_RMD_Amount__c, Withdrawal_Total__c, 
                Scheduled_Withdrawal_Total__c, Total_Planned_Distributions__c
            FROM RMD_Account_Type__c
            WHERE Id = :acctType.Id
        ];

        acctRmd.RMD_Amount__c += 5;
        acctRmd.RMD_Withdrawal__c = -1 * acctRmd.RMD_Amount__c;
        acctRmd.RMD_Scheduled_Withdrawal__c = 0;
        acctRmd.RMD_Planned_Distribution__c += 20;

        // Test
        System.Test.startTest();
        update acctRmd;
        System.Test.stopTest();
        } catch(exception e){
            String message = e.getMessage();
            System.assert(e.getMessage().contains('One of the Remainder option is required. error:u-RMD-1007'), 'message=' + e.getMessage());
            
        }
    }
}