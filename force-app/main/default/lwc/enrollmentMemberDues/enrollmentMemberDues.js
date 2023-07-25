import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent, FlowNavigationPauseEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class EnrollmentMemberDues extends LightningElement {
    // Enrollment form object for input and output
    @api enrollmentForm;
    @api formId;
    @api isNavigateBack;
    enrollmentFormClone;

    // UI visibility
    contributionTypeOptions;
    showEmployerSection;
    showMemberSection;

    // Default field values
    DATE_TODAY = new Date().toLocaleDateString();
    PERCENT_MIN = 1;
    TOTAL_PERCENT_MAX = 14;

    // Input values
    contributionTypes = [];
    employerPercent;
    memberPercent;
    taxTreatment;
    startDate;

    // Labels and text
    MSG_GENERAL = 'As a member, dues will be made to the Pension Plan on your behalf in accordance with your employer\'s Participation Agreement.';
    MSG_CHECK_ONE = 'Check one as applicable and complete';
    CHECK_LABEL_EMPLOYER = 'I elect employer contributions to my Pension Plan';
    CHECK_LABEL_MEMBER = 'I elect to make employee contributions to my Pension Plan';

    MSG_EMPLOYER = 'My employer will contribute the following percentage:';
    MSG_MEMBER = 'Complete the below section if your employer\'s Participation Agreement (i) permits each member to elect a different percentage ' +
        'of member dues on a pre-tax basis, (ii) permits an election between pre-tax or after-tax member dues, and/or (iii) permits each member to elect ' +
        'a different percentage of Compensation Base to determine dues.';
    MSG_MEMBER_REFERENCE = 'See Compensation Base Resource Worksheet for assistance in determining your Compensation Base.';
    MSG_MEMBER_PERCENT = 'I hereby direct my employer to reduce my salary on a pre-tax basis by an amount of my Compensation Base.';
    MSG_MEMBER_PERCENT_DISCLAIMER = 'Employer and member dues in aggregate must total 14% if you are a minister and at least 6% if you are not a minister.';

    LABEL_PERCENT = 'Percent[%]';
    LABEL_CHECK_ADDL_CONT = 'I do not wish to make any additional contributions outside of what my employer is contributing';
    LABEL_CHECK_SALARY_RED = 'My employer will reduce my salary in accordance with (i) my employer\s Participation Agreement with Pension Fund or ' +
        '(ii) the salary reduction agreement that I have entered into with my employer to make pre-tax or after-tax member dues to the Pension Plan.';
    LABEL_DATE = 'Start date of your Pension Plan';
    LABEL_TAX_TREATMENT = 'Member dues will be paid as:';

    TAX_OPTIONS = [
        { label: 'After-tax', value: 'After-tax' }, 
        { label: 'Pre-tax', value: 'Pre-tax' }
    ];
    DATE_MIN = new Date(new Date().getFullYear(), 0, 1).toLocaleDateString();

    ERROR_EMPLOYER_PERCENT_REQUIRED = 'A Percentage Employer Dues amount is required when "I do not wish to make any additional contributions outside of what my employer is contributing" checkbox is checked.';
    ERROR_PERCENT_RANGE_MAX = 'Full Dues should be equal to 14% of your compensation.';
    ERROR_MEMBER_PERCENT_REQUIRED = 'A Percentage Member Dues amount is required when “My employer will reduce my salary” checkbox is checked.';
    ERROR_PERCENT_RANGE_MIN = 'Amount must be greater than 0%.';
    ERROR_DATE_REQUIRED = 'Start Date is required.';
    ERROR_REQUIRED_GENERAL = 'Please select a Choice';
    ERROR_REQUIRED_AT_LEAST_ONE_PERCENT = 'An amount for either Percentage Employer Dues or Percentage Member Dues must be provided.';
    ERROR_DATE_RANGE = 'Please contact PFCC for prior year enrollments.';

    // For retaining data input during navigation, set field values based on enrollment form values after data receipt
    connectedCallback() {
        this.contributionTypeOptions = [
            { label: this.CHECK_LABEL_EMPLOYER, value: 'Employer' },
            { label: this.CHECK_LABEL_MEMBER, value: 'Member' },
        ];

        this.enrollmentFormClone = {...this.enrollmentForm};
        this.employerPercent = this.enrollmentFormClone.Employer_Dues__c;
        this.memberPercent = this.enrollmentFormClone.Member_Dues__c;
        this.taxTreatment = this.enrollmentFormClone.Employee_Contribution_Type__c;

        // Manually convert datetime value from form to correct date to prevent incorrect conversion
        if (this.enrollmentFormClone.Date_Dues_Will_Begin__c) {
            this.startDate = this.enrollmentFormClone.Date_Dues_Will_Begin__c.split('T')[0];
        }

        // Show sections for data already entered
        if (this.enrollmentFormClone.elect_both_employer_and_employee_contrib__c) {
            this.contributionTypes = [ 'Employer', 'Member' ];
            this.showEmployerSection = true;
            this.showMemberSection = true;
        }
        else if (this.enrollmentFormClone.do_not_wish_to_make_any_additional_contr__c) {
            this.contributionTypes = [ 'Employer' ];
            this.showEmployerSection = true;
        }
        else if (this.enrollmentFormClone.My_employer_will_reduce_my_salary_in_acc__c) {
            this.contributionTypes = [ 'Member' ];
            this.showMemberSection = true;
        }
    }

    // Toggle contribution type and clear dependencies
    toggleContributionType(event) {
        const oldTypes = this.contributionTypes;
        const newTypes = event.detail.value;
        this.contributionTypes = newTypes;

        this.showEmployerSection = newTypes.includes('Employer');
        this.showMemberSection = newTypes.includes('Member');

        // Clear employer amount values when unchecking
        if (!newTypes.includes('Employer') && oldTypes.includes('Employer')) {
            this.employerPercent = null;
        }

        // Clear member amount values when unchecking
        if (!newTypes.includes('Member') && oldTypes.includes('Member')) {
            this.memberPercent = null;
        }
    }

    // On input field change, sync input to associated variable
    handleInputChange(event) {
        // Format value for percentage fields
        if (event.target.name == 'memberPercent' || event.target.name == 'employerPercent') {
            let formattedPercent = +parseFloat(event.target.value).toFixed(2);
            event.target.value = formattedPercent;
        }

        // Clear any existing validation errors
        event.target.setCustomValidity('');
        event.target.reportValidity();

        // Assign input value to variable
        this[event.target.name] = event.target.value;
    }

    // Save the input to the form and navigate within the flow
    navigate(event) {
        const button = event.target.dataset.name;

        // Update enrollment form clone with input
        this.enrollmentFormClone.Employer_Dues__c = this.employerPercent;
        this.enrollmentFormClone.Member_Dues__c = this.memberPercent;
        this.enrollmentFormClone.Date_Dues_Will_Begin__c = this.startDate;
        this.enrollmentFormClone.Employee_Contribution_Type__c = this.taxTreatment;

        const isEmployer = this.contributionTypes.includes('Employer');
        const isMember = this.contributionTypes.includes('Member');
        this.enrollmentFormClone.My_employer_will_reduce_my_salary_in_acc__c = !isEmployer && isMember;
        this.enrollmentFormClone.do_not_wish_to_make_any_additional_contr__c = isEmployer && !isMember;
        this.enrollmentFormClone.elect_both_employer_and_employee_contrib__c = isEmployer && isMember;

        // Proceed to next flow step
        this.dispatchEvent(new FlowAttributeChangeEvent('enrollmentForm', this.enrollmentFormClone));

        // Go back
        if (button == 'btnBack') {
            this.dispatchEvent(new FlowNavigationBackEvent());
        }
        // Validate and go forward
        else if (button == 'btnNext') {
            if (this.validate()) {
                this.dispatchEvent(new FlowNavigationNextEvent());
            }
        }
    }

    // Validate all input fields
    validate() {
        let isValid = true;
        const inputFields = this.template.querySelectorAll('.form-validate');
        const employerDuesField = this.template.querySelector('[data-id="employerPercent"]');
        const memberDuesField = this.template.querySelector('[data-id="memberPercent"]');
        const taxTreatmentField = this.template.querySelector('[data-id="taxTreatment"]');

        // Clear existing error messages and check input field validation first
        inputFields.forEach(field => {
            field.setCustomValidity('');
            if (!field.checkValidity()) {
                isValid = false;
            }
        });

        // If required field validation passes, check percentage total amount
        if (isValid && this.showEmployerSection && this.showMemberSection) {
            const totalPercent = parseFloat(this.employerPercent) + parseFloat(this.memberPercent);

            // If both percents are selected, the total must equal 14%
            if (totalPercent != this.TOTAL_PERCENT_MAX) {
                isValid = false;
                employerDuesField.setCustomValidity(this.ERROR_PERCENT_RANGE_MAX);
                if (memberDuesField) memberDuesField.setCustomValidity(this.ERROR_PERCENT_RANGE_MAX);
            }
        }

        // Show error messages
        inputFields.forEach(field => {
            field.reportValidity();
        });
        return isValid;
    }
}