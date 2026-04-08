@IsTest
private class TimezoneLookupForLwcControllerTest {
    private class GeoThenTzMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getEndpoint().contains('geocode')) {
                res.setBody(
                    '{"status":"OK","results":[{"geometry":{"location":{"lat":34.05,"lng":-118.24}}}]}'
                );
            } else {
                res.setBody(
                    '{"status":"OK","timeZoneId":"America/Los_Angeles","timeZoneName":"Pacific Daylight Time","rawOffset":-28800,"dstOffset":3600}'
                );
            }
            return res;
        }
    }

    @IsTest
    static void lookupTimezoneFromAddress_controller() {
        Test.setMock(HttpCalloutMock.class, new GeoThenTzMock());
        Map<String, Object> payload = TimezoneLookupForLwcController.lookupTimezoneFromAddress(
            'Los Angeles',
            null
        );
        Assert.isTrue((Boolean) payload.get('success'));
        Assert.areEqual('America/Los_Angeles', (String) payload.get('timezoneIana'));
    }
}
