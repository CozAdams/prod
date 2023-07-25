/**
* @author Lev
* @date 2021
*
* @description Test class for ThreatMetrixIntegrationService
*/
@IsTest
private class ThreatMetrixIntegrationServiceTest {
    /* TEST DATA */
    static String calloutString;
    static ThreatMetrixIntegrationServiceTestMock mock;

    /* TEST DATA INITIALIZATION */
    static void init(Boolean includeMock) {
        // Callout mock
        if (includeMock) {
            calloutString = 'TEST';
            mock = new ThreatMetrixIntegrationServiceTestMock();
            Test.setMock(HttpCalloutMock.class, mock);
        }
    }

    /* TEST METHODS */
    @isTest
    static void testGetSfdcSessionId_codeCoverage() {
        // Code coverage only, since session is not available for testing during deploy
        System.Test.startTest();
        Map<String, String> sessionMap = ThreatMetrixIntegrationService.getSfdcSession();
        System.Test.stopTest();
    }

    @isTest
    static void testGetIntegrationDetails() {
        System.Test.startTest();
        List<ThreatMetrix_Integration__mdt> queryInfo = ThreatMetrixIntegrationService.getIntegrationDetails('Withdrawal');
        System.Test.stopTest();

        // Assert that the callout details were returned
        System.assertNotEquals(0, queryInfo.size());
    }

    @isTest
    static void testSendJsonRequest() {
        init(true);

        System.Test.startTest();
        String response = ThreatMetrixIntegrationService.sendJsonRequest(calloutString, 'POST');
        System.Test.stopTest();

        // Assert that the response body is returned 
        System.assertEquals(false, String.isBlank(response));
    }
}