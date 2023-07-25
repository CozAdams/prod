({
    verify : function(component, event, helper) {
        if(helper.checkIfValid(component)) {
            helper.twilioVerifyCode(component);
        }
    },

    resend : function(component, event, helper) {
        let navigate = component.get("v.navigateFlow");
        navigate("BACK");
    }
})