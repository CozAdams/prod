@IsTest
private class TwilioAPILightningControllerTest {
    private static final String SECRET_KEY_HEADER = 'X-Authy-API-Key';
    private static final String VIA = 'SMS';
    private static final String ISO_CODE = 'United States';
    private static final String COUNTRY_CODE = '1';
    private static final String PHONE_NUMBER = '5555555555';
    private static final String EMAIL = 'test@example.com';
    private static final String VERIFICATION_CODE = '123456789';
    private static final String USER_ID = '12345';
    @isTest private static void getVerificationCode_UserAlreadyExist_ReturnSuccess(){
        Test.setMock(HttpCalloutMock.class, new HttpMockAuthy());
        Test.startTest();
            Map<String, Object> responseJSON = (Map<String, Object>)
                JSON.deserializeUntyped(TwilioAPILightningController.getVerificationCode(COUNTRY_CODE, PHONE_NUMBER, USER_ID, VIA));
        Test.stopTest();
        System.assert((Boolean)responseJSON.get('success'), 'Expecting the HTTP request return with information');

    }
    @isTest private static void getVerificationCode_UserDoesNotAlreadyExist_ReturnSuccess(){
        Test.setMock(HttpCalloutMock.class, new HttpMockVerify());
        Test.startTest();
            Map<String, Object> responseJSON = (Map<String, Object>)
                JSON.deserializeUntyped(TwilioAPILightningController.getVerificationCode(COUNTRY_CODE, PHONE_NUMBER, '', VIA));
        Test.stopTest();
        System.assert((Boolean)responseJSON.get('success'), 'Expecting the HTTP request return with information');
    }
    @isTest private static void confirmVerificationCode_UserAlreadyExist_ReturnSuccess(){
        Test.setMock(HttpCalloutMock.class, new HttpMockAuthy());
        Test.startTest();
            Map<String, Object> responseJSON = (Map<String, Object>)
                JSON.deserializeUntyped(TwilioAPILightningController.confirmVerificationCode(COUNTRY_CODE, PHONE_NUMBER, EMAIL, VERIFICATION_CODE, USER_ID));
        Test.stopTest();
        System.assert((Boolean)responseJSON.get('success'), 'Expecting the HTTP request return with information');
    }

    @isTest private static void confirmVerificationCode_UserDoesNotExist_ReturnSuccess(){
        Test.setMock(HttpCalloutMock.class, new HttpMockVerify());
        Test.startTest();
            Map<String, Object> responseJSON = (Map<String, Object>)
                JSON.deserializeUntyped(TwilioAPILightningController.confirmVerificationCode(COUNTRY_CODE, PHONE_NUMBER, EMAIL, VERIFICATION_CODE, ''));
        Test.stopTest();
        System.assert((Boolean)responseJSON.get('success'), 'Expecting the HTTP request return with information');
    }

    @isTest private static void retrieveISOandCountryCode() {
        Test.startTest();
            Map<String, Object> frontEndPackage = (Map<String, Object>) TwilioAPILightningController.retrieveISOandCountryCode();
        Test.stopTest();
            Map<String, List<String>> isoToCountryCodeMap = (Map<String, List<String>>)frontEndPackage.get('isoToCountryCodeMap');
            Sobject userContact = (Sobject) frontEndPackage.get('contact');

        List<String> countryCodeList = isoToCountryCodeMap.get(ISO_CODE);
        System.assert(isoToCountryCodeMap.containsKey(ISO_CODE), 'US is the standard iso code and should always be in the meta data ISO to Country Codes');
        System.assertEquals(COUNTRY_CODE, countryCodeList[0], 'The correct country code should be mapped to the iso code');
        System.assertEquals(Contact.SobjectType, userContact.getSObjectType(), 'The return value should be a contact sobject');
    }

    private class HttpMockVerify implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assert(req.getEndpoint().contains(Label.Twilio_API_Base_Url),
                'The end point should always been pointing to the Twilio base url');
            System.assertEquals(Label.Twilio_API_Production_Key, req.getHeader(SECRET_KEY_HEADER),
                'The secret key should always been included in the header');
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new TwilioResponse('good', true)));
            res.setStatusCode(200);
            return res;
        }
    }

    private class HttpMockAuthy implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            System.assert(req.getEndpoint().contains(Label.Twilio_API_Base_Url),
                'The end point should always been pointing to the Twilio base url');
            System.assert(req.getEndpoint().contains(USER_ID),
                'The end point for Authy API should have the Twilio Id included');
            System.assertEquals(Label.Twilio_API_Production_Key, req.getHeader(SECRET_KEY_HEADER),
                'The secret key should always been included in the header');
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new TwilioResponse('good', true)));
            res.setStatusCode(200);
            return res;
        }
    }
    private class TwilioResponse {
        public String message;
        public Boolean success;
        public TwilioResponse(String message, Boolean success) {
            this.message = message;
            this.success = success;
        }
    }
}