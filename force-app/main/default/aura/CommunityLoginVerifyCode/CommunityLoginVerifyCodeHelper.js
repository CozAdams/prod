({
    checkIfValid : function(component) {
        let isValid = component.find('field').get('v.validity').valid;
        component.set('v.hasValidationErrors', !isValid);
        return isValid;
    },
    
    twilioVerifyCode: function(component) {
        let countryCode = component.get('v.countryCode');
        let phoneNumber = component.get('v.phoneNumber');
        let email = component.get('v.email');
        let verificationCode = component.get('v.verificationCode');
        let twilioId = component.get('v.twilioId');
        
        let action = component.get('c.confirmVerificationCode');
        action.setParams({countryCode, phoneNumber, email, verificationCode, twilioId});
        action.setCallback(this, function(response){
            const state = response.getState();
            if (state === 'SUCCESS') {
                let twilioResponse = JSON.parse(response.getReturnValue());
                if(twilioResponse.success) {
                    if(twilioResponse.user && twilioResponse.user.id) {
                        component.set('v.twilioId', twilioResponse.user.id.toString());
                    }
                    let navigate = component.get("v.navigateFlow");
                    navigate("NEXT");
                } else {
                    component.set('v.errorMessage', twilioResponse.message.replace('Token', 'Security Code'));
                }
            }
            else if (state === 'ERROR') {
                let errors = response.getError();
                const errorMessage = (errors && errors[0] && errors[0].message)? errors[0].message : 'Unknown error occured';
                component.set('v.errorMessage', errorMessage);
            }
        });
        $A.enqueueAction(action);
    }
})