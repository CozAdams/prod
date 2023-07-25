public class TwilioAPILightningController {
    @AuraEnabled
    public static String getVerificationCode(String countryCode, String phoneNumber, String twilioId, String via) {
        TwilioAPIServices apiService = new TwilioAPIServices();
        String response;
        if(string.isBlank(twilioId)) {
            response = apiService.verifyPhoneNumber(via, countryCode, phoneNumber);
        } else {
            response = apiService.authyRequestVerificationCode(via, twilioId);
        }
        return response;
    }

    @AuraEnabled
    public static String confirmVerificationCode(String countryCode, String phoneNumber, String email, String verificationCode, String twilioId) {
        TwilioAPIServices apiService = new TwilioAPIServices();
        String response;
        if(string.isBlank(twilioId)) {
            response = apiService.firstTimeConfirmToken(countryCode, phoneNumber, verificationCode);
            TwilioAPIServices.TwilioResponse respondValue = (TwilioAPIServices.TwilioResponse) JSON.deserialize(response, TwilioAPIServices.TwilioResponse.class);
            if(respondValue.success) {
                response = apiService.createdAuthyUser(phoneNumber, email, countryCode);
            }
        } else {
            response = apiService.authyConfirmToken(verificationCode, twilioId);
        }

        return response;
    }

    @AuraEnabled
    public static Object retrieveISOandCountryCode() {
        Map<String, Object> infoWrapper = new Map<String, Object>();
        Map<String, List<String>> isoToCountryCodesMap = new Map<String, List<String>>();
        List<String> phoneNumber = new List<String>();
        for(ISO_to_Country_Code__mdt isoToCountryCode : [
            SELECT ISO_Code__c,
                Country_Code__c
            FROM ISO_to_Country_Code__mdt
            ORDER BY ISO_Code__c, Country_Code__c]) {
            List<String> countryCodes = isoToCountryCodesMap.get(isoToCountryCode.ISO_Code__c);
            if(countryCodes == null) {
                countryCodes = new List<String>();
                isoToCountryCodesMap.put(isoToCountryCode.ISO_Code__c, countryCodes);
                
            }
            countryCodes.add(isoToCountryCode.Country_Code__c);
        }
        User currentUser = [SELECT ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        List<Contact> userContact = [
        SELECT MobilePhone,
                HomePhone,
                OtherPhone,
                Npe01__WorkPhone__c
            FROM Contact
            WHERE Id =: currentUser.ContactId LIMIT 1];


        infoWrapper.put('isoToCountryCodeMap', isoToCountryCodesMap);
        infoWrapper.put('contact', (!userContact.isEmpty()? userContact[0] : new Contact()));
        return infoWrapper;
    }
}