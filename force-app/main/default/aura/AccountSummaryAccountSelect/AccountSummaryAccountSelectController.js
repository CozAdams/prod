({
    getAccountSummaries: function(component, event, helper) {
        helper.getAccountSummaries(component, event, helper);
    },

    handleAccountSelectValidation: function(component, event, helper) {
        let isValid = true;
        let accountSummarySelectField = component.find('accountSummarySelect');

        if(accountSummarySelectField.get('v.value') === '') {
            isValid = false;
            $A.util.addClass(accountSummarySelectField, 'slds-has-error');
        } else {
            $A.util.removeClass(accountSummarySelectField, 'slds-has-error');
        }
        return isValid;
    },

    handleSelectionChange : function(component, event){
        console.log('+++handleSelectionChange value isss: ',  event.getSource().get("v.value"))
        if(  event.getSource().get("v.value") == "new403b"){
             component.set('v.show403bForm', true);
        }else{
            component.set('v.show403bForm', false);
            component.set('v.case.Account_Summary_To_Deposit_To__c',   event.getSource().get("v.value"))
        }
    }
})