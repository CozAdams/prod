@isTest
public class BillerDirectRTCBEndpointTest {

    @isTest
    static void billerResponseTest(){
        Account testAccount = TestDataFactory.createAccount(true, 'Household Account' ,'testAccount');
        Contact testContact = TestDataFactory.createContact(true, testAccount.Id, 'test Name');
        Account_Summary__c testAccountSummary = TestDataFactory.createAccountSummary(true, testContact.Id, testAccount.Id, 'test');
        Case c = TestDataFactory.createCase(true);
        
        system.debug('Case ' + c.Id);

        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/billeriqresponse/';
            
        request.httpMethod = 'POST';

        request.requestBody = Blob.valueOf('{"Success": true,"Result": {"Payments": [{"InvoicePayments": [{"BillerRemittanceField1" : "'+testContact.Id+'", "BillerInvoiceNo": "test2", "BillerRemittanceField4" : "" , "BillerRemittanceField2": "'+testAccountSummary.Id+'", "AccountNumber": "1" }], "TransactionID": "0001", "ProcessDate": "2023-03-15T23:00:00", "Channel" : "2"}], "PaymentAmount": "100"}}');
        RestContext.request = request;

        String returnValue = BillerDirectRTCBEndpoint.billerResponse();
        
        request.requestBody = Blob.valueOf('{"Success": true,"Result": {"Payments": [{"InvoicePayments": [{"BillerRemittanceField1" : "'+testContact.Id+'", "BillerInvoiceNo": "test2", "BillerRemittanceField4" : "" , "BillerRemittanceField2": "'+testAccountSummary.Id+'", "AccountNumber": "1" }], "TransactionID": "0001", "ProcessDate": "2023-03-15T23:00:00", "CreateDate" : "2023-03-15T23:00:00", "Channel" : "4"}], "PaymentAmount": "100"}}');
        RestContext.request = request;

        returnValue = BillerDirectRTCBEndpoint.billerResponse();
        
        request.requestBody = Blob.valueOf('{"Success": true,"Result": {"Payments": [{"InvoicePayments": [{"BillerRemittanceField1" : "'+testContact.Id+'", "BillerInvoiceNo": "test2", "BillerRemittanceField4" : "" , "BillerRemittanceField2": "'+testAccountSummary.Id+'", "AccountNumber": "1" }], "TransactionID": "0001", "ProcessDate": "2023-04-15T23:00:00", "CreateDate" : "2023-04-15T23:00:00", "Channel" : "4"}], "PaymentAmount": "100"}}');
        RestContext.request = request;

        returnValue = BillerDirectRTCBEndpoint.billerResponse();
        
        request.requestBody = Blob.valueOf('{"Success": true,"Result": {"Payments": [{"InvoicePayments": [{"BillerRemittanceField1" : "'+testContact.Id+'", "BillerInvoiceNo": "test2", "BillerRemittanceField4" : "' + c.Id + '" , "BillerRemittanceField2": "'+testAccountSummary.Id+'", "AccountNumber": "1" }], "TransactionID": "0001", "ProcessDate": "2023-04-15T23:00:00", "CreateDate" : "2023-04-15T23:00:00", "Channel" : "6"}], "PaymentAmount": "100"}}');
        RestContext.request = request;

        returnValue = BillerDirectRTCBEndpoint.billerResponse();
    }    



}