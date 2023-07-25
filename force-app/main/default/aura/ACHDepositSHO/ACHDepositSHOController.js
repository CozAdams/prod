({
    doInit :function(component, event, helper){
        helper.getAccountSummary(component);
    },

    closeModal : function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },

	next : function(component, event, helper) {
        component.set('v.showDeposit', true);

        if(component.get('v.paymentType') === 'recurring' )
		    component.set('v.showRecurring', true);

        component.find("show1").forEach(
            a => $A.util.addClass(a, "slds-hide")
        );
        component.find("show1").forEach(
            a => $A.util.removeClass(a, "slds-show")
        );
	}
})