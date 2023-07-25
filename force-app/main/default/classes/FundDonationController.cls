public with sharing class FundDonationController {
    private static final String MASTER_FUND_RECORDTYPE = 'Master_Funds';
    private static final String NAMED_FUND_RECORDTYPE = 'Named_Funds';
    @TestVisible
    private static final String OTHER_DONATION_OPTION = 'Other';
    @TestVisible
    private static final String RECURRING_DONATION_ERROR = 'You can only select recurring donation if a single fund is selected!';
    @TestVisible
    private static final String NO_PRODUCTS_SELECTED = 'You must select at least one fund to donate!';
    @TestVisible
    private static final String DONATION_ERROR = 'Donation Amount is required and must be greater than ';

    public dn8n__Donation_Page__c donationPage{get;set;}
    public Map<String, ProductWrapper> productWrappersByProductId {get; set;}
    public Map<String, ProductWrapper> selectedProductWrappersByProductId {get; set;}
    public Boolean disableForm {get;set;}

    // Form Fields
    public String salutation{get;set;}
    public String firstName {get; set;}
    public String lastName{get;set;}
    public String emailAddress{get; set;}
    public String companyName {get; set;}
    public String address {get; set;}
    public String city {get; set;}
    public String billingState {get; set;}
    public String billingPostalCode {get; set;}
    public String billingCountry {get; set;}
    public String phoneNumber {get; set;}
    public String inHonorMemoryValue {get; set;}
    public List<SelectOption> salutationOptions {
        get{
            if (salutationOptions == null) {
                salutationOptions = new List<SelectOption>();
                List<PicklistEntry> picklistEntries = Contact.Salutation.getDescribe().getPicklistValues();
                for (PicklistEntry picklistEntry : picklistEntries) {
                    salutationOptions.add(new SelectOption(picklistEntry.value, picklistEntry.label));
                }
            }
            return salutationOptions;
        }
        set;
    }

    public List<SelectOption> honorMemoryPicklistValues {
        get{
            if (HonorMemoryPicklistValues == null) {
                honorMemoryPicklistValues = new List<SelectOption>();
                honorMemoryPicklistValues.add(new SelectOption('', ' '));
                List<PicklistEntry> picklistEntries = pymt__PaymentX__c.In_Honor_Of_or_In_Memory_Of__c.getDescribe().getPicklistValues();
                for (PicklistEntry picklistEntry : picklistEntries) {
                    HonorMemoryPicklistValues.add(new SelectOption(picklistEntry.value, picklistEntry.label));
                }
            }
            return honorMemoryPicklistValues;
        }
        set;
    }

    public List<SelectOption> billingStateOptions {
        get {
            return FundDonationService.getStateOptions(billingCountry);
        }
        set;
    }
    public Boolean hasBillingStateOptions {
        get {
            return !billingStateOptions.isEmpty();
        }
        set;
    }
    public List<SelectOption> billingCountryOptions {
        get {
            if (billingCountryOptions == null) {
                billingCountryOptions = FundDonationService.getCountryOptions();
            }
            return billingCountryOptions;
        }
        set;
    }
    public String optionalDonationMessage {get; set;}
    public String honoreeNameAndAddress {get; set;}
    public Boolean interestedInLearningMoreAboutEstateLegacyGift {get; set;}
    public Boolean employerMatchingDonation {get; set;}

    // for typeAhead
    public String productWrapperJSON {
        get {
            List<ProductWrapper> wrappers = new List<ProductWrapper>();
            for (ProductWrapper wrapper : (List<ProductWrapper>) productWrappersByProductId.values()) {
                if (!wrapper.product.Hide_from_Search_Bar__c && !wrapper.product.Display_on_Donation_Page__c) {
                    wrappers.add(wrapper);
                }
            }
            return String.escapeSingleQuotes(JSON.serialize(wrappers));
        }
        set;
    }
    // for radios
    public List<SelectOption> productWrapperOptions {
        get {
            if (productWrapperOptions == null) {
                productWrapperOptions = new List<SelectOption>();
                for (ProductWrapper wrapper : ((List<ProductWrapper>) productWrappersByProductId.values())) {
                    if (wrapper.product.Display_on_Donation_Page__c) {
                        productWrapperOptions.add(new SelectOption(wrapper.product.Id, wrapper.product.Name));
                    }
                }
            }
            return productWrapperOptions;
        }
        set;
    }

    public List<ProductWrapper> sortedProductWrapperList {
        get {
            if (sortedProductWrapperList == null) {
                sortedProductWrapperList = (List<ProductWrapper>) productWrappersByProductId.values();
            }
            return sortedProductWrapperList;
        }
        set;
    }


    public Boolean enableOtherDonation{get;set;}
    public List<SelectOption> suggestedDonationOptions{get;set;}

    //recurring specific
    public List<SelectOption> recurringPeriodOptions {get; set;}
    public Boolean isRecurring{get;set;}
    public String occurrences{get;set;}
    public String selectedRecurringPeriod{get;set;}

    public FundDonationController(ApexPages.StandardController standardController){
        if (!Test.isRunningTest()) {
            standardController.addFields(new List<String> {
                    'dn8n__HTML_Header__r.ctnt__HTML_Content__c', 'dn8n__HTML_Footer__r.ctnt__HTML_Content__c',
                    'dn8n__Processor_Connection__r.pymt__Processor_Id__c', 'dn8n__Currency_ISO_Code__c',
                    'Name', 'dn8n__Suggested_Donation_Amounts__c', 'dn8n__Status__c', 'dn8n__Publication_Date__c',
                    'dn8n__Expiration_Date__c', 'dn8n__Payment_Record_Name__c', 'dn8n__Minimum_Donation__c',
                    'dn8n__Donation_Options__c', 'dn8n__Confirmation_URL__c'
            });
        }
        donationPage = (dn8n__Donation_Page__c) standardController.getRecord();
        isRecurring = false;
        billingCountry = 'US';
        enableOtherDonation = false;
        selectedProductWrappersByProductId = new Map<String, ProductWrapper>();
        productWrappersByProductId = new Map<String, ProductWrapper>();
        suggestedDonationOptions = new List<SelectOption>();
        optionalDonationMessage = '';
        honoreeNameAndAddress = '';
        interestedInLearningMoreAboutEstateLegacyGift = false;
        employerMatchingDonation = false;

        recurringPeriodOptions = new List<SelectOption>();
        if (donationPage.dn8n__Donation_Options__c != null) {
            List<String> donationOptions = donationPage.dn8n__Donation_Options__c.split(';');
            for (String donationOption : donationOptions) {
                if (!donationOption.equalsIgnoreCase('One Time')) {
                    if ('Monthly'.equals(donationOption)) {
                        recurringPeriodOptions.add(new SelectOption('Month', donationOption));
                    }
                    if ('Annual'.equals(donationOption)) {
                        recurringPeriodOptions.add(new SelectOption('Year', donationOption));
                    }
                }
            }
        }
        selectedRecurringPeriod = recurringPeriodOptions != null && !recurringPeriodOptions.isEmpty() ? recurringPeriodOptions[0].getValue() : '';
        disableForm = donationPage.dn8n__Status__c != FundDonationService.PUBLISHED || donationPage.dn8n__Publication_Date__c > Date.today() || (donationPage.dn8n__Expiration_Date__c != null && donationPage.dn8n__Expiration_Date__c < Date.today());

        List<Product2> products = [SELECT Id, Name, Display_on_Donation_Page__c, Hide_from_Search_Bar__c FROM Product2
            WHERE RecordType.DeveloperName = :MASTER_FUND_RECORDTYPE OR RecordType.DeveloperName = :NAMED_FUND_RECORDTYPE ORDER BY Name];
        for (Product2 product : products) {
            productWrappersByProductId.put(product.Id, new ProductWrapper(product));
        }

        String suggestedOptions = donationPage.dn8n__Suggested_Donation_Amounts__c;
        if(String.isNotBlank(suggestedOptions)){
            List<String> options = suggestedOptions.split(';');
            String currencySymbol = FundDonationService.getCurrencySymbol(donationPage.dn8n__Currency_ISO_Code__c);
            for(String opt : options) {
                if(opt.equals('?')){
                    enableOtherDonation = true;
                } else if(isNumeric(opt)){
                    suggestedDonationOptions.add(new SelectOption( opt, currencySymbol + opt));
                }
            }
        }
        if(enableOtherDonation){
            suggestedDonationOptions.add(new SelectOption(OTHER_DONATION_OPTION, OTHER_DONATION_OPTION));
        }
    }

    public PageReference processDonation(){
        if (selectedProductWrappersByProductId.size() < 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_PRODUCTS_SELECTED));
            return null;
        }
        // Create shopping cart items and total up the payment amount
        Decimal paymentAmount = 0;
        List<pymt__Shopping_Cart_Item__c> shoppingCartItems = new List<pymt__Shopping_Cart_Item__c>();
        for (ProductWrapper productWrapper : ((List<ProductWrapper>) selectedProductWrappersByProductId.values())) {
            pymt__Shopping_Cart_Item__c shoppingCartItem = new pymt__Shopping_Cart_Item__c();
            if(String.isBlank(productWrapper.selectedDonationOption)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR ,DONATION_ERROR
                        + FundDonationService.getCurrencySymbol(donationPage.dn8n__Currency_ISO_Code__c) + donationPage.dn8n__Minimum_Donation__c));
                return null;
            }
            if(productWrapper.selectedDonationOption == OTHER_DONATION_OPTION){
                shoppingCartItem.pymt__Unit_Price__c = productWrapper.donationAmount;
            } else{
                shoppingCartItem.pymt__Unit_Price__c = Decimal.valueOf(productWrapper.selectedDonationOption);
            }
            if(shoppingCartItem.pymt__Unit_Price__c == null || (donationPage.dn8n__Minimum_Donation__c != null && shoppingCartItem.pymt__Unit_Price__c < donationPage.dn8n__Minimum_Donation__c)
                    || (donationPage.dn8n__Minimum_Donation__c == null && shoppingCartItem.pymt__Unit_Price__c <= 0)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DONATION_ERROR
                        + FundDonationService.getCurrencySymbol(donationPage.dn8n__Currency_ISO_Code__c) + donationPage.dn8n__Minimum_Donation__c));
                return null;
            }
            shoppingCartItem.Name = productWrapper.product.Name;
            shoppingCartItem.pymt__Product__c = productWrapper.product.Id;
            shoppingCartItem.pymt__Quantity__c = 1;
            shoppingCartItems.add(shoppingCartItem);
            paymentAmount = paymentAmount + shoppingCartItem.pymt__Unit_Price__c;
        }
        List<Contact> existingContacts = [SELECT Id, FirstName, LastName, Email, AccountId, MailingStreet, MailingCity,
                MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Email = :emailAddress LIMIT 1];
        Contact myContact;
        Savepoint sp = Database.setSavepoint();
        try{
            if (existingContacts.isEmpty()) { // not found
                Account newAccount = new Account();
                if (String.isBlank(companyName)) {
                    companyName = firstName + ' ' + lastName;
                }
                newAccount.Name = companyName;
                newAccount.BillingStreet = address;
                newAccount.BillingCity = city;
                newAccount.BillingState = billingState;
                newAccount.BillingPostalCode = billingPostalCode;
                newAccount.BillingCountry = billingCountry;
                newAccount.npe01__SYSTEMIsIndividual__c = true;
                insert newAccount;
                myContact = getContactFromFormInfo(newAccount.Id);
                insert myContact;
            } else { // found
                myContact = existingContacts[0];
            }
            String paymentId;
            if(!isRecurring) {
                pymt__PaymentX__c paymentX = new pymt__PaymentX__c();
                paymentX.pymt__Contact__c = myContact.Id;
                paymentX.dn8n__Donation_Page__c = donationPage.Id;
                paymentX.pymt__Processor_Connection__c = donationPage.dn8n__Processor_Connection__c;
                paymentX.pymt__Date__c = Date.today();
                paymentX.pymt__Billing_Last_Name__c = myContact.LastName;
                paymentX.pymt__Billing_First_Name__c = myContact.FirstName;
                paymentX.pymt__Billing_City__c = myContact.MailingCity;
                paymentX.pymt__Billing_Email__c = myContact.Email;
                paymentX.pymt__Billing_Company__c = companyName;
                paymentX.pymt__Billing_Postal_Code__c = myContact.MailingPostalCode;
                paymentX.pymt__Billing_Country__c = myContact.MailingCountry;
                paymentX.pymt__Billing_State__c = myContact.MailingState;
                paymentX.pymt__Billing_Street__c = myContact.MailingStreet;
                paymentX.Name = donationPage.dn8n__Payment_Record_Name__c;
                paymentX.pymt__Currency_ISO_Code__c = donationPage.dn8n__Currency_ISO_Code__c;
                paymentX.pymt__Payment_Processor__c = donationPage.dn8n__Processor_Connection__r.pymt__Processor_Id__c;
                paymentX.pymt__Amount__c = paymentAmount;
                paymentX.pymt__Status__c = 'In Process';
                paymentX.Memo__c = optionalDonationMessage;
                paymentX.Name_and_Address__c = honoreeNameAndAddress;
                paymentX.Interested_in_an_estate_legacy_gift__c = interestedInLearningMoreAboutEstateLegacyGift;
                paymentX.My_employer_is_matching_my_donation__c = employerMatchingDonation;
                paymentX.dn8n__Donation__c = true;
                paymentX.In_Honor_Of_or_In_Memory_Of__c = inHonorMemoryValue;
                paymentX.Optional_Phone_Number__c = phoneNumber;

                insert paymentX;
                paymentId = paymentX.Id;

                for(pymt__Shopping_Cart_Item__c item : shoppingCartItems){
                    item.pymt__Payment__c = paymentX.Id;
                }
                insert shoppingCartItems;
            } else {
                pymt__Payment_Profile__c paymentProfile = new pymt__Payment_Profile__c();
                paymentProfile.pymt__Contact__c = myContact.Id;
                paymentProfile.Donation_Product__c = selectedProductId;
                paymentProfile.dn8n__Donation_Page__c = donationPage.Id;
                paymentProfile.pymt__Processor_Connection__c = donationPage.dn8n__Processor_Connection__c;
                paymentProfile.pymt__Subscription_Start_Date__c = Date.today();
                paymentProfile.pymt__Billing_Last_Name__c = myContact.LastName;
                paymentProfile.pymt__Billing_First_Name__c = myContact.FirstName;
                paymentProfile.pymt__Billing_City__c = myContact.MailingCity;
                paymentProfile.pymt__Billing_Email__c = myContact.Email;
                paymentProfile.pymt__Billing_Company__c = companyName;
                paymentProfile.pymt__Billing_Postal_Code__c = myContact.MailingPostalCode;
                paymentProfile.pymt__Billing_Country__c = myContact.MailingCountry;
                paymentProfile.pymt__Billing_State__c = myContact.MailingState;
                paymentProfile.pymt__Billing_Street__c = myContact.MailingStreet;
                paymentProfile.Name = donationPage.dn8n__Payment_Record_Name__c;
                paymentProfile.pymt__Currency_ISO_Code__c = donationPage.dn8n__Currency_ISO_Code__c;
                paymentProfile.pymt__Amount__c = paymentAmount;
                paymentProfile.pymt__Subscription_Status__c = 'Not Activated';
                paymentProfile.Memo__c = optionalDonationMessage;
                paymentProfile.In_Honor_Of_or_In_Memory_Of__c = inHonorMemoryValue;
                paymentProfile.Name_and_Address__c = honoreeNameAndAddress;
                paymentProfile.Interested_in_an_estate_legacy_gift__c = interestedInLearningMoreAboutEstateLegacyGift;
                paymentProfile.My_employer_is_matching_my_donation__c = employerMatchingDonation;
                paymentProfile.pymt__Account__c = myContact.AccountId;
                paymentProfile.pymt__Total_Occurrences__c = String.isNotBlank(occurrences) && occurrences.isNumeric() ? Integer.valueOf(occurrences) : null;
                paymentProfile.pymt__Frequency__c = 1;
                paymentProfile.pymt__Period__c = selectedRecurringPeriod;
                paymentProfile.RecordTypeId = getRecurringRecordType(donationPage.dn8n__Processor_Connection__r.pymt__Processor_Id__c);
                insert paymentProfile;
                paymentId = paymentProfile.Id;
            }
            PageReference redirectPageReference = getRedirectPage(paymentId);
            return redirectPageReference;
        }
        catch(Exception e){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    // Selecting and deselecting funds
    public String selectedProductId {get; set;}
    public void selectFund() {
        if (isRecurring) {
            if (selectedProductWrappersByProductId.size() == 1) {
                productWrappersByProductId.get(selectedProductWrappersByProductId.values().get(0).product.Id).isSelected = false;
            }
            selectedProductWrappersByProductId.clear();
        }
        selectedProductWrappersByProductId.put(selectedProductId, productWrappersByProductId.get(selectedProductId));
    }
    public void deselectFund() {
        selectedProductWrappersByProductId.remove(selectedProductId);
        productWrappersByProductId.get(selectedProductId).isSelected = false;
        selectedProductId = null;
    }
    public void toggleFund() {
        if (selectedProductWrappersByProductId.containsKey(selectedProductId)) {
            deselectFund();
        } else {
            selectFund();
        }
    }
    public void recurringFundValidation() {
        if (selectedProductWrappersByProductId.size() > 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RECURRING_DONATION_ERROR));
            isRecurring = false;
        } else {
            if (selectedProductWrappersByProductId.size() == 1) {
                selectedProductId = selectedProductWrappersByProductId.values().get(0).product.Id;
            } else {
                selectedProductId = null;
            }
        }
    }

    public class ProductWrapper {
        public Boolean isSelected {get; set;}
        public Product2 product {get; set;}
        public Decimal donationAmount {get; set;}
        public String selectedDonationOption{get;set;}
        public Boolean isHiddenFromSearch{get;set;}
        public Boolean isDisplayOnDonationPage{get;set;}

        public ProductWrapper(Product2 product) {
            this.donationAmount = 0;
            this.product = product;
            this.isHiddenFromSearch = product.Hide_from_Search_Bar__c;
            this.isDisplayOnDonationPage = product.Display_on_Donation_Page__c;
        }
    }

    // Helpers
    private Id getRecurringRecordType(String processorName){
        Id typeId;
        Map<String, String> recordTypeDeveloperNamebyProcessorName = FundDonationService.recordTypeDeveloperNamebyProcessorName;
        if(String.isNotBlank(processorName) && recordTypeDeveloperNamebyProcessorName.containsKey(processorName)){
            List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperNamebyProcessorName.get(processorName) AND SobjectType = :'pymt__Payment_Profile__c' LIMIT 1];
            if(!recordTypes.isEmpty()){
                typeId = recordTypes[0].Id;
            }
        }
        return typeId;
    }
    private PageReference getRedirectPage(String payId){
        PageReference ref;
        if(!isRecurring){
            ref = Page.pymt__SiteCheckout;
            ref.getParameters().put('pid', payId);
            ref.setRedirect(true);
        } else{
            ref = Page.pymt__sitesubscribe;
            ref.getParameters().put('ppid', payId);
            ref.setRedirect(true);
        }
        if(String.isNotBlank(donationPage.dn8n__Confirmation_URL__c)){
            ref.getParameters().put('finish_url', donationPage.dn8n__Confirmation_URL__c);
        }
        return ref;
    }
    private Contact getContactFromFormInfo(String accountId) {
        Contact con = new Contact();
        con.AccountId = accountId;
        con.Salutation = salutation;
        con.FirstName = firstName;
        con.LastName = lastName;
        con.Email = emailAddress;
        con.MailingStreet = address;
        con.MailingCity = city;
        con.MailingState = billingState;
        con.MailingPostalCode = billingPostalCode;
        con.MailingCountry = billingCountry;
        return con;
    }
    private static Boolean isNumeric(String s){
        Boolean returnValue;
        try{
            Decimal.valueOf(s);
            returnValue = true;
        } catch (TypeException e) {
            returnValue = false;
        }
        return returnValue;
    }
}