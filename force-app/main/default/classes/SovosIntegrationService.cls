public with sharing class SovosIntegrationService {
    @InvocableMethod
    public static List<String> getAllForms(List<String> utilityString) {
        List<String> str = new List<String>();
        String rectType = 'tin';
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            SovosIntegration__c customSettings = SovosIntegration__c.getInstance();
            HttpResponse res = new HttpResponse();

            SovosIntegrationUtility util = (SovosIntegrationUtility)Json.deserialize(utilityString[0], SovosIntegrationUtility.class);
            //System.debug('------------'+util.recordId);

            if(util.isPrintMethod) {
                String serializedResponse = printPdf(util.tinNumber, util.formId,util.taxYear);
                str.add(serializedResponse);
            } else {
                Integer currentYear = getCurrentYear();
                for(Integer i = 0; i< Integer.valueOf(System.Label.No_of_Form_years);i++){
                    currentYear = currentYear - 1;
                    req.setEndpoint('callout:Sovos_Integration/xml/forms/all');
                    String body ='uid=' + '{!$Credential.UserName}:{!$Credential.Password}@' + customSettings.Domain__c;
                    body = body + '&rectype=' + rectType + '&alias=' + customSettings.Alias__c+currentYear + '&recid='+util.recordId;
                    req.setBody(body);
                    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                    req.setMethod('GET');
                    System.debug('get All forms Req End--->'+req.getEndpoint());
                    System.debug('get All forms Req--->'+req.getBody());
                    res = http.send(req);
                    System.debug('res--->'+res.getBody());
                    str.add(Json.serialize(parseXML(res.getBody())));
                }       
        }
        System.debug('String end point : '+str);
                return str;
    }

    private static List<SovosIntegrationUtility> parseXML(String responseXML){
        DOM.Document document = new DOM.Document();
        document.load(responseXML);
        System.debug('document--->'+document);
        
        List<SovosIntegrationUtility>  wrapperList= new List<SovosIntegrationUtility>();
        String errMessage = '';
        String taxYear = '';
        String formName = '';
        String dateModified = '';
        String tin = '';
        String formId = '';

        JSONGenerator gen = JSON.createGenerator(true);
        
        for (DOM.XmlNode node : document.getRootElement().getChildren())
        {
            System.debug('Inside for------>'+node.getName());

            if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
                system.debug('Node : '+node.getName());
                    if(node.getName()=='Body'){
                        for (Dom.XMLNode child: node.getChildElements()) {
                            system.debug('Child : '+child);
                            if(child.getName()=='Fault'){
                                for (Dom.XMLNode errChild: child.getChildElements()) {
                                    if(errChild.getName()=='detail'){
                                        system.debug('errChild'+errChild);
                                        for (Dom.XMLNode errChild1: errChild.getChildElements()) {
                                            if (errChild1.getNodeType() == DOM.XMLNodeType.ELEMENT) {
                                                System.debug('errChild1'+errChild1.getName());
                                                 errChild1.getAttribute('Message', null);
                                                System.debug('errMessage--->'+errMessage);
                                                if(errMessage.contains('Search found 0 records')){
                                                    errMessage = 'No forms to display';
                                                }                                                
                                            }
                                        }
                                    }
                                }

                            } else if(child.getName()=='List'){    
                                for (Dom.XMLNode recepientChild: child.getChildElements()) {
                                    if(recepientChild.getName()=='Recipient'){
                                        System.debug('TIN Number  : '+recepientChild.getAttribute('TIN', null));
                                        tin = recepientChild.getAttribute('TIN', null);
                                        for (Dom.XMLNode payerChild: recepientChild.getChildElements()) {
                                            if(payerChild.getName()=='Payer'){
                                                for (Dom.XMLNode formChild: payerChild.getChildElements()) {
                                                    taxYear = formChild.getAttribute('TAXYEAR', null);
                                                    formName = formChild.getName();
                                                    dateModified = formChild.getAttribute('DATEMODIFIED', null);
                                                    formId = formChild.getAttribute('RECNO', null);
                                                    System.debug('formChild : '+formChild.getName());
                                                    System.debug('TAXYEAR  : '+formChild.getAttribute('TAXYEAR', null));
                                                    System.debug('DATEMODIFIED : '+formChild.getAttribute('DATEMODIFIED', null));
                                                    System.debug('FormId : '+formChild.getAttribute('RECNO', null));                    
                                                    wrapperList.add(new SovosIntegrationUtility(null,formName,taxYear,dateModified,errMessage,tin,formId,false,null));
                                                }
                                            }
                                            
                                        }
                                    }      
                                }                                                      
                             }                           
                        }
                        
                    }
            }

            
            
        }
        System.debug('Wrapper List'+wrapperList);
        return wrapperList;
    }        


    public static String printPdf(String tin, String formId,String taxYear) {
       // List<String> str = new List<String>();
        String rectType = 'tin';
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            SovosIntegration__c customSettings = SovosIntegration__c.getInstance();
            
            req.setEndpoint('callout:Sovos_Integration/html/forms/print');
            String body ='uid=' + '{!$Credential.UserName}:{!$Credential.Password}@' + customSettings.Domain__c;
            body = body + '&rectype=' + rectType + '&alias=' + customSettings.Alias__c +taxYear + '&recid='+tin + '&FORMID='+formId;
            req.setBody(body);
            System.debug('Body---'+body);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setMethod('GET');
            HttpResponse res = http.send(req);
            System.debug('Response --->'+res);
            System.debug('res--->'+res.getBody());

            //String pdfData = EncodingUtil.base64Encode(Blob.valueOf(res.getBody()));
            //return Json.serialize(new SovosIntegrationUtility(null,null,null,null,null,null,null,false,pdfData));
            
            String pdfData = EncodingUtil.base64Encode(res.getbodyasblob());
			return pdfData;
            
    } 


    private static Integer getCurrentYear(){
        Date dat = System.today();
        return dat.year();
      
    }
       
}