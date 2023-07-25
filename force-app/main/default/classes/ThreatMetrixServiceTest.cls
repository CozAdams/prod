@isTest
private class ThreatMetrixServiceTest {

    
    private class testRequestOtpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"Status":{"ConversationId":"31000977688819","RequestId":"1493476889","TransactionStatus":"pending","ActionType":"otp","Reference":"REST_Transaction"},"Products":[{"ProductType":"OTP","ExecutedStepName":"OTP","ProductConfigurationName":"PFCC_OTP_Default","ProductStatus":"pending"}]}');
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');

                return res;

        }
    }

    private class testRequestOtpFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('tionId":"31000977688819","RequestId":"1493476889","TransactionStatus":"pending","ActionType":"otp","Reference":"REST_Transaction"},"Products":[{"ProductType":"OTP","ExecutedStepName":"OTP","ProductConfigurationName":"PFCC_OTP_Default","ProductStatus":"pending"}]}');
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');

                return res;

        }
    }

    private class testSendJsonRequestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"Status":{"ConversationId":"31000977688819","RequestId":"1493486259","TransactionStatus":"passed","Reference":"REST_Transaction"},"Products":[{"ProductType":"OTP","ExecutedStepName":"OTP","ProductConfigurationName":"PFCC_OTP_Default","ProductStatus":"pass"}]}');
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');

                return res;

        }
    }




    @isTest
    static void testRequestOTP() {
        Test.setMock(HttpCalloutMock.class, new testRequestOtpMock());
        System.Test.startTest();
        String otpInfo = ThreatMetrixService.requestOTP('phone','AB4131000AB');
        System.Test.stopTest();

        // Assert that the callout details were returned
        System.assertEquals(false, String.isBlank(otpInfo));
    }
 

    @isTest
    static void testSendJsonRequest() {
        Test.setMock(HttpCalloutMock.class, new testSendJsonRequestMock());

        System.Test.startTest();
        Boolean response = ThreatMetrixService.confirmOTP('48198374910', '32134');
        System.Test.stopTest();

        // Assert that the response body is returned 
        System.assert(response);
    }
    @isTest
    static void testGetUserContactDetails(){



        Account org = TestDataFactory.createAccount(true, 'Organization', 'TESTORG');
        Contact memberContact = TestDataFactory.createContact(true, org.Id, 'TESTING');
        User memberUser = TestDataFactory.createUser(true, 'PFCC Employer Portal', memberContact.Id);

        System.Test.startTest();
        User testUser = ThreatMetrixService.getUserContactDetails(memberUser.Id);
        System.Test.stopTest();


    }


}