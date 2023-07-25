@IsTest
public class RetirementCalculatorControllerTest {

    @TestSetup
    public static void setup() {
        Contact c;
        UserRole role = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User portalUserCreator;

        System.runAs(new User(Id = UserInfo.getUserId())) {
             
            portalUserCreator = (User) SObjectFactory.create(User.SObjectType, new Map<Schema.SObjectField, Object>{
                    User.UserRoleId => role.Id, User.ProfileId => profile.Id, User.IsActive => true
            });
           
        }

        profile = [SELECT Id from Profile WHERE Name = 'PFCC Customer CPL - Member'];

        System.runAs(portalUserCreator) {
            Account acc = (Account) SObjectFactory.create(Account.SObjectType, new Map<Schema.SObjectField, Object>{
                Account.Name => 'test', Account.OwnerId => portalUserCreator.Id
             });

            c = (Contact) SObjectFactory.create(Contact.SObjectType, new Map<Schema.SObjectField, Object> {
                Contact.LastName => 'testaTEST', Contact.AccountId => acc.Id, Contact.Annual_Salary__c => 50000,
                Contact.Birthdate => Date.today().addYears(-50), Contact.Contact_Type__c => 'Member',
                    Contact.Social_Security_Number__c => '333-22-1111', Contact.SSN_Verification_Required__c => false,
                Contact.Gender__c => 'M', Contact.Member_Type__c => 'Lay', Contact.Contact_Status__c => 'Active'      
            });

            SObjectFactory.create(User.SObjectType, new Map<Schema.SObjectField, Object>{
                    User.LastName => 'portalTest', User.ProfileId => profile.Id, User.ContactId => c.Id, User.IsActive => true
            });
        }

        SObjectFactory.create(Save_Retirement_Calculations__c.SobjectType, new Map<Schema.SObjectField, Object> {
                Save_Retirement_Calculations__c.Contact__c => c.Id, Save_Retirement_Calculations__c.Name => 'test',
                Save_Retirement_Calculations__c.Monthly_Pension_Credits__c => 1000
        });
    }

  /*
     public static testMethod void testRetrieveUserContact() {
        User u = [SELECT Id, contactid from User where id = '0053o000006ZM7xAAG']; // LastName = 'portalTest' limit 1];
        Contact c = [SELECT Id from Contact where id = '0033o00003rD4YEAA0' ];
      
        System.runAs(u) {
            Test.startTest();
              c = RetirementCalculatorCont.retrieveRunningUserContact();
           
            Test.stopTest();
        }
        
        System.assertEquals(50000, c.Annual_Salary__c, 'Contact annual salary should be 50000');
    }
 */   

    public static testMethod void testGetAvatarUrl() {
        User u = [SELECT Id from User where id = '0053o000006ZM7xAAG' ]; //Bob Test - CPL Member LastName = 'portalTest' limit 1];
        String url;
        System.runAs(u) {
            Test.startTest();
            url = RetirementCalculatorCont.getAvatarURL();
            Test.stopTest();
        }
        System.assertNotEquals(null, url, 'Should retrieve url and not be null');
    }

    public static testMethod void testSaveCalculations() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'testaTEST' limit 1];
        Save_Retirement_Calculations__c newCalc = (Save_Retirement_Calculations__c) SObjectFactory.build(
            Save_Retirement_Calculations__c.SobjectType, new Map<Schema.SObjectField, Object> {
                Save_Retirement_Calculations__c.Contact__c => c.Id, Save_Retirement_Calculations__c.Monthly_Pension_Credits__c => 1000
            }
        );
        Test.startTest();
        RetirementCalculatorCont.saveCalculations(newCalc);
        Test.stopTest();

        List<Save_Retirement_Calculations__c> calcs = [SELECT Id from Save_Retirement_Calculations__c where Contact__c = :c.Id];
        System.assertEquals(2, calcs.size(), 'There should now be 2 calculations on this Contact');
    }

    public static testMethod void testSaveCalculationsDuplicate() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'testaTEST' limit 1];
        Save_Retirement_Calculations__c newCalc = (Save_Retirement_Calculations__c) SObjectFactory.build(
                Save_Retirement_Calculations__c.SobjectType, new Map<Schema.SObjectField, Object> {
                        Save_Retirement_Calculations__c.Contact__c => c.Id, Save_Retirement_Calculations__c.Monthly_Pension_Credits__c => 1000,
                        Save_Retirement_Calculations__c.Name => 'test'
                }
        );
        Test.startTest();
        RetirementCalculatorCont.saveCalculations(newCalc);
        Test.stopTest();

        List<Save_Retirement_Calculations__c> calcs = [SELECT Id from Save_Retirement_Calculations__c where Contact__c = :c.Id];
        System.assertEquals(1, calcs.size(), 'There should now be 1 calculation on this Contact');
    }

    public static testMethod void testDeleteCalculations() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'testaTEST' limit 1];
        Save_Retirement_Calculations__c calc = [SELECT Id from Save_Retirement_Calculations__c limit 1];
        Test.startTest();
        RetirementCalculatorCont.deleteCalculations(calc.Id);
        Test.stopTest();

        List<Save_Retirement_Calculations__c> calcs = [SELECT Id from Save_Retirement_Calculations__c where Contact__c = :c.Id];
        System.assertEquals(0, calcs.size(), 'There should now be 0 calculations on this Contact');
    }

    public static testMethod  void testLoadCalculations() {
        User u = [SELECT Id, IsActive, Profile.Name from User where LastName = 'portalTest' limit 1];
        List<Save_Retirement_Calculations__c> calcs;
        System.runAs(u) {
            Test.startTest();
            calcs = RetirementCalculatorCont.loadCalculations();
            Test.stopTest();
        }

        System.assertEquals(1, calcs.size(), 'Should return only 1 calculation');
        System.assertEquals(1000, calcs.get(0).Monthly_Pension_Credits__c, 'Should return 1000 monthly pension credits for that calculation');
    }
}