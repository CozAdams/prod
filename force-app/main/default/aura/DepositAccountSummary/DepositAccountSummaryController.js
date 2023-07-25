({
	doInit : function(component, event, helper) {
		helper.getAccountSummary(component);
		helper.buildCase(component);
	},

	toggleSavingSpinner: function(component, event, handler) {
		component.set('v.isSaving', !component.get('v.isSaving'));
	}, 

	hideLoadingSpinner: function(component, event, handler) {
		component.set('v.isLoading', false);
	},

	handleFrequencyChange : function(component, event, helper) {
		component.set('v.case.Contribution_Start_Date__c', null);
		component.set('v.case.Contribution_End_Date__c', null);
		component.set('v.case.Contribution_Date__c', null);
	}, 

	handleRecurringDayChange : function(component, event, helper) {
		if (component.get('v.case.Contribution_Date__c') != null) {
			helper.setContributionStartDateMin(component);
		}
	}, 

	save : function(component, event, helper) {
		component.set('v.isSaving', true);
		helper.validateCase(component);
	}, 

	closeFormWindow : function(component, event, helper) {
		$A.get('e.force:closeQuickAction').fire();
	}
});