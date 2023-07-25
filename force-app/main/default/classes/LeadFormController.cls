/*********************************************************************************************
* Created By: Khushboo Modi
* Email: khushboo.modi@revelanttech.com
* Created: 02/15/2017
* Description:  Create new leads and rerender page based on url attributes
* Changes: 09/28/2017 - john.wrightsman@revelanttech.com - added Phone and Employer_Zip required fields
*
*********************************************************************************************/
public class LeadFormController {

    public Lead newLead {get;set;}
    public String type {get;set;}
    public Boolean success {get;set;}
    public String displayMessage {get;set;}

    /**
    * @description : Contructor
    */
    public LeadFormController() {
        try {
            newLead = new Lead();
            type = apexpages.currentPage().getParameters().get('type');
            newLead.country = apexpages.currentPage().getParameters().get('geo');
            success = false;
            displayMessage = '';

            system.debug('*********************Type: ' + type);
            system.debug('*********************Geo: ' + newLead.country);

            if(String.isEmpty(type)) {
                type = 'ind';
                system.debug('*********************Type is empty: ' + type);
            }

            if(String.isEmpty(newLead.country)) {
                newLead.Employer_Country__c = 'us';
            }

            // Set the record type per the type url parameter
            if(type.equals('ind')) {
                newLead.recordTypeId = [select Id from RecordType where sObjectType = 'Lead' and Name = 'Prospect' LIMIT 1].Id;
                if(String.isEmpty(newLead.Company)) {
                    newLead.Company = 'Unassigned';
                }
            } else if(type.equals('org')) {
                newLead.recordTypeId = [select Id from RecordType where sObjectType = 'Lead' and Name = 'Organization' LIMIT 1].Id;
            }
            system.debug('*********************recordtypeId: ' + newLead.recordTypeId);

        } catch(Exception e) {
            system.debug('*********************error: ' + e);
            displayMessage = 'There has been an error submitting the form. Please try again later.';
        }

    }

    /**
    * @description : creates new lead with the recordtypeId based on type attribute
    * @param       : None
    * @return      : void
    */
    public void submitForm() {
        system.debug('*******************function submitForm');
        displayMessage = '';
        if (type.equals('org')) {
            //copy state from employer state
            newLead.State = newLead.Employer_State_Province__c;

            if (String.isEmpty(newLead.FirstName) ||
                String.isEmpty(newLead.LastName) ||
                String.isEmpty(newLead.Phone) ||
                String.isEmpty(newLead.Email) ||
                String.isEmpty(newLead.Company) ||
                String.isEmpty(newLead.Employer_State_Province__c)) {
                displayMessage = 'Please fill out the required fields! required fields are marked by an asterisk(*).';
            }
        } else {
            if (String.isEmpty(newLead.FirstName) ||
                String.isEmpty(newLead.LastName) ||
                String.isEmpty(newLead.Company) ||
                String.isEmpty(newLead.Email) ||
                String.isEmpty(newLead.Phone) ||
                String.isEmpty(newLead.State)) {
                displayMessage = 'Please fill out the required fields! required fields are marked by an asterisk(*).';
            }
        }

        if(String.isEmpty(displayMessage)) {
            try {
                Database.DMLOptions dmlOptions = new Database.DMLOptions();
                dmlOptions.assignmentRuleHeader.useDefaultRule = true;
                newLead.setOptions(dmlOptions);
                insert newLead;
                success = true;
                displayMessage = 'Thank you for your interest. We look forward to speaking with you. Your dedicated Area Director will contact you within the next two business days or you can call us at 866.495.7322.';
            } catch(Exception e) {
                system.debug('*********************error: ' + e);
                displayMessage = 'There has been an error submitting the form. Please try again later.';
            }
        }
    }
}