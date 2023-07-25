import getMaxContributionLimits from '@salesforce/apex/AccountSummaryService.getMaxContributionLimits';
import getTotalContributionsSoFar from '@salesforce/apex/AccountSummaryService.getTotalContributionsSoFar';

// Get maximum contribution limits from config for a specific account type and year, based on member's age
async function getContributionLimit(accountType, memberAge, year) {
    let maxAmount;
    const result = await getMaxContributionLimits({ 
        accountType, 
        years: [ year ] 
    })
    
    const limit = result[0];
    if (limit) {
        if (memberAge >= limit.Retirement_Age__c) {
            maxAmount = limit.Amount_at_Retirement_Age__c;
        }
        else {
            maxAmount = limit.Amount_Before_Retirement_Age__c;
        }
    }
    return maxAmount;
}

// Get a member's previous contributions total for a given account type and year
async function getPreviousContributionTotal(contactId, accountSummaryType, yearParam) {
    const result = await getTotalContributionsSoFar({ 
        contactId, 
        accountSummaryType, 
        yearParam
    })
    const previousTotal = parseInt(result);
    return previousTotal;
}

export { 
    getContributionLimit, 
    getPreviousContributionTotal
};