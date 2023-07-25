import { api, wire, LightningElement } from 'lwc';
import SCORE_THRSHOLD from '@salesforce/label/c.ThreatMetrixLogOutThreshold';
import { getRecord ,createRecord} from 'lightning/uiRecordApi';
import { generateProfilingTag, buildSessionQuery, sendSessionQuery, convertWiredObject, buildThreatReportCase } from 'c/threatMetrixUtil';


import USER_ID from '@salesforce/user/Id';

import {FlowNavigationNextEvent, FlowAttributeChangeEvent} from 'lightning/flowSupport';

const BANK_ACCOUNT_FIELDS = [ 'bnk_Bank__c.bnk_Bank_Name__c', 'bnk_Bank__c.bnk_Routing_Number__c', 'bnk_Bank__c.bnk_Account_Number__c' ];
const USER_CONTACT_FIELDS = [ 'User.ContactId', 'User.Contact.FirstName', 'User.Contact.LastName', 'User.Contact.PIN__c', 'User.Contact.MobilePhone',
    'User.Contact.Current_State__c', 'User.Contact.Email' ];

export default class ThreatMetrixLogger extends LightningElement {
    @api sessionId;
    @api case;
    @api userId;
    @api user;
    @api bankAccountId;
    @api threatMetrixScore;
    contactInfo;
    // Conditions
    @api isLogin;
    @api otpAuthenticated = false;
    @api threatReportId;
     showSpinner;

    // Begin logging process for all community user actions exception Withdrawal
    connectedCallback() {
        console.log('In Connected Callback');
        // If profiling has already run, assess threat and log report
        console.log('In threat sessionId ' + this.sessionId);
        if (this.sessionId) {
            this.buildQuery();
        }
        // If session ID has not been provided, run profiling to set it
        else {
            // For login actions, only add profiling on first load of landing page
            if (this.isLogin) {
                console.log('In threat sessionId 2 ' + this.sessionId);
                // this.showSpinner = true;
                const oldHeadScript = document.getElementById('threat-metrix-script');
                if (!oldHeadScript) {
                    this.addProfiling();
                }
                else {
                    // this.showSpinner = false;
                }
            }
            // For all other actions, reprofile on every page load
            else {
                console.log('In threat sessionId 3 ' + this.sessionId);
                this.addProfiling();
            }
        }
        console.log('In threat sessionId 4 ' + this.sessionId);
    }

    // Add profiling tags to markup to being logging user activity
    async addProfiling() {
        generateProfilingTag()
            .then(profilingInfo => {
                // Get session ID and src tag
                this.sessionId = profilingInfo.sessionId;
                const src = profilingInfo.src;

                // Remove old head script tag
                const head = document.getElementsByTagName('head').item(0);
                let oldHeadScript = document.getElementById('threat-metrix-script');
                if (oldHeadScript) head.removeChild(oldHeadScript);

                // Add head script tag 
                const headScriptTag = document.createElement('script');
                headScriptTag.setAttribute('id', 'threat-metrix-script');
                headScriptTag.setAttribute('type', 'text/javascript');
                headScriptTag.setAttribute('src', src);
                head.appendChild(headScriptTag);

                // Remove old body noscript tag
                const body = document.getElementsByTagName('body').item(0);
                const oldBodyNoScript = document.getElementById('threat-metrix-iframe');
                if (oldBodyNoScript) body.removeChild(oldBodyNoScript);


/*  
                // Add body noscript tag
                const style = 'width: 100px; height: 100px; border: 0; position: absolute; top:-5000px;';
                const noscriptIframe = document.createElement('iframe');
                noscriptIframe.setAttribute('style', style);
                const noscriptSrc = src.replace('.js', '').replace('&allow_reprofile=1', '');
                noscriptIframe.setAttribute('src', noscriptSrc);

                const bodyNoScriptTag = document.createElement('noscript');
                bodyNoScriptTag.setAttribute('id', 'threat-metrix-iframe');
                bodyNoScriptTag.appendChild(noscriptIframe);
                body.appendChild(bodyNoScriptTag);
*/
                // For login action, assess threat and log report immediately
                if (this.isLogin) {
                    // Setting userId will trigger User record wire method and threat analysis process
                    this.userId = USER_ID;
                }
            })
            .catch(error => {
                // Do nothing to ensure page functionality is not affected by ThreatMetrix errors
                console.log('+++error in retrieveing tag iss : ' ,error);

            })
            console.log('In addProfiling sessionId ' + this.sessionId);
    }

    // For Login action, build dummy Case record to hold details when user ID is populated
    @wire(getRecord, { recordId: '$userId', fields: USER_CONTACT_FIELDS })
    userRecord({ error, data }) {
        console.log('In userRecord');
        let logger = this;
        if (data) {
            // Build Case based on Contact details
            this.user = convertWiredObject(data);
            const caseContact = convertWiredObject(this.user.Contact);
            this.contactInfo = caseContact;
            this.case = buildThreatReportCase(null, caseContact, 'Login');

            // Enforce delay before threat assessment to ensure ThreatMetrix has time to process new session
            // setTimeout(function() {
                // logger.showSpinner = false;
                logger.buildQuery();
            // }, 5000);
        }
    }

    // For Withdrawal actions, retrieve bank account information for callout before beginning logging process
    @wire(getRecord, { recordId: '$bankAccountId', fields: BANK_ACCOUNT_FIELDS })
    bankRecord({ error, data }) {
        console.log('In bankRecord');
        if (data) {
            // Add bank account details to Case record
            const bankAccount = convertWiredObject(data);
            const transactionCase = { ...this.case };

            transactionCase.Bank_Name__c = bankAccount.bnk_Bank_Name__c;
            transactionCase.Bank_Routing_ABA__c = bankAccount.bnk_Routing_Number__c;
            transactionCase.Checking_Account__c = bankAccount.bnk_Account_Number__c;
            this.case = transactionCase;

            this.buildQuery();
        }
    }

    // For Withdrawal actions, set case and bank account properties
    @api
    setSessionQueryInfo(threatMetrixCase, bankAccount) {
        console.log('In setSessionQueryInfo');
        this.case = threatMetrixCase;
        this.bankAccountId = bankAccount;

        //SE-2293
        if(!bankAccount) {
            console.log('IN setSessionQueryInfo blank bankAccount');
            this.buildQuery();
        }
    }


    // Get SFDC session ID to use as ThreatMetrix session ID params
    @api
    buildQuery() {
        console.log('in build query', this.sessionId, this.case);
        buildSessionQuery(this.sessionId, this.case)
            .then(calloutString => {
                if (calloutString) {
                    console.log('++++callout string is', calloutString);
                    this.sendQuery(calloutString);
                }
            })
            .catch(error => {
                // Do nothing to ensure page functionality is not affected by ThreatMetrix errors
                console.log('+++error in building session query is : ' ,error);

            })
    }

    // Send session query callout to ThreatMetrix and create Threat Report record from response
    sendQuery(calloutString) {
        console.log('In Threat Metrix');
        this.showSpinner = true;
        sendSessionQuery(calloutString) 
            .then(response => {
                console.log('response from threat metrix issss', response);


                this.threatMetrixScore = parseInt(response?.policy_details_api?.policy_detail_api[0]?.customer?.score);
                console.log("threat metrix score isssss", response?.policy_details_api?.policy_detail_api[0]?.customer?.score );
                this.showSpinner = false;
                this.logThreatReport(this.case, response).then(createdRecord=>{

                    console.log("++created threat report record from util isss", createdRecord);
                    this.threatReportId = createdRecord.id;
                    console.log('+++threat report Id isss', this.threatReportId)


                    this.dispatchEvent(new FlowAttributeChangeEvent('threatReportId' , this.threatReportId));
                    this.dispatchEvent(new CustomEvent('threatmetrixscorechange', { detail: this.threatMetrixScore }))
                    this.dispatchEvent(new CustomEvent('threatreportidchange', { detail: this.threatReportId }))
                    this.dispatchEvent(new FlowNavigationNextEvent());

                 })



                // Not necessary unless a new action is implemented that does not refresh the LWC after submit
                // this.addProfiling(); 
            })
            .catch(error => {
                console.log('+++error in sending session query is : ' , error);

                    this.dispatchEvent(new FlowAttributeChangeEvent('threatReportId' , null));
                    this.dispatchEvent(new CustomEvent('threatmetrixscorechange', { detail: null }))
                    this.dispatchEvent(new CustomEvent('threatreportidchange', { detail: null}))
                    this.dispatchEvent(new FlowNavigationNextEvent());
                // Do nothing to ensure page functionality is not affected by ThreatMetrix errors
            })
    }


     logThreatReport(transactionCase, response) {
        console.log('In logThreatReport');
        const riskInfo = response.policy_details_api.policy_detail_api[0].customer;
        console.log('+++threat report record isss : ' , transactionCase);
        console.log('+++riskInfo : ' , riskInfo);

        let fields = {};
        fields['Case__c'] = transactionCase.Id;
        fields['Community_Contact__c'] = transactionCase.ContactId;
        fields['Score__c'] = riskInfo.score;
        fields['Review_Status__c'] = riskInfo.review_status;
        fields['Risk_Rating__c'] = riskInfo.risk_rating;
        fields['Action__c'] = transactionCase.Subject.replaceAll('_', ' ');
        fields['ThreatMetrix_Session_ID__c'] = response.session_id;


            if(riskInfo.score < parseInt(SCORE_THRSHOLD) && (Action__c = 'Login') ){
                alert('We are unable to complete your request to login into the member portal at this time. Please contact Pension Fund at 866-495-7322 for assistance and reference Code TM:0011');
                window.location.replace("/MyPensionfund/secur/logout.jsp");  
                } 
        
        return createRecord({ apiName: 'Threat_Report__c', fields });
        
    }     
        		
}