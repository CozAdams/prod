public class SovosPortalDocumentsController {

    @AuraEnabled(cacheable=true)
    public static List<FormObject> getData(String userId) {
        List<FormObject> lstFormRecords = new List<FormObject>();
        User userRec = [SELECT Id, ContactId, Contact.Social_Security_Number__c FROM User WHERE Id =: userId LIMIT 1];

        // Callout: Get Forms
        SovosIntegrationUtility util = new SovosIntegrationUtility(userRec.Contact.Social_Security_Number__c, null, null, null, null, null, null, false, null);
        List<String> str = new List<String>();
        str.add(JSON.serialize(util));
        List<String> lstResponse = SovosIntegrationService.getAllForms(str);
        
        if(lstResponse.size() > 0) {
            for(Object response : lstResponse) {
                
                String payload = string.valueOf(response);
                List<Object> result = (List<Object>)JSON.deserializeUntyped(payload);
                
                if(result.size() > 0) {
                    for(Object record : result) {

                        Map<String, Object> mapResponse = (Map<String, Object>)record;
                        String tinNumber = string.valueOf(mapResponse.get('tinNumber'));
                        String formId = string.valueOf(mapResponse.get('formId'));
                        String formName = string.valueOf(mapResponse.get('formName'));
                        String taxYear = string.valueOf(mapResponse.get('taxYear'));
                        String dateModified = string.valueOf(mapResponse.get('dateModified'));

                        if(!String.isBlank(tinNumber) && !String.isBlank(formId) && !String.isBlank(formName) && !String.isBlank(taxYear) && !String.isBlank(dateModified)) {
                            
                            // Callout: View File
                            String printResponse = SovosIntegrationService.printPdf(tinNumber, formId, taxYear);
                            if(printResponse != null) {
                                FormObject formRecord = new FormObject();
                                formRecord.formName = formName;
                                formRecord.url = 'data:application/pdf;base64,' + printResponse;
                                formRecord.year = taxYear;
                                formRecord.dateModified = dateModified;
                                lstFormRecords.add(formRecord);
                            }
                        }
                    }
                }
            }
        }
        
        return lstFormRecords;
    }

    public class FormObject {
        @AuraEnabled public String formName;
        @AuraEnabled public String url;
        @AuraEnabled public String year;
        @AuraEnabled public String dateModified;
    }
}