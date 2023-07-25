({
	getBankingInformation : function(component) {
		let action = component.get('c.getBankingInformationList');
		action.setParams({'contactId' : component.get('v.currentContact').Id});

		action.setCallback(this, function(response){
            var isProfile = component.get('v.isProfile'); //JS SFMS-7
            let state = response.getState();
            if(state === 'SUCCESS'){
                let bankAccounts = response.getReturnValue();
                component.set('v.bankAccounts', bankAccounts);
                let bankAccountOptions = bankAccounts.map(bankAcct => {
                    return {
                        label: (bankAcct.Bank_Account_Country__c === 'US' ? 'US' : 'Intl') + "  " + bankAcct.bnk_Bank_Name__c + " - " + bankAcct.bnk_Account_Number__c,
                        value: bankAcct.Id,
                        selected: bankAcct.Id === component.get('v.selectedBankAccountId')
                    }
                });

                //JS SFMS-7 Show Add new account when triggered from Profile
                // Add default options to bank account selection
                if(isProfile == true) {
                    bankAccountOptions.unshift({ value: 'New', label: 'Add new account' });
                }
                //JS SFMS-7

                bankAccountOptions.unshift({ value: '', label: 'Choose from an existing account below:' });
                component.set('v.availableBankAccounts', bankAccountOptions);

                let newBankAccount = component.get('v.newBankAccount');
                newBankAccount.bnk_Is_Active__c = true;
                newBankAccount.bnk_Account_Holder_Name__c = component.get('v.currentContact').Id;
                component.set('v.newBankAccount', newBankAccount);
            } else if(state === 'ERROR') {
                component.find('bankingInformationNotifications').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving banking information.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();
            }
        });
        $A.enqueueAction(action);
	},
    saveBankAccount : function(component) {
        let action = component.get('c.saveBankAccount');
        action.setParams({'newBankAccount' : component.get('v.newBankAccount')});

        action.setCallback(this, function(response){
            var isProfile = component.get('v.isProfile');
            let state = response.getState();
            if(state === 'SUCCESS'){
                let newAccountCountry = component.get('v.newBankAccount').Bank_Account_Country__c;
                component.set('v.selectedBankAccountId', response.getReturnValue());
                this.getBankingInformation(component);
                
                console.log('isProfile ' + component.get('v.isProfile'));
                
                if(isProfile == true) {
                    console.log('IN Flow');

                    //SE-2907 JS show toast
                    component.find('bankingInformationNotifications').showToast({
                        'title': 'Success!',
                        'variant': 'success',
                        'message': 'New bank account created successfully.',
                        'mode': 'sticky'
                    });
                    //SE-2907 JS show toast
                    
                    component.set('v.newBankAccountCreated', component.get('v.newBankAccount'));
                    this.createNewBankAccountCase(component);
                }
                else {

                    // Set ID for withdrawal parent component
                    let targetObject = component.get('v.targetObject');
                    if (targetObject != null) {
                        targetObject.Bank_Account__c = response.getReturnValue();
                        component.set('v.targetObject', targetObject);
                    }
    
                    component.find('bankingInformationNotifications').showToast({
                        'title': 'Success!',
                        'variant': 'success',
                        'message': 'New bank account created successfully.',
                        'mode': 'sticky'
                    });
    
                    let newBankAccount = {'sObjectType':'bnk_Bank__c'};
                    newBankAccount.bnk_Is_Active__c = true;
                    newBankAccount.bnk_Account_Holder_Name__c = component.get('v.currentContact').Id;
                    newBankAccount.Bank_Account_Country__c = 'US';
                    newBankAccount.Checking_or_Savings__c = 'Checking';
                    newBankAccount.Id = response.getReturnValue();
                    component.set('v.newBankAccount', newBankAccount);
                    component.set('v.isSelectedAccountIntl', newAccountCountry != 'US');

                    //SE-2907 JS Add spinner
                    this.toggle(component, 'spinner');

                    $A.enqueueAction(component.get('c.closeModal'));
                }
                

            } else if(state === 'ERROR') {
                component.find('bankingInformationNotifications').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': response.getError()[0].message,
                    'mode': 'sticky'
                });

                //SE-2907 JS Add spinner
                this.toggle(component, 'spinner');
            }
        });
        $A.enqueueAction(action);
    },
    getStateList: function(component) {
        let action = component.get('c.getStates');
        action.setParams({'countryISO' : component.get('v.newBankAccount.Bank_Account_Country__c')});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let stateOptions = [];
                let statesJSON = response.getReturnValue();
                stateOptions.push({'label':'', 'value': ''});
                for (let key in statesJSON) {
                    stateOptions.push({'label': statesJSON[key], 'value': key})
                }
                if (stateOptions.length > 0) {
                    stateOptions.sort(function(a, b) {
                        return a.label.localeCompare(b.label)
                    });
                }
                component.set('v.bankStateOptions', stateOptions);
            } else if(state === 'ERROR') {
                component.find('bankingInformationNotifications').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving states list.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();
            }
        });
        $A.enqueueAction(action);
    },
    getCurrentContact : function(component) {
        let action = component.get('c.getContact');
        action.setParams({'contactId': component.get('v.contactId')});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.currentContact', response.getReturnValue());
                this.getBankingInformation(component);
            } else if(state === 'ERROR') {
                component.find('withdrawNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the current Contact.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    }, 
    setSelectedCountryType: function(component) {
        const selectedAcctId = component.get('v.selectedBankAccountId');
        console.log('selectedAcctId ' + selectedAcctId);
        const bankAccountList = component.get('v.bankAccounts');
        const selectedAccount = bankAccountList.find(acct => acct.Id == selectedAcctId);

        if(selectedAcctId != null) {
            component.set('v.isSelectedAccountIntl', selectedAccount.Bank_Account_Country__c != 'US');
        }
        
    }, 
    createBankAccount : function(component, event, helper) {	
        let modal = component.find('modal');
		for(let i = 0; i < modal.length; i++) {
			if($A.util.hasClass(modal[i], 'slds-backdrop')){
				$A.util.removeClass(modal[i], 'slds-backdrop_close');
				$A.util.addClass(modal[i], 'slds-backdrop_open');
			} else if($A.util.hasClass(modal[i], 'slds-modal')) {
				$A.util.removeClass(modal[i], 'slds-fade-in-close');
				$A.util.addClass(modal[i], 'slds-fade-in-open');
			}
		}
	},
    
    showModal : function(component, event, helper) {
        var isProfile = component.get("v.isProfile");
        let modal = component.find('modal');
        
        if(isProfile) {
            let selection = component.find('selection');
            $A.util.addClass(selection[0], 'slds-hide');
            
            for(let i = 0; i < modal.length; i++) {
                if($A.util.hasClass(modal[i], 'slds-backdrop')){
                    $A.util.removeClass(modal[i], 'slds-backdrop_close');
                    $A.util.addClass(modal[i], 'slds-backdrop_open');
                } else if($A.util.hasClass(modal[i], 'slds-modal')) {
                    $A.util.removeClass(modal[i], 'slds-fade-in-close');
                    $A.util.addClass(modal[i], 'slds-fade-in-open');
                }
            }
        }
    },
    
    createNewBankAccountCase : function(component, event, helper) {
        console.log('IN createNewBankAccountCase');
        let newCase = {'sObjectType':'Case'};
        newCase.AccountId = component.get('v.currentContact').AccountId;
        newCase.Bank_Account__c = component.set('v.selectedBankAccountId');
        newCase.Bank_Name__c = component.get('v.newBankAccount').bnk_Bank_Name__c;
        newCase.ContactId = component.get('v.currentContact').Id;
        newCase.Description = 'Bank Account Created.';
        newCase.Origin = 'MemberPortal';
        newCase.Reason = 'Info Change';
        newCase.Reason_Subcategory__c = 'Bank';
        newCase.Subject = 'Bank Account Created.';
        newCase.Type = 'Other';
        
        console.log('IN createNewBankAccountCase');
        let action = component.get('c.createBankAccountReports');
		action.setParams({'c' : newCase});

		action.setCallback(this, function(response){
            let state = response.getState();
            console.log('State ', state);
            if(state === 'SUCCESS'){
                console.log('NEXT');
                component.set('v.caseId', response.getReturnValue());
                var navigate = component.get("v.navigateFlow");
          		navigate("NEXT");
            } else if(state === 'ERROR') {
                console.log('ERROR ' + response.getError()[0].message);
            }

            //SE-2907 JS Add spinner
            this.toggle(component, 'spinner');
        });
        $A.enqueueAction(action);
    },

    //SE-2907 JS Add spinner
    toggle : function(component, cmpId) {
        console.log('cmp' + cmpId);
        var spinner = component.find(cmpId);
        console.log('spinner ' + spinner);
        $A.util.toggleClass(spinner, "slds-hide");
    },

    checkBankAccountNumber : function(component, event, helper) {
        //var accountNumber = event.getSource().get("v.value");
        console.log('IN checkBankAccountNumber');
		var bankAccount = component.get('v.newBankAccount');
        var accountNumber = '';
        accountNumber = bankAccount.bnk_Account_Number__c;
		var isFormValid = true;
		console.log('accountNumber ' + accountNumber + ' ');

		if(accountNumber != undefined && accountNumber.length < 3) {
			isFormValid = false;
			component.find('bankingInformationNotifications').showToast({
                'title': 'Error!',
                'variant': 'error',
                'message': 'An Account number must be at least 3 digits.',
				'mode': 'sticky'
            });
		}
		component.set("v.isValid", isFormValid);
    }
    //SE-2907 JS Add spinner
});