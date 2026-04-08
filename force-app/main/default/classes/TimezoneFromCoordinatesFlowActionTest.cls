@IsTest
private class TimezoneFromCoordinatesFlowActionTest {
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(
                '{"status":"OK","timeZoneId":"America/New_York","timeZoneName":"Eastern Daylight Time","rawOffset":-18000,"dstOffset":3600}'
            );
            return response;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody('{"error":"Internal Server Error"}');
            return response;
        }
    }

    private class GoogleStatusErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"status":"REQUEST_DENIED","errorMessage":"API key invalid."}');
            return response;
        }
    }

    @IsTest
    static void lookup_positive() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        TimezoneFromCoordinatesFlowAction.Request req =
            new TimezoneFromCoordinatesFlowAction.Request();
        req.latitude = 40.7128;
        req.longitude = -74.0060;

        Test.startTest();
        List<TimezoneFromCoordinatesFlowAction.Response> responses =
            TimezoneFromCoordinatesFlowAction.lookup(
                new List<TimezoneFromCoordinatesFlowAction.Request>{ req }
            );
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.isTrue(responses[0].isSuccess);
        Assert.areEqual('America/New_York', responses[0].timezoneIana);
        Assert.areEqual('Eastern Daylight Time', responses[0].timezoneAbbreviation);
        Assert.areEqual(-14400, responses[0].utcOffsetSeconds);
        Assert.areEqual(200, responses[0].httpStatusCode);
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
        Assert.isTrue(!String.isBlank(responses[0].currentLocalDateTime));
    }

    @IsTest
    static void lookup_negative_missingCoordinates() {
        TimezoneFromCoordinatesFlowAction.Request req =
            new TimezoneFromCoordinatesFlowAction.Request();

        List<TimezoneFromCoordinatesFlowAction.Response> responses =
            TimezoneFromCoordinatesFlowAction.lookup(
                new List<TimezoneFromCoordinatesFlowAction.Request>{ req }
            );

        Assert.areEqual(1, responses.size());
        Assert.isFalse(responses[0].isSuccess);
        Assert.isTrue(responses[0].message.contains('required'));
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
    }

    @IsTest
    static void lookup_negative_nonSuccessHttp() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        TimezoneFromCoordinatesFlowAction.Request req =
            new TimezoneFromCoordinatesFlowAction.Request();
        req.latitude = 34.0522;
        req.longitude = -118.2437;

        List<TimezoneFromCoordinatesFlowAction.Response> responses =
            TimezoneFromCoordinatesFlowAction.lookup(
                new List<TimezoneFromCoordinatesFlowAction.Request>{ req }
            );

        Assert.areEqual(1, responses.size());
        Assert.isFalse(responses[0].isSuccess);
        Assert.areEqual(500, responses[0].httpStatusCode);
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
    }

    @IsTest
    static void lookup_negative_googleStatusNotOk() {
        Test.setMock(HttpCalloutMock.class, new GoogleStatusErrorMock());

        TimezoneFromCoordinatesFlowAction.Request req =
            new TimezoneFromCoordinatesFlowAction.Request();
        req.latitude = 47.6062;
        req.longitude = -122.3321;

        List<TimezoneFromCoordinatesFlowAction.Response> responses =
            TimezoneFromCoordinatesFlowAction.lookup(
                new List<TimezoneFromCoordinatesFlowAction.Request>{ req }
            );

        Assert.areEqual(1, responses.size());
        Assert.isFalse(responses[0].isSuccess);
        Assert.isTrue(responses[0].message.contains('REQUEST_DENIED'));
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
    }
}
