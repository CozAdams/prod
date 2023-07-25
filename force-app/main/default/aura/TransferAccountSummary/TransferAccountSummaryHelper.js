({
    getAccountSummary : function(component) {
        let action = component.get('c.getAccountSummary');
        action.setParams({'accountSummaryId' : component.get('v.recordId')});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let accountSummary = response.getReturnValue();
                let accountPlanId = accountSummary.Plan_ID__c;
                component.set('v.accountSummary', accountSummary);
                console.log('+++accountSummary' , JSON.parse(JSON.stringify(accountSummary)));

                console.log('+++ba plan Id ' ,  $A.get("$Label.c.BAA_Plan_Id") , component.get('v.BAA_ACC_TYPE'),accountPlanId );
                switch(accountPlanId) {
                    case component.get('v.BAA_ACC_TYPE'):
                        component.set('v.descriptionHeader', $A.get("$Label.c.OT_Transfer_BAA_E_Signature_Message"));
                        component.set('v.eSignature', $A.get("$Label.c.OT_Transfer_BAA_E_Signature_Message_1")); //reusing same message
                        break;
                    case component.get('v.TDRA_ACC_TYPE'):
                    case component.get('v.TDRA_PR_ACC_TYPE'):
                        component.set('v.descriptionHeader', $A.get("$Label.c.OT_Transfer_TDRA_Top_Header"));
                        component.set('v.eSignature', $A.get("$Label.c.OT_Transfer_TDRA_E_Signature_Message"));
                        break;
                    case component.get('v.IRA_ACC_TYPE'):
                        component.set('v.descriptionHeader', $A.get("$Label.c.OT_Transfer_Traditional_IRA_Top_Header"));
                        component.set('v.eSignature', $A.get("$Label.c.OT_Transfer_Traditional_IRA_E_Signature_Message"));
                        break;
                    case component.get('v.ROTH_ACC_TYPE'):
                        component.set('v.descriptionHeader', $A.get("$Label.c.OT_Transfer_Roth_IRA_Top_Header"));
                        component.set('v.eSignature', $A.get("$Label.c.OT_Transfer_Roth_IRA_E_Signature_Message"));
                        break;
                    case component.get('v.LEGACY_ACC_TYPE'):
                        component.set('v.descriptionHeader', $A.get("$Label.c.OT_Transfer_Legacy_IRA_Top_Header"));
                        component.set('v.eSignature', $A.get("$Label.c.OT_Transfer_Legacy_IRA_E_Signature_Message"));
                        break;
                }
            } else if(state === 'ERROR') {
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the account summary.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    getCurrentUser : function(component) {
        let action = component.get('c.getUser');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.currentUser', response.getReturnValue());
                let childCmp = component.find('accountSelect');
                childCmp.getAccountSummaries(component);
            } else if(state === 'ERROR') {
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the current User.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    getCaseQueueId : function(component) {
        let action = component.get('c.getCaseQueue');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.caseQueueId', response.getReturnValue());
            } else if(state === 'ERROR') {
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions Queue Id.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    getCaseRecordTypeId : function(component) {
        let action = component.get('c.getCaseRecordType');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.caseRecordTypeId', response.getReturnValue());
            } else if(state === 'ERROR') {
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions case record type',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    saveCase : function(component) {
        let currentCase = component.get('v.case');
        let accountSummary = component.get('v.accountSummary');

        if (currentCase.Transfer_BAA_Options__c === 'Close') {
            currentCase.Transfer_Amount__c = accountSummary.Balance__c;
        }
        currentCase.Origin = 'MemberPortal';
        currentCase.OwnerId = component.get('v.caseQueueId');
        currentCase.RecordTypeId = component.get('v.caseRecordTypeId');
        currentCase.Account_Summary__c = accountSummary.Id;
        currentCase.ContactId = component.get('v.currentUser').ContactId;
        currentCase.Portal_Transaction_Type__c = 'Internal Transfer';

        let action = component.get('c.saveCase');
        action.setParams({currentCase});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Success!',
                    'variant': 'success',
                    'message': 'Request has been received.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();

            } else if(state === 'ERROR') {
                component.find('transferNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': response.getError(),
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    }
})