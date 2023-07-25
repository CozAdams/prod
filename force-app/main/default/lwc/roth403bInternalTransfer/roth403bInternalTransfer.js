import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValuesByRecordType,getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord,createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import ENROLLMENT_FORM_OBJECT from '@salesforce/schema/Enrollment_Form__c';

import { CloseActionScreenEvent } from 'lightning/actions';

ERROR_MSG_REQUIRED = 'This field is required.';
import TRANSFER_RULES_URL from '@salesforce/label/c.OT_Transfer_and_Rollover_Rules_URL';


const ACCT_BALANCE_MIN = 100;
const WIRE_FEE_DOMESTIC = 35;
const WIRE_FEE_INTL = 50;

export default class roth403bInternalTransfer extends LightningElement {


    @api caseRecordTypeId;
    @api accountSummaryInfo;


    transferRuleURL
    additionalAmountType
    casePicklistValues
    distributionOptionPicklistOptions
    withdrawalAmountMinError ='Withdrawal amount must be at least $1.'
        
    distributionReasonOptions
    witholdingPaymentTypeOptions
    reasonDate
    startDate

    withdrawalAmount
    additionalDollarAmount
    additionalPercentAmount
    showSpinner = true;

    _distributionReason
    _distributionOption = null;


    get distributionReason (){
        return this._distributionReason;
    }
    set distributionReason(value){
        this._distributionReason = value.trim();
        console.log('++get distribution reason' ,value)
    }

    get distributionOption (){
        return this._distributionOption;
    }
    set distributionOption(value){
        this.withdrawalAmount = '';
        this._distributionOption = value.trim();
        if(value == "Close"){
            this.withdrawalAmount = this.accountSummaryInfo.Balance__c + this.accountSummaryInfo.Accrued_Interest__c;
        }
        console.log('++get distribution Option',value )
    }

    get showReasonDate (){
        let showDate = this.distributionReason ==  'Disability' || this.distributionReason  == 'Death' || this.distributionReason  == 'Severance';
        return showDate;
    }
    get showDistributionOptionDates (){
        return this.distributionOption == "Single Sum";
    }
    get showWithdrawalAmount(){
        return this.distributionOption != "Close" &&  this.distributionOption != null ;
    }

    get showFederalWitholding (){      
        let showWitholding = this.distributionReason ==  'Age' || this.distributionReason  == 'Disability' || this.distributionReason  == 'Severance';
        return showWitholding
    }

    get showFederalWitholdingAmount(){
        return this.additionalAmountType =='Amount';
    }   
    get showFederalWitholdingPercent(){
        return this.additionalAmountType =='Percent';

    }
    get showWitholingFields(){

        return this.additionalAmountType != 'none';
    }   
    get additionalDollarAmountMax(){
       return this.accountSummaryInfo.Balance__c + this.accountSummaryInfo.Accrued_Interest__c - 0.01;


    }
    connectedCallback(){

        try{
            let startDate = new Date();
            console.log("++ accountSummaryInfo passed in iss", JSON.parse(JSON.stringify(this.accountSummaryInfo)));
            console.log("++ addiinotal amount max is ", this.additionalDollarAmountMax);
    
            this.transferRulesUrl = TRANSFER_RULES_URL;
            this.todaysDate = startDate.toLocaleDateString();
    
        }catch(e){

            console.error(e)
        }

    }
    

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    get enrollmentCaseRecordTypeId() {
        // Returns a map of record type Ids 
        const rtis = this.caseObjectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'New Enrollment Case');
    }



    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$caseRecordTypeId' })
    wiredCasePicklistValues({ error, data }) {
       
        try{
            if (data) {
                this.showSpinner = false;
                this.casePicklistValues = data.picklistFieldValues;
                this.witholdingPaymentTypeOptions = [...this.casePicklistValues.Additional_Withholding_Amount_Type__c.values,
                                                        {label: 'None', value:'none'}
                                                        ];
                let distributionOptionPicklistOptions = this.casePicklistValues.Withdraw_TDRA_Options__c;
                let distributionReasonOptions = this.casePicklistValues.Distribution_Reason_TDRA__c;
                console.log("+++picklist data iss before filter issss",  this.casePicklistValues );
  
                if (distributionReasonOptions.controllerValues && distributionReasonOptions.controllerValues.hasOwnProperty('Tax-Deferred 403(b) Retirement Account')) {
                    const controllerValue = distributionReasonOptions.controllerValues['Tax-Deferred 403(b) Retirement Account'];
                    this.distributionReasonOptions = distributionReasonOptions.values.filter( 
                        reason => {
                            return reason.validFor.includes(controllerValue) && reason.value != 'RMD' && reason.value != 'Other'
                        }
                    );

                }

                this.distributionOptionPicklistOptions = distributionOptionPicklistOptions.values.filter(option=> option.value != 'Recurring');
            }else if (error) {
                this.showSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'An error occurred when retrieving the field picklist options.',
                        variant: 'error',
                    }),
                );
            }
        }catch(e){
            this.showSpinner = false;

            console.log('++get picklist error',e);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'An error occurred when retrieving the field picklist options.',
                    variant: 'error',
                }),
            );
        }


            
        }



    handleFieldChange(event) {

        console.log("field change name: ", event.target.dataset.fieldName, " field new value: " ,event.target.value);
        this[event.target.dataset.fieldName] = event.target.value;
    }

    handleShowPopup(event){

            let popup = this.template.querySelector('[data-id="myPopup"]');

            popup.classList.toggle("show");

    }

    handleSubmit(event){

        console.log("case record type Id", this.enrollmentCaseRecordTypeId );
        this.saveCase();
 
    }



  


    handleNumberInputChange(event) {
        // Round input based on number field type
        const fieldName = event.target.dataset.fieldName;
        let roundedInput;
 
        if (fieldName.includes('Dollar') || fieldName == 'withdrawalAmount') {
            roundedInput = +parseFloat(event.target.value).toFixed(2);
        }
        else if (fieldName.includes('Percent')) { 
            roundedInput = +parseFloat(event.target.value).toFixed(1);
        }

        event.target.value = roundedInput;
        this[fieldName] = roundedInput;

        console.log(fieldName)
        // Revalidate
        const field = this.template.querySelector(`[data-field-name="${fieldName}"]`);
        field.setCustomValidity('');
        field.reportValidity();
        console.log('+++',fieldName ,field,this[fieldName] );

    }



    // Validate amount
    validateInput() {

        return [
            ...this.template.querySelectorAll('.withdraw-form-field'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.setCustomValidity('');

            if(inputCmp.getAttribute('data-field-name') == "withdrawalAmount"){

                let amountError;
                const accountBalance = this.accountSummaryInfo.Balance__c
                const amountMax = accountBalance - ACCT_BALANCE_MIN;
                // const amountMax = this.accountBalance - this.accountBalanceMin;
        
                if(this.distributionOption != 'Close'){

                    // Amount must be less than account balance
                    if (this.withdrawalAmount >= accountBalance) {
                        let distributionOption = this.distributionOption == null ? '' : this.distributionOption.toLowerCase();
                        
                        amountError = `Your ${distributionOption} withdrawal amount must be less than your total account balance. If you wish to 
                            withdraw 100% of your balance, please select the "100% of my TDRA Account" Distribution Option.`;
                    }
                    // Resulting balance cannot be less than account minimum
                    else if (this.withdrawalAmount > amountMax) {
                        amountError = `Your withdrawal attempt would leave your balance with less than 
                            ${ACCT_BALANCE_MIN.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '')}. 
                            Please withdraw less or select the option to withdraw and close your account.`; 
                    }

                }

                if (amountError != null)  inputCmp.setCustomValidity(amountError);

            }

            inputCmp.reportValidity();

            return validSoFar && inputCmp.checkValidity();
        }, true);
    }




    saveCase() {

     
        try{



            let fields = {};         
           // fields['Distribution_Frequency__c'] = this.withdrawOption;
            let today = new Date();
            today.setHours(today.getHours()-4);
            // Generic fields
            fields['Subject'] = this.accountSummaryInfo.Member_Name__r.Name + " Enrollment";
            fields['RecordTypeId'] = this.enrollmentCaseRecordTypeId;
            fields['Submitted_Date__c'] = today.toISOString();
            fields['Date_Signed_and_Certified__c'] = today.toISOString();
            console.log('new date isss',today.toISOString());
          //  fields['Test_Datetime__c'] = today.toISOString();
            fields['Funding_From__c'] = this.accountSummaryInfo.Id;
            fields['Account_Type__c'] = 'Tax-Deferred 403(b) Retirement Account';
            fields['Type__c'] = 'In Plan Roth Rollover';
            fields['Status'] = 'Enrollment Submitted';
            fields['Origin'] = 'MemberPortal';
            fields['E_Signature_Confirmed__c'] = true;
            fields['Community_Contact__c'] = this.accountSummaryInfo.Member_Name__c;
            fields['ContactId'] = this.accountSummaryInfo.Member_Name__c;
            //fields['OwnerId'] = this.accountSummaryInfo.Member_Name__c;
            fields['Withdraw_TDRA_Options__c'] = this.distributionOption;
            //fields['Portal_Transaction_Type__c'] = 'Withdrawal';
            fields['Gross_or_Net__c'] = 'Gross';
            fields['Distribution_Reason_TDRA__c'] = this.distributionReason;
            fields['Withdrawal_Amount__c'] = this.withdrawalAmount;
            fields['Signature_Received__c'] = true;
            console.log('+++Fields are ', fields);

            
            if(this.showReasonDate) fields['Distribution_Reason_Date__c'] = this.reasonDate;

            if(this.showDistributionOptionDates){ fields['Distribution_Start_Date__c'] = this.startDate};
            if(this.distributionOption == "Close")fields['Distribution_Start_Date__c'] = today;
            if(this.additionalAmountType != "none") fields['Additional_Withholding_Amount_Type__c'] = this.additionalAmountType;
            if(this.showFederalWitholding && this.showFederalWitholdingAmount ) fields['Distribution_Additional_Dollar_Amount__c'] = this.additionalDollarAmount;
            if(this.showFederalWitholding && this.showFederalWitholdingPercent ) fields['Distribution_Additional_Percent__c'] = this.additionalPercentAmount;


            if(this.validateInput()){

                let enrollmentFields = {};
                enrollmentFields['First_Name__c'] = this.accountSummaryInfo.Member_Name__r.FirstName;
                enrollmentFields['Name'] = this.accountSummaryInfo.Member_Name__r.LastName;
                enrollmentFields['Community_Contact__c'] = this.accountSummaryInfo.Member_Name__c;
                enrollmentFields['Type__c'] = 'In Plan Roth Rollover';
                enrollmentFields['Status__c'] = 'Submitted'
                enrollmentFields['TDRA_Initial_Rollover_Contributions__c'] = this.withdrawalAmount;
                enrollmentFields['Signed_and_certified__c'] = true;
                console.log('enrollmentForm fields ', enrollmentFields);
                // enrollmentFields[''] = '';
                // enrollmentFields[''] = '';
                // enrollmentFields[''] = '';


                this.showSpinner = true;
                const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };
                //const recordInput = { apiName: ENROLLMENT_FORM_OBJECT.objectApiName, fields: enrollmentFields };

                createRecord(recordInput)
                    .then(caseRecord => {
                            // Show success message and close window
                            this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Request has been received.',
                                variant: 'success',
                            }),
                        );
                        this.dispatchEvent(new CustomEvent('close'));
                        
                    })
            }  
        }catch(error){

             // Show error and close window
             const title = 'Error creating record';
             console.log('create reacord ERROR: ', error);
             this.showErrorMessage(title, error);
             this.showSpinner = false;   
        }
    } 



    showErrorMessage(title, error) {
        // Set error message
        let message = 'Unknown error';
        if (error) {
            if (error.message) {
                message = error.message;
            }
            else if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
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