@isTest
private class TwilioAPIServicesTest {
    private static final String SECRET_KEY_HEADER = 'X-Authy-API-Key';
    private static final String VIA = 'SMS';
    private static final String COUNTRY_CODE = '1';
    private static final String PHONE_NUMBER = '5555555555';
    private static final String EMAIL = 'test@example.com';
    private static final String VERIFICATION_CODE = '123456789';
    private static final String USER_ID = '12345';

    @isTest private static void verifyPhoneNumber_SendPhoneCall_SuccessResponse(){
        Test.setMock(HttpCalloutMock.class, new HttpMockVerify());
        TwilioAPIServices apiService = new TwilioAPIServices();

        Test.startTest();
            String serializeJSON = apiService.verifyPhoneNumber(VIA, COUNTRY_CODE, PHONE_NUMBER);
        Test.stopTest();
        Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(serializeJSON);
        System.assert((Boolean) jsonBody.get('success'), 'The HTTP request should passed back the expecting value');
    }

    @isTest private static void firstTimeConfirmToken_SendCode_SuccessResponse(){
        Test.setMock(HttpCalloutMock.class, new HttpMockVerify());
        TwilioAPIServices apiService = new TwilioAPIServices();

        Test.startTest();
            String serializeJSON = apiService.firstTimeConfirmToken(COUNTRY_CODE, PHONE_NUMBER, VERIFICATION_CODE);
        Test.stopTest();
        Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(serializeJSON);
        System.assert((Boolean) jsonBody.get('success'), 'The HTTP request should passed back the expecting value');
    }

    @isTest private static void createdAuthyUser_SuccessfullyCreated(){
        Test.setMock(HttpCalloutMock.class, new HttpMockVerify());
        TwilioAPIServices apiService = new TwilioAPIServices();

        Test.startTest();
            String serializeJSON = apiService.createdAuthyUser(PHONE_NUMBER, EMAIL, COUNTRY_CODE);
        Test.stopTest();
        Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(serializeJSON);
        System.assert((Boolean) jsonBody.get('success'), 'The HTTP request should passed back the expecting value');
    }

    @isTest private static void authyRequestVerificationCode_SuccessResponse(){
        Test.setMock(HttpCalloutMock.class, new HttpMockAuthy());
        TwilioAPIServices apiService = new TwilioAPIServices();

        Test.startTest();
            String serializeJSON = apiService.authyRequestVerificationCode(VERIFICATION_CODE, USER_ID);
        Test.stopTest();
        Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(serializeJSON);
        System.assert((Boolean) jsonBody.get('success'), 'The HTTP request should passed back the expecting value');
    }

    @isTest private static void authyConfirmToken_SuccessResponse(){
        Test.setMock(HttpCalloutMock.class, new HttpMockAuthy());
        TwilioAPIServices apiService = new TwilioAPIServices();

        Test.startTest();
            String serializeJSON = apiService.authyConfirmToken(VERIFICATION_CODE, USER_ID);
        Test.stopTest();
        Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(serializeJSON);
        System.assert((Boolean) jsonBody.get('success'), 'The HTTP request should passed back the expecting value');
    }

    public class HttpMockVerify implements HttpCalloutMock {
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

    public class HttpMockAuthy implements HttpCalloutMock{
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