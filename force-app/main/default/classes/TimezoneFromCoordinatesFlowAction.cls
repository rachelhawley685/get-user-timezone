public with sharing class TimezoneFromCoordinatesFlowAction {
    @InvocableMethod(
        label='Lookup Timezone From Coordinates'
        description='Calls an external timezone API using latitude/longitude.'
        category='Timezone'
        callout=true
    )
    public static List<Response> lookup(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            if (requestItem == null || requestItem.latitude == null || requestItem.longitude == null) {
                responseItem.isSuccess = false;
                responseItem.currentUtcDateTime = DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                responseItem.message = 'Latitude and longitude are required.';
                responses.add(responseItem);
                continue;
            }

            try {
                GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromCoordinates(
                    requestItem.latitude,
                    requestItem.longitude,
                    requestItem.epochSeconds,
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
            label='Latitude'
            description='Latitude for timezone lookup.'
            required=true
        )
        public Decimal latitude;

        @InvocableVariable(
            label='Longitude'
            description='Longitude for timezone lookup.'
            required=true
        )
        public Decimal longitude;

        @InvocableVariable(
            label='Epoch Timestamp (Seconds)'
            description='Optional timestamp if your provider requires it for DST-aware responses.'
            required=false
        )
        public Long epochSeconds;

        @InvocableVariable(
            label='API Key (Optional)'
            description='Optional API key appended as query param for providers like Google Time Zone API.'
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
