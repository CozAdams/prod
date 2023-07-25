({
    TwilioAPICallout : function(component, via) {
        let action = component.get('c.getVerificationCode');
        let countryCode = component.get('v.countryCode');
        let phoneNumber = component.get('v.phoneNumber');
        let twilioId = component.get('v.twilioId');
        action.setParams({countryCode, phoneNumber, twilioId, via});
        action.setCallback(this, function(response){
            const state = response.getState();
            if (state === 'SUCCESS') {
                let twilioResponse = JSON.parse(response.getReturnValue());
                if(twilioResponse.success) {
                    let navigate = component.get('v.navigateFlow');
                    navigate("NEXT");
                } else {
                    component.set('v.errorMessage', twilioResponse.message.replace('SMS', 'text'));
                }
            }
            else if (state === 'ERROR') {
                const errors = response.getError();
                const errorMessage = (errors && errors[0] && errors[0].message)? errors[0].message : 'Unknown error occured';
                component.set('v.errorMessage', errorMessage);
            }
        });
        $A.enqueueAction(action);
    }
})