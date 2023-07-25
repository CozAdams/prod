({
    init : function(cmp, event, helper) {
        helper.initAttributes(cmp);
    }, 
    handleContributionTypeChange : function(cmp, event, helper) {
        helper.handleContributionTypeChange(cmp);
    }, 
    navigateForward: function(cmp, event, helper) {
        var isValid = helper.validate(cmp);
        if (isValid) {
            var navigate = cmp.get('v.navigateFlow');
            navigate('NEXT');
        }
    }, 
    navigateBack: function(cmp, event, helper) {
        var navigate = cmp.get('v.navigateFlow');
        navigate('BACK');
    }
})