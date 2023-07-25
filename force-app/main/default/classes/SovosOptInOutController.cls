global with sharing class SovosOptInOutController {

    
    @AuraEnabled(cacheable=true)
    public static Boolean getData(String userId){
        User userRec = [SELECT Id, Contact.Stop_receiving_paper_tax_statements__c,Contact.Opt_Out_Prompted_All_Paper_Tax_Forms__c FROM User WHERE Id =: userId LIMIT 1];
        System.debug('inside getData'+userRec.Contact.Opt_Out_Prompted_All_Paper_Tax_Forms__c );
        if(userRec.Contact.Opt_Out_Prompted_All_Paper_Tax_Forms__c  == true){
            return false;
        }
        else {
            return true;
        }
    }
    
    @AuraEnabled
    public static void updateOptInOutForUser(String userId, Boolean selectedOption){
        User userRec = [SELECT Id, Contact.Id FROM User WHERE Id =: userId LIMIT 1];
        Contact cnt = [SELECT Stop_receiving_paper_tax_statements__c ,Opt_Out_Prompted_All_Paper_Tax_Forms__c
                    FROM Contact 
                    WHERE Id =: userRec.Contact.Id];
        cnt.Stop_receiving_paper_tax_statements__c = selectedOption;
        cnt.Opt_Out_Prompted_All_Paper_Tax_Forms__c = true;
        try {
                update cnt;
        }
        catch(Exception e){
            System.debug('Exception'+e);
        }
    
    }

   @future(callout=true)
    public static void invokeCallout(String id){
        Contact contactValue = [SELECT Id, Contact.Social_Security_Number__c , Stop_receiving_paper_tax_statements__c
                           FROM Contact
                           WHERE Id =: id];
        String optType = '';
        if(contactValue.Stop_receiving_paper_tax_statements__c == true){
            optType = 'IN';
        }else {
            optType = 'OUT';
        }
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        SovosIntegration__c customSettings = SovosIntegration__c.getInstance();
        HttpResponse res = new HttpResponse();
        List<String> responses = new List<String>();
         Integer currentYear = getCurrentYear();
        for(Integer i = 0; i< Integer.valueOf(System.Label.No_of_Form_years);i++){
            currentYear = currentYear - 1;
            req.setEndpoint('callout:Sovos_Integration/xml/opt');
            String body ='uid=' + '{!$Credential.UserName}:{!$Credential.Password}@' + customSettings.Domain__c+'&tin='+contactValue.Social_Security_Number__c;
            body = body + '&alias=' + customSettings.Alias__c+currentYear+ '&opttype='+optType+ '&updatetype=NOFULL';
            req.setBody(body);
            System.debug('Body--->'+body);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setMethod('GET');
            if(!Test.isRunningTest()){
                res = http.send(req);
                responses.add(String.valueOf(res.getStatusCode()));    
            }else {
                responses.add(String.valueOf('200'));   
            }
            
        }
    }


    private static Integer getCurrentYear(){
        Date dat = System.today();
        return dat.year();
      
    }
}