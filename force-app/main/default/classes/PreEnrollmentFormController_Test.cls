@isTest
public class PreEnrollmentFormController_Test {
	static testMethod void Test_submitFormContact() {
        Test.startTest();
        PreEnrollmentFormController controller = new PreEnrollmentFormController();
        List<SelectOption> items = new List<SelectOption>();
        items = controller.getPositions();
        controller.submitForm();
        Test.stopTest();
    }
    
    static testMethod void Test_submitFormContactSuccess() {
        Test.startTest();
        PreEnrollmentFormController controller = new PreEnrollmentFormController();
        List<SelectOption> items = new List<SelectOption>();
        items = controller.getPositions();
        controller.enrollmentForm.FirstName = 'Test';
        controller.enrollmentForm.LastName = 'Test';
        controller.enrollmentForm.Street = 'Test';
        controller.enrollmentForm.City = 'Test';
        controller.enrollmentForm.State = 'Test';
        controller.enrollmentForm.PostalCode = '12456';
        controller.enrollmentForm.Email = 'abc@xyz.com';
        controller.enrollmentForm.MobilePhone = '1234567894';
        controller.company = 'Test';
        controller.selectedPosition = 'Clergy';
        controller.enrollmentForm.Started_Planning__c = 'IRA';
        controller.enrollmentForm.On_Track_for_Retirement__c = 'Yes';
        controller.enrollmentForm.Paying_Off_Debt__c = 'Yes';
        controller.enrollmentForm.Savings_for_Unexpected_Expenses__c = 'Yes';
        controller.enrollmentForm.Considered_Consolidation__c = 'Yes';
        controller.enrollmentForm.Interests__c = 'US Pension';
        controller.submitForm();
        Test.stopTest();
    }
}