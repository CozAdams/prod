/*********************************************************************************************
* Created By: Khushboo Modi
* Email: khushboo.modi@revelanttech.com
* Created: June 2017
* Description:  Salary Contribution Agreement
* Changes:
*
*********************************************************************************************/
public class SalaryContributionAgreementController {
    
    public Opportunity opportunity {get;set;}
    /** 
    * @description : Contructor
    */
    public SalaryContributionAgreementController() {
        String id = apexpages.currentpage().getparameters().get('id');
        try {
            List<Opportunity> oppList = [select TDRA_Member_Contribution_Amount__c, TDRA_Member_Contribution__c, Member_Dues__c, Catch_up_Exception__c, Effective_Date__c 
                            from Opportunity where id =: id];    
            if(oppList.size() > 0) {
                opportunity = oppList[0];  
            }
        } catch(Exception e) {
            System.debug('*************exception: ' + e);
        }
    }
}