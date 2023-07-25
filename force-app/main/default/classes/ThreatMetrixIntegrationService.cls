/*******************************************************************************************************
* @author Lev
* @date 2021
*
* @description Integration service for ThreatMetrix action risk analysis
*/
public class ThreatMetrixIntegrationService {
    /*******************************************************************************************************
    * @description  Get session details for session IDs, IP address, and username
    * @return       SFDC session
    */
    @AuraEnabled 
    public static Map<String, String> getSfdcSession() {
        Map<String, String> sessionMap;
        if (!Test.isRunningTest()) sessionMap = Auth.SessionManagement.getCurrentSession();
        return sessionMap;
    }

    /*******************************************************************************************************
    * @description  Retrieve callout details for a specified community user action
    * @param        actionType - community user action that needs risk analysis
    * @return       custom metadata record with callout details
    */
    @AuraEnabled
    public static List<ThreatMetrix_Integration__mdt> getIntegrationDetails(String actionType) {
        List<ThreatMetrix_Integration__mdt> queryInfo = [
            SELECT API_Key__c, Org_ID__c, REST_Endpoint__c, Method_Type__c, Application_Name__c, Service_Type__c, 
                Event_Type__c, Policy__c, Customer_Event_Type__c
            FROM ThreatMetrix_Integration__mdt
            WHERE DeveloperName = :actionType
        ];
        return queryInfo;
    }

    /*******************************************************************************************************
    * @description  Send JSON request to ThreatMetrix
    * @param        calloutString - URL of callout endpoint with params
    *@param         methodType - request type to use
    * @return       callouts response body
    */
    @AuraEnabled 
    public static String sendJsonRequest(String calloutString, String methodType) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(calloutString);
        request.setMethod(methodType);
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        String responseBody;
        try {
            HttpResponse response = http.send(request);
            responseBody = response.getBody();
        }
        catch(Exception e) {
            // System.debug('ERROR: ' + e.getMessage());
            // TO DO: INSERT ERROR LOG
            // String url = calloutString.split('?')[0];
            // String errorMsg = 'Error during ' + methodType + ' callout to ' + url + ': ' + e.getMessage();
            // insertErrorLog(errorMsg, methodType, apiLog);
        }
        return responseBody;
    }
}