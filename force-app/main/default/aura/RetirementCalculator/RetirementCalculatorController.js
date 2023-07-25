({
	doInit : function(cmp, event, helper) {
		helper.loadAvatar(cmp);
        helper.loadData(cmp);
        helper.loadCalculations(cmp);
	},
	calcRetirementDate : function(cmp, event, helper){
        helper.calcRetirementDate(cmp);
        if(helper.isDateInPast($A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate')))) {
            helper.showToast('Retirement date cannot be in the past!');
            cmp.set('v.retireDate', helper.formatISODate(helper.calcEligDate(new Date())));
            //helper.calcRetirementAge(cmp);
        }
        helper.calcRetirementAge(cmp);
	    helper.calculateDynamicValues(cmp);
	    helper.updateChart(cmp);
	},
    calcRetirementAge : function(cmp, event, helper) {
        if(helper.isDateInPast($A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate')))) {
            helper.showToast('Retirement date cannot be in the past!');
            cmp.set('v.retireDate', helper.formatISODate(helper.calcEligDate(new Date())));
        }
        if (!helper.isDateFirstOfTheMonth($A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate')))) {
            helper.showToast('Retirement date must be first of the month!');
            cmp.set('v.retireDate', helper.formatISODate(helper.calcEligDate(new Date())));
        }
	    helper.calcRetirementAge(cmp);
        helper.calculateDynamicValues(cmp);
        helper.updateChart(cmp);
    },
    closeCalcListCard : function(cmp, event, helper) {
	    helper.closeCard(cmp, 'calcList');
    },
	loadCalculation : function(cmp, event, helper) {
        let calcList = cmp.get('v.calcList');
        for (let i = 0; i < calcList.length; i++) {
            if (calcList[i].Id === event.currentTarget.dataset.id) {
                cmp.set('v.salary', calcList[i].Annual_Salary__c);
                cmp.set('v.pensionCredsPerMonth', calcList[i].Monthly_Pension_Credits__c);
                cmp.set('v.retireDate', calcList[i].Desired_Retirement_Date__c);
                cmp.set('v.yearlyPercentageSalaryIncrease', calcList[i].Salary_Percentage_Increase__c);
                helper.calcRetirementAge(cmp);
                helper.calculateDynamicValues(cmp);
                helper.updateChart(cmp);
                break;
            }
        }
        helper.closeCard(cmp, 'calcList');
	},
    handleActions : function(cmp, event, helper) {
	    let v = event.getParam('value');
	    if (v === undefined) {
            v = event.getSource().get('v.value');
        }
	    if (v === 'reset') {
            helper.initializeValues(cmp);
        } else if (v === 'load') {
            helper.openCard(cmp, 'calcList');
        } else if (v === 'save') {
            helper.saveCalc(cmp);
        } else if (v === 'print') {
	        print();
        }
    },
    calculateSalary: function(cmp, event, helper) {
        const contact = cmp.get("v.contact");
        if (contact.DB_Membership_Status__c === 'Inactive' || contact.DB_Membership_Status__c === 'Refund Vested' || contact.DB_Membership_Status__c === 'Unclaimed Balance') {
            cmp.set('v.salary', 0);
            helper.showToast('Inactive users cannot update salary.');
            return;
        }
		if (cmp.get('v.salary') > cmp.get('v.calculatorSetting.Salary_Upper_Bounds__c')) {
			cmp.set('v.salary', cmp.get('v.calculatorSetting.Salary_Upper_Bounds__c'));
			helper.showToast(cmp.get('v.calculatorSetting.Salary_Upper_Bounds_Err__c'));
		}
        if (cmp.get('v.salary') < cmp.get('v.calculatorSetting.Salary_Lower_Bounds__c')) {
		    cmp.set('v.salary', cmp.get('v.calculatorSetting.Salary_Lower_Bounds__c'));
		    helper.showToast(cmp.get('v.calculatorSetting.Salary_Lower_Bounds_Err__c'));
        }
        helper.calculateDynamicValues(cmp);
		helper.calculateSalaryIncrement(cmp);
        helper.updateChart(cmp);
    },

    calculateSalaryIncrease : function(cmp, event, helper) {
        if (cmp.get('v.yearlyPercentageSalaryIncrease') > cmp.get('v.calculatorSetting.Salary_Percentage_Upper_Bound__c')) {
            cmp.set('v.yearlyPercentageSalaryIncrease', cmp.get('v.calculatorSetting.Salary_Percentage_Upper_Bound__c'));
            helper.showToast(cmp.get('v.calculatorSetting.Salary_Percentage_Upper_Bound_Err__c'));
        }
        if (cmp.get('v.yearlyPercentageSalaryIncrease') < cmp.get('v.calculatorSetting.Salary_Percentage_Lower_Bound__c')) {
            cmp.set('v.yearlyPercentageSalaryIncrease', cmp.get('v.calculatorSetting.Salary_Percentage_Lower_Bound__c'));
            helper.showToast(cmp.get('v.calculatorSetting.Salary_Percentage_Lower_Bound_Err__c'));
        }
        helper.calculateDynamicValues(cmp);
        helper.calculateSalaryIncrement(cmp);
        helper.updateChart(cmp);
    },
    
    deleteCalculation : function(cmp, event, helper) {
        let savedCalcId = event.getSource().get('v.value');
        helper.deleteCalculation(cmp, savedCalcId);
    }
})