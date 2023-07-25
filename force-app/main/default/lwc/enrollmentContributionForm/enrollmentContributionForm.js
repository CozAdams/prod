import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getContributionLimit, getPreviousContributionTotal } from 'c/contributionLimitsUtils';
// import getMaxContributionLimits from '@salesforce/apex/AccountSummaryService.getMaxContributionLimits';

import USER_ID from '@salesforce/user/Id';
import ACCT_TYPE_IRA from '@salesforce/label/c.IRA_ACC_TYPE';
import TAX_CUTOFF_MONTH from '@salesforce/label/c.taxDateMonth';
import TAX_CUTOFF_DAY from '@salesforce/label/c.taxDateDay';

export default class EnrollmentContributionForm extends LightningElement {
    @api enrollmentForm;
    enrollmentFormClone;
    contactId;
    memberAge;
    previousContributionTotal;

    // UI
    isLoaded;
    amountLimit;
    maxAmount;
    singleDateMin;
    recurringDateMin;
    taxYearOptions;
    recurringDayOptions;

    // Input
    isSingle;
    isRecurring;
    singleAmount;
    taxYear;
    singleDate;
    recurringAmount;
    recurringDay;
    recurringDate;

    ERROR_CHECKBOX_REQUIRED = 'A one-time or recurring debit must be authorized to continue.';
    ERROR_SINGLE_AMT_MIN = 'Amount must be at least $100.';
    ERROR_SINGLE_AMT_MAX = 'Contribution limit for this year is $PLACEHOLDER, please correct the amount.';
    ERROR_AMT_PREVIOUS = 'Your contribution cannot be greater than $PLACEHOLDER.'
    ERROR_SINGLE_AMT_REQ = 'A single amount is required when Single Sum Contribution is selected';
    ERROR_RECUR_AMT_MIN = 'Amount must be greater than $0.';
    ERROR_RECUR_AMT_REQ = 'A recurring amount is required when Recurring Contributions is selected.';
    ERROR_RECUR_DAY = 'The date must match the recurring date you chose above. Please select the PLACEHOLDER of the month in which you would like the recurring debit to begin.';

    // Get user contact ID and age for amount validation
    @wire(getRecord, { recordId: USER_ID, fields: [ 'User.ContactId', 'User.Contact.Age__c' ] })
    userRecord({ error, data }) {
        if (data) {
            // Get maximum contribution limit for amount validation
            try {
                this.memberAge = data.fields.Contact.value.fields.Age__c.value;
                this.contactId = data.fields.ContactId.value;
                this.loadForm();
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

    // Set form options and existing enrollment form data
    loadForm() {
        this.setDefaultFormValues();

        // Set values on form for data already entered
        this.enrollmentFormClone = {...this.enrollmentForm};

        // Single contribution values
        if (this.enrollmentFormClone.Single_Sum_Contribution__c && this.enrollmentFormClone.Single_Sum_Contribution__c > 0) {
            this.isSingle = true;
            this.singleAmount = this.enrollmentFormClone.Single_Sum_Contribution__c;
            this.taxYear = this.enrollmentFormClone.Single_Sum_Contribution_Year__c.toString();
            this.singleDate = this.enrollmentFormClone.Single_Sum_Contribution_Start_Date__c.split('T')[0];
        }

        // Recurring contribution values
        if (this.enrollmentFormClone.Recurring_Contribution_Amount__c && this.enrollmentFormClone.Recurring_Contribution_Amount__c > 0) {
            this.isRecurring = true;
            this.recurringAmount = this.enrollmentFormClone.Recurring_Contribution_Amount__c;
            this.recurringDay = this.enrollmentFormClone.Recurring_Contributions_Date__c;
            this.recurringDate = this.enrollmentFormClone.Recurring_Contributions_Start_Date__c.split('T')[0];
        } 
    }

    // Set form default values for options and validation
    setDefaultFormValues() {
        // Date minimums
        const todaysDate = new Date();
        let tomorrow = todaysDate;
        tomorrow.setDate(todaysDate.getDate() + 1);
        this.singleDateMin = tomorrow.toLocaleDateString();

        let firstOfNextMonth = todaysDate;
        firstOfNextMonth.setMonth(todaysDate.getMonth() + 1);
        firstOfNextMonth.setDate(1);
        this.recurringDateMin = firstOfNextMonth.toLocaleDateString();

        // Tax year picklist options
        let taxYears = [];
        let currentYear = todaysDate.getFullYear();
        let cutoffDate = new Date(TAX_CUTOFF_MONTH + ',' + TAX_CUTOFF_DAY + ',' + currentYear);
        currentYear = currentYear.toString();
        
		if (todaysDate <= cutoffDate) {
            let lastYear = currentYear - 1;
            lastYear = lastYear.toString();
            taxYears.push({ label: lastYear, value: lastYear });
		}

		taxYears.push({ label: currentYear, value: currentYear });
        this.taxYearOptions = taxYears;
        this.taxYear = currentYear;
        this.handleTaxYearChange(null);
        
        // Recurring day picklist options
        this.recurringDayOptions = [
            { label: '1st of month', value: '1st' }, 
            { label: '15th of month', value: '15th' }
        ];
    }

    // Update values when input is changed
    handleInputChange(event) {
        this[event.target.dataset.fieldName] = event.target.value;
    }

    // Update values when checkbox is changed
    handleCheckboxChange(event) {
        const fieldName = event.target.dataset.fieldName;
        const checked = event.target.checked;
        this[fieldName] = checked;

        // Clear dependent values on uncheck
        if (!checked) {
            if (fieldName == 'isSingle') {
                this.singleAmount = null;
                this.taxYear = null;
                this.singleDate = null;
            }
            else {
                this.recurringAmount = null;
                this.recurringDay = null;
                this.recurringDate = null;
            }
        }
    }

    // Round input to format for currency
    handleCurrencyInputChange(event) {
        // Round input
        const roundedInput = +parseFloat(event.target.value).toFixed(2);
        event.target.value = roundedInput;
        this.handleInputChange(event);

        // Revalidate
        const fieldName = event.target.dataset.fieldName;
        const field = this.template.querySelector(`[data-field-name="${fieldName}"]`);
        field.setCustomValidity('');
        field.reportValidity();
    }

    // Modify amount validation parameters based on selected tax year change
    handleTaxYearChange(event) {
        if (event) this.handleInputChange(event);
        
        this.setMaxContributionLimits();  
        this.setPreviousContributionTotal(); 
    }

    // Save the input to the form and navigate within the flow
    navigate(event) {
        const button = event.target.dataset.name;

        // Update enrollment form clone with input
        this.enrollmentFormClone = {...this.enrollmentForm};
        this.enrollmentFormClone.Single_Sum_Contribution_Type__c = this.isSingle ? 'One-Time Debit' : 'Recurring Debit';

        if (this.isSingle) {
            this.enrollmentFormClone.Single_Sum_Contribution__c = this.singleAmount;
            this.enrollmentFormClone.Single_Sum_Contribution_Year__c = this.taxYear;
            this.enrollmentFormClone.Single_Sum_Contribution_Start_Date__c = this.singleDate;
        }

        this.enrollmentFormClone.Recurring_Contribution_Amount__c = this.recurringAmount || 0; // Value needed by next flow step
        if (this.isRecurring) {
            this.enrollmentFormClone.Recurring_Contributions_Date__c = this.recurringDay;
            this.enrollmentFormClone.Recurring_Contributions_Start_Date__c = this.recurringDate;
        }

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
    }

    // Validate all input fields
    validate() {
        let isValid = true;
        const inputFields = this.template.querySelectorAll('.formValidate');

        // Clear existing error messages and check standard input field validation first
        inputFields.forEach(field => {
            field.setCustomValidity('');
            if (!field.checkValidity()) {
                isValid = false;
            }
        });
        // If standard field validation passes, check logic-based required fields
        if (isValid) {
            // Ensure at least one contribution type is checked
            if (!this.isSingle && !this.isRecurring) {
                isValid = false;

                const checkFields = this.template.querySelectorAll('.check-field');
                checkFields.forEach(field => {
                    field.setCustomValidity(this.ERROR_CHECKBOX_REQUIRED);
                    field.reportValidity();
                });
            }
        }

        if (isValid) {
            // Ensure single amount is within limits
            if (this.isSingle) {
                const remainingAmount = this.maxAmount - this.previousContributionTotal;
                if (Number(this.singleAmount) > remainingAmount) {
                    isValid = false;
                    const singleAmtField = this.template.querySelector('[data-field-name="singleAmount"]');
                    singleAmtField.setCustomValidity(this.ERROR_AMT_PREVIOUS = this.ERROR_AMT_PREVIOUS.replace('PLACEHOLDER', remainingAmount));
                }
            }
            
            // Recurring date must match selected recurring day of month
            if (this.isRecurring) {
                const datePickerDay = this.recurringDate.split('-')[2];
                const dateRecurringDay = datePickerDay == '01' ? '1st' : datePickerDay == '15' ? '15th' : '';

                if (this.recurringDay != dateRecurringDay) {
                    isValid = false;
                    const recurringDateField = this.template.querySelector('[data-field-name="recurringDate"]');
                    recurringDateField.setCustomValidity(this.ERROR_RECUR_DAY.replace('PLACEHOLDER', this.recurringDay));
                }
            }
        }

        if(isValid) {
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
        else {
            inputFields.forEach(field => {
                field.reportValidity();
            });
        }
    }

    // Set maximum member amount based on contribution limits
    setMaxContributionLimits() {
        getContributionLimit(ACCT_TYPE_IRA, this.memberAge, this.taxYear)
            .then(data => {
                if (typeof data == 'string') {
                    const title = 'An error occurred when retrieving contribution limits.';
                    this.showErrorMessage(title, error);
                }
                else {
                    this.maxAmount = data;
                    this.ERROR_SINGLE_AMT_MAX = this.ERROR_SINGLE_AMT_MAX.replace('PLACEHOLDER', this.maxAmount);
                }
            })
            .catch(error => {
                const title = 'An error occurred when retrieving contribution limits.';
                this.showErrorMessage(title, error);
            })
    }

    // Set previous contributions total for validation on submit
    setPreviousContributionTotal() {
        getPreviousContributionTotal(this.contactId, ACCT_TYPE_IRA, this.taxYear)
            .then(data => {
                if (typeof data == 'string') {
                    const title = 'An error occurred when retrieving previous contribution total.';
                    this.showErrorMessage(title, error);
                }
                else {
                    this.previousContributionTotal = data;
                }
            })
            .catch(error => {
                const title = 'An error occurred when retrieving previous contribution total.';
                this.showErrorMessage(title, error);
            })
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