({
	doInit : function(component, event, helper) {



        component.set('v.PENSION_ACC_TYPE', $A.get("$Label.c.TDRA_Plan_Id"));
        component.set('v.TDRA_ACC_TYPE', $A.get("$Label.c.TDRA_Plan_Id"));
        component.set('v.TDRA_PR_ACC_TYPE', $A.get("$Label.c.TDRA_PR_Plan_Id"));
        component.set('v.BAA_ACC_TYPE', $A.get("$Label.c.BAA_Plan_Id"));
        component.set('v.IRA_ACC_TYPE', $A.get("$Label.c.IRA_Plan_Id"));
        component.set('v.ROTH_ACC_TYPE', $A.get("$Label.c.ROTH_Plan_Id"));
        component.set('v.LEGACY_ACC_TYPE', $A.get("$Label.c.Legacy_IRA_Plan_Id"));
        component.set('v.ROTH403B_ACC_TYPE', $A.get("$Label.c.ROTH403B_Plan_Id"));
        component.set('v.new403bDescriptionHeader', $A.get("$Label.c.OT_Transfer_403b_Top_Header"));
        


        helper.getAccountSummary(component);
        helper.getCurrentUser(component);
        helper.getCaseQueueId(component);
        helper.getCaseRecordTypeId(component);

        // import ACCT_TYPE_TDRA from '@salesforce/label/c.TDRA_Plan_Id';
        // import ACCT_TYPE_TDRA_PR from '@salesforce/label/c.TDRA_PR_Plan_Id';
        // import ACCT_TYPE_457 from '@salesforce/label/c.X457_Plan_Id';
        // import ACCT_TYPE_BAA from '@salesforce/label/c.BAA_Plan_Id';
        // import ACCT_TYPE_ROTH from '@salesforce/label/c.ROTH_Plan_Id';
        // import ACCT_TYPE_IRA from '@salesforce/label/c.IRA_Plan_Id';
        // import ACCT_TYPE_LEGACY from '@salesforce/label/c.Legacy_IRA_Plan_Id';
        // import ACCT_TYPE_403b from '@salesforce/label/c.ROTH403B_Plan_Id'


        // <aura:attribute name="PENSION_ACC_TYPE" type="String" access="Private" default="US Pension Plan"/>
        // <aura:attribute name="TDRA_ACC_TYPE" type="String" access="Private" default="Tax-Deferred 403(b) Retirement Account"/>
        // <aura:attribute name="TDRA_PR_ACC_TYPE" type="String" access="Private" default="Tax-Deferred 403(b) Retirement Account Puerto Rico"/>
        // <aura:attribute name="BAA_ACC_TYPE" type="String" access="Private" default="Benefit Accumulation Account"/>
        // <aura:attribute name="IRA_ACC_TYPE" type="String" access="Private" default="Traditional IRA"/>
        // <aura:attribute name="ROTH_ACC_TYPE" type="String" access="Private" default="Roth IRA"/>
        // <aura:attribute name="LEGACY_ACC_TYPE" type="String" access="Private" default="Legacy IRA"/>

        let picklistService = component.find('picklistService');
        picklistService.getEntries('Case', 'Transfer_BAA_Options__c', entries => {
            component.set('v.baaTransferOptions', entries);
        });
        picklistService.getEntries('Case', 'Transfer_TDRA_Options__c', entries => {
            component.set('v.tdraTransferOptions', entries);
        });
        picklistService.getEntries('Case', 'Transfer_ROTH_Options__c', entries => {
            component.set('v.rothTransferOptions', entries);
        });
        picklistService.getEntries('Case', 'Transfer_IRA_Options__c', entries => {
            component.set('v.iraTransferOptions', entries);
        });
	},





    // if (this.showReason) {
    //     let values = reasonValueData.values;
    //     if (reasonValueData.controllerValues && reasonValueData.controllerValues.hasOwnProperty(this.accountType)) {
    //         const controllerValue = reasonValueData.controllerValues[this.accountType];
    //         values = values.filter( 
    //             value => value.validFor.find(controller => controller === controllerValue) 
    //         );
    //     }
    //     this.reasonOptions = values;
    // }
   closeModal : function( component){

        $A.get('e.force:closeQuickAction').fire();

   },

	save : function(component, event, helper) {
        component.set('v.isSaving', true);

        // Validate required fields
        let childCmp = component.find('eSignatureComp');
        let isFormValid = childCmp.eSignatureFieldValidation();
        let accountSelectCmp = component.find('accountSelect');
        if (!accountSelectCmp.accountSummaryValidation()) {
            isFormValid = false;
        }
        let formFields = [].concat(component.find('transferFormField'));
        for (let i = 0; i < formFields.length; i++) {
            if ($A.util.isEmpty(formFields[i].get('v.value'))) {
                if (formFields[i].setCustomValidity != null) {
                    formFields[i].setCustomValidity('This field is required!');
                    formFields[i].reportValidity();
                } else {
                    $A.util.addClass(formFields[i], 'slds-has-error');
                }
                isFormValid = false;
            } else {
                if (formFields[i].setCustomValidity != null) {
                    formFields[i].setCustomValidity('');
                    formFields[i].reportValidity();
                } else {
                    $A.util.removeClass(formFields[i], 'slds-has-error');
                }
            }
        }
        if (!isFormValid) {
            component.find('transferNotificationLibrary').showToast({
                'title': 'Fields Required',
                'variant': 'error',
                'message': 'Please fill out all required fields on the form',
                'mode': 'sticky'
            });
            component.set('v.isSaving', false);
            return;
        }

        // Handle transfer limits
        let accountSummary = component.get('v.accountSummary');
        let amount = component.get('v.case.Transfer_Amount__c');
        let errorMsg = '';

        if (accountSummary.Account_Type__c === component.get('v.BAA_ACC_TYPE') &&
                (amount <= 0 || amount > accountSummary.Balance__c - 25)) {
            let formattedBalance = (accountSummary.Balance__c - 25).toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '');
            errorMsg = 'Your transfer range must be between $0 and $' + formattedBalance + '. Minimum balance must be $25';
        } else if (amount <= 0 || amount > accountSummary.Balance__c) {
            let formattedBalance = accountSummary.Balance__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '');
            errorMsg = 'Your transfer range must be between $0 and $' + formattedBalance;
        }

        if(!$A.util.isEmpty(errorMsg)) {
            component.find('transferNotificationLibrary').showToast({
                'title': 'Error!',
                'variant': 'error',
                'message': errorMsg,
                'mode': 'sticky'
            });
            component.set('v.isSaving', false);
            return;
        }

        helper.saveCase(component);
	}
})