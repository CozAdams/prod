({
	doInit: function(component, event, helper) {
		helper.getCurrentContact(component);
		let picklistService = component.find('picklistService');
        picklistService.getEntries('bnk_Bank__c', 'Checking_or_Savings__c', entries => {
            component.set('v.checkingOrSavingsOptions', entries);
        });
		component.set('v.newBankAccount.Checking_or_Savings__c', 'Checking');
		
		picklistService.getEntries('bnk_Bank__c', 'Bank_Account_Country__c', entries => {
			component.set('v.bankCountryOptions', entries);
		})
		component.set('v.newBankAccount.Bank_Account_Country__c', 'US');
        helper.getStateList(component);
            var isProfile = component.get("v.isProfile");
            
            if(component.get('v.selectedBankAccountId') == 'New') {
                    // Open Add Bank Account on component load
                    var newBankAccount = {
                    'sObjectType':'bnk_Bank__c', 
                    'Checking_or_Savings__c': 'Checking',
					'bnk_Account_Number__c' : '',
                    'Bank_Account_Country__c': 'US', 
            		'bnk_Is_Active__c': isProfile ? false : true, 
                    'bnk_Account_Holder_Name__c': component.get('v.contactId')
                };                                   
                component.set('v.newBankAccount', newBankAccount);
                component.set('v.selectedBankAccountId', null);
                helper.createBankAccount(component);
        	}
    
    	helper.showModal(component);
	},

	retrieveStatesIfAny: function(component, event, helper) {
		helper.getStateList(component);
	},

	onchangeAccountNumber: function(component, event, helper) {
		helper.checkBankAccountNumber(component, event, helper);
	},

	saveNewBankAccount : function(component, event, helper) {
		console.log('IN');
		//SE-2907 JS Add spinner
		helper.toggle(component, 'spinner');
		helper.checkBankAccountNumber(component, event, helper);
		var isProfile = component.get("v.isProfile");

		let formFields = component.find('bankAccountField');
        
		var isFormValid = formFields.reduce(function (validSoFar, formField) {
			console.log('formField ' + formField);

			//SE-2907 rearrange validation
			if ($A.util.isEmpty(formField.get('v.value'))) {
				formField.setCustomValidity('This field is required!');
				formField.reportValidity();
				$A.util.addClass(formField, 'slds-has-error');
			}
			else {
				//reset form
				formField.setCustomValidity('');
				formField.reportValidity(); 
				$A.util.removeClass(formField, 'slds-has-error');
			}

			let isFieldValid = formField.checkValidity();
			formField.reportValidity();
			//SE-2907 rearrange validation

			return validSoFar && isFieldValid;
		}, true);

		var acconutNumberValid = component.get("v.isValid");
		
		console.log('isFormValid ' + isFormValid + ' ' + acconutNumberValid);
		console.log('isProfile ' + isProfile);
        if (isFormValid && acconutNumberValid) {
			//JS SE-2924 Utilize component on Flow
			if(!isProfile)
            	helper.saveBankAccount(component);
			else {
				//JS SE-2724 Pass blank Routing Number if Country is not US
				var bnk = component.get('v.newBankAccount');

				if(bnk.bnk_Routing_Number__c == null && bnk.Bank_Account_Country__c != 'US') {
					bnk.bnk_Routing_Number__c = '';
				}
				
				component.set('v.newBankAccount', bnk);
				//JS SE-2724

				var navigate = component.get("v.navigateFlow");
				navigate("NEXT");
			}
			//JS SE-2924
		} else {
            component.find('bankingInformationNotifications').showToast({
                'title': 'Error!',
                'variant': 'error',
                'message': 'Please resolve the errors on the form',
				'mode': 'sticky'
            });

			//SE-2907 JS Add spinner
			helper.toggle(component, 'spinner');
        }
	},

	closeModal : function(component, event, helper) {
		let modal = component.find('modal');
		for(let i = 0; i < modal.length; i++) {
			if($A.util.hasClass(modal[i], 'slds-backdrop')){
				$A.util.addClass(modal[i], 'slds-backdrop_close');
				$A.util.removeClass(modal[i], 'slds-backdrop_open');
			} else if($A.util.hasClass(modal[i], 'slds-modal')) {
				$A.util.addClass(modal[i], 'slds-fade-in-close');
				$A.util.removeClass(modal[i], 'slds-fade-in-open');
			}
		}
        
        if(component.get('v.isProfile') == true) {
            var navigate = component.get("v.navigateFlow");
          	navigate("BACK");
        }
        else if(component.get('v.flowAutoNext') == true) { 
            var navigate = component.get("v.navigateFlow");
          	navigate("NEXT");
        }
	},

	handleBankingInformationValidation: function(component, event, helper) {
        let bankingSelectField = component.find('selectBankNumber');

        let errorMsg = '';
        if(bankingSelectField.get('v.value') === '') {
            $A.util.addClass(bankingSelectField, 'slds-has-error');
            errorMsg = 'Please fill out all required fields on the form';
        } else {
        	let bankAccountId = bankingSelectField.get('v.value');
        	let bankAccounts = component.get('v.bankAccounts');
        	let isBankDomestic = false;

        	for (let i = 0; i < bankAccounts.length; i++) {
        		if(bankAccounts[i].Id === bankAccountId) {
					if (bankAccounts[i].Bank_Account_Country__c === 'US') {
						isBankDomestic = true;
					}
					break;
				}
			}
        	if(component.get('v.case.Distribution_Payment_Type__c') === 'Domestic Wire' && !isBankDomestic) {
				errorMsg = 'The bank you selected for a Domestic Wire transfer is an International bank account. Please select a Domestic account.';
				$A.util.addClass(bankingSelectField, 'slds-has-error');
			} else if (component.get('v.case.Distribution_Payment_Type__c') === 'International Wire' && isBankDomestic) {
				errorMsg = 'The bank you selected for an International Wire transfer is a Domestic bank account. Please select an International account.';
				$A.util.addClass(bankingSelectField, 'slds-has-error');
        	} else {
				$A.util.removeClass(bankingSelectField, 'slds-has-error');
			}
		}
        return errorMsg;
	},
	setBankOnObject: function(component, event, helper) {
		const bankAccountSelection = component.get('v.selectedBankAccountId');
        
		// If user selects add new account, open create modal
		if (bankAccountSelection == 'New') {
			// Refresh bank account information to default only
			var newBankAccount = {
				'sObjectType':'bnk_Bank__c', 
				'Checking_or_Savings__c': 'Checking', 
				'Bank_Account_Country__c': 'US', 
				'bnk_Is_Active__c': true, 
                'bnk_Account_Holder_Name__c': component.get('v.currentContact').Id
			};
			component.set('v.newBankAccount', newBankAccount);
			component.set('v.selectedBankAccountId', null);
			helper.createBankAccount(component);
		}
		// Otherwise, set the bank account on the object
		else {
			let sobject = component.get('v.targetObject');
			if (sobject != null) {
				sobject[component.get('v.targetField')] = component.get('v.selectedBankAccountId');
			}
		}

		// Set country type of selected account for other form dependencies
		helper.setSelectedCountryType(component);
	}
});