@isTest
global class SovosCalloutMock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest request) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cnv="http://www.1099convey.com/dwp/xml/"><Body><cnv:List><cnv:Recipient RecId="33452" TIN="026385036 1" Account="RI-14-30146" Name="STACIE SHAPIRO" Address="14022 GRANNAN LN" City="CARMEL" State="IN" ZIP="46074-7760"><cnv:Payer PTIN="350942638" PTinType="1" PShortName="PENS" PName="PENSION FUND OF THE CHRISTIAN CHURCH" PAddress="1099 N. MERIDIAN ST." PCity="INDIANAPOLIS" PState="IN" PZIP="46204"><cnv:C5498 ALTSTATE="IN" RECNO="71551" ACCOUNTNO="RI-14-30146" ALT_STATE_SOURCE="R" PTIN="350942638" DATEMODIFIED="05/28/2021" BOX7="4" BOX5="25208.4700" TIN="026385036 1" TAXYEAR="2020"/></cnv:Payer></cnv:Recipient><cnv:Recipient RecId="8362" TIN="026385036" Account="40060802" Name="STACIE SHAPIRO" Address="14022 GRANNAN LN" City="CARMEL" State="IN" ZIP="46074-7760"><cnv:Payer PTIN="350942638" PTinType="1" PShortName="PENS" PName="PENSION FUND OF THE CHRISTIAN CHURCH" PAddress="1099 N. MERIDIAN ST." PCity="INDIANAPOLIS" PState="IN" PZIP="46204"><cnv:C1099I BOX1="941.7300" ACCOUNTNO="40060802" ALTSTATE="IN" ALT_STATE_SOURCE="R" PTIN="350942638" RECNO="20599" TAXYEAR="2020" XMITRUN="83" TIN="026385036" DATEMODIFIED="01/08/2021"/></cnv:Payer></cnv:Recipient></cnv:List></Body></SOAP-ENV:Envelope>');
        return res; 
    }
}