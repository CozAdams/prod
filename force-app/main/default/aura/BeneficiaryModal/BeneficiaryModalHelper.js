({
    toggleModalState : function(component){
        var modal = component.find('modalContainer');
        var backdrop = component.find('modalBackdrop');
        $A.util.toggleClass(backdrop,'slds-backdrop--open');
        $A.util.toggleClass(backdrop,'slds-backdrop--hide');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(modal, 'slds-fade-in-hide');
    },

    setPicklistOptions : function(component, objectName, fieldName, optionsAttribute) {
        let action = component.get("c.getPicklistOptions");
        action.setParams({
            "objectName": objectName,
            "fieldName": fieldName
        });
        let opts = [{key:"",value:"--None--"}];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                let types = response.getReturnValue();
                console.log(response.getReturnValue());
                for (var key in types) {
                    opts.push({
                        key: key,
                        value: types[key]
                    });
                }
                component.set("v."+optionsAttribute, opts);
            }
        });
        $A.enqueueAction(action);
    },

    doSaveBeneficiary : function(component, contact, relationship, beneficiary){
        component.set("v.isSaving", true);

        let action;

        if(beneficiary.Id){
            action = component.get("c.updateBeneficiary");
        }else{
            action = component.get("c.createBeneficiary");
        }

        action.setParams({
           "cont":contact,
           "relationship":relationship,
           "beneficiary":beneficiary
       })

       action.setCallback(this, function(response) {
            let state = response.getState();
            console.log("state:"+state);
            if (state == "SUCCESS") {
               //fire an event that the beneficiary has changed
               let isNew = beneficiary.Id ? false : true;
               if(isNew){
                    beneficiary = response.getReturnValue();
               }

               let evt = component.getEvent("beneficiaryChanged");
               evt.setParams({"beneficiary": beneficiary,
                              "isNew": isNew});
               evt.fire();

               this.toggleModalState(component);

            }else if (state === "ERROR") {
               let errors = response.getError();
               let message = "Unknown error"; // Default error message
               // Retrieve the error message sent by the server
               if (errors && Array.isArray(errors) && errors.length > 0) {
                   message = errors[0].message;
               }

               // Pass the error message if any
               if (errors && Array.isArray(errors) && errors.length > 0) {
                   component.set("v.saveError", errors[0].message);
               }

            }
            component.set("v.isSaving", false);


        });
        $A.enqueueAction(action);
    },

    populateExistingBeneficiaryData : function(component, beneficiaryId){
        let action = component.get("c.getBeneficiaryInformation");
        action.setParams({
            "beneficiaryId":beneficiaryId
        });

        action.setCallback(this, function(response) {
            //todo:add spinner
            let state = response.getState();
            console.log("state:"+state);
            if (state == "SUCCESS") {
                let result = response.getReturnValue();
                console.log("result:"+result);
                console.log("result.contact:"+result.contact);
                component.set("v.newContact",result.contact);
                component.set("v.newBeneficiary", result.beneficiary);
                component.set("v.newRelationship",result.relationship);
                this.toggleModalState(component);

            }else if (state === "ERROR") {
                let errors = response.getError();
                let message = "Unknown error"; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                 message = errors[0].message;
                }

                // Pass the error message if any
                if (errors && Array.isArray(errors) && errors.length > 0) {
                 component.set("v.saveError", errors[0].message);
                }
            }
        });
        $A.enqueueAction(action);
    },
})