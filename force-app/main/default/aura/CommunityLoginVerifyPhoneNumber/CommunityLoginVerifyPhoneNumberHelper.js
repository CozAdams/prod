({
    PREFER_PHONE : {
        'Home' : 'HomePhone',
        'Work' : 'npe01__WorkPhone__c', 
        'Mobile' : 'MobilePhone',
        'Other' : 'OtherPhone'
    },
    checkIfValid : function(component) {
        var allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        component.set('v.hasValidationErrors', !allValid);
        return allValid;
    },
    fetchData : function(component) {
        let action = component.get('c.retrieveISOandCountryCode');
        action.setCallback(this, function(response){
            const state = response.getState();
            if (state === 'SUCCESS') {
                let info = response.getReturnValue();
                let codeMap = info['isoToCountryCodeMap'];

                this.setPhoneList(component, info['contact']);

                let isoCodeList = [];
                for(let key in codeMap) {
                    isoCodeList.push(key);
                }
                component.set('v.isoToCountryCodeMap', codeMap);
                component.set('v.isoCodeList', isoCodeList);
                component.set('v.isoCode', 'United States');

                this.renderCountryCodes(component);
            }
            else if (state === 'ERROR') {
                const errors = response.getError();
                const errorMessage = (errors && errors[0] && errors[0].message)? errors[0].message : 'Unknown error occured';
                component.set('v.errorMessage', errorMessage);
            }
            component.set('v.isLoading', false);
        });
        $A.enqueueAction(action);
    },
    setPhoneList : function(component, contact) {
        let phoneMap = new Array();
        Object.keys(contact).forEach(phoneType =>{
            if(phoneType !== 'Id' && contact[phoneType]) {
                const phoneNumber = contact[phoneType].replace(/[- )(]/g, "");
                const phoneMask = phoneNumber.slice(0, -4).replace(/\d{1}/g, "X") + phoneNumber.slice(-4);
                if(phoneType === 'MobilePhone') {
                    phoneMap.unshift({mask : phoneMask, actual : phoneNumber});
                } else {
                    phoneMap.push({mask : phoneMask, actual : phoneNumber});
                }
            }
        });
        component.set('v.phoneList', phoneMap);
    },
    navigationToNext : function(component) {
        let navigate = component.get('v.navigateFlow');
        navigate('NEXT');
    },
    renderCountryCodes : function(component) {
        let isoCode = component.get('v.isoCode');
        component.set('v.countryCodeList', component.get('v.isoToCountryCodeMap')[isoCode]);
        component.set('v.countryCode', component.get('v.isoToCountryCodeMap')[isoCode][0]);
    }

})