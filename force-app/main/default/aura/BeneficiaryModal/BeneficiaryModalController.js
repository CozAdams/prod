({
    doInit: function(component, event, helper) {
        helper.setPicklistOptions(component, "npe4__Relationship__c", "npe4__Type__c", "relationshipOptions");
        helper.setPicklistOptions(component, "Beneficiary__c", "Beneficiary_Type__c", "beneficiaryTypeOptions");
    },

    showModal : function(component, event, helper) {
        let summaryId = component.get("v.accountSummaryId");
        let accountMemberId = component.get("v.accountMemberId");
        let ben;

        if(summaryId){
            let newId = new Date().getTime().toString();
            ben =  {
                "id":newId,
                "beneficiary":{"Beneficiary_Percentage__c":0, "Account_Summary__c":summaryId},
                "contact":{},
                "relationship":{ "npe4__Contact__c":accountMemberId}
            };
            component.set("v.modalTitle", "New Beneficiary");
            component.set("v.isNew", true);
        }else{
            ben = component.get("v.beneficiary");
            component.set("v.isNew", false);
            component.set("v.modalTitle", "Edit Beneficiary");
        }


        let formFields = {};
        formFields.firstName = ben.contact.FirstName;
        formFields.lastName = ben.contact.LastName;
        formFields.birthdate = ben.contact.Birthdate;
        formFields.phone = ben.contact.Phone;
        formFields.relationshipType = ben.relationship.npe4__Type__c;
        formFields.beneficiaryType = ben.beneficiary.Beneficiary_Type__c;
        formFields.beneficiaryPercentage = ben.beneficiary.Beneficiary_Percentage__c;
        formFields.socialSecurityNumber = ben.contact.Social_Security_Number__c;
        formFields.mailingStreet = ben.contact.MailingStreet;
        formFields.mailingCity = ben.contact.MailingCity;
        formFields.mailingState = ben.contact.MailingState;
        formFields.mailingPostalCode = ben.contact.MailingPostalCode;
        formFields.mailingCountry = ben.contact.MailingCountry;
        formFields.otherStreet = ben.contact.OtherStreet;
        formFields.otherCity = ben.contact.OtherCity;
        formFields.otherState = ben.contact.OtherState;
        formFields.otherPostalCode = ben.contact.OtherPostalCode;
        formFields.otherCountry = ben.contact.OtherCountry;
        component.set("v.formFields",formFields);
        component.set("v.beneficiary", ben);
        component.set("v.saveError","");
        helper.toggleModalState(component);
    },

    hideModal : function(component, event, helper){
        helper.toggleModalState(component);
    },

    handleSave : function(component, event, helper){
        let isFormValid = component.find("beneficiaryAddForm").reduce(function (validSoFar, inputCmp) {
                    // Displays error messages for invalid fields
                    return validSoFar && inputCmp.get("v.validity").valid;
                }, true);
        if(!isFormValid){
            component.set("v.saveError", "Please fill out all required fields.");
        }else{

            let formFields = component.get("v.formFields");
            let ben = component.get("v.beneficiary");
            ben.contact.FirstName = formFields.firstName;
            ben.contact.LastName = formFields.lastName;
            ben.contact.Birthdate = formFields.birthdate;
            ben.contact.Phone = formFields.phone;
            ben.relationship.npe4__Type__c = formFields.relationshipType;
            ben.beneficiary.Beneficiary_Type__c = formFields.beneficiaryType;
            ben.beneficiary.Beneficiary_Percentage__c = formFields.beneficiaryPercentage;
            ben.contact.Social_Security_Number__c = formFields.socialSecurityNumber;
            ben.contact.MailingStreet = formFields.mailingStreet;
            ben.contact.MailingCity = formFields.mailingCity;
            ben.contact.MailingState = formFields.mailingState;
            ben.contact.MailingPostalCode = formFields.mailingPostalCode;
            ben.contact.MailingCountry = formFields.mailingCountry;
            ben.contact.OtherStreet = formFields.otherStreet;
            ben.contact.OtherCity = formFields.otherCity;
            ben.contact.OtherState = formFields.otherState;
            ben.contact.OtherPostalCode = formFields.otherPostalCode;
            ben.contact.OtherCountry = formFields.otherCountry;

            helper.toggleModalState(component);
            let evt = component.getEvent("beneficiaryChanged");
            evt.setParams({"beneficiary": ben, "isNew": component.get("v.isNew")});
            evt.fire();
        }
    },

})