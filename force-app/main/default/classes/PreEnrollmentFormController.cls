/*********************************************************************************************
* Created By: Khushboo Modi
* Email: khushboo.modi@revelanttech.com
* Created: July 2017
* Description: Collect pre-enrollment information from the new lead
* Changes: 08/21/2017 - john.wrightsman@revelanttech.com - Added ability to save conference name from url; Default Lead.LeadSource to Quiz
*
*********************************************************************************************/
public class PreEnrollmentFormController {
    
    public Lead enrollmentForm {get;set;}
    public String selectedPosition {get;set;}
    public String otherPosition {get;set;}
    public String company {get;set;}
    public String errorMsg {get;set;}
    public Boolean successForm {get;set;}
    public String conferenceName {get;set;}
    
    /** 
    * @description : picklist values for positions
    * @param       : None
    * @return      : List<SelectOption>
    */
    public List<SelectOption> getPositions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('',''));
        options.add(new SelectOption('Clergy','Clergy'));
        options.add(new SelectOption('Church Staff','Church Staff'));
        options.add(new SelectOption('University/College','University/College'));
        options.add(new SelectOption('Benevolent Care Facility','Benevolent Care Facility'));
        options.add(new SelectOption('Other','Other'));
        return options;
    }
    
    /** 
    * @description : Contructor
    */
    public PreEnrollmentFormController() {
        enrollmentForm = new Lead();
        selectedPosition  = '';
        otherPosition = '';
        company = '';
        errorMsg = '';
        successForm = false;
        conferenceName = ApexPages.currentPage().getParameters().get('conference');
    }
    
    /** 
    * @description : validates required fields and create new lead with a campaign
    * @param       : None
    * @return      : void
    */
    public void submitForm() {
        errorMsg = '';
        if(String.isEmpty(enrollmentForm.FirstName)) {
            errorMsg += 'First Name is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.LastName)) {
            errorMsg += 'Last Name is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Street)) {
            errorMsg += 'Street is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.City)) {
            errorMsg += 'City is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.State)) {
            errorMsg += 'State is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.PostalCode)) {
            errorMsg += 'Zip is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Email)) {
            errorMsg += 'Email is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.MobilePhone) && String.isEmpty(enrollmentForm.Work_Phone__c)) {
            errorMsg += 'Cell or Work phone is required! <br/>';
        }
        if(String.isEmpty(company)) {
            errorMsg += 'Company is required! <br/>';
        }
        if(String.isEmpty(selectedPosition)) {
            errorMsg += 'Position is required! <br/>';
        } else if(selectedPosition == 'Other' && String.isEmpty(otherPosition)){
            errorMsg += 'Other Position is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Started_Planning__c)) {
            errorMsg += 'How have you started planning for retirement? is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.On_Track_for_Retirement__c)) {
            errorMsg += 'Are you on track to save 75% to 85% of your current income for retirement? is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Paying_Off_Debt__c)) {
            errorMsg += 'Are you working on paying off all debt? is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Savings_for_Unexpected_Expenses__c)) {
            errorMsg += 'Do you have a savings account for unexpected expenses such as car repairs? is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Considered_Consolidation__c)) {
            errorMsg += 'Have you considered consolidating or rolling over your retirement accounts into one account to reduce fees and streamline your investments? is required! <br/>';
        }
        if(String.isEmpty(enrollmentForm.Interests__c)) {
            errorMsg += 'Im interested in having an Area Director contact me in regard to the following: is required! <br/>';
        }
        if(errorMsg == ''){
            enrollmentForm.Company = company;
            enrollmentForm.LeadSource = 'Quiz';
            enrollmentForm.Conference_Name__c = conferenceName;
            if(selectedPosition == 'Other') {
                enrollmentForm.Title = otherPosition;
            } else {
                enrollmentForm.Title = selectedPosition;
            }
            try {
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule= true;
                enrollmentForm.setOptions(dmo);
                insert enrollmentForm;
                Id campaignId = [select Id from Campaign where Name = 'GA 2017 Questionnaire'].Id;
                CampaignMember mem = new CampaignMember (campaignId = campaignId, leadId = enrollmentForm.id, Status = 'Sent');
                insert mem;
                successForm = true;
            } catch(Exception e) {
                System.debug('************************error: ' + e);
            }
        }
    }
}