({
    // Retrieve Case record type ID
    getCaseRecordTypeId : function(component) {
        let action = component.get('c.getCaseRecordType');
        
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let caseObj = component.get('v.case');
                caseObj.RecordTypeId = response.getReturnValue();
                component.set('v.case', caseObj);
            } else if(state === 'ERROR') {
                component.find('withdrawNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions case record type',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    // Set esignature message based on account type
    setEsignMessage: function(component) {
        let accountPlanId = component.get('v.accountPlanId');
        let esignMessage;
        const PREFIX = 'By signing this Application, I make the following certifications:<br /><ul>';
        const SUFFIX = '</ul>';

        switch(accountPlanId) {
            case '403BTRAD':
            case '403BTRADPR':
            case '403BROTH':
            //case '457(b) Deferred Compensation Plan':
            case '457BPLAN':

                esignMessage = PREFIX + 
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_TDRA_E_Signature_Message_1') + '</li>' + 
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_TDRA_E_Signature_Message_2') + '</li>' +
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_TDRA_E_Signature_Message_3') + '</li>' + 
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_TDRA_E_Signature_Message_4') + '</li>' +
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_TDRA_E_Signature_Message_5') + '</li>' +
                    SUFFIX;
                break;
            case 'IRATRAD':
            case 'IRALEG':
                esignMessage = PREFIX + 
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_Traditional_IRA_E_Signature_Message_1') + '</li>' + 
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_Traditional_IRA_E_Signature_Message_2') + '</li>' +
                    '<li>' + $A.get('$Label.c.OT_Withdrawal_Traditional_IRA_E_Signature_Message_3') + '</li>' +
                    SUFFIX;
                break;
            case 'IRAROTH':
                esignMessage = PREFIX + 
                '<li>' + $A.get("$Label.c.OT_Withdrawal_ROTH_E_Signature_Message_3") + '</li>' + 
                '<li>' + $A.get("$Label.c.OT_Withdrawal_ROTH_E_Signature_Message_4") + '</li>' + 
                SUFFIX;
                break;
            case 'BENACC':
                esignMessage = $A.get('$Label.c.OT_Withdrawal_BAA_E_Signature_Message');
                break;
        }
        component.set('v.eSignature', esignMessage);
    }
});