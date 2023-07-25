/*********************************************************************************************
*
*   Class Name:     AccountOwnerBatch_Test
*   Created By:     Khushboo Modi (Revelant Technologies)
*   Email:          khushboo.modi@revelanttech.com
*   Created On:     12/06/2016
*   Purpose:        Test class for AccountOwnerBatch 
**********************************************************************************************/

@isTest
public class AccountOwnerBatch_Test {
    private static testMethod void territoryAssignmentToAccountsByTrigger() {

        Account objAccount = new Account( Name = 'Test Acc - 01', ShippingState = 'USA');
        insert objAccount;
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        
        System.RunAs(usr)
        {
            Test.startTest();
            insertTestTerritory(objAccount.Id);
            AccountOwnerBatch sh1 = new AccountOwnerBatch();      
            String sch = '0 0 23 * * ?';
            system.schedule('Test check', sch, sh1);
            Test.stopTest();
        }
    }

    //@future
    private static void insertTestTerritory(Id AccId)
    {
        List<Territory2Type> terriType   = [SELECT id, DeveloperName from Territory2Type LIMIT 1];
        List<Profile> adminProfile = [select id, name from Profile where  name = 'System Administrator'];

        Territory2Model terrModel = new Territory2Model();
        terrModel .DeveloperName='ModelName'; // required field
        terrModel.Name = 'Name'; // required field
        insert terrModel ;

        Territory2 objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=terriType[0].Id);
        insert objTerr;

        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = AccId, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;

        Profile p = [SELECT id, Name FROM Profile where name = 'System Administrator' ].get(0);  
        User u = new User(firstname= 'Test',
                  lastname='XXXX',
                  Alias='Test',
                  email = 'test1234@test.com',
                  username= 'test1234xxx@test.com', 
                  profileId= p.id, 
                  emailencodingkey='UTF-8',
                  languagelocalekey='en_US',
                  localesidkey='en_US',
                  timezonesidkey='America/Los_Angeles');
        insert u;

        User u2 = new User(firstname= 'Test',
                  lastname='XXXX',
                  Alias='Test',
                  email = 'test1234122@test.com',
                  username= 'test1234xxx123@test.com', 
                  profileId= p.id, 
                  emailencodingkey='UTF-8',
                  languagelocalekey='en_US',
                  localesidkey='en_US',
                  timezonesidkey='America/Los_Angeles');
        insert u2;


        UserTerritory2Association objUserTerritory2Association = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Account Executive');
        insert objUserTerritory2Association;

        UserTerritory2Association objUserTerritory2Association2 = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u2.Id, RoleInTerritory2='Account Executive');
        insert objUserTerritory2Association2;  

    }
}