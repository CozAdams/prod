import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord,createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCaseQueue from '@salesforce/apex/AccountSummaryService.getCaseQueue';
import getPermissionToWithdraw from '@salesforce/apex/AccountSummaryService.getPermissionToWithdraw';
import getWithdrawalCountForMonth from '@salesforce/apex/AccountSummaryService.getWithdrawalCountForMonth';
import getTDRAAccounts from '@salesforce/apex/AccountSummaryService.getAccountSummaryListTDRA';
import { buildThreatReportCase } from 'c/threatMetrixUtil';

// Objects
import CASE_OBJECT from '@salesforce/schema/Case';

// Custom Labels
import TRANSFER_RULES_URL from '@salesforce/label/c.OT_Transfer_and_Rollover_Rules_URL';
import ACCT_TYPE_TDRA from '@salesforce/label/c.TDRA_Plan_Id';
import ACCT_TYPE_TDRA_PR from '@salesforce/label/c.TDRA_PR_Plan_Id';
import ACCT_TYPE_457 from '@salesforce/label/c.X457_Plan_Id';
import ACCT_TYPE_BAA from '@salesforce/label/c.BAA_Plan_Id';
import ACCT_TYPE_ROTH from '@salesforce/label/c.ROTH_Plan_Id';
import ACCT_TYPE_IRA from '@salesforce/label/c.IRA_Plan_Id';
import ACCT_TYPE_LEGACY from '@salesforce/label/c.Legacy_IRA_Plan_Id';
import ACCT_TYPE_403b from '@salesforce/label/c.ROTH403B_Plan_Id'

import HEADER_ROTH from '@salesforce/label/c.OT_Withdrawal_Roth_IRA_Top_Header';
import HEADER_IRA from '@salesforce/label/c.OT_Withdrawal_Traditional_IRA_Top_Header';
import HEADER_TDRA from '@salesforce/label/c.OT_Withdrawal_TDRA_Top_Header';
import MESSAGE_OTHER from '@salesforce/label/c.Other_Distribution_Option_Note';
import HEADER_ROTH403B from '@salesforce/label/c.OT_Withdrawal_Roth_403b_Top_Header';
import SCORE_THRSHOLD from '@salesforce/label/c.ThreatMetrixOtpThreshold';
import X403BTRAD_MESSAGE from '@salesforce/label/c.X403BTRAD_Message'; //JS SE-2724
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';

// Fields
const acctSummaryFields = [ 
    'Account_Summary__c.Name','Account_Summary__c.Account_Type__c',  'Account_Summary__c.Balance__c', 'Account_Summary__c.Organization__c', 'Account_Summary__c.Member_Name__r.MailingStreet', 
    'Account_Summary__c.Member_Name__r.MailingCity', 'Account_Summary__c.Member_Name__r.MailingState', 'Account_Summary__c.Member_Name__r.MailingPostalCode', 
    'Account_Summary__c.Member_Name__r.PIN__c','Account_Summary__c.Member_Name__r.DB_Membership_Status__c', 'Account_Summary__c.Member_Name__r.FirstName', 'Account_Summary__c.Member_Name__r.LastName', 'Account_Summary__c.Member_Name__r.MobilePhone', 
    'Account_Summary__c.Member_Name__r.Home_Address_Street_1__c', 'Account_Summary__c.Member_Name__r.Home_Address_Street_2__c', 'Account_Summary__c.Member_Name__r.Home_Address_City__c', 'Account_Summary__c.Plan_ID__c',
    'Account_Summary__c.Member_Name__r.Home_Address_State_Province__c', 'Account_Summary__c.Member_Name__r.Home_Address_Zip__c', 'Account_Summary__c.Member_Name__r.Home_Address_Country__c', 
    'Account_Summary__c.Member_Name__r.npe01__WorkEmail__c', 'Account_Summary__c.Member_Name__r.npe01__HomeEmail__c', 'Account_Summary__c.Member_Name__r.Email','Account_Summary__c.Accrued_Interest__c', 'Account_Summary__c.Years_since_first_Roth_Contribution__c',
    'Account_Summary__c.Member_Name__r.Has_member_met_RR_5_Year_taxable_period__c', 'Account_Summary__c.Member_Name__r.Age_in_months__c','Account_Summary__c.Member_Name__r.Birthdate', 'Account_Summary__c.Member_Name__r.DB_Membership_Status__c', 'Account_Summary__c.Account_Desc__c',
];

// Messages
const WITHDRAWAL_COUNT_LIMIT_MESSAGE = 'You have met or exceeded your withdrawal limit this month. Any withdrawals will incur a $20 fee.';
const WIRE_FEE_NOTE = 'Wire fee will be deducted from the Gross Withdrawal Amount designated above.';
const AMT_MAX_HOME_PURCHASE = 10000;
const ERROR_HOME_PURCHASE_MAX = 'You cannot withdraw more than $10,000 for your home purchase.';

// Constant values
// const ACCT_BALANCE_MIN_BAA = 25;
// const ACCT_BALANCE_MIN_OTHER = 100;
const ACCT_BALANCE_MIN = 100;
const WIRE_FEE_DOMESTIC = 35;
const WIRE_FEE_INTL = 50;


export default class OnlineTransactionWithdraw extends LightningElement {
    @api userId;
    @api case;
    @api accountType;
    @api accountPlanId;
    @api accountSummaryId;
    @api accountSummary;
    @api showForm;
    @api isSaving;    
    _otpAuthenticated = false;

    saveRecordObj;


    showOtp = false;
    tmscore;
    scoreThreashold = SCORE_THRSHOLD;
    _threatMetrixResponseScore;
    ownerId;
    isAccountTypeIRA;
    isAccountTypeTDRA;
    //showForm=false;
    showTdraOrderingOptout = false;
    

    // Form content constants
    HOUSING_CHECKBOX_LABEL = 'I am a member who is a minister and eligible for housing allowance. I hereby request that the Board of Directors designate my recurring distributions as housing allowance.';
    ERROR_MSG_REQUIRED = 'This field is required!';

    // Form content
    header;
    withdrawalCount;
    withdrawalCountMessage;
    otherMessage;
    transferRulesUrl;
    userFriendlyAcctType;

    // Form visibility
    isAccountSummaryReady;
    isCaseReady;
    isDataReady;
    isFormReady;
    
    showWithdrawalCount;
    showReason;
    showReasonDate;
    showReasonOther;
    showTransferRules;
    showDates;
    showWithdrawalAmount;
    showPaymentType;
    showMailingAddress;
    showWireFeeNote;
    showGrossOrNet;
    showWithholdingOption;
    showAllowances;
    showMaritalStatus;
    showAdditionalAmountType;
    showHousingAllowance;
    showAdditionalAmount;
    showAdditionalPercent;
    showRolloverContactFields;
    showBankingInfo;
    showTdraComment = true; //JS SE-
	showdistributionPaymentType = true; //JS SFMS-21
    tdraMessage = X403BTRAD_MESSAGE; //JS SE-2724
    showSpinner = false;
    isWithholdingOptionReadOnly;
    // Form picklist options
    casePicklistData;
    reasonOptions;
    withdrawOptions;
    paymentTypeOptions;
    grossOrNetOptions;
    withholdingOptions;
    maritalStatusOptions;
    additionalAmountTypeOptions;
    distributionPaymentTypeOptions;
    rolloverRecipientCountryOptions;
    qualifiedOrNonqualified;
    tdraOrderingOptout = false;
    // Form validation
    todaysDate;
    todaysDateFormatted;
    endDateMin;
    endDateMax;
    withdrawalAmountMin;
    withdrawalAmountMinError;
    withdrawalAmountMax;
    withdrawalAmountMaxError;
    wireFeeAmount;
    accountAccruedInterest; 
    accountName;

    // accountBalanceMin;

    // Form input values
    reason;
    reasonDate;
    reasonOther;
    withdrawOption;
    startDate;
    endDate;
    withdrawalAmount;
    paymentType;
    grossOrNet;
    withholdingOption;
    allowances;
    maritalStatus;
    additionalAmountType;
    hasHousingAllowance;
    additionalDollarAmount;
    distributionPaymentType;
    rolloverRecipientName;
    rolloverTrusteeName;
    rolloverContactName;
    rolloverRecipientPhone;
    rolloverRecipientStreet; //JS SE-2496 Added Street
    rolloverRecipientCity;
    rolloverRecipientState;
    rolloverRecipientCountry;
    rolloverRecipientZip;
    selectedDistributionType;
    selectedPaymentType;

    // get defaultWithholdingOptions (){
    //     const contactInfo = this.accountSummary.fields.Member_Name__r.value;
        
    //     if(contactInfo.fields.Has_member_met_RR_5_Year_taxable_period__c.value == 'Yes' && (contactInfo.fields.Age_in_months__c.value/12) >= 59.5 ){

    //         return 'No Withholding'
    //     }else {
    //         switch(this.reason){
    //             case 'Disability':
    //                 return 'No Withholding'
    //             case 'RMD' :
    //                 return 'Yes Withholding'
    //             case 'Age':
    //                 break;
    //             default :
    //              return '20% Withholding'



    //         }
    //     }
    // }
    // get isDefaultWithholdingReadOnly (){
    //     const contactInfo = this.accountSummary.fields.Member_Name__r.value;
    //     (contactInfo.fields.Has_member_met_RR_5_Year_taxable_period__c.value == 'Yes' && (contactInfo.fields.Age_in_months__c.value/12)) >= 59.5 ? true : false;

    // }


    @api  get threatMetrixResponseScore(){
        return this._threatMetrixResponseScore;
    }
    set threatMetrixResponseScore(value){

        this._threatMetrixResponseScore = value


    }

    get showRoth403bWarning(){
        return this.accountPlanId == ACCT_TYPE_403b; 

    }

    evaluateThreatMetrixScore(event){
        this.threatMetrixResponseScore = event.detail;
        console.log(' returned scrore from threatmetrix event is ' + event.detail, 'null or undefined' ,this.threatMetrixResponseScore == null ||this.threatMetrixResponseScore == undefined ,' compare ', !this.threatMetrixResponseScore );

        if(this.threatMetrixResponseScore == NaN || this.threatMetrixResponseScore == null || this.threatMetrixResponseScore == undefined || this.threatMetrixResponseScore < SCORE_THRSHOLD){ //check threshold compared to score.
            this.showForm = false;
            this.showOtp = true;
            this.dispatchEvent(new CustomEvent('hideforms'));


        }else{
            this.saveCase();

        }


    }

    // @api get otpAuthenticated(){
    //     return this._otpAuthenticated;
    // }
    // set otpAuthenticated(value){

    //     this._otpAuthenticated = value;
    //     this.dispatchEvent(new CustomEvent('otpauthenticated'));


    // }

    disconnectedCallback(){
        console.log('Disconncted call back has been fired', this.showOtp );
        if (this.showOtp == true){
            alert('We are unable to complete your request at this time. Please contact Pension Fund at 866-495-7322 for assistance');
            window.location.replace("/MyPensionfund/secur/logout.jsp");
        }      
    }




    handleOptAuthenticated(){
        this.showOtp = false;
        this.saveCase();


    }

    
    handleThreatReportIdChange(event){

        this.threatReportId = event.detail;
        console.log('threat report Id from online transaction  LWC isss',this.threatReportId);
    }

    // Retrieve Account Summary data and load form
    @wire(getRecord, { recordId: '$accountSummaryId', fields: acctSummaryFields })
    wiredRecord({ error, data }) {
        if (data) {
            console.log("++setAccountSummaryData input", data );
            this.setAccountSummaryData(data);

        }
        // Error message when Account Summary data can't be loaded
        else if (error) {
            console.error(error);
            const title = 'An error occurred when retrieving the account summary.';
            this.showErrorMessage(title, error);
        }
    }

    // Get form picklist values from Case record type
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$case.RecordTypeId' })
    wiredCasePicklistValues({ error, data }) {
        if (data) {
            this.isCaseReady = true;
            this.casePicklistData = data.picklistFieldValues;
            // If form content has been generated, populate picklists
            if (this.isFormReady) {
                this.loadFieldOptions();
            }
        }
        else if (error) {
            const title = 'An error occurred when retrieving the field picklist options.';
            this.showErrorMessage(title, error);
        }
    }

    // Set account summary data on components
    setAccountSummaryData(data) {
        this.accountSummary = data;
        this.accountBalance = this.accountSummary.fields.Balance__c.value;
        this.accountAccruedInterest = this.accountSummary.fields.Accrued_Interest__c.value;
        this.accountName = this.accountSummary.fields.Name.value;
        
        console.log('++account name',this.accountName  );

        // Set account type on parent Aura component for visibility logic
        const accountType = this.accountSummary.fields.Account_Type__c.value;
        const accountPlanId = this.accountSummary.fields.Plan_ID__c.value;

        this.accountType = accountType;
        this.accountPlanId = accountPlanId;

        
        const accountPlanIdEvent = new CustomEvent('accountplanidchangeevent', {
            detail: { accountPlanId }
        });
        this.dispatchEvent(accountPlanIdEvent);
        
        // Load form once data is set
        this.isAccountSummaryReady = true;
        this.checkWithdrawPermission(this.accountPlanId);
        
  
    }


    handleTdraOderingSubmit(){

        const agreementCheckbox = this.template.querySelector("[data-field-name='tdraOrderingAgreementCheckbox']");

        if(agreementCheckbox.reportValidity()){

            this.showForm = true;
            this.tdraOrderingOptout = true;
            this.showTdraOrderingOptout = false;
            this.checkWithdrawPermission(this.accountPlanId);
    

        }

    }



    handleTdraOderingCancel(){

        this.dispatchEvent(new CustomEvent('close'));


    }
    // Disable ability to withdraw for 457 account if not permissable by age and employment
    checkWithdrawPermission(accountPlanId) {
        const orgId = this.accountSummary.fields.Organization__c.value;
        const template = this;
        const contactInfo = this.accountSummary.fields.Member_Name__r.value;
        const accountDescription = this.accountSummary.fields.Account_Desc__c.value;
        console.log('+++check for contact info',contactInfo );
        switch(accountPlanId){
            case ACCT_TYPE_457:
                getPermissionToWithdraw(orgId)
                .then(hasPermission => {
                    if (hasPermission) {
                        this.loadFormData();
                    }
                    else {
                        // Show error and close form window
                        const title = 'Withdrawals are not permitted until age 72 when currently employed and contributing to a Tax Advantaged 457(b) account.';
                        template.showErrorMessage(title, null);
                        this.dispatchEvent(new CustomEvent('close'));
                    }
                })
                .catch(error => {
                    // Show error and close form window
                    const title = 'An error occurred when retrieving the permission to withdraw based on age and affiliation employment status.';
                    template.showErrorMessage(title, error);
                    this.dispatchEvent(new CustomEvent('close'));
                });
                break;
            case ACCT_TYPE_403b:

                /*JS SE-2593 commented out due to duplicate if in 408
                //check to see if account type is in summary
                if(accountDescription == 'in-plan roth rollover acccount'){
                    //if formula field is not met throw error message
                    if(!(contactInfo.fields.DB_Membership_Status__c == 'Disability' || (contactInfo.fields.Age_in_months__c.value/12) >= 59.5 || this.accountSummary.fields.Years_since_first_Roth_Contribution__c.value >= 5)){
                            const title = 'You have not met your 5-Year Recapture Period for this account. Please contact your Plan Administrator.';
                            template.showErrorMessage(title, null);
                            this.dispatchEvent(new CustomEvent('close'));
                    }
                }
                */
                
                //extract values to custom label or custom metadata?
                // Would age ever be null ?
                //
                if(accountDescription.toLowerCase() == 'in-plan roth rollover conversion account' && !(contactInfo.fields.DB_Membership_Status__c == 'Disability' || (contactInfo.fields.Age_in_months__c.value/12) >= 59.5 || this.accountSummary.fields.Years_since_first_Roth_Contribution__c.value >= 5)){ 
                    const title = 'You have not met your 5-Year Recapture Period for this account. Please contact your Plan Administrator.';
                    template.showErrorMessage(title, null);
                    this.dispatchEvent(new CustomEvent('close'));
                    
                }
                    else{
                        getTDRAAccounts({contactId:contactInfo.id })
                            .then(tdraAccountSummaries =>{
                                console.log('+++IN3' );
                                this.grossOrNet = 'Gross'
                                console.log('in roth403b permission check' ,contactInfo.fields.Has_member_met_RR_5_Year_taxable_period__c.value,(contactInfo.fields.Age_in_months__c.value) , contactInfo.fields.Age_in_months__c.value/12 );
                                console.log('+++tdra account list ' , tdraAccountSummaries , contactInfo.Id );

                                if((contactInfo.fields.Has_member_met_RR_5_Year_taxable_period__c.value == 'Yes' && (contactInfo.fields.Age_in_months__c.value/12) >= 59.5) || contactInfo.fields.DB_Membership_Status__c.value == 'Disability' ){
                                    
                                    console.log('+++qualifiedOrNonqualified is QUALIFIED  ' );

                                    this.qualifiedOrNonqualified = 'Qualified';
                                    this.withholdingOption ='No Withholding'
                                    this.isWithholdingOptionReadOnly = true;
                
                
                                }else if(contactInfo.fields.Has_member_met_RR_5_Year_taxable_period__c.value == 'Yes' && (contactInfo.fields.Age_in_months__c.value/12) < 59.5 && contactInfo.fields.DB_Membership_Status__c.value != 'Disability' ){
                                    

                                    console.log('+++qualifiedOrNonqualified is BLANK  ' );

                                    this.qualifiedOrNonqualified = 'Blank';
                                    this.withholdingOption ='No Withholding'; // JS SE-2593
                                    this.isWithholdingOptionReadOnly = true;  // JS SE-2593
                
                                }else{
                                    //You have not met your 5-Year Recapture Period for this account. Please contact your Plan Administrator
                                    const title = 'You have not met your 5-taxable-year period and are requesting a Non-qualified Distribution. Please contact your Plan Administrator.'; 
                                    template.showErrorMessage(title, null);
                                    this.dispatchEvent(new CustomEvent('close'));
                                    
                                }
                                console.log('IN tdraAccountSummaries.length ' + tdraAccountSummaries.length);
                                console.log('IN this.tdraOrderingOptout ' + this.tdraOrderingOptout);
                                if(tdraAccountSummaries.length > 0 && !this.tdraOrderingOptout){
                                    this.showForm = true;
                                    var totalBalance = 0;

                                    for(let acct of tdraAccountSummaries){
                                        console.log('IN acct.Balance__c ' + acct.Balance__c);
                                        totalBalance += acct.Balance__c;
                                        
                                    }

                                    if(totalBalance > 0){

                                        this.showTdraOrderingOptout = true;
                                        this.showForm = false;
                                    }
                                    else{
                                        this.showForm = true;
                                    }
                                    
                                    console.log('Total Balance ' + totalBalance);

                                    if(this.showForm)
                                        this.loadFormData();

                                }else{

                                    this.loadFormData();

                                }
                                console.log('IN tdraAccountSummaries.length ' + tdraAccountSummaries.length);
                                console.log('IN this.tdraOrderingOptout ' + this.tdraOrderingOptout);
                                console.log('IN this.showForm ' + this.showForm);
                                
                                console.log('IN Withdrawl Options ' + this.withholdingOption);

                            }).catch(error => {
                                const title = 'An error occurred when retrieving this month\'s withdrawal count.';
                                template.showErrorMessage(title, error);
                            });
                    }    
                
                break;
            default:
                this.loadFormData();
        }
    }

    // Load form data
    loadFormData() {
        // Set owner ID
        const template = this;
        getCaseQueue()
            .then(result => {
                this.ownerId = result;
            })
            .catch(error => {
                const title = 'An error occurred when retrieving the Online Transactions Queue Id.';
                template.showErrorMessage(title, error);
            });

        // Set withdrawal count for BAA
        if (this.accountPlanId == ACCT_TYPE_BAA) {
            getWithdrawalCountForMonth({ accountSummaryId: this.accountSummaryId })
                .then(result => {
                    this.withdrawalCount = result;
                    this.isDataReady = true;
                    this.loadFormFields();
                })
                .catch(error => {
                    const title = 'An error occurred when retrieving this month\'s withdrawal count.';
                    template.showErrorMessage(title, error);
                });
        }
        else {
            this.isDataReady = true;
            this.loadFormFields();
        }
    }

    // Load form based on account type 
    loadFormFields() {
        // Consistent fields
        this.otherNote = MESSAGE_OTHER;
        this.transferRulesUrl = TRANSFER_RULES_URL;
        this.showWithdrawalAmount = true;
        this.showPaymentType = true;
        this.wireFeeNote = WIRE_FEE_NOTE;
        this.userFriendlyAcctType = '';
        this.paymentType = 'ACH';
        this.distributionPaymentType = 'Direct';
        this.showBankingInfo = true;
        this.reason = 'Age';
        // this.accountBalanceMin = this.accountType == ACCT_TYPE_BAA ? ACCT_BALANCE_MIN_BAA : ACCT_BALANCE_MIN_OTHER;
        // console.log('MIN: ', this.accountBalanceMin);

        // Validation values
        this.loadValidationAttributes();
        console.log('accountPlanId ' + this.accountPlanId);
        // Account type dependent fields
        switch(this.accountPlanId) {
            case ACCT_TYPE_TDRA:
                //JS SE-2724
                this.withholdingOption = '20% Withholding';
                this.showMaritalStatus = false;
                this.showAllowances = false;
                //JS SE-2724
            case ACCT_TYPE_TDRA_PR:
            case ACCT_TYPE_457:
            case ACCT_TYPE_403b:

                this.isAccountTypeTDRA = true;
                this.showMaritalStatus = false; //JS SE-2724
                this.showAllowances = false; //JS SE-2724
                this.showAdditionalAmountType = true;
                this.showReason = true;
                this.showTransferRules = true;
                this.showWithdrawalAmount = true;
                this.showPaymentType = true;
                this.showGrossOrNet = true;
                this.showWithholdingOption = true;
                this.header = HEADER_TDRA;

                console.log('ACCT_TYPE_403b ' + ACCT_TYPE_403b);
                if(this.accountPlanId == ACCT_TYPE_403b ){
                    this.header = HEADER_ROTH403B; 
                    this.isAccountTypeTDRA = false;
                    this.reason = '';
                    this.showAdditionalAmountType = false;
                    this.showGrossOrNet = false;
					this.withholdingOption = 'No Withholding'; //JS SE-2724
                }else {
                    this.withholdingOption = '20% Withholding';
                }

                break;
            case ACCT_TYPE_BAA:
                this.withdrawalAmountMin = 25;
                this.userFriendlyAcctType = 'BAA';
                this.reason = null;
                this.showTdraComment = false; //SE-2724
				this.showdistributionPaymentType = false; //JS SFMS-21 do not display Distribution Payment Type for BAA
                break;
            case ACCT_TYPE_ROTH:
                this.isAccountTypeIRA = true;
                this.showIRAMessage = true;
                this.showReason = true;
                this.showWithholdingOption = true;
                this.header = HEADER_ROTH;
                this.userFriendlyAcctType = 'Roth';
                this.showTransferRules = true;
                this.reason = 'Age 59 ½ or older';
                this.showGrossOrNet = true; //JS SE-2596
				
				//START JS SE-2724
				this.showMaritalStatus = false;
				this.showAllowances = false;
                this.withholdingOption = 'No Withholding';
				this.isWithholdingOptionReadOnly = true;
                //END JS SE-2724
				
				console.log('IN ACCT_TYPE_ROTH');
                break;
            case ACCT_TYPE_IRA:
                this.withholdingOption = 'Yes Withholding';
                this.isWithholdingOptionReadOnly = true;
            case ACCT_TYPE_LEGACY:
                this.isAccountTypeIRA = true;
                this.header = HEADER_IRA;
                this.userFriendlyAcctType = 'IRA';
                this.showReason = true;
                this.showTransferRules = true;
                this.showWithdrawalAmount = true;
                this.showPaymentType = true;
                this.showGrossOrNet = true;
                this.showWithholdingOption = true;
                this.withholdingOption = 'Yes Withholding'; //JS SE-2724
                console.log('IN ACCT_TYPE_LEGACY');
        }

        // Withdrawal count
        if (this.withdrawalCount != null && this.withdrawalCount >= 2) {
            this.withdrawalCountMessage = `You've made ${this.withdrawalCount} withdrawal(s) from this account. \n\n${WITHDRAWAL_COUNT_LIMIT_MESSAGE}`;
            this.showWithdrawalCount = true;
        }

        // If picklist values have been retrieved, populate picklists
        this.isFormReady = true;
        if (this.isCaseReady) {
            this.loadFieldOptions();
        }
    }

    // Load validation values and messages
    loadValidationAttributes() {
        // Dates
        this.handleStartDateChange(null);

        // Withdrawal Amount 
        this.withdrawalAmountMin = this.accountPlanId == 'BENACC' ? 25 : 1;
        this.withdrawalAmountMinError = 'Withdrawal amount must be at least $' + this.withdrawalAmountMin + '.';
        this.withdrawalAmountMax = this.accountBalance;

        // Wire fee
        this.wireFeeAmount = 0;
    }

    // Populate picklists
    loadFieldOptions() {
        try{
                    // Standard options
            console.log('++casePicklistData  ' ,this.casePicklistData )

            this.paymentTypeOptions = this.casePicklistData.Distribution_Payment_Type__c.values;
            this.grossOrNetOptions = this.casePicklistData.Gross_or_Net__c.values;
            this.additionalAmountTypeOptions = this.casePicklistData.Additional_Withholding_Amount_Type__c.values;
            this.distributionPaymentTypeOptions = this.casePicklistData.Distribution_Payment_IRA_Type__c.values;
            this.rolloverRecipientCountryOptions = this.casePicklistData.Mailing_Country_Reference__c.values;
            this.withdrawOptions = this.casePicklistData.Withdraw_TDRA_Options__c.values;

            let maritalStatusOptions = [{
                attributes: null, label: 'Not Applicable', validFor: [], value: ''
            }];
            this.maritalStatusOptions = maritalStatusOptions.concat(this.casePicklistData.Marital_Status_Transactions__c.values);

            // Account Type dependent options
            let reasonValueData;
            // let withdrawOptionsValues;
            let withholdingOptionsValues;

            switch(this.accountPlanId) {
                case ACCT_TYPE_TDRA:
                case ACCT_TYPE_TDRA_PR:
                case ACCT_TYPE_457:

                    reasonValueData = this.casePicklistData.Distribution_Reason_TDRA__c;
                    // withdrawOptionsValues = this.casePicklistData.Withdraw_TDRA_Options__c.values;
                    withholdingOptionsValues = this.casePicklistData.Distribution_Withholding_TDRA__c.values;
                    break;
                case ACCT_TYPE_ROTH:

                    reasonValueData = this.casePicklistData.Distribution_Reason_Roth__c;
                    // withdrawOptionsValues = this.casePicklistData.Withdraw_ROTH_Options__c.values;
                    withholdingOptionsValues = this.casePicklistData.Distribution_Withholding__c.values;
                    break;
                case ACCT_TYPE_IRA:
                case ACCT_TYPE_LEGACY:
                    reasonValueData = this.casePicklistData.Distribution_Reason_IRA__c;
                    // withdrawOptionsValues = this.casePicklistData.Withdraw_IRA_Options__c.values;
                    withholdingOptionsValues = this.casePicklistData.Distribution_Withholding__c.values;
                    break;
                case ACCT_TYPE_BAA:
                    // withdrawOptionsValues = this.casePicklistData.Withdraw_BAA_Options__c.values;
                    withholdingOptionsValues = this.casePicklistData.Distribution_Withholding__c.values;
                    break;
                case ACCT_TYPE_403b:
                    reasonValueData = this.casePicklistData.Distribution_Reason_TDRA__c;
                    withholdingOptionsValues = this.casePicklistData.Distribution_Withholding_TDRA__c.values;
                    break;



            }
            
            // Distribution reason 
            if (this.showReason) {
                let values = reasonValueData.values;
                if (reasonValueData.controllerValues && reasonValueData.controllerValues.hasOwnProperty(this.accountType)) {
                    const controllerValue = reasonValueData.controllerValues[this.accountType];
                    values = values.filter( 
                        value => value.validFor.find(controller => controller === controllerValue) 
                    );
                }
                this.reasonOptions = values;
            }
            
            // Set dynamic options on form
            // this.withdrawOptions = withdrawOptionsValues;
            this.withholdingOptions = withholdingOptionsValues;
            
            // Show form
            this.showForm = true;
            this.dispatchEvent(new CustomEvent('loadevent', {}));

        }catch(e){
            console.log('++error in loadFieldopotoins isss  ' ,e)

            
        }

       
    }

    // Show error message
    showErrorMessage(title, error) {
        // Set error message
        let message = '';
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

    // Handle general field change
    handleFieldChange(event) {
        this[event.target.dataset.fieldName] = event.target.value;
    }

    // Handle checkbox change
    handleCheckboxChange(event) {
        const fieldName = event.target.dataset.fieldName;
        const checked = event.target.checked;
        this[fieldName] = checked;
    }

    // Handle change to reason
    handleReasonChange(event) {
        this.handleFieldChange(event);

        const contactInfo = this.accountSummary.fields.Member_Name__r.value;
        const reasonforDistributionField = this.template.querySelector("[data-field-name='reason']");
        reasonforDistributionField.setCustomValidity('');
        this.dispatchEvent(new CustomEvent('submitbuttondisableevent', {
            detail: {"disabled" : false}
        }));

		console.log('this.accountPlanId ' + this.accountPlanId + ' ' + ACCT_TYPE_TDRA);
        const newValue = event.target.value;
        this.showReasonOther = newValue == 'Other';
        this.showReasonDate = newValue == 'Disability' || newValue == 'Death' || newValue == 'Severance';

        if(this.accountPlanId == ACCT_TYPE_403b && this.qualifiedOrNonqualified != 'Qualified'){
            this.isWithholdingOptionReadOnly = false;

            switch(newValue){
				//START JS SE-2724 Commented out
				/*
                case 'Disability':
					this.withholdingOption = 'No Withholding';
                    this.isWithholdingOptionReadOnly = true;
                    break;
                case 'RMD' :
                    this.withholdingOption = 'Yes Withholding'; //JS SE-2724 Commented out
                    break;
                */
				//END JS SE-2724
				
				case 'Age':
                    
                    if((contactInfo.fields.Age_in_months__c.value/12) <= 59.5){
                        reasonforDistributionField.setCustomValidity(`Our records indicate your birthdate is ${contactInfo.fields.Birthdate.displayValue} , please select another Reason for Distribution or contact your Administrator to correct your birthdate on file.`);        
                        this.dispatchEvent(new CustomEvent('submitbuttondisableevent', {
                            detail: {"disabled" : true}
                        }));
                   }

                    break;
                default :
                this.withholdingOption =  'No Withholding'; //JS SE-2724
            }

        }
        //START JS SE-2724
        else if(this.accountPlanId == ACCT_TYPE_ROTH) {
            if(this.reason == 'Other' || this.reason == 'Home Purchase')
                this.withholdingOption = '10% Withholding';
            else
				this.withholdingOption = 'No Withholding';
        }
		else if(this.accountPlanId == ACCT_TYPE_TDRA) {
            console.log('IN 403BTRAD');
			this.handle403BTRAD();
		}
        //END JS SE-2724

        if (newValue == 'Home Purchase') {
            amountMax = AMT_MAX_HOME_PURCHASE;
            this.validateAmount();
        }
    }





    roth403bAgeChcek(){

        try{
            const contactInfo = this.accountSummary.fields.Member_Name__r.value;
            const reasonforDistributionField = this.template.querySelector("[data-field-name='reason']");
            console.log('reason button selection ', reasonforDistributionField);
           if((contactInfo.fields.Age_in_months__c.value/12) <= 59.5){
                reasonforDistributionField.setCustomValidity(`Our records indicate your birthdate is ${contactInfo.fields.Birthdate.displayValue} , please select another Reason for Distribution or contact your Administrator to correct your birthdate on file.`)
                //disable submit button

                this.dispatchEvent(new CustomEvent('submitbuttondisableevent', {
                    detail: {"disabled" : true}
                }));
           }else{

                reasonforDistributionField.setCustomValidity('')
                this.dispatchEvent(new CustomEvent('submitbuttondisableevent', {
                    detail: {"disabled" : false}
                }));

           }

        }catch(e){
            console.error(e);
        }



    }





    // Handle change to withdraw option 
    handleWithdrawOptionChange(event) {
        this.handleFieldChange(event);

        if(this.accountPlanId == ACCT_TYPE_TDRA)
            this.handle403BTRAD(); //JS SE-2724

        const newValue = event.target.value;
        this.showDates = newValue == 'Recurring';
        this.showWithdrawalAmount = newValue != 'Close';
        this.showPaymentType = newValue != 'Recurring';
        this.showMailingAddress = false;

        if(this.accountPlanId != ACCT_TYPE_BAA && this.accountPlanId != ACCT_TYPE_ROTH &&  this.accountPlanId != ACCT_TYPE_403b){

            this.showGrossOrNet = true;
        }

     

        console.log('isAccountTypeIRA ' + this.isAccountTypeIRA);
        console.log('isAccountTypeTDRA ' + this.isAccountTypeTDRA);
        // Set default withholding option 
        if (newValue == 'Single Sum') {
   
            //JS SE-2724 Commented out in if condition
			//|| (this.accountPlanId == ACCT_TYPE_403b && this.qualifiedOrNonqualified !='Qualified' && this.reason !='Disability')
            if (this.isAccountTypeTDRA && this.accountPlanId != ACCT_TYPE_TDRA) {
                this.withholdingOption = '20% Withholding' ;

            }else if(this.isAccountTypeIRA){

                //START JS SE-2724
                if(this.accountPlanId != ACCT_TYPE_IRA && this.accountPlanId != ACCT_TYPE_ROTH && this.accountPlanId != ACCT_TYPE_LEGACY)
                    this.withholdingOption = '10% Withholding';
                //END JS SE-2724
                
                
                
                    
                
            }            
            this.handleWithholdingOptionChange(null);
        }

        // Clear dependent field values
        if (newValue != 'Recurring') {
            this.startDate = null;
            this.endDate = null;
            this.showHousingAllowance = false;
            this.showHousingAmounts = false;
        }
        else {
            this.paymentType = null;
            this.showHousingAllowance = this.isAccountTypeTDRA;
        }

        // Handle clearing or validation of amount
        if (newValue == 'Close') {
            this.withdrawalAmount = null;
            this.showGrossOrNet = false;


        }
        else if (this.withdrawalAmount && this.withdrawalAmount > 0) {
            this.validateAmount();
        }
    }

    // Handle start date change
    handleStartDateChange(event) {
        let startDate;

        // Input change
        if (event) {
            this.handleFieldChange(event);

            // Clear existing errors
            const startDateField = this.template.querySelector('[data-field-name="startDate"]');
            startDateField.setCustomValidity('');
            startDateField.reportValidity();
            startDate = new Date(event.target.value);

            // Start date must be on the first of the month
            const timezoneOffset = startDate.getTimezoneOffset();
            startDate.setMinutes(startDate.getMinutes() + timezoneOffset);

            if (startDate.getDate() !== 1) {
                startDateField.setCustomValidity('Distribution start date must be the first day of the month.');
                startDateField.reportValidity();
            }
        }
        // Initial form load
        else {
            startDate = new Date();
            this.todaysDate = startDate.toLocaleDateString('en-us');
            const todayArray = this.todaysDate.split('/');
            this.todaysDateFormatted = todayArray[2] + '-' + todayArray[0] + '-' + todayArray[1];
        }

        // Change end date min and max validation based on start date value
        let twoMonthsLater = new Date(startDate);
        twoMonthsLater.setMonth(startDate.getMonth() + 2);
        twoMonthsLater.setDate(twoMonthsLater.getDate() - 1);
        this.endDateMin = twoMonthsLater.toLocaleDateString();

        let fiftyYearsLater = new Date(startDate);
        fiftyYearsLater.setFullYear(startDate.getFullYear() + 50);
        fiftyYearsLater.setDate(fiftyYearsLater.getDate() - 1);
        this.endDateMax = fiftyYearsLater.toLocaleDateString();

        if(this.accountPlanId == ACCT_TYPE_TDRA)
          this.handle403BTRAD(); //JS SE-2724
    }

    // Handle end date change
    handleEndDateChange(event) {
        this.handleFieldChange(event);

        // Clear existing errors
        const endDateField = this.template.querySelector('[data-field-name="endDate"]');
        endDateField.setCustomValidity('');
        endDateField.reportValidity();

        // End date must be after start date
        const startDate = new Date(this.startDate);
        let endDate = new Date(this.endDate);
        //JS SE-2724 Validate only when end date is populated
        if(this.endDate != null) {
            if (this.startDate >= this.endDate) {
                endDateField.setCustomValidity('Distribution end date must be after distribution start date.');
                endDateField.reportValidity();
            }
            // End date must be the last day of the month
            else {
                const timezoneOffset = endDate.getTimezoneOffset();
                endDate.setMinutes(endDate.getMinutes() + timezoneOffset);
                const lastDayOfMonth = new Date(endDate.getFullYear(), endDate.getMonth() + 1, 0);
                
                if (endDate.getDate() !== lastDayOfMonth.getDate()) {
                    endDateField.setCustomValidity('Distribution end date must be the last day of the month.');
                    endDateField.reportValidity();
                }
            }
        }
        //JS SE-2724

        if(this.accountPlanId == ACCT_TYPE_TDRA)
            this.handle403BTRAD(); //JS SE-2724
    }

    // Handle withdrawal amount change 
    handleAmountChange(event) {

        try{

            this.handleNumberInputChange(event);
            this.validateAmount();
        }catch(e){
            console.error(e)
        }

    }
    

    // Handle payment type change
    handlePaymentTypeChange(event) {
        this.handleFieldChange(event);

        const newValue = event.target.value;
        this.selectedPaymentType = newValue;
       
        // Set banking info visibility flag on parent Aura component
        const showBankingInfo = newValue != 'Check' && this.selectedDistributionType != 'Rollover';
        const paymentTypeChangeEvent = new CustomEvent('paymenttypechangeevent', {
            detail: { showBankingInfo }
        });
        this.dispatchEvent(paymentTypeChangeEvent);
        this.showMailingAddress = newValue == 'Check';

        // Wire fee dependencies
        this.showWireFeeNote = newValue.includes('Wire') && this.grossOrNet == 'Gross'
        this.wireFeeAmount = newValue == 'Domestic Wire' ? WIRE_FEE_DOMESTIC : this.paymentType == 'International Wire' ? WIRE_FEE_INTL : 0;
        this.validateAmount();
    }

    handleGrossOrNetChange(event){

        const newValue = event.target.value;
        this.handleFieldChange(event);
        (newValue == 'Gross' && this.paymentType.includes('Wire')) ? this.showWireFeeNote = true : this.showWireFeeNote = false;
        console.log('ingross or net change', this.showWireFeeNote );
        this.validateAmount();

    }

    // Handle change to withholding option
    handleWithholdingOptionChange(event) {
        const oldValue = this.withholdingOption;
        if (event) this.handleFieldChange(event);
        const newValue = this.withholdingOption;

        const isWithholding = newValue != null & newValue != '' && newValue != 'No Withholding';
        //this.showAllowances = isWithholding; //JS SE-2724
        //this.showMaritalStatus = isWithholding; //JS SE-2724
        this.showAdditionalAmountType = isWithholding;
        this.showAdditionalAmount = isWithholding && this.amountType == 'Amount';
        this.showAdditionalPercent = isWithholding && this.amountType == 'Percent';

        // Handle additional amount dependency visibility and values
        if (oldValue != 'No Withholding' && newValue == 'No Withholding') {
            this.additionalAmountType = null;
            this.additionalDollarAmount = null;
            this.additionalPercentAmount = null;
            this.allowances = null;
        }
        this.handleAdditionalAmountTypeChange(null);
    }

    // Handle change to additional amount type
    handleAdditionalAmountTypeChange(event) {
        if (event) this.handleFieldChange(event);
        const newValue = this.additionalAmountType;

        this.showAdditionalAmount = newValue == 'Amount';
        this.showAdditionalPercent = newValue == 'Percent';
        if (newValue == 'Amount') this.additionalPercentAmount = null;
        if (newValue == 'Percent') this.additionalDollarAmount = null;
    }

    // Handle change to distribution payment type
    handleDistributionPaymentTypeChange(event) {
        
        this.handleFieldChange(event);

        const newValue = event.target.value;
        this.selectedDistributionType = newValue;
        this.showRolloverContactFields = newValue == 'Rollover';

        // Set banking info visibility flag on parent Aura component
        const showBankingInfo = newValue == 'Direct' && this.selectedPaymentType != 'Check';
        const paymentTypeChangeEvent = new CustomEvent('paymenttypechangeevent', {
            detail: { showBankingInfo }
        });
        this.dispatchEvent(paymentTypeChangeEvent);
        this.showBankingInfo = showBankingInfo;

        //START JS SE-2724
        if(this.accountPlanId == ACCT_TYPE_IRA || this.accountPlanId == ACCT_TYPE_LEGACY) {
            if(this.distributionPaymentType == 'Rollover')
                this.withholdingOption = 'No Withholding';
            else {
                this.withholdingOption = 'Yes Withholding';
            }

        }
        //END JS SE-2724

        // Clear rollover contact fields if they are hidden
        if (!this.showRolloverContactFields) {
            this.rolloverRecipientName = null;
            this.rolloverTrusteeName = null;
            this.rolloverContactName = null;
            this.rolloverRecipientPhone = null;
            this.rolloverRecipientStreet = null; //JS SE-2496 Added Street
            this.rolloverRecipientCity = null;
            this.rolloverRecipientState = null;
            this.rolloverRecipientCountry = null;
            this.rolloverRecipientZip = null;
        }
    }

    // Handle number input change by rounding
    handleNumberInputChange(event) {
        // Round input based on number field type
        const fieldName = event.target.dataset.fieldName;
        let numDecimalPlaces = 0;
        if (fieldName.includes('Dollar') || fieldName == 'withdrawalAmount') {
            numDecimalPlaces = 2;
        }
        else if (fieldName.includes('Percent')) { 
            numDecimalPlaces = 1;
        }
        
        const roundedInput = +parseFloat(event.target.value).toFixed(numDecimalPlaces);
        event.target.value = roundedInput;
        this.handleFieldChange(event)

        // Revalidate
        const field = this.template.querySelector(`[data-field-name="${fieldName}"]`);
        field.setCustomValidity('');
        field.reportValidity();
    }

    // Validate amount
    validateAmount() {
        const withdrawalAmountField = this.template.querySelector('[data-field-name="withdrawalAmount"]');
        withdrawalAmountField.setCustomValidity('');
        withdrawalAmountField.reportValidity();
        
        let amountError;
				
		////set acct minimum based on product
        if(this.accountPlanId == ACCT_TYPE_BAA){
            ACCT_BALANCE_MIN = 25;
        }else{
            ACCT_BALANCE_MIN = 100;
        }
    //////

        const amountMax = this.accountBalance - ACCT_BALANCE_MIN;
        // const amountMax = this.accountBalance - this.accountBalanceMin;
        console.log( 'max amount ',amountMax, ' withdraw amount  ',this.withdrawalAmount );
        // Amount must be less than account balance
        if (this.withdrawalAmount >= this.accountBalance) {
            let withdrawOption = this.withdrawOption == null ? '' : this.withdrawOption.toLowerCase();
            
            amountError = `Your ${withdrawOption} withdrawal amount must be less than your total account balance. If you wish to 
                withdraw 100% of your balance, please select the "100% of my ${this.userFriendlyAcctType} Account" Distribution Option.`;
        }
        // Resulting balance cannot be less than account minimum
        else if (this.withdrawalAmount > amountMax) {
            amountError = `Your withdrawal attempt would leave your balance with less than 
                ${ACCT_BALANCE_MIN.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '')}. 
                Please withdraw less or select the option to withdraw and close your account.`; 
        }
        // If using wire, resulting balance cannot be less than account minimum - wire fee
        else if (this.showWireFeeNote && this.withdrawalAmount > (amountMax - this.wireFeeAmount)) {
            amountError = `A $${this.wireFeeAmount} fee for Wire has to be taken from your account balance, therefore you cannot 
                withdraw 100% of your balance and choose payment type ${this.paymentType}.`;
        }
        // If Roth home purchase, amount cannot be greater than 10K
        else if (this.reason == 'Home Purchase' && this.withdrawalAmount > AMT_MAX_HOME_PURCHASE) {
            amountError = ERROR_HOME_PURCHASE_MAX;
        }
        
        // Display error
        if (amountError != null) {
            withdrawalAmountField.setCustomValidity(amountError);
            withdrawalAmountField.reportValidity();
        }
    }

    @api
    setPaymentTypeInternational() {
        if (this.showPaymentType) {
            this.paymentType = 'International Wire';
            this.validateAmount();
            this.showWireFeeNote = true;
            this.wireFeeAmount = WIRE_FEE_INTL;
        }
    }

    @api
    saveCase() {
           this.showSpinner = true;
            let fields = this.saveRecordObj;
            console.log('+++Fields are ', fields);
            // Insert Case
            const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };
            createRecord(recordInput)
                .then(caseRecord => {
                    if(this.threatReportId){
                        let fields = {
                            Id : this.threatReportId,
                            Case__c : caseRecord.id
                        }
                        const recordInput = { fields };
                        updateRecord(recordInput)
                            .then(()=>{
    
                                console.log('++threat report record updated');
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
                        }else{
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Request has been received.',
                                    variant: 'Error',
                                }),
                            );
                            this.dispatchEvent(new CustomEvent('close'));

                        }

                })
                .catch(error => {
                    // Show error and close window
                    const title = 'Error creating record';
                    console.log('create reacord ERROR: ', error);
                    this.showErrorMessage(title, error);
                   // this.dispatchEvent(new CustomEvent('close'));
                });
    } 


    @api
    requestThreatMetrixScore(bankAccount, isEsignValid){
        try{
					 // next line commented by brandon to restore previous logid
					 // 
			//		if( this.validateForm(bankAccount) === null) { bankAccount = '1';}
					
		//	if (( bankAccount = '1' || this.validateForm(bankAccount)) && isEsignValid) {
//            if (this.validateForm(bankAccount) && isEsignValid) { 

if (( bankAccount == null || this.validateForm(bankAccount)) && isEsignValid) {
			//			if (isEsignValid) { 			
								
								
                let fields = {};
               //this.bankAccount = bankAccount; might not need.
                console.log('++ bank accoutn from requestThreatMetrixScore iss ', bankAccount );

                // Fields dependent on withdraw option
                if (this.withdrawOption == 'Close') {
                    console.log (parseFloat(this.accountBalance), parseFloat(this.accountAccruedInterest));
                    this.withdrawalAmount = parseFloat((parseFloat(this.accountBalance )+ parseFloat(this.accountAccruedInterest)).toFixed(2));
                    this.withdrawalAmount = this.withdrawalAmount ? this.withdrawalAmount  : parseFloat(this.accountBalance );
                    fields['Distribution_Frequency__c'] = 'Single Sum';
                    if(this.accountPlanId == ACCT_TYPE_BAA){
                        this.grossOrNet = "Net"
                    }else{
                        this.grossOrNet = "Gross"
                    }
                }
                else {
                    fields['Distribution_Frequency__c'] = this.withdrawOption;
                    if (this.withdrawOption == 'Recurring') {
                        this.Distribution_Date__c = 'First';
                    }
                }

                // Generic fields
                fields['RecordTypeId'] = this.case.RecordTypeId;
                fields['Account_Summary__c'] = this.accountSummaryId;
                fields['Account_Type__c'] = this.accountType;
                fields['OwnerId'] = this.ownerId;
                fields['Portal_Transaction_Type__c'] = 'Withdrawal';
                fields['Origin'] = 'MemberPortal';
                fields['ContactId'] = this.contactId;
                fields['Qualified_Non_Qualified_Distribution__c'] = this.qualifiedOrNonqualified;
                // Input fields
                fields['Distribution_Start_Date__c'] = this.startDate || this.todaysDateFormatted;
                fields['Distribution_End_Date__c'] = this.endDate;
                if (this.showReasonDate) fields['Distribution_Reason_Date__c'] = this.reasonDate;
                fields['Distribution_Reason_Other__c'] = this.reasonOther;
                fields['Withdrawal_Amount__c'] = this.withdrawalAmount;
                fields['Distribution_Payment_Type__c'] = this.paymentType;
                fields['Excess_Transaction_Filed__c'] = this.showWithdrawalCount;
                fields['Gross_or_Net__c'] = this.grossOrNet;
                fields['Distribution_Allowances__c'] = this.allowances;
                fields['Marital_Status_Transactions__c'] = this.maritalStatus;
                fields['Additional_Withholding_Amount_Type__c'] = this.additionalAmountType;
                fields['Dist_Has_Housing_Allowance__c'] = this.hasHousingAllowance;
                fields['Distribution_Additional_Dollar_Amount__c'] = this.additionalDollarAmount;
                fields['Distribution_Additional_Percent__c'] = this.additionalPercentAmount;
                fields['Distribution_Payment_IRA_Type__c'] = this.distributionPaymentType;
                fields['Dist_Name_of_Recipient_Roth_IRA__c'] = this.rolloverRecipientName;
                fields['Dist_Name_of_Trustee_Custodian__c'] = this.rolloverTrusteeName;
                fields['Dist_Contact_Name__c'] = this.rolloverContactName;
                fields['Dist_Phone_Number__c'] = this.rolloverRecipientPhone;
                fields['Dist_Mailing_Street__c'] = this.rolloverRecipientStreet; //JS SE-2496 Added Street
                fields['Dist_Trustee_Custodian_City__c'] = this.rolloverRecipientCity;
                fields['Dist_Trustee_Custodian_State__c'] = this.rolloverRecipientState;
                fields['Dist_Trustee_Custodian_Country__c'] = this.rolloverRecipientCountry;
                fields['Dist_Trustee_Custodian_Zip_Code__c'] = this.rolloverRecipientZip;
                fields['Bank_Account__c'] = bankAccount;
                fields['E_Signature_Confirmed__c'] = isEsignValid;



                // Fields that vary by account type
                if (this.isAccountTypeTDRA || this.accountPlanId == ACCT_TYPE_403b ) {
                    fields['Distribution_Reason_TDRA__c'] = this.reason;
                    fields['Withdraw_TDRA_Options__c'] = this.withdrawOption;
                    fields['Distribution_Withholding_TDRA__c'] = this.withholdingOption;
                    fields['TDRA_Ordering_Opt_out__c'] = this.tdraOrderingOptout;
                }
                else {
                    fields['Distribution_Withholding__c'] = this.withholdingOption;

                    if (this.isAccountTypeIRA) {
                        if (this.accountPlanId == ACCT_TYPE_ROTH) {
                            fields['Distribution_Reason_Roth__c'] = this.reason;
                            fields['Withdraw_TDRA_Options__c'] = this.withdrawOption;
                        }
                        else {
                            fields['Distribution_Reason_IRA__c'] = this.reason;
                            fields['Withdraw_TDRA_Options__c'] = this.withdrawOption;
                        }
                    }
                    else if (this.accountPlanId == ACCT_TYPE_BAA) {
                        fields['Withdraw_TDRA_Options__c'] = this.withdrawOption;
                    }
                }
                console.log('case fields ', fields , this.accountPlanId , this.accountPlanId == ACCT_TYPE_403b );
                this.saveRecordObj = fields;




                let transactionCase = { ...fields};
                const caseContact = this.accountSummary.fields.Member_Name__r.value;
                console.log('++case contact isss ', caseContact);

                transactionCase['accountName'] = this.accountName;
                transactionCase.Description = caseContact.fields.PIN__c.value;
                transactionCase.First_Name__c = caseContact.fields.FirstName.value;
                transactionCase.Middle_Name__c = caseContact.fields.LastName.value;
                transactionCase.Home_Address_Street_1__c = caseContact.fields.Home_Address_Street_1__c.value;
                transactionCase.Home_Address_Street_2__c = caseContact.fields.Home_Address_Street_2__c.value;
                transactionCase.Home_Address_City__c = caseContact.fields.Home_Address_City__c.value;
                transactionCase.Home_Address_State_Province__c = caseContact.fields.Home_Address_State_Province__c.value;
                transactionCase.Home_Address_Zip__c = caseContact.fields.Home_Address_Zip__c.value;
                transactionCase.Home_Address_Country__c = caseContact.fields.Home_Address_Country__c.value;
                transactionCase.E_mail_Address__c = caseContact.fields.npe01__WorkEmail__c.value;
                transactionCase.Email__c = caseContact.fields.npe01__HomeEmail__c.value;
                transactionCase.ContactEmail = caseContact.fields.Email.value;
                transactionCase.ContactPhone = caseContact.fields.MobilePhone.value;
                transactionCase.ContactId = caseContact.id;

                transactionCase.Subject = 'Withdrawal';
                transactionCase.Account_Type__c = this.accountType;

                console.log('++transactionCaseeee isss ', transactionCase);
                console.log('in 1');
                this.template.querySelector('c-threat-metrix-logger').setSessionQueryInfo(transactionCase, bankAccount);
                console.log('in 2');

                const isSaving = false;
                const isSavingChangeEvent = new CustomEvent('issavingchangeevent', {
                    detail: { isSaving }
                });
                this.dispatchEvent(isSavingChangeEvent);
                
            }else{


                const isSaving = false;
                const isSavingChangeEvent = new CustomEvent('issavingchangeevent', {
                    detail: { isSaving }
                });
                this.dispatchEvent(isSavingChangeEvent);

            }

        }catch(e) {
             console.log('threat metrix ERROR: ', e);
            // Empty until error logging is added
        }
            
    }



    // Validate form input before saving as Case
    validateForm(bankAccount) {
        let isValid;
        let warningMessage = '';

        // Clear previous custom validation
        const housingFields = this.template.querySelectorAll('.housing-field');
        housingFields.forEach((field) => {
            field.setCustomValidity('');
            field.reportValidity();
        });

        // Built-in validation
        isValid = 
            [...this.template.querySelectorAll('.withdraw-form-field')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, 
        true);
        
        // Show any necessary warning messages if validation passes
        if (isValid) {
            // Required bank account
            if (this.showBankingInfo && !bankAccount) {
                isValid = false;
            }
            // Wire fee warning
            if (this.showWireFeeNote) {
                warningMessage += `A $${this.wireFeeAmount} fee for ${this.paymentType} has to be taken from your account balance and will` + 
                    ` be deducted from your withdrawal amount.\n`;
            }
            
            // Close account GEC warning
            if (this.withdrawOption == 'Close') {
                warningMessage += `\nIf you choose to withdraw fully and close your account, you will lose on GEC. We recommend to` + 
                    ` leave a small balance ($100) since GEC is paid on average daily balances.\n\nClick OK to continue or Cancel to revise`;               
            }
        }
        
        // Show warning message
        if (isValid && warningMessage != '') {
            isValid = confirm('Warning: ' + warningMessage);
            return isValid;
        }

        if (!isValid) {
            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Please make the following changes highlighted on the form.',
                    variant: 'error',
                }),
            );
        }
        return isValid;

        // Validate allowances - TEMPORARILY DISABLED FOR HOT FIX
        // if ((accountSummary.Account_Type__c === component.get('v.IRA_ACC_TYPE') || accountSummary.Account_Type__c === component.get('v.ROTH_ACC_TYPE') || accountSummary.Account_Type__c === component.get('v.LEGACY_ACC_TYPE')
        //         || accountSummary.Account_Type__c === component.get('v.TDRA_ACC_TYPE') || accountSummary.Account_Type__c === component.get('v.TDRA_PR_ACC_TYPE') || accountSummary.Account_Type__c === component.get('v.X457_ACC_TYPE')) && component.get('v.case.Distribution_Withholding__c') === 'Yes Withholding'
        //         && (component.get('v.case.Distribution_Allowances__c') < 0 || component.get('v.case.Distribution_Allowances__c') > 10)) {
        //     component.find('withdrawNotificationLibrary').showToast({
        //         'title': 'Error!',
        //         'variant': 'error',
        //         'message': 'Please enter a number of allowances number between 0 and 10',
        //         'mode': 'sticky'
        //     });
        //     return;
        // }
    }
	
	//handle 403BTRAD values
    //JS SE-2724
	handle403BTRAD() {
		console.log('this.reason ' + this.reason);
        console.log('this.withdrawOption ' + this.withdrawOption);
        console.log('this.startDate ' + this.startDate);
        console.log('this.endDate ' + this.endDate);

        this.showWithholdingOption = true;
        this.showMaritalStatus = false;
        this.showAllowances = false;
        this.maritalStatus = null;
        this.allowances = null;
        //this.showTdraComment = false;
        this.withholdingOption = '20% Withholding';
        
        if(this.reason == 'RMD') {
			this.withholdingOption = 'Yes Withholding';
            console.log('IN RMD');
        }
		else if(this.reason == 'Rollover')
			this.withholdingOption = 'No Withholding';
        else if(this.withdrawOption == 'Recurring') {
            var year = 0;

			if(this.startDate != null && this.endDate != null) {
                console.log('IN Recurring');
				year = this.calculateDistributionYears();
				console.log('IN Recurring');
			}

            if(year >= 10 || this.endDate == null) {
                this.withholdingOption = null;
                this.showWithholdingOption = false;
                this.showMaritalStatus = true;
                this.showAllowances = true;
                this.maritalStatus = 'Single';
                this.allowances = 0;
                //this.showTdraComment = true;
            }
            else if(year < 10) {
                this.withholdingOption = '20% Withholding';
            }
		}
        console.log('this.withholdingOption ' + this.withholdingOption );
			
    }
	
	//calculate years between distribution dates
	//JS SE-2724
	calculateDistributionYears() {
        console.log('IN calculateDistributionYears');
        console.log('startDate ' + this.startDate);
        console.log('endDate ' + this.endDate);

        const startDateArr = this.startDate.split("-");
        const endDateArr = this.endDate.split("-");

        var startYear = startDateArr[0];
        var startMonth = startDateArr[1];
        var startDay = startDateArr[2];

        var endYear = endDateArr[0];
        var endMonth = endDateArr[1];
        var endDay = endDateArr[2];

        var calculatedYear = endYear - startYear;

        console.log('calculatedyear ' + calculatedYear);
        console.log(endMonth - 1 + ' ' + startMonth);

        if(endMonth == '12' && startMonth == '01' && startYear == endYear)
            calculatedYear++;
        else if(startYear != endYear && (startMonth - 1) != endMonth && endMonth < startMonth && startMonth != 1)
            calculatedYear--;

        console.log('calculatedyear 1 ' + calculatedYear);
        
		return calculatedYear;
	}
}