@IsTest
private class FundDonationServiceTest {
	@TestSetup
	static void setup() {
        SObjectFactory.create(Country__c.SObjectType, new Map<Schema.SObjectField, Object> {
            Country__c.Name => 'CA',
            Country__c.ISO__c => 'CA',
            Country__c.Label__c => 'Canada'
        });
		SObjectFactory.create(Country__c.SObjectType, new Map<Schema.SObjectField, Object> {
			Country__c.Name => 'US',
			Country__c.ISO__c => 'US',
			Country__c.Label__c => 'United States'
		});

		SObjectFactory.create(State__c.SObjectType, new Map<Schema.SObjectField, Object> {
			State__c.Name => 'US-AK',
			State__c.CountryISO__c => 'US',
			State__c.ISO__c => 'AK',
			State__c.Label__c => 'Alaska'
		});

        SObjectFactory.create(Currency__c.SObjectType, new Map<Schema.SobjectField, Object> {
            Currency__c.Name => 'USD',
            Currency__c.Symbol__c => '$'
        });
	}	

	@IsTest
	static void testRecordTypeDeveloperNamebyProcessorName() {
        Test.startTest();
		Map<String, String> fieldMap = FundDonationService.recordTypeDeveloperNamebyProcessorName;
		List<Funds_Donation_Processor_Mapping__mdt> fundsDonationMdts = [SELECT Processor_Name__c, Record_Type__c FROM Funds_Donation_Processor_Mapping__mdt];
        Set<String> fieldKeys = fieldMap.keySet();
        Set<String> fieldValues = new Set<String>(fieldMap.values());
        Test.stopTest();

		System.assertEquals(fundsDonationMdts.size(),fieldMap.keySet().size(), 
			'Expecting the fieldMap of fundsDonation Meta Datas has the same size of the fundsDonation Meta Datas retrieved');
		for (Funds_Donation_Processor_Mapping__mdt mdt : fundsDonationMdts) {
			System.assert(fieldKeys.contains(mdt.Processor_Name__c), 'Expecting the keys of the fieldMap for fundsDonation Meta Data contains all Processor Names from fundsDonation Meta Datas retrieved');
			System.assert(fieldValues.contains(mdt.Record_Type__c), 'Expecting the values of the fieldMap for fundsDonation Meta Data contains all Record Type froms fundsDonation Meta Datas retrieved');
		}
	}

	@IsTest
	static void testGetCountryOptions() {
        Test.startTest();
		List<SelectOption> countryOptions = FundDonationService.getCountryOptions();
		Map<String,List<Country__c>> countriesMap = (Map<String, List<Country__c>>) GroupBy.strings('ISO__c',Country__c.getAll().values());
        Test.stopTest();

        System.assertEquals('Canada', countryOptions.get(0).getLabel(), 'Asserting that Canada will come before the US alphabetically');
		System.assertEquals(countriesMap.keySet().size(), countryOptions.size(), 'Expecting the country options contain all countries created in custom settings');
		for (SelectOption countryOption : countryOptions) {
			String countryISO = countryOption.getValue();
			Country__c country = countriesMap.get(countryISO).get(0);
			System.assert(country != null, 'Expecting getting the country object with specific ISO code');
			System.assertEquals(countryOption.getLabel(), country.Label__c, 'Expecting the SelectOption contains the correct label that has been set in custom setting');
		}
	}

	@IsTest
	static void testGetStateOptions() {
        Test.startTest();
		List<SelectOption> stateOptions = FundDonationService.getStateOptions('US');
		Map<String,List<State__c>> statesMap = (Map<String, List<State__c>>) GroupBy.strings('ISO__c',State__c.getAll().values());
        Test.stopTest();

		System.assertEquals(statesMap.keySet().size(), stateOptions.size(), 'Expecting the state options contain all states created in custom settings');
		for (SelectOption stateOption : stateOptions) {
			String stateISO = stateOption.getValue();
			State__c state = statesMap.get(stateISO).get(0);
			System.assert(state != null, 'Expecting getting the state object with specific ISO code');
			System.assertEquals(stateOption.getLabel(), state.Label__c, 'Expecting the SelectOption contains the correct label that has been set in custom setting');
		}
	}

    @IsTest
    static void testCurrencyOptions() {
        Test.startTest();
        String currencySymbol = FundDonationService.getCurrencySymbol('USD');
        Test.stopTest();

        System.assertEquals('$', currencySymbol, 'Make sure that that the currency code matches the ISO code.');
    }
}