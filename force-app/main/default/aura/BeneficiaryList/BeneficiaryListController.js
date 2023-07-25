({
    doInit : function(component, event, helper) {
        //determine navigation visibility
        let availableActions = component.get('v.availableActions');
        for (let i = 0; i < availableActions.length; i++) {
             if (availableActions[i] == "PAUSE") {
                component.set("v.canPause", true);
             } else if (availableActions[i] == "BACK") {
                component.set("v.canBack", true);
             } else if (availableActions[i] == "NEXT") {
                component.set("v.canNext", true);
             } else if (availableActions[i] == "FINISH") {
                component.set("v.canFinish", true);
             }
        }
        helper.getAccountSummary(component);
        helper.getBeneficiaries(component);
        helper.setPicklistOptions(component, "Beneficiary__c", "Beneficiary_Type__c", "typeOptions");
    },

    handleEditBeneficiary : function(component, event, helper){
        let beneficiaries = component.get("v.beneficiaries");
        let selectedId = event.getSource().get("v.value");
        for(let i=0; i<beneficiaries.length; i++){
            let ben = beneficiaries[i];
            if(ben.id == selectedId ){
                component.set("v.selectedBeneficiary", ben);
                break;
            }
        }
        let modal = component.find("editModal");
        modal.openModal();
    },

    handleAddBeneficiary : function(component, event, helper){
        let modal = component.find("addModal");
        modal.openModal();
    },

    handleBeneficiaryChanged : function(component, event, helper){
        console.log(' Beneficiary changed:'+event.getParam("beneficiary").contact.FirstName);
        let beneficiaries = component.get("v.beneficiaries");
//        let newBen = event.getParam("beneficiary");

        if(event.getParam("isNew")){
//            let newBeneficiariesList = [];
//            for(let i=0; i<beneficiaries.length; i++){
//                let ben = beneficiaries[i];
//                if(changedBen.id === ben.id){
//                    newBeneficiariesList.push(changedBen);
//                }else{
//                    newBeneficiariesList.push(ben);
//                }
//            }
//            beneficiaries = newBeneficiariesList;
//        }else{
            beneficiaries.push(event.getParam("beneficiary"));
        }
        component.set("v.beneficiaries",beneficiaries);
        helper.validatePercentage(component, beneficiaries);
    },

    onPercentageChange : function(component, event, helper){
        helper.validatePercentage(component, component.get("v.beneficiaries"));
    },

    onNavButtonPressed: function(component, event, helper) {
        let actionClicked = event.getSource().getLocalId();
        console.log(event)
        if(actionClicked != 'BACK'){
            helper.save(component, actionClicked);
        }else{
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": "/update-beneficiaries"
            });
            urlEvent.fire();
            // let navigate = component.get('v.navigateFlow');
            // navigate(actionClicked);
        }

    },
})