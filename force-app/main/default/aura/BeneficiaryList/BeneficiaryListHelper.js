({
    getAccountSummary : function(component){
        let action = component.get("c.getAccountSummaryById");
        action.setParams({ summaryId : component.get("v.accountSummaryId") });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let accountSummary =  response.getReturnValue();
                component.set("v.accountNumber",accountSummary.Account_Number__c);
                component.set("v.accountMemberId",accountSummary.Member_Name__c);
                component.set("v.accountType",accountSummary.Account_Type__c);
            }else if (state === "ERROR") {
                component.set("v.showSaveError", true);
            }
        });

        $A.enqueueAction(action);
    },

    getBeneficiaries : function(component){
        let action = component.get("c.getBeneficiariesBySummaryId");
        action.setParams({ summaryId : component.get("v.accountSummaryId") });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
               console.log("success");
                let beneficiaries =  response.getReturnValue();

                for(let i=0; i<beneficiaries.length; i++){
                    let ben = beneficiaries[i];
                    if(!ben.beneficiary.Beneficiary_Percentage__c){
                        ben.beneficiary.Beneficiary_Percentage__c = 0;
                    }
                }
                console.log('beneficiaries2:'+beneficiaries);
                component.set("v.beneficiaries",beneficiaries);
            }else if (state === "ERROR") {
                component.set("v.showSaveError", true);
            }
        });

        $A.enqueueAction(action);
    },

    setPicklistOptions : function(component, objectName, fieldName, optionsAttribute) {
        let action = component.get("c.getPicklistOptions");
        action.setParams({
            "objectName": objectName,
            "fieldName": fieldName
        });
        let opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                let types = response.getReturnValue();

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

    validatePercentage : function(component, beneficiaries){
        let types  = {};
        let errors = [];
        const accountType = component.get('v.accountType');
        for (let i = 0; i < beneficiaries.length; i++) {
            let rec = beneficiaries[i];
            if(rec){
                let type = rec.beneficiary.Beneficiary_Type__c;
                let percent = rec.beneficiary.Beneficiary_Percentage__c ? Number(rec.beneficiary.Beneficiary_Percentage__c) : 0;
                let relationship = rec.relationship.npe4__Type__c;
                if(type == 'Primary' && percent != 100 || (accountType.includes("Pension") && relationship != 'Spouse')){
                    let primaryBeneficiaryError = $A.get("$Label.c.Primary_Beneficiary_Type_Invalid");
                    errors.push(primaryBeneficiaryError);
                }
                if(types.hasOwnProperty(type)){
                    types[type] += percent;
                }else{
                    types[type] = percent;
                }
            }
        }


        for(let key in types){
            if(types[key] != 100){
                let msg = "The total percentage of all "+key+" Beneficiaries is "+types[key]+"%. It must equal 100%.";
                errors.push(msg);
            }
        }


        component.set("v.percentageErrors", errors);
        component.set("v.hasPercentageError", errors.length > 0);

    },

    save : function(component, actionClicked){
        const allBeneficiaries = component.get("v.beneficiaries")
        let totalPrimaryPercent = 0;
        let totalContingentPercent = 0;
        let contingentExists = false;
        let currentBeneficiary;
        for (let i = 0; i < allBeneficiaries.length; i++) {
            currentBeneficiary = allBeneficiaries[i].beneficiary;
            totalPrimaryPercent += currentBeneficiary.Beneficiary_Type__c == 'Primary' ?  Number(currentBeneficiary.Beneficiary_Percentage__c) : 0;
            if (currentBeneficiary.Beneficiary_Type__c == 'Contingent') {
                totalContingentPercent += Number(currentBeneficiary.Beneficiary_Percentage__c);
                contingentExists = true;
            }
        }
        if (totalPrimaryPercent != 100 || (totalContingentPercent != 100 && contingentExists)) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error!',
                message:'The total percentage for all Primary Beneficiaries and Contingent Benficiaries (if there are any) must add up to 100% each!',
                duration:' 5000',
                type: 'error',
            });
            toastEvent.fire();
            return;
        }

        component.set("v.isSaving", true);
        let action = component.get("c.saveBeneficiaries");
        action.setParams({
            "accountSummaryId":component.get("v.accountSummaryId"),
            "beneficiaries": JSON.stringify(component.get("v.beneficiaries"))
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
            // Fire the navigation action
            let navigate = component.get('v.navigateFlow');
            navigate(actionClicked);

            }else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                component.set("v.saveErrorDetails", errors[0].message);
                    message = errors[0].message;
                }
                component.set("v.showSaveError", true);
                component.set("v.isSaving",false);

            }
        });
        $A.enqueueAction(action);
    }
})