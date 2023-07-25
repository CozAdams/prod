global class SovosIntegrationUtility {

    global String recordId {get; set;}
    global String formName  {get; set;}
    global String taxYear  {get; set;}
    global String dateModified  {get; set;}
    global String errorMessage  {get; set;}
    global String tinNumber {get; set;}
    global String formId {get; set;}
    global Boolean isPrintMethod {get; set;}
    global String blobResponse {get; set;}

    global SovosIntegrationUtility(){

    }


    global SovosIntegrationUtility(String recordId, String formName, String taxYear, 
                    String dateModified , String errorMessage,String tinNumber,String formId,Boolean isPrintMethod,String blobResponse){
            this.recordId = recordId;
            this.formName = formName;
            this.taxYear = taxYear;
            this.dateModified = dateModified;
            this.errorMessage = errorMessage;
            this.tinNumber = tinNumber;          
            this.formId = formId;
            this.isPrintMethod = isPrintMethod;
            this.blobResponse = blobResponse;
        }
}