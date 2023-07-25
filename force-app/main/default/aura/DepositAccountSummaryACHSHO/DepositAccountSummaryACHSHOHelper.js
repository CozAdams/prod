({
	getAccountSummary : function(component) {
		let action = component.get('c.getAccountSummary');
		action.setParams({'accountSummaryId' : component.get('v.recordId')});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                // Load form on success
                let newAccountSummary = response.getReturnValue();
                component.set('v.accountSummary', newAccountSummary);

                if (component.get('v.caseRecordTypeId')) {
                    this.loadForm(component);
                }
            } 
            else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the account summary.',
                    'mode': 'sticky'
                });
                component.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);
	},

    buildCase: function(component) {
        let action = component.get('c.getCaseRecordType');
        
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.case.RecordTypeId', response.getReturnValue());
                component.set('v.caseRecordTypeId', response.getReturnValue());

                if (component.get('v.accountSummary.Account_Type__c')) {
                    this.loadForm(component);
                }
            } else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions case record type',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    }, 

    loadForm: function(component) {
        let accountSummary = component.get('v.accountSummary');
        let accountType = component.get('v.accountSummary.Account_Type__c');
        
        // Get user and case queue info for saving
        this.getCurrentUser(component);
        this.getCaseQueueId(component);

        // Set headers and ESign messages based on account type
        switch(accountType) {
            case component.get('v.PENSION_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Pay_Dues_E_Signature_Agreement_Message"));
                component.set('v.descriptionHeader', $A.get("$Label.c.OT_Deposit_Pension_Plan_Top_Header"));
                break;
            case component.get('v.TDRA_ACC_TYPE'):
            case component.get('v.TDRA_PR_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Deposit_TDRA_E_Signature_Message"));
                component.set('v.descriptionHeader', $A.get("$Label.c.OT_Deposit_TDRA_Top_Header"));
                break;
            case component.get('v.BAA_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Deposit_BAA_E_Signature_Message"));
                break;
            case component.get('v.IRA_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Deposit_Traditional_IRA_E_Signature_Message"));
                component.set('v.descriptionHeader', $A.get("$Label.c.OT_Deposit_Traditional_IRA_Top_Header"));
                break;
            case component.get('v.ROTH_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Deposit_Roth_IRA_E_Signature_Message"));
                component.set('v.descriptionHeader', $A.get("$Label.c.OT_Deposit_Roth_IRA_Top_Header"));
                break;
            case component.get('v.X457_ACC_TYPE'):
                component.set('v.eSignature', $A.get("$Label.c.OT_Deposit_TDRA_E_Signature_Message"));
                component.set('v.descriptionHeader', $A.get("$Label.c.OT_Deposit_TDRA_Top_Header"));
                break;
            case component.get('v.LEGACY_ACC_TYPE'):
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Transaction Not Available',
                    'variant': 'error',
                    'message': 'Deposit transactions are not available for Legacy IRA accounts.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();
                break;
        }
		
        // Redirect BA to new LWC 
        if (accountType == component.get('v.BAA_ACC_TYPE') || accountType == component.get('v.IRA_ACC_TYPE') || accountType == component.get('v.ROTH_ACC_TYPE')) {
            component.set('v.isRedirect', true);
            component.set('v.isLoading', false); 
        }
        // Use original component for other account types until refactors are complete
        else {
            // Set recurring picklist options
            let picklistService = component.find('picklistService');
            picklistService.getEntries('Case', 'Contribution_Frequency__c', entries => {
                // Only BAA has access to 'Change Recurring' option until other account types are moved to LWC
                let filteredEntries = entries.filter(entry => entry.value != 'Change Recurring');
                component.set('v.contributionOptions', filteredEntries);
            });
            picklistService.getEntries('Case', 'Contribution_Date__c', entries => {
                component.set('v.recurringContributionDayOptions', entries);
            });

            // Set tax year picklist options
            let taxYear = [];
            let currentTime = new Date();
            let aprilVerification = new Date($A.get('$Label.c.taxDateMonth')+ ',' +$A.get('$Label.c.taxDateDay') + ',' + currentTime.getFullYear());

            if(currentTime <= aprilVerification) {
                taxYear.push((currentTime.getFullYear() - 1) + '');
            }
            taxYear.push(currentTime.getFullYear() + '');
            component.set('v.taxYearOptions', taxYear);
            component.set('v.case.Contribution_Year__c', currentTime.getFullYear() + '');

            this.setContributionStartDateMin(component);

            // Null checks for amount fields
            if ($A.util.isEmpty(accountSummary.Current_Monthly_Dues__c)) {
                accountSummary.Current_Monthly_Dues__c = 0;
            }
            if ($A.util.isEmpty(accountSummary.Total_Dues_Outstanding__c)) {
                accountSummary.Total_Dues_Outstanding__c = 0;
            }

            // Set deposit options
            component.set('v.depositOptions', [
                {'label': 'Current Amount Due: $' + accountSummary.Total_Dues_Outstanding__c, 'value': 'currentAmountDue'},
                {'label': 'Monthly Member Dues: $' + accountSummary.Current_Monthly_Dues__c, 'value': 'monthlyMemberDues'},
                {'label': 'Other Amount', 'value': 'otherAmount'}]);

            // Get configured contribution limits
            this.getMaxContributionLimits(component);
            
            // Show form when all content is ready
            component.set('v.isLoading', false);
        }
    }, 

    getCurrentUser : function(component) {
        let action = component.get('c.getUser');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.currentUser', response.getReturnValue());
            } else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the current User.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    getCaseQueueId : function(component) {
        let action = component.get('c.getCaseQueue');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.caseQueueId', response.getReturnValue());
            } else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions Queue Id.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    getCaseRecordTypeId : function(component) {
        let action = component.get('c.getCaseRecordType');
        
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.caseRecordTypeId', response.getReturnValue());
            } else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the Online Transactions case record type',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    },

    // Get contribution limits for the year options and account type
    getMaxContributionLimits : function(component) {
        const accountSummary = component.get('v.accountSummary');
        const taxYears = component.get('v.taxYearOptions');
        
        let action = component.get('c.getMaxContributionLimits');
        action.setParams({
            'accountType' : accountSummary.Account_Type__c,
            'years' : taxYears
        });

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.MAX_CONTRIBUTION_AMOUNTS', response.getReturnValue());
            } 
            else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the maximum contribution type.',
                    'mode': 'sticky'
                });
            }
        });
        $A.enqueueAction(action);
    }, 

    setContributionStartDateMin : function(component) {
        let currentTime = new Date();
        let minStartYear = currentTime.getFullYear();
        
        // Minimum start date defaults to first of next month
        let minStartMonth = currentTime.getMonth() + 1;
        
        // For end of month dates with expected start date of 1st, push out another month to allow processing time
        let dayOfMonth = component.get('v.case.Contribution_Date__c');
		if (dayOfMonth == 'First' && currentTime.getDate() > 19) {
            minStartMonth++;
		}
		
        // Account for the end of year dates
        if (minStartMonth > 11) {
            minStartMonth = minStartMonth - 12;
            minStartYear++;
        }
        
        let minStartDate = new Date(minStartYear, minStartMonth, 1).toISOString(); 
        component.set('v.minStartDate', minStartDate);
    },

    validateCase : function(component) {
        let accountSummary = component.get('v.accountSummary');
        let errorMsg = '';

        // Validate required fields
        let childCmp = component.find('eSignatureComp');
        let isFormValid = childCmp.eSignatureFieldValidation();
        let bankingCmp = component.find('bankingInformationComp');
        
        if (bankingCmp != null) {
            errorMsg = bankingCmp.bankingInformationValidation();
            if(errorMsg !== '') {
                isFormValid = false;
            }
        }

        // Validate and save BAA through LWC
        if (component.get('v.isRedirect')) {
            // Save Case
            let record = component.get('v.case');
            record.OwnerId = component.get('v.caseQueueId');
            component.find('formLWC').saveCase(isFormValid, record);
        }
        // Validate original
        else {
            let formFields = [].concat(component.find('depositFormField'));
            for (let i = 0; i < formFields.length; i++) {
                if ($A.util.isEmpty(formFields[i].get('v.value'))) {
                    if (formFields[i].setCustomValidity != null) {
                        formFields[i].setCustomValidity('This field is required!');
                        formFields[i].reportValidity();
                    } 
                    else {
                        $A.util.addClass(formFields[i], 'slds-has-error');
                    }
                    isFormValid = false;
                } 
                else {
                    if (formFields[i].setCustomValidity != null) {
                        formFields[i].setCustomValidity('');
                        formFields[i].reportValidity();
                    } 
                    else {
                        $A.util.removeClass(formFields[i], 'slds-has-error');
                    }
                }
            }

            if(!isFormValid) {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error',
                    'variant': 'error',
                    'message': errorMsg === '' ? 'Please fill out all required fields on the form' : errorMsg,
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
                return;
            }

            // Validate options
            if(component.get('v.case.Contribution_Frequency__c') === 'Recurring' 
                && component.get('v.selectedDepositOption') !== 'monthlyMemberDues'
                && accountSummary.Account_Type__c === component.get('v.PENSION_ACC_TYPE')) {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'If your contribution option is a Recurring Contribution, your deposit option must be Monthly Member Dues.',
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
                return;
            }

            let currentTime = new Date();
            if(component.get('v.case.Contribution_Frequency__c') === 'Recurring' && component.get('v.case.Contribution_Year__c') !== (currentTime.getFullYear() + '')
                    && (accountSummary.Account_Type__c === component.get('v.IRA_ACC_TYPE') || accountSummary.Account_Type__c === component.get('v.ROTH_ACC_TYPE'))) {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'You must select the current year if you wish to make a recurring contribution.',
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
                return;
            }

            // Recurring Contribution Dates
            if(component.get('v.case.Contribution_Frequency__c') === 'Recurring') {
                // Account for timezone offset when comparing dates
                const startDateString = component.get('v.case.Contribution_Start_Date__c');
                let startDate = new Date(startDateString);
                const timezoneOffset = startDate.getTimezoneOffset();
                startDate.setMinutes(startDate.getMinutes() + timezoneOffset);

                const endDateString = component.get('v.case.Contribution_End_Date__c');
                let endDate = new Date(endDateString);
                endDate.setMinutes(endDate.getMinutes() + timezoneOffset);

                // Verify minimum start date
                const minStartDate = new Date(component.get('v.minStartDate'));
                if (minStartDate > startDate) {
                    const options = { year: 'numeric', month: 'long', day: 'numeric' };
                    const dateString = new Date(component.get('v.minStartDate')).toLocaleDateString('en-US', options);
                    errorMsg = 'Start date must be on or after ' + dateString;
                }

                // Start date must match recurring day of month selection
                const startDay = startDateString.split('-')[2];
                const dayOfMonth = component.get('v.case.Contribution_Date__c');

                if (dayOfMonth == 'First' && startDay != '01') {
                    errorMsg = 'Please enter first of the month';
                }
                else if (dayOfMonth == 'Fifteenth' && startDay != '15') {
                    errorMsg = 'Please enter 15th of the month';
                }

                // Date range must be between 2 months and 50 years
                if (errorMsg == '' && endDateString != null) {
                    let minEndDate = new Date(startDate);
                    minEndDate.setMonth(minEndDate.getMonth() + 2);
                    minEndDate.setDate(minEndDate.getDate() - 1);

                    let maxEndDate = new Date(startDate);
                    maxEndDate.setFullYear(maxEndDate.getFullYear() + 50);
                    maxEndDate.setDate(maxEndDate.getDate() - 1);

                    if (endDate < startDate) {
                        errorMsg = 'Start date must be before end date';
                    }
                    else if (endDate < minEndDate) {
                        errorMsg = 'Please use one-time contribution option, recurring option should be used for a period greater than 2 month';
                    }
                    else if (endDate >= maxEndDate) {
                        errorMsg = 'Exceeds maximum time allowed for a recurring contribution';
                    }
                }

                if (errorMsg != '') {
                    component.find('depositNotificationLibrary').showToast({
                        'title': 'Error!',
                        'variant': 'error',
                        'message': errorMsg,
                        'mode': 'sticky'
                    });
                    component.set('v.isSaving', false);
                    return;
                }
                
               
            }



             // Validate Pension amount
             errorMsg = '';
             let amount = component.get('v.case.Deposit_Amount__c');
             if(accountSummary.Account_Type__c === component.get('v.PENSION_ACC_TYPE')) {
                 switch(component.get('v.selectedDepositOption')) {
                     case 'monthlyMemberDues':
                         component.set('v.case.Deposit_Amount__c', accountSummary.Current_Monthly_Dues__c);
                         break;
                     case 'currentAmountDue':
                         component.set('v.case.Deposit_Amount__c', accountSummary.Total_Dues_Outstanding__c);
                         break;
                     default:
                 }
                 amount = component.get('v.case.Deposit_Amount__c');

                 if (amount > accountSummary.Total_Dues_Outstanding__c || amount <= 0) {
                     let formattedBalance = accountSummary.Total_Dues_Outstanding__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '');            
                     errorMsg = 'Your contribution range must be between 0 and the Current Amount Due (' + formattedBalance + ')';
                 }
             }
             // Validate BAA amount against minimum
             else if (accountSummary.Account_Type__c === component.get('v.BAA_ACC_TYPE') && amount < 10) {
                 errorMsg = 'Your contribution range must be greater than or equal to $10.00';
             } 



            if(!$A.util.isEmpty(errorMsg)) {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': errorMsg,
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
                return;
            }

            // Validate IRA amount against stored contribution limits
            if (accountSummary.Account_Type__c === component.get('v.IRA_ACC_TYPE') || 
                accountSummary.Account_Type__c === component.get('v.ROTH_ACC_TYPE') || 
                accountSummary.Account_Type__c === component.get('v.TDRA_ACC_TYPE') || 
                accountSummary.Account_Type__c === component.get('v.TDRA_PR_ACC_TYPE')) {
                this.validateContributionLimits(component);
            }
            else {
                this.saveCase(component);
          }
        }
    },

    validateContributionLimits : function(component) {
        let action = component.get('c.getTotalContributionsSoFar');
        let amount = component.get('v.case.Deposit_Amount__c');

        action.setParams({
            'contactId' : component.get('v.currentUser.ContactId'),
            'accountSummaryType' : component.get('v.accountSummary.Account_Type__c'),
            'yearParam' : component.get('v.case.Contribution_Year__c')
        });

        action.setCallback(this, function(response){
            let state = response.getState();
            let errorMsg;

            if(state === 'SUCCESS'){
                component.set('v.totalContributedSoFar', response.getReturnValue());
                const selectedTaxYear = component.get('v.case.Contribution_Year__c');
                const memberAge = component.get('v.accountSummary.Member_Name__r.Age__c');

                let contributedSoFar = 0;
                if (component.get('v.case.Contribution_Frequency__c') === 'Single Sum') {
                    contributedSoFar = component.get('v.totalContributedSoFar');
                }

                // Find stored limit for the selected tax year
                let limits = component.get('v.MAX_CONTRIBUTION_AMOUNTS');
                let storedLimit = limits.find(limit => limit.Year__c == selectedTaxYear);
                
                // If a stored limit is found, set the contribution limit
                let maximumContributionLimit;
                if (storedLimit) {
                    if (!memberAge || memberAge < storedLimit.Retirement_Age__c) {
                        maximumContributionLimit = storedLimit.Amount_Before_Retirement_Age__c;
                    }
                    else {
                        maximumContributionLimit = storedLimit.Amount_at_Retirement_Age__c;
                    }
                }
                
                // Ensure the deposit will not exceed the member's contribution limit for the year
                if (maximumContributionLimit) {
                    let possibleContributionSize = maximumContributionLimit - contributedSoFar;
                    if (possibleContributionSize < 10) {
                        errorMsg = 'No further contributions are allowed since you have met your yearly limit';
                    } 
                    else if (amount < 10 || amount > possibleContributionSize) {
                        let formattedContrSize = possibleContributionSize.toLocaleString('en-US', { style: 'currency', currency: 'USD' }).replace('.00', '');
                        errorMsg = 'Your contribution range must be between $10 and ' + formattedContrSize;
                    }
                }

                if(!$A.util.isEmpty(errorMsg)) {
                    component.find('depositNotificationLibrary').showToast({
                        'title': 'Error!',
                        'variant': 'error',
                        'message': errorMsg,
                        'mode': 'sticky'
                    });
                    component.set('v.isSaving', false);
                    return;
                }
                this.saveCase(component);
            } 
            else if(state === 'ERROR') {
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': 'An error occurred when retrieving the total amount to be deposited.',
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
            }
        });
        $A.enqueueAction(action);
    },

    saveCase : function(component) {
        let currentCase = component.get('v.case');
        let accountSummary = component.get('v.accountSummary');

        if(accountSummary.Account_Type__c === component.get('v.PENSION_ACC_TYPE')) {
            currentCase.Portal_Transaction_Type__c = 'Pay Dues';
        } else {
            currentCase.Portal_Transaction_Type__c = 'Deposit';
        }
        currentCase.Origin = 'MemberPortal';
        currentCase.OwnerId = component.get('v.caseQueueId');
        currentCase.RecordTypeId = component.get('v.caseRecordTypeId');
        currentCase.Account_Summary__c = accountSummary.Id;
        currentCase.ContactId = component.get('v.currentUser').ContactId;

        // For one-time contributions, set start date to today
        if (currentCase.Contribution_Frequency__c != 'Recurring') {
            let todaysDate = new Date();
            currentCase.Contribution_Start_Date__c = todaysDate.toLocaleDateString();
        }

        let action = component.get('c.saveCase');
        action.setParams({currentCase});

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Success!',
                    'variant' : 'success',
                    'message': 'Request has been received.',
                    'mode': 'sticky'
                });
                $A.get('e.force:closeQuickAction').fire();

            } else if(state === 'ERROR') {
                let errors = response.getError();
                let errorMsg;
                if (errors && errors[0]) {
                    errorMsg = errors[0].message;
                }
                component.find('depositNotificationLibrary').showToast({
                    'title': 'Error!',
                    'variant': 'error',
                    'message': errorMsg,
                    'mode': 'sticky'
                });
                component.set('v.isSaving', false);
            }
        });
        $A.enqueueAction(action);
    }
});