public with sharing class GoogleMapsTimezoneUtil {
    public class LookupResult {
        public Boolean success;
        public String timezoneIana;
        public String timezoneDisplayName;
        public Integer utcOffsetSeconds;
        public Integer httpStatusCode;
        public String message;
        public Decimal latitude;
        public Decimal longitude;
    }

    public static LookupResult lookupTimezoneFromCoordinates(
        Decimal latitude,
        Decimal longitude,
        Long epochSeconds,
        String apiKey
    ) {
        LookupResult result = new LookupResult();
        if (latitude == null || longitude == null) {
            result.success = false;
            result.message = 'Latitude and longitude are required.';
            return result;
        }
        String resolvedKey = resolveApiKey(apiKey);
        Long ts = epochSeconds != null ? epochSeconds : DateTime.now().getTime() / 1000;
        String endpoint =
            'https://maps.googleapis.com/maps/api/timezone/json'
            + '?location='
            + EncodingUtil.urlEncode(String.valueOf(latitude) + ',' + String.valueOf(longitude), 'UTF-8')
            + '&timestamp='
            + EncodingUtil.urlEncode(String.valueOf(ts), 'UTF-8');
        if (!String.isBlank(resolvedKey)) {
            endpoint += '&key=' + EncodingUtil.urlEncode(resolvedKey, 'UTF-8');
        }
        return sendTimezoneRequest(endpoint);
    }

    private static String resolveApiKey(String apiKey) {
        if (!String.isBlank(apiKey)) {
            return apiKey;
        }
        Google_Maps_Config__mdt config = Google_Maps_Config__mdt.getInstance('Default');
        return config != null ? config.API_Key__c : null;
    }

    public static LookupResult lookupTimezoneFromAddress(String address, String apiKey) {
        LookupResult result = new LookupResult();
        if (String.isBlank(address)) {
            result.success = false;
            result.message = 'Address is required.';
            return result;
        }
        String resolvedKey = resolveApiKey(apiKey);
        String geoEndpoint =
            'https://maps.googleapis.com/maps/api/geocode/json'
            + '?address='
            + EncodingUtil.urlEncode(address.trim(), 'UTF-8');
        if (!String.isBlank(resolvedKey)) {
            geoEndpoint += '&key=' + EncodingUtil.urlEncode(resolvedKey, 'UTF-8');
        }
        try {
            HttpRequest geoReq = new HttpRequest();
            geoReq.setMethod('GET');
            geoReq.setTimeout(10000);
            geoReq.setEndpoint(geoEndpoint);
            HttpResponse geoRes = (new Http()).send(geoReq);
            if (geoRes.getStatusCode() < 200 || geoRes.getStatusCode() >= 300) {
                result.success = false;
                result.httpStatusCode = geoRes.getStatusCode();
                result.message = 'Geocoding returned status: ' + geoRes.getStatusCode();
                return result;
            }
            Map<String, Object> geoPayload = (Map<String, Object>) JSON.deserializeUntyped(geoRes.getBody());
            String geoStatus = getString(geoPayload, 'status');
            if (geoStatus != 'OK') {
                result.success = false;
                result.message = 'Geocoding status: ' + geoStatus;
                return result;
            }
            List<Object> results = (List<Object>) geoPayload.get('results');
            if (results == null || results.isEmpty()) {
                result.success = false;
                result.message = 'No geocoding results for that address.';
                return result;
            }
            Map<String, Object> first = (Map<String, Object>) results[0];
            Map<String, Object> geometry = (Map<String, Object>) first.get('geometry');
            Map<String, Object> location = (Map<String, Object>) geometry.get('location');
            if (location == null) {
                result.success = false;
                result.message = 'Geocoding response missing location.';
                return result;
            }
            result.latitude = toDecimal(location.get('lat'));
            result.longitude = toDecimal(location.get('lng'));
            LookupResult tzResult = lookupTimezoneFromCoordinates(
                result.latitude,
                result.longitude,
                null,
                apiKey
            );
            if (tzResult != null) {
                tzResult.latitude = result.latitude;
                tzResult.longitude = result.longitude;
            }
            return tzResult;
        } catch (Exception ex) {
            result.success = false;
            result.message = 'Address lookup failed: ' + ex.getMessage();
            return result;
        }
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Decimal) {
            return (Decimal) value;
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    private static LookupResult sendTimezoneRequest(String endpoint) {
        LookupResult responseItem = new LookupResult();
        try {
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setTimeout(10000);
            req.setEndpoint(endpoint);
            HttpResponse res = (new Http()).send(req);
            parseTimezoneResponse(res, responseItem);
        } catch (Exception ex) {
            responseItem.success = false;
            responseItem.message = 'Timezone lookup failed: ' + ex.getMessage();
        }
        return responseItem;
    }

    private static void parseTimezoneResponse(HttpResponse res, LookupResult responseItem) {
        Integer statusCode = res.getStatusCode();
        responseItem.httpStatusCode = statusCode;
        if (statusCode < 200 || statusCode >= 300) {
            responseItem.success = false;
            responseItem.message = 'Timezone API returned non-success status: ' + statusCode;
            return;
        }
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String providerStatus = getString(payload, 'status');
        if (!String.isBlank(providerStatus) && providerStatus != 'OK') {
            responseItem.success = false;
            String errorMessage = getString(payload, 'errorMessage');
            responseItem.message =
                'Google Time Zone API status: ' + providerStatus
                + (String.isBlank(errorMessage) ? '' : ' (' + errorMessage + ')');
            return;
        }
        responseItem.timezoneIana = getString(payload, 'timeZoneId');
        responseItem.timezoneDisplayName = getString(payload, 'timeZoneName');
        Integer rawOffset = getInteger(payload, 'rawOffset');
        Integer dstOffset = getInteger(payload, 'dstOffset');
        if (rawOffset != null || dstOffset != null) {
            responseItem.utcOffsetSeconds =
                (rawOffset == null ? 0 : rawOffset) + (dstOffset == null ? 0 : dstOffset);
        }
        responseItem.success = !String.isBlank(responseItem.timezoneIana);
        responseItem.message = responseItem.success
            ? 'Timezone lookup succeeded.'
            : 'Google Time Zone API did not return timeZoneId.';
    }

    private static String getString(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private static Integer getInteger(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Long) {
            return Integer.valueOf(String.valueOf(value));
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }
}
