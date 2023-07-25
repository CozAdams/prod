public with sharing class TwilioAPIServices {
    private final String VERIFY_URL;
    private final String VERIFY_CONFIRM_URL;
    private final String AUTHY_CREATE_USER_URL;
    private final String AUTHY_REMOVE_USER_URL;
    private final String AUTHY_URL;
    private final String AUTHY_CONFIRM_URL;
    private final String API_KEY;
    public TwilioAPIServices() {
        String baseUrl = Label.Twilio_API_Base_Url;
        this.VERIFY_URL = baseUrl + '/protected/json/phones/verification/start';
        this.VERIFY_CONFIRM_URL = baseUrl + '/protected/json/phones/verification/check';
        this.AUTHY_CREATE_USER_URL = baseUrl + '/protected/json/users/new';
        this.AUTHY_URL = baseUrl + '/protected/json/{via}/{AUTHY_ID}';
        this.AUTHY_CONFIRM_URL = baseUrl + '/protected/json/verify/{TOKEN}/{AUTHY_ID}';
        this.API_KEY = Label.Twilio_API_Production_Key;
    }
    public String verifyPhoneNumber(String via, String countryCode, String phoneNumber) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();

        req.setEndPoint(this.VERIFY_URL);
        req.setHeader('X-Authy-API-Key', this.API_KEY);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');

        req.setBody(JSON.serialize(new VerifyPhonePayLoad(via, phoneNumber, Integer.valueOf(countryCode))));

        try{
            resp = http.send(req);
            return resp.getBody();
        } catch(CalloutException ex) {
            return JSON.serialize(new TwilioResponse(ex.getMessage(), false));
        }
    }

    public class VerifyPhonePayLoad {
        String via;
        String phone_number;
        Integer country_code;
        Integer code_length = 6;
        String locale = 'en';
        public VerifyPhonePayLoad(String via, String phone_number, Integer country_code) {
            this.via = via;
            this.phone_number = phone_number;
            this.country_code = country_code;
        }
    }

    public String firstTimeConfirmToken(String countryCode, String phoneNumber, String verificationCode) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();

        req.setEndPoint(this.VERIFY_CONFIRM_URL + '?phone_number=' + phoneNumber + '&country_code=' + countryCode + '&verification_code=' + verificationCode);
        req.setHeader('X-Authy-API-Key', this.API_KEY);
        req.setMethod('GET');

        try{
            resp = http.send(req);
            return resp.getBody();
        } catch(CalloutException ex) {
            return JSON.serialize(new TwilioResponse(ex.getMessage(), false));
        }
    }

    public String createdAuthyUser(String phoneNumber, String email, String countryCode) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();

        req.setEndPoint(this.AUTHY_CREATE_USER_URL);
        req.setHeader('X-Authy-API-Key', this.API_KEY);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');

        req.setBody(JSON.serialize(new AuthyCreateUserPayload(new UserInfo(email, phoneNumber, countryCode))));

        try{
            resp = http.send(req);
            return resp.getBody();
        } catch(CalloutException ex) {
            return JSON.serialize(new TwilioResponse(ex.getMessage(), false));
        }
    }

    public String authyRequestVerificationCode(String via, String userId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        req.setEndPoint(this.AUTHY_URL.replace('{via}', via).replace('{AUTHY_ID}', userId));
        req.setHeader('X-Authy-API-Key', this.API_KEY);
        req.setMethod('GET');

        try{
            resp = http.send(req);
            return resp.getBody();
        } catch(CalloutException ex) {
            return JSON.serialize(new TwilioResponse(ex.getMessage(), false));
        }
    }

    public String authyConfirmToken(String verificationCode, String userId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();

        req.setEndPoint(this.AUTHY_CONFIRM_URL.replace('{TOKEN}', verificationCode).replace('{AUTHY_ID}', userId));
        req.setHeader('X-Authy-API-Key', this.API_KEY);
        req.setMethod('GET');

        try{
            resp = http.send(req);
            return resp.getBody();
        } catch(CalloutException ex) {
            return JSON.serialize(new TwilioResponse(ex.getMessage(), false));
        }
    }
    public class TwilioResponse {
        public String message;
        public Boolean success;

        public TwilioResponse(String message, Boolean success) {
            this.message = message;
            this.success = success;
        }
    }

    public class AuthyCreateUserPayload {
        public UserInfo user;
        public AuthyCreateUserPayload(UserInfo user) {
            this.user = user;
        }
    }
    public class UserInfo {
        private String email;
        private String cellphone;
        private String country_code;
        public UserInfo(String email, String cellphone, String country_code) {
            this.email = email;
            this.cellphone = cellphone;
            this.country_code = country_code;
        }
    }
}