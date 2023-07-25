({
    doInit : function(component, event, helper) {
        helper.fetchData(component);
    },
    navigationToNextPage : function(component, event, helper) {
        if(helper.checkIfValid(component)) {
            helper.navigationToNext(component);
        }
    },
    updateCountryCodeSelection : function(component, event, helper) {
        helper.renderCountryCodes(component);
    }
})