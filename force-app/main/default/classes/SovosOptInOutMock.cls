@isTest
global with sharing class SovosOptInOutMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        //res.setBody('([{"taxYear":"2022","idVal":"","formName":"C1099I","errorMessage":"","dateModified":"01/06/2023"}],[{"taxYear":"2021","idVal":"","formName":"C1099I","errorMessage":"","dateModified":"01/07/2022"}])');
        return res; 
    }
}