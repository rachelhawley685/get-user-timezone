@IsTest
private class GoogleMapsTimezoneUtilTest {
    private class GeoThenTzMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getEndpoint().contains('geocode')) {
                res.setBody(
                    '{"status":"OK","results":[{"geometry":{"location":{"lat":41.8781,"lng":-87.6298}}}]}'
                );
            } else {
                res.setBody(
                    '{"status":"OK","timeZoneId":"America/Chicago","timeZoneName":"Central Daylight Time","rawOffset":-21600,"dstOffset":3600}'
                );
            }
            return res;
        }
    }

    private class TzOnlyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"status":"OK","timeZoneId":"America/New_York","timeZoneName":"Eastern Daylight Time","rawOffset":-18000,"dstOffset":3600}'
            );
            return res;
        }
    }

    @IsTest
    static void lookupFromCoordinates_positive() {
        Test.setMock(HttpCalloutMock.class, new TzOnlyMock());
        GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromCoordinates(
            40.7128,
            -74.0060,
            null,
            null
        );
        Assert.isTrue(lr.success);
        Assert.areEqual('America/New_York', lr.timezoneIana);
        Assert.areEqual(-14400, lr.utcOffsetSeconds);
    }

    @IsTest
    static void lookupFromAddress_positive() {
        Test.setMock(HttpCalloutMock.class, new GeoThenTzMock());
        GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromAddress(
            'Chicago IL',
            null
        );
        Assert.isTrue(lr.success);
        Assert.areEqual('America/Chicago', lr.timezoneIana);
        Assert.areEqual(41.8781, lr.latitude);
        Assert.areEqual(-87.6298, lr.longitude);
    }

    @IsTest
    static void lookupFromAddress_blank() {
        GoogleMapsTimezoneUtil.LookupResult lr = GoogleMapsTimezoneUtil.lookupTimezoneFromAddress('  ', null);
        Assert.isFalse(lr.success);
        Assert.isTrue(lr.message.contains('required'));
    }
}
