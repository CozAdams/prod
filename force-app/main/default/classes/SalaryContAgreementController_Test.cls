@isTest
public class SalaryContAgreementController_Test {
	static Opportunity opportunity;
    static Account account;
    
    static void createTestData() {
        account = new Account(Name = 'test co');
        insert account;
    	opportunity = new Opportunity(AccountId = account.id, name = 'test opp', CloseDate = System.today(),
                                    StageName = 'Posted');
        insert opportunity;
        //AttachPDFController.savePdf(opportunity.Id);
    }
    
    static testMethod void Test_SalaryContributionAgreement() {
        createTestData();
        system.currentPageReference().getParameters().put('id',opportunity.id);
        Test.startTest();
        SalaryContributionAgreementController controller = new SalaryContributionAgreementController();
        Test.stopTest();
    }
}