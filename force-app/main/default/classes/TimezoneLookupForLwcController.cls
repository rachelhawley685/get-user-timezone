public with sharing class TimezoneLookupForLwcController {
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> lookupTimezoneFromAddress(String address, String apiKey) {
        GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromAddress(
            address,
            apiKey
        );
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('success', lr.success);
        payload.put('timezoneIana', lr.timezoneIana);
        payload.put('timezoneDisplayName', lr.timezoneDisplayName);
        payload.put('utcOffsetSeconds', lr.utcOffsetSeconds);
        payload.put('httpStatusCode', lr.httpStatusCode);
        payload.put('message', lr.message);
        payload.put('latitude', lr.latitude);
        payload.put('longitude', lr.longitude);
        return payload;
    }
}
