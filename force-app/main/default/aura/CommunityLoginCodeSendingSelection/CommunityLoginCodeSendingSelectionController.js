({
    doInit : function(component, event, helper) {
        const phoneNumber = component.get('v.phoneNumber');
        if(!$A.util.isEmpty(phoneNumber)) {
            let firstChunk = phoneNumber.slice(0, -3).replace(/\d{1}/g, "X");
            component.set('v.hiddenPhoneDisplay', firstChunk + phoneNumber.slice(-3));
        }
    },
    handleMessageSend : function(component, event, helper) {
        let via = event.getSource().getLocalId();
        helper.TwilioAPICallout(component, via);
    },
    goBack : function(component, event, helper) {
        let navigate = component.get('v.navigateFlow');
        navigate('BACK');
    }
})