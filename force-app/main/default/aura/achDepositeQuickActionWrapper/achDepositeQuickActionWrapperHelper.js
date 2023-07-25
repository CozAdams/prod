({
    getAccountSummary : function(component) {
		let action = component.get('c.getAccountSummary');
		action.setParams({'accountSummaryId' : component.get('v.recordId')});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                // Load form on success
                let newAccountSummary = response.getReturnValue();
                component.set('v.accountSummary', newAccountSummary);
            } 
            else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the account summary.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
	}
})