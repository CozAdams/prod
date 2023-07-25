public with sharing class FundDonationService {

    public static final String PUBLISHED = 'Published';

    public static Map<String, String> recordTypeDeveloperNamebyProcessorName {
        get {
            if (recordTypeDeveloperNamebyProcessorName == null) {
                recordTypeDeveloperNamebyProcessorName = new Map<String, String>();
                List<Funds_Donation_Processor_Mapping__mdt> fundsDonationMdts = [SELECT Processor_Name__c, Record_Type__c FROM Funds_Donation_Processor_Mapping__mdt];
                for (Funds_Donation_Processor_Mapping__mdt mdt : fundsDonationMdts) {
                    recordTypeDeveloperNamebyProcessorName.put(mdt.Processor_Name__c, mdt.Record_Type__c);
                }
            }
            return recordTypeDeveloperNamebyProcessorName;
        }
        set;
    }

    public static List<SelectOption> getCountryOptions() {
        List<Country__c> countries = Country__c.getAll().values();
        List<SelectOptionWrapper> countryOptionWrappers = new List<SelectOptionWrapper>();
        for (Country__c country : countries) {
            countryOptionWrappers.add(new SelectOptionWrapper(new SelectOption(country.ISO__c, country.Label__c)));
        }
        countryOptionWrappers.sort();
        return wrappersToSelectOptions(countryOptionWrappers);
    }

    public static List<SelectOption> getStateOptions(String countryISO) {
        List<State__c> states = State__c.getAll().values();
        List<SelectOptionWrapper> stateOptionWrappers = new List<SelectOptionWrapper>();
        for (State__c state : states) {
            if (state.CountryISO__c == countryISO) {
                stateOptionWrappers.add(new SelectOptionWrapper(new SelectOption(state.ISO__c, state.Label__c)));
            }
        }
        stateOptionWrappers.sort();
        return wrappersToSelectOptions(stateOptionWrappers);
    }

    public static String getCurrencySymbol(String currencyCode) {
        if (String.isNotBlank(currencyCode)) {
            return Currency__c.getInstance(currencyCode).Symbol__c;
        }
        return '';
    }

    private static List<SelectOption> wrappersToSelectOptions(List<SelectOptionWrapper> wrappers) {
        List<SelectOption> selectOptions = new List<SelectOption>();
        for (SelectOptionWrapper wrapper : wrappers) {
            selectOptions.add(wrapper.selectOption);
        }
        return selectOptions;
    }

    public class SelectOptionWrapper implements Comparable {
        public SelectOption selectOption {get; set;}

        public SelectOptionWrapper(SelectOption selectOption) {
            this.selectOption = selectOption;
        }

        public Integer compareTo(Object selectOptionParam) {
            SelectOption selectOption = ((SelectOptionWrapper) selectOptionParam).selectOption;
            return this.selectOption.getLabel().compareTo(selectOption.getLabel());
        }
    }
}