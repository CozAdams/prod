public with sharing class AddressGoogleSearchController {
    private static final List<Google_Maps_API_Setting__mdt> GOOGLE_API_SETTINGS = [SELECT API_URL__c, Maps_API_Key__c, Places_API_Key__c FROM Google_Maps_API_Setting__mdt WHERE MasterLabel = 'Default'];

    @AuraEnabled
    public static AutocompleteResponse getAddresses(String input) {
        String endpoint = '/place/autocomplete/json?input=' + EncodingUtil.urlEncode(input, 'UTF-8') + '&key=' + getApiSetting().Places_API_Key__c;
        try {    
            String response = getResponse(endpoint);
            AutocompleteResponse autoRes = (AutocompleteResponse) JSON.deserialize(response, AutocompleteResponse.class);
            if (autoRes.status != 'OK' && autoRes.status != 'ZERO_RESULTS') {
                throw new GoogleAPIException(autoRes.status + (autoRes.error_message != null ? ': ' + autoRes.error_message : ''));
            }
            return autoRes;
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static DetailResponse getPlaceDetails(String placeId) {
        String endpoint = '/place/details/json?placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8') + '&key=' + getApiSetting().Places_API_Key__c;
        try {
            String response = getResponse(endpoint);
            DetailResponse detRes = (DetailResponse) JSON.deserialize(response, DetailResponse.class);
            if (detRes.status != 'OK' && detRes.status != 'ZERO_RESULTS') {
                throw new GoogleAPIException(detRes.status + (detRes.error_message != null ? ': ' + detRes.error_message : ''));
            }
            return detRes;
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    public static String getResponse(String endpoint) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Google_Maps_API_Setting__mdt setting =  getApiSetting();
        req.setMethod('GET');
        req.SetEndpoint(setting.API_URL__c + endpoint);
        req.setTimeOut(120000);
        try {
            res = h.send(req);
            String responseBody = res.getBody();
            // Status 'OK' indicates success
            // Status 'REQUEST_DENIED' indicates a problem
            System.debug('RESPONSE ' + responseBody);
            return responseBody;
        } catch (Exception e) {
            throw new GoogleAPIException(e.getMessage(), e);
        }
    }

    private static Google_Maps_API_Setting__mdt getApiSetting() {
        if (GOOGLE_API_SETTINGS.isEmpty()) {
            throw new GoogleAPIException('Google API Settings not found. Please verify if a Google Maps API Setting custom metadata record named "Default" exists.');
        }

        return GOOGLE_API_SETTINGS[0];
    }

    public virtual class Response {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String error_message;
    }

    public class AutocompleteResponse extends Response {
        @AuraEnabled
        public List<AddressItem> predictions;
    }

    public class DetailResponse extends Response {
        @AuraEnabled
        public DetailResult result;
    }

    private class AddressItem {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String place_id;
        @AuraEnabled
        public StructuredFormatting structured_formatting;
    }

    private class MatchedSubstring {
        @AuraEnabled
        public Integer length;
        @AuraEnabled
        public Integer offset;
    }

    private class StructuredFormatting {
        @AuraEnabled
        public String main_text;
        @AuraEnabled
        public List<MatchedSubstring> main_text_matched_substrings;
        @AuraEnabled
        public String secondary_text;
        @AuraEnabled
        public List<MatchedSubstring> secondary_text_matched_substrings;
    }

    public class DetailResult {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String place_id;
        @AuraEnabled
        public String formatted_address;
        @AuraEnabled
        public List<AddressComponent> address_components;
        @AuraEnabled
        public Geometry geometry;
    }

    private class AddressComponent {
        @AuraEnabled
        public String long_name;
        @AuraEnabled
        public String short_name;
        @AuraEnabled
        public List<String> types;
    }

    private class Geometry {
        @AuraEnabled
        public GeometryLocation location;
    }

    private class GeometryLocation {
        @AuraEnabled
        public Double lat;
        @AuraEnabled
        public Double lng;
    }

    public class GoogleAPIException extends Exception {}
}