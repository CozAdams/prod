({
    // Data retrieval for creating new Case
	doInit : function(component, event, helper) {
        helper.getCaseRecordTypeId(component);
        // helper.checkWithdrawPermission(component);
    },
    
    // Set attributes for visibility logic based on account type and child form input
    setAccountPlanId: function(component, event, helper) {
        component.set('v.accountPlanId', event.getParam('accountPlanId'));
        
        // Set esignature message based on account type
        helper.setEsignMessage(component);
    }, 

    // Set banking info visibility
    setShowBankingInfo: function(component, event, helper) {
        component.set('v.showBankingInfo', event.getParam('showBankingInfo'));
    },

    // Show form after all child components and data are ready
    showForm: function(component, event, helper) {
        component.set('v.showForm', true);
    }, 
    hideForm: function(component, event, helper) {
        component.set('v.showForm', false);
    }, 


    submitButtonControl : function(component,event,helper){
        console.log('++submitButtonControl', event.getParam('disabled'))
        let submitButton = component.find('submitBtn');

        event.getParam('disabled') ? submitButton.set('v.disabled', true) : submitButton.set('v.disabled', false);

    },
    // Handle bank account selection change
    handleBankAccountChange: function(component, event, helper) {
        // If changing to international bank account, set default payment type to International Wire
        if (event.getParam('value') && !event.getParam('oldValue')) {
            component.find('formLWC').setPaymentTypeInternational();
        }
    }, 

    // Save new Case record
    save: function(component, event, helper) {
        component.set('v.isSaving', true);

        // Validate esign checkbox
        const isEsignValid = component.find('eSignatureComp').eSignatureFieldValidation();

        // Validate bank account
        const bankAccount = component.get('v.case').Bank_Account__c;
        const bankingInfoCmp = component.find('bankingInformationComp');
        if (bankingInfoCmp) {
            bankingInfoCmp.bankingInformationValidation();
        }

        // Save Case
        //component.find('formLWC').saveCase(bankAccount, isEsignValid);
        component.find('formLWC').requestThreatMetrixScore(bankAccount, isEsignValid) 
    },

    // Close window after save
    closeFormWindow: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    }, 

    // Spinner visibility during record save
    toggleSavingSpinner: function(component, event, helper) {
        component.set('v.isSaving', event.getParam('isSaving'));
    }

    //toggleSavingSpinner: function(component, event, handler) {
	//	component.set('v.isSaving', !component.get('v.isSaving'));
	//}
});