({
    getAccountSummaries: function(component, event, helper) {

        component.set('v.TDRA_ACC_TYPE',$A.get("$Label.c.TDRA_Plan_Id") )
        const currentAccountSummary = component.get('v.currentAccountSummary');

        let action = component.get('c.getAccountSummaryList');
        
        action.setParams({'contactId' : component.get('v.currentUser.ContactId'),
                'currentAccount': currentAccountSummary});
        // action.setParams({'contactId' : component.get('v.currentUser.ContactId'),
        //         'accountSummaryType': component.get('v.currentAccountSummary.Account_Type__c'),
        //         'currentAccountSummaryId': component.get('v.currentAccountSummary.Id')});

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === 'SUCCESS'){


                if(currentAccountSummary.Account_Desc__c && currentAccountSummary.Account_Desc__c.includes('Rollover') && currentAccountSummary.Plan_ID__c == $A.get("$Label.c.TDRA_Plan_Id")){
                    component.set('v.accountSummaryList', []);

                }else{
                    component.set('v.accountSummaryList', response.getReturnValue());

                }

                

                this.setMatchingAccountFlag(component);
            } 
            else if(state === 'ERROR') {
                component.find('accountSummaryAccountSelectNotifications').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving account summary list.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();
            }
        });
        $A.enqueueAction(action);
    }, 
    // Set matching account attribute for error message and form functionality
    setMatchingAccountFlag: function(component) {
        const acctSummaryDesc = component.get('v.currentAccountSummary').Account_Desc__c;
        const accountSummaries = component.get('v.accountSummaryList');
        const isTDRA = component.get('v.currentAccountSummary').Plan_ID__c == $A.get("$Label.c.TDRA_Plan_Id")

        // Check for matching accounts based on product type and description
        let hasMatch = true;

        if (accountSummaries.length == 0 && !isTDRA) {
            hasMatch = false;
        }else{
            const match = accountSummaries.find(acctSummary => acctSummary.Account_Desc__c == acctSummaryDesc);
            if (match == undefined && !isTDRA) {
                hasMatch = false;
            }
        }
        component.set('v.hasMatchingAccount', hasMatch);
    }
})