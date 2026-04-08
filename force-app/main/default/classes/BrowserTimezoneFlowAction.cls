public with sharing class BrowserTimezoneFlowAction {
    @InvocableMethod(
        label='Resolve Browser Timezone'
        description='Normalizes timezone information captured from the browser for Flow usage.'
        category='Timezone'
    )
    public static List<Response> resolve(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            responseItem.timezoneIana = normalizeTimezone(requestItem.timezoneIana);
            responseItem.utcOffsetMinutes = requestItem.utcOffsetMinutes;
            responseItem.currentUtcDateTime = DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            if (requestItem.utcOffsetMinutes != null) {
                DateTime localTime = DateTime.now().addMinutes(requestItem.utcOffsetMinutes);
                responseItem.currentLocalDateTime = localTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
            }
            responseItem.isValidTimezone = isLikelyIana(responseItem.timezoneIana);
            responseItem.message = responseItem.isValidTimezone
                ? 'Timezone captured successfully.'
                : 'Timezone is blank or not in expected IANA format.';
            responses.add(responseItem);
        }

        return responses;
    }

    private static String normalizeTimezone(String timezoneIana) {
        if (String.isBlank(timezoneIana)) {
            return null;
        }
        return timezoneIana.trim();
    }

    private static Boolean isLikelyIana(String timezoneIana) {
        if (String.isBlank(timezoneIana)) {
            return false;
        }

        // Most browser-reported timezones use Area/Location format.
        return timezoneIana.contains('/');
    }

    public class Request {
        @InvocableVariable(
            label='Timezone (IANA)'
            description='Value from browser JavaScript, such as America/Los_Angeles.'
            required=true
        )
        public String timezoneIana;

        @InvocableVariable(
            label='UTC Offset Minutes'
            description='Optional UTC offset in minutes from browser JavaScript.'
            required=false
        )
        public Integer utcOffsetMinutes;
    }

    public class Response {
        @InvocableVariable(label='Timezone (IANA)')
        public String timezoneIana;

        @InvocableVariable(label='UTC Offset Minutes')
        public Integer utcOffsetMinutes;

        @InvocableVariable(label='Is Valid Timezone')
        public Boolean isValidTimezone;

        @InvocableVariable(label='Current Local Date Time')
        public String currentLocalDateTime;

        @InvocableVariable(label='Current UTC Date Time')
        public String currentUtcDateTime;

        @InvocableVariable(label='Message')
        public String message;
    }
}
