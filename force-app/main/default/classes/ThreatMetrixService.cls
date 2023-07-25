public with sharing class ThreatMetrixService {

    public static final String requestEndpoint= 'Threat_Metrix_OTP_';
    public static final String confirmationEndpoint = 'Threat_Metrix_OTP_Confirmation';

    @AuraEnabled
    public static String requestOTP(String format, String contactInfo) {

        format = format.toLowerCase();
        String selectedEndpoint = requestEndpoint + format;
        ThreatMetrix_Integration__mdt calloutDetail = [
            SELECT Id, MasterLabel, DeveloperName, Method_Type__c, Dynamic_Payload__c
            FROM ThreatMetrix_Integration__mdt
            WHERE DeveloperName = :selectedEndpoint
            LIMIT 1
            ];
        Map<String, Object> responseData;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        try{


            if(format == 'sms'){
                request.setEndpoint('callout:' + requestEndpoint + 'phone');
            }else{
                request.setEndpoint('callout:' + requestEndpoint + format);
            }

            request.setBody(calloutDetail.Dynamic_PayLoad__c.replace('{{' + format + '}}', contactInfo));
            request.setMethod(calloutDetail.Method_Type__c);
            request.setHeader('Content-Type','application/json;charset=UTF-8');
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                system.debug(response.getStatusCode());
                system.debug(response.getBody());
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug(results);
                responseData = (Map<String, Object>) results.get('Status');
                return String.valueOf(responseData.get('ConversationId'));
            }
            else{
                System.debug('Failed API callout. ' + response.getStatusCode() + ': ' + response.getBody());
                throw new AuraHandledException(response.getStatusCode() + ': ' + response.getBody()); 
            }
        }
        catch(Exception e){
            throw new AuraHandledException('Something went wrong: '
            + e.getMessage()+ ' '+ e.getLineNumber() + ' ' + e.getCause());
            
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean confirmOTP(String conversationNumber, String inputNumber) {
        System.debug('conversationNumber: ' + conversationNumber);
        System.debug('inputNumber: ' + inputNumber);
        ThreatMetrix_Integration__mdt calloutDetail = [
            SELECT Id, MasterLabel, DeveloperName, Method_Type__c, Dynamic_Payload__c
            FROM ThreatMetrix_Integration__mdt
            WHERE DeveloperName = :confirmationEndpoint
            LIMIT 1
            ];
        Map<String, Object> responseData;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        try{
            request.setEndpoint('callout:' + confirmationEndpoint + '/' + conversationNumber);
            request.setBody(calloutDetail.Dynamic_PayLoad__c.replace('{{passcode}}', inputNumber));
            request.setMethod(calloutDetail.Method_Type__c);
            request.setHeader('Content-Type','application/json;charset=UTF-8');
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                system.debug(response.getStatusCode());
                system.debug(response.getBody());
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug(results);
                responseData = (Map<String, Object>) results?.get('Status');
                return String.valueOf(responseData.get('TransactionStatus')) == 'passed';
            }
            else{
                System.debug('Failed API callout. ' + response.getStatusCode() + ': ' + response.getBody());
                throw new AuraHandledException(response.getStatusCode() + ': ' + response.getBody()); 
            }
        }
        catch(Exception e){
            throw new AuraHandledException('Something went wrong: '
            + e.getMessage()); 
        }
    }

     @AuraEnabled
    public static User getUserContactDetails(Id userId) {
        List<User> userList = 
            [
                SELECT Id, Contact.FirstName, Contact.LastName, Contact.Email, ContactId, Contact.Phone, Contact.MobilePhone,Contact.HomePhone, 
                        Contact.npe01__PreferredPhone__c, Contact.OtherPhone, Twilio_Phone_Number__c	
	             FROM User
    	         WHERE Id = :userId LIMIT 1
            ];
        if(userList.size() > 0){
            return userList[0];
        }
        Throw new AuraException('No related contact found');
    }


}