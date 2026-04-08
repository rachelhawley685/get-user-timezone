@IsTest
private class BrowserTimezoneFlowActionTest {
    @IsTest
    static void resolve_positive() {
        BrowserTimezoneFlowAction.Request req = new BrowserTimezoneFlowAction.Request();
        req.timezoneIana = 'America/Chicago';
        req.utcOffsetMinutes = -300;

        List<BrowserTimezoneFlowAction.Response> responses =
            BrowserTimezoneFlowAction.resolve(new List<BrowserTimezoneFlowAction.Request>{ req });

        Assert.areEqual(1, responses.size());
        Assert.areEqual('America/Chicago', responses[0].timezoneIana);
        Assert.areEqual(-300, responses[0].utcOffsetMinutes);
        Assert.isTrue(responses[0].isValidTimezone);
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
        Assert.isTrue(!String.isBlank(responses[0].currentLocalDateTime));
    }

    @IsTest
    static void resolve_negative_blankTimezone() {
        BrowserTimezoneFlowAction.Request req = new BrowserTimezoneFlowAction.Request();
        req.timezoneIana = ' ';

        List<BrowserTimezoneFlowAction.Response> responses =
            BrowserTimezoneFlowAction.resolve(new List<BrowserTimezoneFlowAction.Request>{ req });

        Assert.areEqual(1, responses.size());
        Assert.areEqual(null, responses[0].timezoneIana);
        Assert.isFalse(responses[0].isValidTimezone);
        Assert.isTrue(!String.isBlank(responses[0].currentUtcDateTime));
    }
}
