public with sharing class TimezoneFromAddressFlowAction {
    @InvocableMethod(
        label='Lookup Timezone From Address'
        description='Calls Google Maps Geocoding and Timezone APIs using a street address.'
        category='Timezone'
        callout=true
    )
    public static List<Response> lookup(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            if (requestItem == null || String.isBlank(requestItem.address)) {
                responseItem.isSuccess = false;
                responseItem.message = 'Address is required.';
                responses.add(responseItem);
                continue;
            }

            try {
                GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromAddress(
                    requestItem.address,
                    requestItem.apiKey
                );
                mapLookupToResponse(lr, responseItem);
            } catch (Exception ex) {
                responseItem.isSuccess = false;
                responseItem.message = 'Timezone lookup failed: ' + ex.getMessage();
            }

            responses.add(responseItem);
        }

        return responses;
    }

    private static void mapLookupToResponse(GoogleMapsTimezoneUtil.LookupResult lr, Response responseItem) {
        responseItem.isSuccess = lr.success;
        responseItem.timezoneIana = lr.timezoneIana;
        responseItem.timezoneAbbreviation = lr.timezoneDisplayName;
        responseItem.utcOffsetSeconds = lr.utcOffsetSeconds;
        responseItem.httpStatusCode = lr.httpStatusCode;
        responseItem.message = lr.message;
        responseItem.currentUtcDateTime = DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        if (lr.utcOffsetSeconds != null) {
            DateTime localTime = DateTime.now().addSeconds(lr.utcOffsetSeconds);
            responseItem.currentLocalDateTime = localTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
        }
    }

    public class Request {
        @InvocableVariable(
            label='Address'
            description='Full address string for timezone lookup (e.g. "123 Main St, Chicago, IL 60601, US").'
            required=true
        )
        public String address;

        @InvocableVariable(
            label='API Key (Optional)'
            description='Optional override API key. Leave blank to use Custom Metadata.'
            required=false
        )
        public String apiKey;
    }

    public class Response {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Timezone (IANA)')
        public String timezoneIana;

        @InvocableVariable(label='Timezone Abbreviation')
        public String timezoneAbbreviation;

        @InvocableVariable(label='UTC Offset (Seconds)')
        public Integer utcOffsetSeconds;

        @InvocableVariable(label='HTTP Status Code')
        public Integer httpStatusCode;

        @InvocableVariable(label='Current Local Date Time')
        public String currentLocalDateTime;

        @InvocableVariable(label='Current UTC Date Time')
        public String currentUtcDateTime;

        @InvocableVariable(label='Message')
        public String message;
    }
}
