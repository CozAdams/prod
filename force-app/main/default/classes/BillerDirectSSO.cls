public with sharing class BillerDirectSSO {
    

    


    @AuraEnabled
    public static String RedirectToBillerIQ(String accountSummaryId){
      datetime creationDate = datetime.now();
      Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

      String dateString;
      String monthString;
      String dayString;
    
      Account_Summary__c selectedAccount = [Select Id, Name, Member_Pin__c, Member_Name__r.Name FROM Account_Summary__c Where Id =: accountSummaryId LIMIT 1];
      String accountName = selectedAccount.Name;
//      String accountName = 'DB-15-1121';
      String accountPin = selectedAccount.Member_Pin__c;
      String contactName = selectedAccount.Member_Name__r.Name;
      String contactID = selectedAccount.Member_Name__c;

/*
  '<saml:Attribute Name="ExternalID" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+ LoginUserId +'</saml:AttributeValue>'+
            '</saml:Attribute>'+
*/



      monthString = string.valueOf(creationDate.month());
      if(monthString.length() < 2){
        monthString = '0' + monthString;
      }

      dayString = string.valueOf(creationDate.day());
      if(dayString.length() < 2){
        dayString = '0' + dayString;
      }

      dateString = creationDate.year() + '-' + monthString + '-' + dayString + 'T' + creationDate.time();

      String LoginUserId = UserInfo.getUserId();

      String userName = UserInfo.getUserName();
      User activeUser = [Select Email From User where Username = : userName limit 1];
      String userEmail = activeUser.Email;



        system.debug(creationDate);
        String Body ='<?xml version="1.0" encoding="UTF-8"?><samlp:Response ID="' + guid + '" Version="2.0" IssueInstant="' + dateString + '" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">'+
        '<saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">https://53.billerdirectexpress.com</saml:Issuer>'+
        '<samlp:Status>'+
          '<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>'+
        '</samlp:Status>'+
        '<saml:Assertion Version="2.0" ID="' + guid + '" IssueInstant="' + dateString + '" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">'+
          '<saml:Issuer>https://53.billerdirectexpress.com</saml:Issuer>'+
          '<saml:Subject>'+
            '<saml:NameID>FFM</saml:NameID>'+
            '<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer" />'+
          '</saml:Subject>'+
          '<saml:AttributeStatement>'+
            '<saml:Attribute Name="ApiVersion" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>3000</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="BillerKey" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>PFCCSSO</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="ApiKey" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>1b93e62c-c1aa-40d3-ab51-e98060552225</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="ExternalID" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+ contactID +'</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="Email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+ userEmail +'</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="ReferenceNumber" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+accountName+'</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="OtherData" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+accountPin+'</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="NameCompany" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>'+contactName+'</saml:AttributeValue>'+
            '</saml:Attribute>'+
            '<saml:Attribute Name="UserRole" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">'+
              '<saml:AttributeValue>SSOCustomer</saml:AttributeValue>'+
            '</saml:Attribute>'+
            
          '</saml:AttributeStatement>'+
          '<saml:AttributeStatement saml:AuthInstant="' + dateString +'"/>'+
          '<saml:AuthnContext>'+
            '<saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>'+
          '</saml:AuthnContext>'+
        '</saml:Assertion>'+
      '</samlp:Response>';

      //Body = Body.replaceAll(' ', '+');
      system.debug(Body);
      Blob beforeblob = Blob.valueOf(Body);
      string paramvalue = EncodingUtil.base64Encode(beforeblob);
      system.debug(paramvalue);

      return paramvalue;

      
    }

    
}