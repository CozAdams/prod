import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent, FlowNavigationPauseEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getMaxContributionLimits from '@salesforce/apex/AccountSummaryService.getMaxContributionLimits';
import getTotalContributionsSoFar from '@salesforce/apex/AccountSummaryService.getTotalContributionsSoFar';

import USER_ID from '@salesforce/user/Id';
import ACCT_TYPE_TDRA from '@salesforce/label/c.TDRA_ACC_TYPE';

export default class EnrollmentMemberDuesTDRA extends LightningElement {
    // Enrollment form object for input and output
    @api enrollmentForm;
    enrollmentFormClone;
    contactId;
    currentYear;

    // UI values
    employerContributionTypes = [];
    employeeContributionTypes = [];

    employerAmount;
    employerPercent;
    memberAmount;
    memberPercent;

    rothEmployerAmount;
    rothEmployerPercent;
    rothMemberAmount;
    rothMemberPercent;

    employerContributionTypeOptions;
    employeeContributionTypeOptions;
    maxAmount;

    showEmployerSection;
    showMemberSection;
    showRothEmployerSection;
    showRothMemberSection;

    // Labels and text
    MSG_CHECK_ONE = 'Check all that apply';
    CHECK_LABEL_EMPLOYER = 'I elect to make pre-tax employer contributions into a TDRA 403(b)';
    CHECK_LABEL_MEMBER = 'I elect to make pre-tax employee contributions into a TDRA 403(b)';

    //Roth 403(b) chagnes
    CHECK_LABEL_ROTH_MEMBER = 'I elect to make Roth after-tax employee contributions into a Roth 403(b)';
    CHECK_LABEL_ROTH_EMPLOYER = 'I elect to make Roth after-tax employer contributions into a Roth 403(b)';

    //403(b) changes ends

    MSG_EMPLOYER_SECTION = 'Please complete the below section if you elected employer contributions';
    MSG_MEMBER_SECTION = 'Please complete the below section if you elected employee contributions';
    MSG_SECTION_EMPLOYER_EQUAL_TO = 'Employer Contributions equal to:';
    MSG_SECTION_COMPLETE = 'To voluntarily elect to make contributions to the TDRA through your employer, complete the following:';
    LABEL_AMOUNT = 'Amount[$]';
    LABEL_PERCENT = 'Percent[%]';

    MSG_PAY_PERIOD = ' (may be any whole dollar amount or percentage but cannot be both) as a contribution to my TDRA 403(b)/Roth 403(b). ' +
        'I understand that my total contributions cannot exceed the Internal Revenue Service limits for the taxable year. ' +
        '(See www.pensionfund.org for information on these limits) I understand that my election applies only with respect to ' +
        'salary paid or made available to me after I become a member in the TDRA 403(b)/Roth 403(b), and is legally binding and irrevocable with ' +
        'respect to amounts paid or made available to me while it remains in effect.';

    MSG_MEMBER_CONFIRMATION = 'I hereby direct my employer to contribute the following on a pre-tax basis:';
    ERROR_RANGE_MIN = 'Amount must be more than than $0.';
    ERROR_RANGE_MAX_AMT = 'Contribution limit for this year is $PLACEHOLDER, please correct the amount.';
    ERROR_RANGE_MAX_PERCENT = 'Amount cannot be more than 100%.';
    ERROR_REQUIRED_AT_LEAST_ONE = 'Please enter either an Amount or Percent.';
    ERROR_AMOUNT_ONLY_ONE = 'Only one value can be entered for Amount or Percent.';
    
    // Get user contact ID and age for amount validation
    @wire(getRecord, { recordId: USER_ID, fields: [ 'User.ContactId', 'User.Contact.Age__c' ] })
    userRecord({ error, data }) {
        if (data) {
            // Get maximum contribution limit for amount validation
            try {
                const memberAge = data.fields.Contact.value.fields.Age__c.value;
                this.contactId = data.fields.ContactId.value;
                this.setMaxContributionLimits(memberAge);   
            }
            catch(error) {
                const title = 'An error occurred when retrieving user information.';
                this.showErrorMessage(title, error);
            }
        }
        else if (error) {
            const title = 'An error occurred when retrieving user information.';
            this.showErrorMessage(title, error);
        }
    }

    // For retaining data input during navigation, set field values based on enrollment form values after data receipt
    connectedCallback() {

        try{
            // Set checkbox options
            this.employerContributionTypeOptions = [
                { label: this.CHECK_LABEL_EMPLOYER, value: 'Employer' },
               // { label: this.CHECK_LABEL_ROTH_EMPLOYER, value: 'Roth Employer'},


            ];

            this.employeeContributionTypeOptions = [
               
                { label: this.CHECK_LABEL_MEMBER, value: 'Member' },
                { label: this.CHECK_LABEL_ROTH_MEMBER, value: 'Roth Member'},

            ];
            // Set values on form for data already entered
            this.enrollmentFormClone = {...this.enrollmentForm};
            this.employerAmount = this.enrollmentFormClone.Employer_Contributions_to_TDRA__c;
            this.employerPercent = this.enrollmentFormClone.TDRA_Employer_Contribution__c;
            this.memberAmount = this.enrollmentFormClone.Member_Contributions_to_TDRA__c;
            this.memberPercent = this.enrollmentFormClone.TDRA_Member_Contribution__c;

            this.rothEmployerAmount = this.enrollmentFormClone.Roth_Employer_Contribution_Amount__c;
            this.rothEmployerPercent = this.enrollmentFormClone.Roth_Employer_Contribution_Percent__c;
            this.rothMemberAmount = this.enrollmentFormClone.Roth_Member_Contribution_Amount__c;
            this.rothMemberPercent = this.enrollmentFormClone.Roth_Member_Contribution_Percent__c;

            //ask about the need of these fields???
          /*  if (this.enrollmentFormClone.elect_both_employer_and_employee_contrib__c) {
                this.contributionTypes = [ 'Employer', 'Member' ];

            }
            else if (this.enrollmentFormClone.do_not_wish_to_make_any_additional_contr__c) {
                this.contributionTypes = [ 'Employer' ];
            }
            else if (this.enrollmentFormClone.My_employer_will_reduce_my_salary_in_acc__c) {
                this.contributionTypes = [ 'Member' ];
            }*/

            if(this.employerAmount || this.employerPercent){
                this.showEmployerSection = true;
                this.employerContributionTypes.push('Employer');

            }
            if(this.memberAmount || this.memberPercent){
                this.showMemberSection = true;
                this.employeeContributionTypes.push('Member');

            }
            if(this.rothEmployerAmount || this.rothEmployerPercent ){
                this.showRothEmployerSection = true;
                this.employerContributionTypes.push('Roth Employer');

            }
            if(this.rothMemberAmount || this.rothMemberPercent){
                this.showRothMemberSection = true;
                this.employeeContributionTypes.push('Roth Member');

            }

            // Show sections for data already entered

        }catch(e){
            console.log("++error" , e);
            
        }
    }

    // Set maximum member amount based on contribution limits
    setMaxContributionLimits(memberAge) {
        this.currentYear = new Date().getFullYear();
        getMaxContributionLimits({ accountType: ACCT_TYPE_TDRA, years: [ this.currentYear] })
            .then(data => {
                if (data) {
                    // Set max value for member amount
                    const limit = data[0];
                    if (memberAge >= limit.Retirement_Age__c) {
                        this.maxAmount = limit.Amount_at_Retirement_Age__c;
                    }
                    else {
                        this.maxAmount = limit.Amount_Before_Retirement_Age__c;
                    }
                    
                    // Update member amount validation message
                    this.ERROR_RANGE_MAX_AMT = this.ERROR_RANGE_MAX_AMT.replace('PLACEHOLDER', this.maxAmount);
                }
                else {
                    const title = 'An error occurred when retrieving contribution limits.';
                    this.showErrorMessage(title, error);
                }
            })
            .catch(error => {
                const title = 'An error occurred when retrieving contribution limits.';
                this.showErrorMessage(title, error);
            })
    }

    // On input field change, sync input to associated variable
    handleInputChange(event) {
        // Format value for percentage fields
        let formattedPercent = +parseFloat(event.target.value).toFixed(2);
        event.target.value = formattedPercent;

        const inputFields = this.template.querySelectorAll('.form-validate');
        inputFields.forEach(field => {
            field.setCustomValidity('');
            field.reportValidity();
        });

        // Assign input value to variable
        this[event.target.name] = event.target.value;
    }

    // Toggle contribution type and clear dependencies
    toggleContributionType(event) {
         try{


            const newTypes = event.detail.value;
            let oldTypes;
        // console.log("toggleContributionType event", target);

            console.log("toggleContributionType event", JSON.parse(JSON.stringify(event.detail)));

            switch(event.target.name){

                
                case "employerContributionTypes" : 
                    oldTypes = this.employerContributionTypes;
                    this.employerContributionTypes = newTypes;
                    this.showEmployerSection = newTypes.includes('Employer');
                    this.showRothEmployerSection = newTypes.includes('Roth Employer');

                    if (!newTypes.includes('Employer') && oldTypes.includes('Employer')) {
                        this.employerAmount = null;
                        this.employerPercent = null;
                    };
                    if (!newTypes.includes('Roth Employer') && oldTypes.includes('Roth Employer')) {
                        this.rothEmployerAmount = null;
                        this.rothEmployerPercent = null;
                    };
                break;

                case "employeeContributionTypes" :
                    oldTypes = this.employeeContributionTypes;
                    this.employeeContributionTypes = newTypes;
                    this.showMemberSection = newTypes.includes('Member');
                    this.showRothMemberSection = newTypes.includes('Roth Member');

                    if (!newTypes.includes('Member') && oldTypes.includes('Member')) {
                        this.memberAmount = null;
                        this.memberPercent = null;
                    }
            
                    if (!newTypes.includes('Roth Member') && oldTypes.includes('Roth Member')) {
                        this.rothMemberAmount = null;
                        this.rothMemberPercent = null;
                    }
                break;
            }



         }catch(e){
            console.error(e);
        }
       

    }

    // Save the input to the form and navigate within the flow
    navigate(event) {
       try{
        const button = event.target.dataset.name;

        // Update enrollment form clone with input
        this.enrollmentFormClone.Employer_Contributions_to_TDRA__c = this.employerAmount;
        this.enrollmentFormClone.TDRA_Employer_Contribution__c = this.employerPercent;
        this.enrollmentFormClone.Member_Contributions_to_TDRA__c = this.memberAmount;
        this.enrollmentFormClone.TDRA_Member_Contribution__c = this.memberPercent;
        this.enrollmentFormClone.Roth_Member_Contribution_Amount__c = this.rothMemberAmount;
        this.enrollmentFormClone.Roth_Member_Contribution_Percent__c = this.rothMemberPercent;
        this.enrollmentFormClone.Roth_Employer_Contribution_Amount__c = this.rothEmployerAmount;
        this.enrollmentFormClone.Roth_Employer_Contribution_Percent__c	 = this.rothEmployerPercent;

        //ask about the need of these fields???
        const isEmployer = this.employerContributionTypes.includes('Employer') ||  this.employerContributionTypes.includes('Roth Employer')  ;
        const isMember = this.employeeContributionTypes.includes('Member') ||  this.employeeContributionTypes.includes('Roth Member') ;
        this.enrollmentFormClone.My_employer_will_reduce_my_salary_in_acc__c = !isEmployer && isMember;
        this.enrollmentFormClone.do_not_wish_to_make_any_additional_contr__c = isEmployer && !isMember;
        this.enrollmentFormClone.elect_both_employer_and_employee_contrib__c = isEmployer && isMember;

        console.log("++enrollment form being submitted is " ,  this.enrollmentFormClone)
        // Proceed to next flow step
        this.dispatchEvent(new FlowAttributeChangeEvent('enrollmentForm', this.enrollmentFormClone));

        // Go back
        if (button == 'btnBack') {
            this.dispatchEvent(new FlowNavigationBackEvent());
        }
        // Go forward
        else if (button == 'btnNext') {
            this.validate();
        }


    }catch(e){

        console.log("+++navigation error", e);
       } 
    }

    // Validate all input fields
    validate() {
        try{
            let isValid = true;
            const inputFields = this.template.querySelectorAll('.form-validate');
            const employerAmountField = this.template.querySelector('[data-id="employerAmount"]');
            const employerPercentField = this.template.querySelector('[data-id="employerPercent"]');
            const memberAmountField = this.template.querySelector('[data-id="memberAmount"]');
            const memberPercentField = this.template.querySelector('[data-id="memberPercent"]');
            const employerCheckboxGroup = this.template.querySelector('[data-id="employerCheckboxGroup"]');
            const employeeCheckboxGroup = this.template.querySelector('[data-id="employeeCheckboxGroup"]');
    
    
            const rothEmployerAmountField = this.template.querySelector('[data-id="rothEmployerAmount"]');
            const rothEmployerPercentField = this.template.querySelector('[data-id="rothEmployerPercent"]');
            const rothMemberAmountField = this.template.querySelector('[data-id="rothMemberAmount"]');
            const rothMemberPercentField = this.template.querySelector('[data-id="rothMemberPercent"]');
    
            // Clear existing error messages and check standard input field validation first
            inputFields.forEach(field => {
                field.setCustomValidity('');
                if (!field.checkValidity()) {
                    isValid = false;
                }
            });
            
            // If standard field validation passes, check logic-based required fields
            if (isValid) {
                    if(this.employerContributionTypes.length == 0 && this.employeeContributionTypes.length == 0 ){
        
                        employerCheckboxGroup.setCustomValidity('Please Select At Least One Enrollment');
                        employeeCheckboxGroup.setCustomValidity('Please Select At Least One Enrollment');
                        isValid = false;
                    }
                    
                    // Employer selection requires a dollar OR percent amount
                    if (this.employerContributionTypes.includes('Employer') ) {
                        let validAmount = this.employerAmount && this.employerAmount > 0;
                        let validPercent = this.employerPercent && this.employerPercent > 0;
        
                        //Non-Roth
                        if (!validAmount && !validPercent) {
                            isValid = false;
                            employerAmountField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
                            employerPercentField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);

                        }
                        else if (validAmount && validPercent) {
                            isValid = false;
                            employerAmountField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
                            employerPercentField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);

    
                        }
                    }
        
                    if ( this.employerContributionTypes.includes('Roth Employer') ) {
        
                        let rothValidAmount = this.rothEmployerAmount && this.rothEmployerAmount > 0;
                        let rothValidPercent = this.rothEmployerPercent && this.rothEmployerPercent > 0;
                        //Roth
                        if (!rothValidAmount && !rothValidPercent) {
                            isValid = false;
                            rothEmployerAmountField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
                            rothEmployerPercentField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
    
                        }
                        else if (rothValidAmount && rothValidPercent) {
                            isValid = false;
                            rothEmployerAmountField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
                            rothEmployerPercentField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);

                        }
                    }
        
                    // Member selection requires dollar OR percent amount
                    if (this.employeeContributionTypes.includes('Member')) {
                        let validAmount = this.memberAmount && this.memberAmount > 0;
                        let validPercent = this.memberPercent && this.memberPercent > 0;
        
                        //Non-Roth
        
                        if (!validAmount && !validPercent) {
                            isValid = false;
                            memberAmountField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
                            memberPercentField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
    
                        }
                        else if (validAmount && validPercent) {
                            isValid = false;
                            memberAmountField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
                            memberPercentField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
    
                        }
                    }
        
                    if (this.employeeContributionTypes.includes('Roth Member') ) {
                        let rothValidAmount = this.rothMemberAmount && this.rothMemberAmount > 0;
                        let rothValidPercent = this.rothMemberPercent && this.rothMemberPercent > 0;
                        //Roth
                        if (!rothValidAmount && !rothValidPercent) {
                            isValid = false;
                            rothMemberAmountField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
                            rothMemberPercentField.setCustomValidity(this.ERROR_REQUIRED_AT_LEAST_ONE);
    
                        }
                        else if (rothValidAmount && rothValidPercent) {
                            isValid = false;
                            rothMemberAmountField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
                            rothMemberPercentField.setCustomValidity(this.ERROR_AMOUNT_ONLY_ONE);
    
                        }
        
                    }
    
                    console.log('+++do while debug');
    
                if (isValid) {
                    // Validate member amount with previous contributions
                    this.validateAmount();
                }
                else {
                    this.reportAndNavigate(isValid);
                }
            }else {
                this.reportAndNavigate(isValid);
            }

        }catch(e){

            console.log('++validate error' , )
        }
     

    }

    // Verify amount with previous contributions does not exceed yearly contribution limits
    validateAmount() {
        const memberAmountField = this.template.querySelector('[data-id="memberAmount"]');
        const rothMemberAmountField = this.template.querySelector('[data-id="rothMemberAmount"]');

        let isValid = true;
        
        getTotalContributionsSoFar({ 
            contactId: this.contactId, 
            accountSummaryType: ACCT_TYPE_TDRA, 
            yearParam: this.currentYear 
        }) 
        .then(previousAmount => {
            // If previous contributions already exceed limits
            const memberAmount = parseInt(this.memberAmount);
            if (previousAmount > memberAmount) {
                isValid = false;
                memberAmountField.setCustomValidity('No further contributions are allowed since you have met your yearly limit.');
            }
            // If previous contributions with entered amount exceed limits
            else if (memberAmount + previousAmount > this.maxAmount) {
                isValid = false;
                let availableAmount = this.maxAmount - previousAmount;
                memberAmountField.setCustomValidity('Your contribution cannot be greater than $' + availableAmount + '.');

            }else if(this.employeeContributionTypes.includes('Roth Member') && this.employeeContributionTypes.includes('Member')){
                let rothMemberAmount = this.rothMemberAmount ? parseFloat(this.rothMemberAmount) : 0;
                let memberAmount = this.memberAmount ? parseFloat(this.memberAmount) : 0;
                let bothAmountValid = parseFloat(( rothMemberAmount + memberAmount).toFixed(2)) <= this.maxAmount ;
    
                console.log('calc is ', rothMemberAmount ,' + ', memberAmount , ' =?  ', parseFloat(rothMemberAmount  + memberAmount).toFixed(2)   , '  >> max ammount is ', this.maxAmount);
                //Roth
                if (!bothAmountValid ) {
                    isValid = false;
                    rothMemberAmountField.setCustomValidity(`Roth and Non-Roth Amount must not exceed $${this.maxAmount}`);
                    memberAmountField.setCustomValidity(`Roth and Non-Roth Amount must not exceed $${this.maxAmount}`);
                }
            }



            this.reportAndNavigate(isValid);
        })
        .catch(error => {
            const title = 'An error occurred when retrieving previous contributions.';
            this.showErrorMessage(title, error);
        })
    }

    // Show error messages and navigate forward if valid
    reportAndNavigate(isValid) {
        const inputFields = this.template.querySelectorAll('.form-validate');
        inputFields.forEach(field => {
            field.reportValidity();
        });
        if (isValid) {
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }

    // Show error toast message for general errors
    showErrorMessage(title, error) {
        // Set error message
        let message = 'Unknown error';
        if (error) {
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            }
            else if (error.message) {
                message = error.message;
            }
            else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        }

        // Show toast
        this.dispatchEvent(new ShowToastEvent({
            title, 
            message, 
            variant: 'error'
        }));
    }
}