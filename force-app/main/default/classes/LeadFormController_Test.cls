/*********************************************************************************************
* Created By: Khushboo Modi
* Email: khushboo.modi@revelanttech.com
* Created: February 2017
* Description:  Test class for LeadFormController
* Changes: 09/28/2017 - john.wrightsman@revelanttech.com - added Phone and Employer_Zip required fields
*
*********************************************************************************************/
@isTest
public class LeadFormController_Test {

    static testMethod void test_LeadFormInd() {
        PageReference pageRef = Page.LeadForm;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        LeadFormController controller = new LeadFormController();
        controller.submitForm();
        controller.newLead.FirstName ='Test';
        controller.newLead.LastName = 'Hello';
        controller.newLead.Email = 'abc@xyz.com';
        controller.newLead.Phone = '588-2300';
        controller.newLead.Company = 'Test Company';
        controller.newLead.State = 'IN';
        controller.submitForm();
        Test.stopTest();
    }

    static testMethod void test_LeadFormOrg() {
        PageReference pageRef = Page.LeadForm;
        Test.setCurrentPage(pageRef);
        system.currentpageReference().getParameters().put('type','org');
        Test.startTest();
        LeadFormController controller = new LeadFormController();
        controller.newLead.FirstName ='Test';
        controller.newLead.LastName = 'Hello';
        controller.newLead.Email = 'abc@xyz.com';
        controller.newLead.Phone = '588-2300';
        controller.submitForm();
        controller.newLead.Company = 'Test co';
        controller.newLead.Employer_Zip__c = '99999';
        controller.newLead.Employer_State_Province__c = 'IN';
        controller.submitForm();
        Test.stopTest();
    }

}