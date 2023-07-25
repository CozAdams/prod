@isTest
private class AddressGoogleSearchControllerTest {
    @isTest static void testGetAddressesSuccess() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockGoogleAddressSearchSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        String input = '111';
        
        AddressGoogleSearchController.AutocompleteResponse res = AddressGoogleSearchController.getAddresses(input);

        System.assertEquals('OK', res.status, 'Response status should be "OK"');
        System.assertEquals(5, res.predictions.size(), 'Response should return five predictions');
    }

    @isTest static void testGetAddressesNoResults() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockGoogleAddressSearchNoResults');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        String input = '111asdfasdfasdf';
        
        AddressGoogleSearchController.AutocompleteResponse res = AddressGoogleSearchController.getAddresses(input);

        System.assertEquals('ZERO_RESULTS', res.status, 'Response status should be "ZERO_RESULTS"');
        System.assertEquals(0, res.predictions.size(), 'Response should return no predictions');
    }

    @isTest static void testGetAddressesFailure() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockGoogleAddressSearchFailure');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        String input = '';
        AddressGoogleSearchController.AutocompleteResponse res;
        String errorMessage;
        try {
            res = AddressGoogleSearchController.getAddresses(input);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }     
        
        System.assertEquals('INVALID_REQUEST: There was an error processing the request.', errorMessage, 'Error message should return the error from the response');
    }

    @isTest static void testGetPlaceDetailsSuccess() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockGoogleAddressDetailsSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        String input = 'ChIJqefHfr5Qa4gRwoEpml2FTps';
        
        AddressGoogleSearchController.DetailResponse res = AddressGoogleSearchController.getPlaceDetails(input);

        System.assertEquals('OK', res.status, 'Response status should be "OK"');
        System.assert(res.result != null, 'Response result should not be null');
    }

    @isTest static void testGetPlaceDetailsFailure() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockGoogleAddressDetailsFailure');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        String input = 'asdf';
        String errorMessage;
        AddressGoogleSearchController.DetailResponse res;
        
        try {
            res = AddressGoogleSearchController.getPlaceDetails(input);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        System.assertEquals('INVALID_REQUEST: The provided place ID is invalid.', errorMessage, 'Error message should return the error from the response');
    }
}