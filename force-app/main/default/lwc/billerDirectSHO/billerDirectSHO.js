import { LightningElement, wire, api, track } from 'lwc'; 
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_ID from '@salesforce/user/Id';
import getFieldValues from '@salesforce/apex/BillerDirectSHO.getFieldValues';
import getTotalContributionsSoFar from '@salesforce/apex/AccountSummaryService.getTotalContributionsSoFar';
import getMaxContributionLimits from '@salesforce/apex/AccountSummaryService.getMaxContributionLimits';
//import StayInTouchSignature from '@salesforce/schema/User.StayInTouchSignature';

import ACCT_TYPE_ROTH from '@salesforce/label/c.ROTH_ACC_TYPE';
import ACCT_TYPE_IRA from '@salesforce/label/c.IRA_ACC_TYPE';
import TAX_DATE_MONTH from '@salesforce/label/c.taxDateMonth';
import TAX_DATE_DAY from '@salesforce/label/c.taxDateDay';
import TAX_YEAR_DESCRIPTION from '@salesforce/label/c.TaxYearDescription';
import BAA_DEPOSIT_HEADER from '@salesforce/label/c.BAADepositHeader';




export default class BillerDirectSHO extends LightningElement {

    email;
    error;
    @api recordId;
    accountNumber;
    amount;
    name;
    pin;
    contactId;
    accountSummaryId;
    SHO;
    hashID;
    amountAtSubmit;

    //JS SE-2804
    accountSummaryType;
    accountSummary;
    header;
    taxYearOptions;
    taxYear;
    isIRA;
    totalContributionsSoFar;
    limits;


    connectedCallback() {
        this.amountAtSubmit = '0';
        this.amount = 0;
        this.taxYear = '';
    }

    //use imports to retrieve user record email data
    @wire(getRecord,{recordId: USER_ID,fields:[EMAIL_FIELD]})

    wireuser({error,data})
    {
        if(error){
            this.error=error;
            console.log(this.error);
        }
        else if(data){
            this.email=data.fields.Email.value;
            console.log(this.email);
        }
    }
    
    @wire(getFieldValues, {AccountSummaryId: '$recordId', email: '$email', amount: '$amount', taxYear: '$taxYear'})
    wireAccountSummaries({error, data}){
        console.log('succsess ---'  + data);
        console.log('making callout record id=' + this.recordId);
        if(data){
            console.log('succsess ---'  + data);
            let parsedData = JSON.parse(data);
            this.accountSummary = parsedData;
            console.log('succsess ---'  + data);
            this.SHO = true;
            console.log('SHO = ' + this.SHO);
            this.accountSummaryId = this.recordId;
            console.log('AccountSummaryId = ' + this.recordId);
            this.accountNumber = parsedData.Account.Account_Number__c;
            console.log('Account Number = ' + this.accountNumber);
            this.name = parsedData.Account.Member_Name__r.Name;
            console.log('account name = ' + this.name);
            this.pin = parsedData.Account.Member_Pin__c;
            console.log('account pin = ' + this.pin);
            this.contactId = parsedData.Account.Member_Name__r.Id;
            console.log('contact id = ' + this.contactId);
            console.log('hasString = ' + parsedData.hashValue);
            //this.hashID = this.sha512(parsedData.hashValue);
            this.hashID = parsedData.hashValue;
            console.log(this.hashID);
            console.log('ammount + ' + this.amount);
            this.accountSummaryType = parsedData.Account.Account_Type__c;

            //JS SE-2804
            if(this.accountSummaryType == ACCT_TYPE_ROTH || this.accountSummaryType == ACCT_TYPE_IRA) {
                this.isIRA = true;
                this.header = TAX_YEAR_DESCRIPTION;
                
                // Set tax year picklist options
                let val = '';
                let taxYear = [];
                let currentTime = new Date();
                let aprilVerification = new Date(TAX_DATE_MONTH+ ',' + TAX_DATE_DAY + ',' + currentTime.getFullYear());

                
                if(currentTime <= aprilVerification) {
                    val = currentTime.getFullYear() - 1;
                    taxYear.push({label:val.toString(), value:val.toString()});
                }
                else if(this.taxYear == '') {
                    this.taxYear = currentTime.getFullYear().toString();
                }

                val = currentTime.getFullYear();
                taxYear.push({label:val.toString(), value:val.toString()});
                this.taxYearOptions = taxYear;
            }
            else {
                this.header = BAA_DEPOSIT_HEADER;
            }

            this.getContributionLimits();
            this.getTotalContributions();
            //JS SE-2804
        }
        else if(error){
            console.log('error ' + error);
        }
    }

    // Handle general field change
    handleFieldChange(event) {
        this[event.target.dataset.fieldName] = event.target.value;
    }

    handleTaxYearChange(event) {
        this.handleFieldChange(event);
        console.log('IN handleTaxYearChange');
        this.getTotalContributions();
    }
    
    handleClick(evt){

        //const input = this.template.querySelector('lightning-input');
        const form = this.template.querySelector('form');
        
        let isValid = this.validateForm();
        console.log('tax year ' + this.taxYear);

        /*
        if (input.reportValidity()) {
            input.setCustomValidity('');
            this.amountAtSubmit = this.amount.toString();
            form.submit();
            this.dispatchEvent(new CustomEvent('close'));
        }
        */

        if (isValid) {
            this.amountAtSubmit = this.amount.toString();
            form.submit();
            this.dispatchEvent(new CustomEvent('close'));
        }

         //console.log(this.amount.toString());
        //console.log("in handle click" + this.template);
        //document.querySelectorAll('.submitForm');
        //let doc = this.querySelector('form[data-id="fromclass"]');
        //console.log(doc);
        //doc.submit();
        //console.log(document.querySelectorAll('.newdivtest'));
        
    }

    sha512(str) {
    let encodedString = new TextEncoder("utf-8").encode(str);
    console.log(encodedString);
    let encodingValue = crypto.subtle.digest("SHA-512", encodedString);
    console.log('crypto.subtle.digest' + encodingValue);
    let encodingArray = Array.prototype.map.call(new Uint8Array(encodingValue), x=>(('00' + x.toString(16)).slice(-2))).join('');
    console.log(encodingArray);
    return encodingArray;

    //return crypto.subtle.digest("SHA-512", new TextEncoder("utf-8").encode(str)).then(buf => {
    //    return Array.prototype.map.call(new Uint8Array(buf), x=>(('00'+x.toString(16)).slice(-2))).join('');
    //});
    }

    handleAmountChange(event){
        //console.log(JSON.parse(JSON.stringify(event)));
        let amountCmp = this.template.querySelector(".amount");
        amountCmp.setCustomValidity('');
        amountCmp.reportValidity();
        this.amount = event.detail.value;
        //console.log(this.amount);

    }

    // Validate form input
    validateForm() {
        let amountCmp = this.template.querySelector(".amount");
        amountCmp.setCustomValidity('');
        amountCmp.reportValidity();

        if(this.isIRA) this.validateContributionLimits();
        
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.deposit-form-field');
        inputFields.forEach(inputField => {
            console.log('inputFields ' + inputField.checkValidity());
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    validateContributionLimits() {
        let contributedSoFar = 0;
        let taxYear = this.taxYear.toString();
        let memberAge = this.accountSummary.Account.Member_Name__r.Age__c;
        let errorMsg = '';

        let amountCmp = this.template.querySelector(".amount");
        let amount = this.amount;
        
        let storedLimit = this.limits.find(limit => limit.Year__c == this.taxYear);
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

    showToast(title, message, variant, mode) {
        console.log(variant);
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    // Get contribution limits for the year options and account type
    getContributionLimits() {
        let todaysDate = new Date();
        let todaysYear = todaysDate.getFullYear();
        let previousYear = todaysYear - 1;
        let taxYears = [];
        taxYears.push(todaysYear.toString());
        taxYears.push(previousYear.toString());
        console.log('taxYears ' + taxYears);

        getMaxContributionLimits({

            "accountType": this.accountSummaryType,

            "years": taxYears

        })
        .then((result) => {
            this.limits = result;
            
            //this.limits = limits.find(limit => limit.Year__c == this.taxYear);

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

            "accountSummaryType": this.accountSummaryType,

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