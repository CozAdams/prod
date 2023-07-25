import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex methods
import getRelatedAccountSummaries from '@salesforce/apex/AffiliationService.getRelatedAccountSummaries';

// Schema
import FIELD_AFFILIATION_STATUS from '@salesforce/schema/npe5__Affiliation__c.Calculated_Status__c';
import FIELD_AFFILIATION_CONTACT from '@salesforce/schema/npe5__Affiliation__c.npe5__Contact__c';
import FIELD_AFFILIATION_ORGANIZATION from '@salesforce/schema/npe5__Affiliation__c.npe5__Organization__c';

import FIELD_CONTACT_AGE from '@salesforce/schema/Contact.Age__c';
import FIELD_CONTACT_DAYS_UNTIL_BIRTHDAY from '@salesforce/schema/Contact.Days_Until_Birthday__c';
import FIELD_CONTACT_PRIMARY_ADDRESS_TYPE from '@salesforce/schema/Contact.npe01__Primary_Address_Type__c';
import FIELD_CONTACT_ACTIVE_ADDRESS from '@salesforce/schema/Contact.Active_Address__c';
import FIELD_CONTACT_MAILING_STREET from '@salesforce/schema/Contact.MailingStreet';
import FIELD_CONTACT_MAILING_CITY from '@salesforce/schema/Contact.MailingCity';
import FIELD_CONTACT_MAILING_STATE from '@salesforce/schema/Contact.MailingState';
import FIELD_CONTACT_MAILING_POSTAL_CODE from '@salesforce/schema/Contact.MailingPostalCode';
import FIELD_CONTACT_PREFERRED_PHONE from '@salesforce/schema/Contact.npe01__PreferredPhone__c';
import FIELD_CONTACT_MAILING_COUNTRY from '@salesforce/schema/Contact.MailingCountry';
import FIELD_CONTACT_PREFERRED_EMAIL from '@salesforce/schema/Contact.npe01__Preferred_Email__c';
import FIELD_CONTACT_HOME_PHONE from '@salesforce/schema/Contact.HomePhone';
import FIELD_CONTACT_MOBILE_PHONE from '@salesforce/schema/Contact.MobilePhone';
import FIELD_CONTACT_WORK_PHONE from '@salesforce/schema/Contact.npe01__WorkPhone__c';
import FIELD_CONTACT_HOME_EMAIL from '@salesforce/schema/Contact.npe01__HomeEmail__c';
import FIELD_CONTACT_ALTERNATE_EMAIL from '@salesforce/schema/Contact.npe01__AlternateEmail__c';
import FIELD_CONTACT_WORK_EMAIL from '@salesforce/schema/Contact.npe01__WorkEmail__c';
import FIELD_CONTACT_PREFERRED_LANGUAGE from '@salesforce/schema/Contact.Preferred_Language__c';

import FIELD_ACCT_SUMMARY_NAME from '@salesforce/schema/Account_Summary__c.Name';
import FIELD_ACCT_SUMMARY_TYPE from '@salesforce/schema/Account_Summary__c.Account_Type_display__c';
import FIELD_ACCT_SUMMARY_BALANCE from '@salesforce/schema/Account_Summary__c.Balance__c';
import FIELD_ACCT_SUMMARY_CREDITS from '@salesforce/schema/Account_Summary__c.Total_Credits__c';

// Field lists
const AFFILIATION_FIELDS = [ FIELD_AFFILIATION_CONTACT, FIELD_AFFILIATION_ORGANIZATION, FIELD_AFFILIATION_STATUS ];

// Account summary field map for column attributes
const ACCOUNT_SUMMARY_FIELD_MAP = {};
ACCOUNT_SUMMARY_FIELD_MAP[FIELD_ACCT_SUMMARY_NAME.fieldApiName] = { label: 'Name', type: 'string' };
ACCOUNT_SUMMARY_FIELD_MAP[FIELD_ACCT_SUMMARY_TYPE.fieldApiName] = { label: 'Account Type', type: 'string' };
ACCOUNT_SUMMARY_FIELD_MAP[FIELD_ACCT_SUMMARY_BALANCE.fieldApiName] = { label: 'TDRA Balance', type: 'currency' };
ACCOUNT_SUMMARY_FIELD_MAP[FIELD_ACCT_SUMMARY_CREDITS.fieldApiName] = { label: 'Pension Credits', type: 'currency' };

export default class AffiliationRelatedData extends LightningElement {
    // Affiliation data
    @api recordId;
    affiliation;
    affiliationStatus;
    errorMessage;

    // Contact data
    contactId;
    contact;

    CONTACT_FIELDS = [
        FIELD_CONTACT_PRIMARY_ADDRESS_TYPE, FIELD_CONTACT_PREFERRED_PHONE, 
        FIELD_CONTACT_ACTIVE_ADDRESS, FIELD_CONTACT_HOME_PHONE,
        FIELD_CONTACT_MAILING_STREET, FIELD_CONTACT_MOBILE_PHONE,
        FIELD_CONTACT_MAILING_CITY, FIELD_CONTACT_WORK_PHONE,
        FIELD_CONTACT_MAILING_STATE, FIELD_CONTACT_PREFERRED_EMAIL,
        FIELD_CONTACT_MAILING_POSTAL_CODE, FIELD_CONTACT_HOME_EMAIL,
        FIELD_CONTACT_MAILING_COUNTRY, FIELD_CONTACT_ALTERNATE_EMAIL, 
        FIELD_CONTACT_PREFERRED_LANGUAGE, FIELD_CONTACT_WORK_EMAIL,
        FIELD_CONTACT_AGE, FIELD_CONTACT_DAYS_UNTIL_BIRTHDAY
    ];

    // Account Summary data
    accountSummaries;
    accountSummaryColumns = [];
    showTable = false;
    showTableMessage = false;

    ACCOUNT_SUMMARY_FIELDS = [ FIELD_ACCT_SUMMARY_NAME, FIELD_ACCT_SUMMARY_TYPE ];

    // Get affiliation record
    @wire(getRecord, {
        recordId: '$recordId', 
        fields: AFFILIATION_FIELDS
    }) 
    wireAffiliation({ error, data }) {
        if (data) {
            // Assign values from returned Affiliation record
            this.affiliation = data;
            this.affiliationStatus = data.fields.Calculated_Status__c.value;
            this.contactId = data.fields.npe5__Contact__c.value;

            // Retrieve related account summaries for table
            this.loadRelatedAccountSummaries();
        }
        else if (error) {
            this.showToast('Unable to retrieve affiliation data: ' + error.body.message);
        }
    }

    // Get related Account Summary records
    loadRelatedAccountSummaries() {
        // Add additional fields to show on Account Summary if the affiliation is active
        if (this.affiliationStatus == 'Active') {
            this.ACCOUNT_SUMMARY_FIELDS.push(FIELD_ACCT_SUMMARY_BALANCE);
            this.ACCOUNT_SUMMARY_FIELDS.push(FIELD_ACCT_SUMMARY_CREDITS);
        }

        // Build columns for account summary data table
        let columns = [];
        for (let field of this.ACCOUNT_SUMMARY_FIELDS) {
            let fieldApiName = field.fieldApiName;
            let column = { 
                label: ACCOUNT_SUMMARY_FIELD_MAP[fieldApiName].label, 
                fieldName: fieldApiName, 
                type: ACCOUNT_SUMMARY_FIELD_MAP[fieldApiName].type 
            };
            columns.push(column);
        }
        this.accountSummaryColumns = columns;

        // Retrieve data
        getRelatedAccountSummaries({ 
            affiliation: this.convertWiredObjectForApex(this.affiliation)
        })
        .then((data) => {
            this.accountSummaries = data;
            if (this.accountSummaries.length > 0) {
                this.accountSummaries.forEach(acct => {
                    const balance = acct[FIELD_ACCT_SUMMARY_BALANCE.fieldApiName];
                    const credits = acct[FIELD_ACCT_SUMMARY_CREDITS.fieldApiName];

                    if (balance == 0) acct[FIELD_ACCT_SUMMARY_BALANCE.fieldApiName] = null;
                    if (credits == 0) acct[FIELD_ACCT_SUMMARY_CREDITS.fieldApiName] = null;
                })
                this.showTable = true;
            }
            else {
                this.showTableMessage = true;
            }
        })
        .catch((error) => {
            this.showToast('Unable to retrieve related account summary data: ' + error.body.message);
        })
    }

    // Convert wired object to Apex sObject
    convertWiredObjectForApex(data) {
        return {
            sobjectType: data.apiName, 
            Id: data.id, 
            ...Object.keys(data.fields).reduce((a, f) => {
                a[f] = data.fields[f].value;
                return a;
            }, {})
        };
    }

    // Display error toast 
    showToast(errorMessage) {
        const event = new ShowToastEvent({
            title: 'Error!', 
            message: errorMessage, 
            variant: 'error', 
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }
}