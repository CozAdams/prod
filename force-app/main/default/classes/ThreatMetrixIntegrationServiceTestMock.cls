/*******************************************************************************************************
* @author Lev
* @date 2021
*
* @description Mock test utility for ThreatMetrixIntegrationServiceTest
*/
@isTest
global class ThreatMetrixIntegrationServiceTestMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        String responseBody = '{ "policy_details_api": { "policy_detail_api": [ { "customer": { "score": "-24", "review_status": "review", "risk_rating": "medium" } } ] }, }';

        HttpResponse resp = new HttpResponse();
        resp.setBody(responseBody);
        resp.setStatusCode(200);
        resp.setHeader('Content-Type', 'application/json');
        return resp;
    }
}