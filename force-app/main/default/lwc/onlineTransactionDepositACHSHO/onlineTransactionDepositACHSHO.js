import { LightningElement, api, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getTotalContributionsSoFar from '@salesforce/apex/AccountSummaryService.getTotalContributionsSoFar';
import getMaxContributionLimits from '@salesforce/apex/AccountSummaryService.getMaxContributionLimits';

// Objects
import CASE_OBJECT from '@salesforce/schema/Case';

// Configuration labels
import ACCT_TYPE_BAA from '@salesforce/label/c.BAA_ACC_TYPE';
// import ACCT_TYPE_TDRA from '@salesforce/label/c.TDRA_ACC_TYPE';
// import ACCT_TYPE_TDRA_PR from '@salesforce/label/c.TDRA_PR_ACC_TYPE';
// import ACCT_TYPE_457 from '@salesforce/label/c.X457_ACC_TYPE';
import ACCT_TYPE_ROTH from '@salesforce/label/c.ROTH_ACC_TYPE';
import ACCT_TYPE_IRA from '@salesforce/label/c.IRA_ACC_TYPE';
// import ACCT_TYPE_LEGACY from '@salesforce/label/c.LEGACY_ACC_TYPE';

import HEADER_BAA from '@salesforce/label/c.OT_Deposit_BAA_Top_Header';
// import HEADER_PENSION from '@salesforce/label/c.OT_Deposit_Pension_Plan_Top_Header';
// import HEADER_TDRA from '@salesforce/label/c.OT_Deposit_TDRA_Top_Header';
import HEADER_IRA from '@salesforce/label/c.OT_Deposit_Traditional_IRA_Top_Header';
import HEADER_ROTH from '@salesforce/label/c.OT_Deposit_Roth_IRA_Top_Header';

export default class OnlineTransactionDeposit extends LightningElement {
    // Data
    @api case;
    @api accountSummary;
    accountType;
    isBAA; 
    isIRA;
    limits;
    totalContributionsSoFar;
    taxYear;

    // Input
    amount;
    frequency;
    recurringDay;
    startDate;
    endDate;

    // Form content
    header;
    amountMin;
    @api showRecurring; //JS SE_2742
    todaysDate;
    todaysDateFormatted;
    startDateMin;
    endDateMin;
    endDateMax;
    casePicklistData;
    frequencyOptions;
    recurringDayOptions;

    ERROR_MSG_REQUIRED = 'This field is required!';
    ERROR_AMOUNT_MIN = 'Your contribution range must be greater than or equal to $PLACEHOLDER.';

    // Get form picklist values from Case record type
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$case.RecordTypeId' })
    wiredCasePicklistValues({ error, data }) {
        if (data) {
            this.casePicklistData = data.picklistFieldValues;
            this.loadForm();
        }
        else if (error) {
            const title = 'An error occurred when retrieving the field picklist options.';
            this.showErrorMessage(title, error);
        }
    }

    // Load form content
    loadForm() {
        this.accountType = this.accountSummary.Account_Type__c;
        this.contactId = this.accountSummary.Member_Name__r.Id
        this.frequencyOptions = this.casePicklistData.Contribution_Frequency__c.values.filter(item => item.value !== 'Single Sum'); //JS  SE-2472
        //this.frequencyOptions = this.frequencyOptions.filter(item => item.value !== 'Single Sum'); //JS  SE-2472
        this.recurringDayOptions = this.casePicklistData.Contribution_Date__c.values;
        
        this.todaysDate = new Date();
        const todayArray = this.todaysDate.toLocaleDateString().split('/');
        this.todaysDateFormatted = todayArray[2] + '-' + todayArray[0] + '-' + todayArray[1];
        this.taxYear = this.todaysDate.getFullYear().toString();

        // Set header and validation based on Account Type
        switch (this.accountType) {
            case ACCT_TYPE_BAA:
                this.isBAA = true;
                this.header = HEADER_BAA;
                this.amountMin = 10;
                break;
            case ACCT_TYPE_ROTH:
                this.isIRA = true;
                this.header = HEADER_ROTH;
                this.amountMin = 10;
                break;
            case ACCT_TYPE_IRA:
                this.isIRA = true;
                this.header = HEADER_IRA;
                this.amountMin = 10;
                break;
            default: 
                this.amountMin = 0;
        }
        console.log('isIRA ' + this.isIRA);
        this.ERROR_AMOUNT_MIN = this.ERROR_AMOUNT_MIN.replace('PLACEHOLDER', this.amountMin);
        this.setDateRestrictions(false);

        this.getContributionLimits();
        this.getTotalContributions();
    }

    // Handle general field change
    handleFieldChange(event) {
        console.log('IN handleFieldChange');
        this[event.target.dataset.fieldName] = event.target.value;
    }

    // Handle withdrawal amount change 
    handleAmountChange(event) {
        console.log('IN handleAmountChange');
        let amountCmp = this.template.querySelector(".amount");
        amountCmp.setCustomValidity('');
        amountCmp.reportValidity();
        this.handleNumberInputChange(event);

        if(this.isIRA) this.validateContributionLimits();
    }

    // Handle number input change by rounding
    handleNumberInputChange(event) {
        // Round input based on number field type
        const roundedInput = +parseFloat(event.target.value).toFixed(2);
        event.target.value = roundedInput;
        this.handleFieldChange(event)

        // Revalidate
        const fieldName = event.target.dataset.fieldName;
        const field = this.template.querySelector(`[data-field-name="${fieldName}"]`);
        field.setCustomValidity('');
        field.reportValidity();
    }

    // Handle contribution type change for recurring or single sum
    handleFrequencyChange(event) {
        this.handleFieldChange(event);
        const newDay = event.target.value;
        this.showRecurring = newDay != 'Single Sum';

        if (!this.showRecurring) {
            this.showRecurring = false;
            this.recurringDay = null;
            this.startDate = null;
            this.endDate = null;
        }
        this.setDateRestrictions();
    }

    // Handle recurring day change to check date validation
    handleRecurringDayChange(event) {
        this.handleFieldChange(event);
        this.checkDateValidation(); 
    }

    // Handle start date change to check date validation
    handleDateChange(event) {
        this.handleFieldChange(event);
        this.setDateRestrictions(true);
    }

    // Set date minimum and maximum dates
    setDateRestrictions(runValidation) {
        // Minimum start date defaults to first of next month
        let minStartYear = this.todaysDate.getFullYear();
        let minStartMonth = this.todaysDate.getMonth() + 1;
        console.log('runValidation ' + runValidation);
        console.log('minStartMonth 1 ' + minStartMonth);
        console.log('recurringDay ' + this.recurringDay);
        // For end of month dates with expected start date of 1st, push out another month to allow processing time
        const isFirst = this.recurringDay || 'First' == 'First';
        if (isFirst && this.todaysDate.getDate() > 19) {
            minStartMonth++;
        }
        console.log('minStartMonth 2 ' + minStartMonth);
        // Account for end of year dates
        if (minStartMonth > 11) {
            minStartMonth = minStartMonth - 12;
            minStartYear++;
        }
        console.log('minStartMonth 3 ' + minStartMonth);
        let minStartDate1 = new Date(minStartYear, minStartMonth, 1);
        let minStartDate = new Date(minStartYear, minStartMonth, 1).toISOString();
        this.startDateMin = minStartDate;
        console.log('minStartDate ' + minStartDate1);
        console.log('startDateMin ' + this.startDateMin);
        // Change end date min and max validation based on start date value
        const startDate = new Date(this.startDate || this.minStartDate);
        let twoMonthsLater = new Date(startDate);
        twoMonthsLater.setMonth(startDate.getMonth() + 2);
        twoMonthsLater.setDate(twoMonthsLater.getDate() - 1);
        this.endDateMin = twoMonthsLater.toLocaleDateString();

        let fiftyYearsLater = new Date(startDate);
        fiftyYearsLater.setFullYear(startDate.getFullYear() + 50);
        fiftyYearsLater.setDate(fiftyYearsLater.getDate() - 1);
        this.endDateMax = fiftyYearsLater.toLocaleDateString();

        if (runValidation) {
            this.checkDateValidation();
        }
    }

    // Run validation on start and end dates entered
    checkDateValidation() {
        if (this.startDate) {
            // Clear existing validation errors
            const startDateField = this.template.querySelector('[data-field-name="startDate"]');
            startDateField.setCustomValidity('');
            startDateField.reportValidity();

            // Start date cannot be before minimum start date
            let startDate = new Date(this.startDate);
            const timezoneOffset = startDate.getTimezoneOffset();
            startDate.setMinutes(startDate.getMinutes() + timezoneOffset);
            let isValid = startDateField.checkValidity();

            // Start date must match the recurring day
            if (isValid && this.recurringDay) {
                const recurringDay = this.recurringDay == 'First' ? 1 : 15;
                if (startDate.getDate() !== recurringDay) {
                    startDateField.setCustomValidity('Contribution start date must be the ' + this.recurringDay.toLowerCase() + ' day of the month.');
                    startDateField.reportValidity();
                }
            }

            if (isValid && this.endDate) {
                // Clear existing validation errors
                const endDateField = this.template.querySelector('[data-field-name="endDate"]');
                endDateField.setCustomValidity('');
                endDateField.reportValidity();

                let endDate = new Date(this.endDate);
                endDate.setMinutes(endDate.getMinutes() + timezoneOffset);

                // End date must be before start date
                if (endDate < startDate) {
                    isValid = false;
                    endDateField.setCustomValidity('Start date must be before end date.');
                    endDateField.reportValidity();
                }

                // End date must be last day of month
                if (isValid) {
                    const lastDayOfMonth = new Date(endDate.getFullYear(), endDate.getMonth() + 1, 0);
                    if (endDate.getDate() !== lastDayOfMonth.getDate()) {
                        isValid = false;
                        endDateField.setCustomValidity('Contribution end date must be the last day of the month.');
                        endDateField.reportValidity();
                    }
                }

                // Start to end date range must be between 2 months and 50 years
                if (isValid) {
                    isValid = endDateField.checkValidity();
                }
            }
        }
    }

    // Validate all input and create a new deposit Case record
    @api 
    saveCase(isParentValid, record) {
        // Check validation
        const isFormValid = 
            [...this.template.querySelectorAll('.form-field')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, 
        true);

        // Set Case field values based on input
        if (isParentValid && isFormValid) {
            let fields = {};
            fields.Origin = 'MemberPortal';
            fields.Portal_Transaction_Type__c = 'Deposit';
            fields.RecordTypeId = this.case.recordTypeId;
            fields.Account_Summary__c = this.accountSummary.Id;
            fields.OwnerId = record.OwnerId;
            fields.Bank_Account__c = record.Bank_Account__c;
            fields.E_Signature_Confirmed__c = true;

            fields.Deposit_Amount__c = this.amount;
            fields.Contribution_Frequency__c = this.frequency;
            fields.Contribution_Date__c = this.recurringDay;
            fields.Contribution_Start_Date__c = this.startDate || this.todaysDateFormatted;
            fields.Contribution_End_Date__c = this.endDate; 

            // Insert Case
            const recordInput = { apiName: 'Case', fields };
            createRecord(recordInput)
                .then(record => {
                    // Show success message and close window
                    const isSavingChangeEvent = new CustomEvent('issavingchangeevent', { detail: false });
                    this.dispatchEvent(isSavingChangeEvent);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Request has been received.',
                            variant: 'success',
                        }),
                    );
                    this.dispatchEvent(new CustomEvent('close'));
                })
                .catch(error => {
                    // Hide saving spinner and show error message
                    const title = 'An error occurred when creating the transaction case record.';
                    this.showErrorMessage(title, error);

                    const isSavingChangeEvent = new CustomEvent('issavingchangeevent', { detail: false });
                    this.dispatchEvent(isSavingChangeEvent);
                });
        }
        // Hide saving spinner and show error message
        else {
            const isSavingChangeEvent = new CustomEvent('issavingchangeevent', { detail: false });
            this.dispatchEvent(isSavingChangeEvent);
        }
    }

    // Show toast error message
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

    validateContributionLimits() {
        let contributedSoFar = 0;
        let memberAge = this.accountSummary.Member_Name__r.Age__c;
        let errorMsg = '';

        let amountCmp = this.template.querySelector(".amount");
        let amount = this.amount;
        
        let storedLimit = this.limits;
        contributedSoFar = this.totalContributionsSoFar;
        console.log('IN |contributedSoFar ' + contributedSoFar );
        console.log('IN storedLimit ' + storedLimit.Retirement_Age__c );
        console.log('IN memberAge ' + memberAge );
        console.log('IN errorMsg 3 ' + errorMsg );
        // If a stored limit is found, set the contribution limit
        let maximumContributionLimit;
        if (storedLimit) {
            if (!memberAge || memberAge < storedLimit.Retirement_Age__c) {
                maximumContributionLimit = storedLimit.Amount_Before_Retirement_Age__c;
            }
            else {
                maximumContributionLimit = storedLimit.Amount_at_Retirement_Age__c;
            }
        }
        console.log('IN maximumContributionLimit ' + maximumContributionLimit );
        console.log('IN amount ' + amount );
        // Ensure the deposit will not exceed the member's contribution limit for the year
        if (maximumContributionLimit) {
            let possibleContributionSize = maximumContributionLimit - contributedSoFar;
            console.log('IN possibleContributionSize ' + possibleContributionSize );
            if (possibleContributionSize < 10) {
                errorMsg = 'No further contributions are allowed since you have met your yearly limit';
            } 
            else if (amount < 10 || amount > possibleContributionSize) {
                let formattedContrSize = possibleContributionSize.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '');
                errorMsg = 'Your contribution range must be between $10 and ' + formattedContrSize;
            }
        }
        console.log('IN errorMsg 2 ' + errorMsg );
        
        //this.showToast('', 'test', 'success', 'dismissable');
        if(errorMsg != '') {
            amountCmp.setCustomValidity(errorMsg);
            amountCmp.reportValidity();
        }
        

        /*

        
        
        
        if(!$A.util.isEmpty(errorMsg)) {
            component.find('depositNotificationLibrary').showToast({
                'title': 'Error!',
                'variant': 'error',
                'message': errorMsg,
                'mode': 'sticky'
            });
            component.set('v.isSaving', false);
            return;
        }
        this.saveCase(component);
        */
    }

    // Get contribution limits for the year options and account type
    getContributionLimits() {
        let taxYears = [];
        taxYears.push(this.taxYear);
        console.log('taxYears ' + taxYears);
        
        console.log('this.accountType ' + this.accountType);
        getMaxContributionLimits({

            "accountType": this.accountType,

            "years": taxYears

        })
        .then((result) => {
            this.limits = result.find(limit => limit.Year__c == this.taxYear);

            console.log('limits ' + this.limits);
        })
        .catch((error) => {
            console.log('error getContributionLimits ' + error.body.message);
        });
    }

    getTotalContributions() {
        this.totalContributionsSoFar = 0;
        getTotalContributionsSoFar({

            "contactId": this.contactId,

            "accountSummaryType": this.accountType,

            "yearParam": this.taxYear

        })
        .then((result) => {
            this.totalContributionsSoFar = result;
            console.log('totalContributionsSoFar ' + this.totalContributionsSoFar);
        })
        .catch((error) => {
            console.log('error getTotalContributions ' + error.body.message);
            //this.error = error;

            //this.contacts = undefined;

        });
    }
}