({
    // Initialize default attributes
    initAttributes : function(cmp) {
        // Recurring contribution options
        var recurringDebitOptions = [
            {
                'label': '1st of month', 
                'value': '1st'
            }, 
            {
                'label': '15th of month', 
                'value': '15th'
            }
        ];
        cmp.set('v.recurringDebitOptions', recurringDebitOptions);  

        // Effective date minimum - Single Sum
        var today = new Date();
        var tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        var tomorrowDate = $A.localizationService.formatDate(new Date(tomorrow), 'YYYY-MM-DD');
        cmp.set('v.effectiveDateSingleMin', tomorrowDate);

        // Effective date minimum - Recurring
        var thisYear = today.getFullYear();
        var thisMonth = today.getMonth();
        var nextMonth = thisMonth == 11 ? 0 : thisMonth + 1;
        var nextMonthStart = $A.localizationService.formatDate(new Date(thisYear, nextMonth, 1), 'YYYY-MM-DD');
        cmp.set('v.effectiveDateRecurringMin', nextMonthStart);
    }, 
    // Refresh attribute values based on changed contribution types
    handleContributionTypeChange: function(cmp) {
        // Determine selected contribution types
        var isRecurring = cmp.get('v.isRecurring');  
        var isSingle = cmp.get('v.isSingle');

        // Set validation based on selected contribution types
        var contributionType = isSingle ? 'One-Time Debit' : 'Recurring Debit';
        var recurringMin = isRecurring && isSingle ? 1 : isRecurring ? 25 : 0;
        var singleMin = isSingle ? 25 : 0;

        // Clear amount value for deselected contribution types
        if (!isSingle) { 
            cmp.set('v.singleAmount', null);
            cmp.set('v.effectiveDateSingle', null);
        }
        if (!isRecurring) {
            cmp.set('v.recurringAmount', null);
            cmp.set('v.recurringDebitDay', null);
            cmp.set('v.effectiveDateRecurring', null);
        }

        // Assign attribute values
        cmp.set('v.contributionType', contributionType);
        cmp.set('v.recurringAmountMin', recurringMin);
        cmp.set('v.singleAmountMin', singleMin);
    }, 
    validate: function(cmp) {
        // Validation attributes
        var isValid = true;
        var errorMessage = 'Please correct the errors below to continue';
        var isSingle = cmp.get('v.isSingle');
        var isRecurring = cmp.get('v.isRecurring');
        
        // Contribution type
        if (!isSingle && !isRecurring) {
            isValid = false;
            cmp.set('v.hasErrorContributionType', true);
        }
        
        let validateFields = [].concat(cmp.find('formValidate'));
        for (let i = 0; i < validateFields.length; i++) {
            let field = validateFields[i];
            if (!field.checkValidity()) {
                isValid = false;
                field.reportValidity();
            }
        }
        
        // Recurring effective date validation
        let recurringDateField = cmp.find('effectiveDateRecurring');
        if (recurringDateField) {
            // Clear existing errors
            recurringDateField.setCustomValidity('');
            recurringDateField.reportValidity();

            // Check standard validation
            if (!recurringDateField.checkValidity()) {
                isValid = false;
                recurringDateField.reportValidity();
            }
            // Check custom validation
            else {
                let debitDay = cmp.get('v.recurringDebitDay') == '1st' ? 1 : 15;
                let effectiveDateVal = cmp.get('v.effectiveDateRecurring');
                let effectiveDateDay = +(effectiveDateVal.split('-')[2]);

                if (debitDay != effectiveDateDay) {
                    isValid = false;
                    let errorMsg = 'The date must match the recurring date you chose above. Please select the ' + cmp.get('v.recurringDebitDay') + ' of the month in which you would like the recurring debit to begin.';
                    recurringDateField.setCustomValidity(errorMsg);
                    recurringDateField.reportValidity();
                }
            }
        }
        return isValid;
    }
})