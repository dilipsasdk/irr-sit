/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for Teds Service.
*/

@IsTest
private class IRR_SVC_TedsService_Test {

    @IsTest
    static void testGetPassengerInfosForFlight() {
        String jsonResponse = '[{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"CTCM","number":"+46701234567"},{"type":"AP-unknown","number":"+4680000000"}],"email":[{"type":"CTCE","address":"name@email.com"},{"type":"AP-unknown","address":"ap@unknown.com"}]},"frequentTraveler":{"euroBonus":[{"segmentIds":["ST1"],"number":"544127491","tier":"EBB"}],"other":[{"segmentIds":["ST1"],"number":"S125891143","carrier":"LH"}]},"specialServiceRequests":[{"segmentIds":["ST1","ST2"],"type":"Wheelchair","code":"WCHR","text":"WCHR ASSISTANCE.PROVIDED REGULATIONS IN SALES PROCEDURES ARE MET"}],"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LH0946-20200211-ORD-ARN", "operatingId":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingId":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingId":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingId":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}]';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),    
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.anyObject()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String flightId = 'SK0946-20200211-ORD-ARN';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(
                flightId);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.anyObject()
        );
        Map<String, Object> matchMap = new Map<String, Object>{
                'flightId' => flightId
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.eqString('/teds-booking/bookings'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.mapWithPath(matchMap)
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assertEquals('P2WNNO', passengerInfo.bookingReference);
        System.assertEquals('ABC1234', passengerInfo.codsId);
        System.assertEquals('MILLEY/SAM', passengerInfo.lastNameSlashFirstName);
        System.assert(passengerInfo.hasPhoneNumber);
        System.assert(passengerInfo.hasEmailAddress);
        System.assertEquals('+46701234567', passengerInfo.phoneNumber);
        System.assertEquals('name@email.com', passengerInfo.emailAddress);
        System.assertEquals('SK0946-20200211-ORD-ARN', passengerInfo.thisSegment.flightId);
        System.assertEquals('Y', passengerInfo.thisSegment.bookingClass);
        System.assertEquals('C', passengerInfo.thisSegment.serviceClass);
        System.assertEquals('HK', passengerInfo.thisSegment.statusCode);
        System.assertEquals(true, passengerInfo.thisSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.thisSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.thisSegment.ticketNumber);
        System.assertEquals('ORD', passengerInfo.thisSegment.stationDeparture);
        System.assertEquals('ARN', passengerInfo.thisSegment.stationArrival);
        System.assertEquals(true, passengerInfo.thisSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.thisSegment.status);
        System.assertEquals(true, passengerInfo.hasNextSegment);
        System.assertEquals('SK1407-20200212-ARN-CPH', passengerInfo.nextSegment.flightId);
        System.assertEquals('Y', passengerInfo.nextSegment.bookingClass);
        System.assertEquals('C', passengerInfo.nextSegment.serviceClass);
        System.assertEquals('TK', passengerInfo.nextSegment.statusCode);
        System.assertEquals(true, passengerInfo.nextSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.nextSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.nextSegment.ticketNumber);
        System.assertEquals('ARN', passengerInfo.nextSegment.stationDeparture);
        System.assertEquals('CPH', passengerInfo.nextSegment.stationArrival);
        System.assertEquals(true, passengerInfo.nextSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.nextSegment.status);
        System.assertEquals('EBB', passengerInfo.ebLevel);
        System.assertEquals('LH', passengerInfo.otherFQTVCarrier);
        System.assertEquals('WCHR', passengerInfo.SSR);
    }

    @IsTest
    static void testGetPassengerInfosForFlight_NoTicket_AP() {
        String jsonResponse = '[{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"AP-unknown","number":"+4680000000"}],"email":[{"type":"AP-unknown","address":"ap@unknown.com"}]},"frequentTraveler":{"euroBonus":[{"segmentIds":["ST1"],"number":"544127491","tier":"EBB"}],"other":[{"segmentIds":["ST1"],"number":"S125891143","carrier":"LH"}]},"specialServiceRequests":[{"segmentIds":["ST1","ST2"],"type":"Wheelchair","code":"WCHR","text":"WCHR ASSISTANCE.PROVIDED REGULATIONS IN SALES PROCEDURES ARE MET"}],"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"SK0946-20200211-ORD-ARN","operatingId":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingId":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingId":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingId":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingId":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}]';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.anyObject()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String flightId = 'SK0946-20200211-ORD-ARN';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(
                flightId);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.anyObject()
        );
        Map<String, Object> matchMap = new Map<String, Object>{
                'flightId' => flightId
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.eqString('/teds-booking/bookings'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.mapWithPath(matchMap)
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assert(passengerInfo.hasPhoneNumber);
        System.assert(passengerInfo.hasEmailAddress);
        System.assertEquals('+4680000000', passengerInfo.phoneNumber);
        System.assertEquals('ap@unknown.com', passengerInfo.emailAddress);
        System.assertEquals('SK0946-20200211-ORD-ARN', passengerInfo.thisSegment.flightId);
        System.assertEquals(false, passengerInfo.thisSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.thisSegment.isWideroeTicket);
        System.assertEquals(null, passengerInfo.thisSegment.ticketNumber);
    }

    @IsTest
    static void testGetPassengerInfosForFlight_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.anyObject()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(503, 'Service Unavailable'));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String flightId = 'SK0946-20200211-ORD-ARN';

        //When
        Boolean caughtException = false;
        try {
            IRR_SVC_TedsService.getPassengerInfosForFlight(flightId);
        }
        catch (IRR_SVC_TedsService.TedsException tedsException) {
            if (tedsException.getMessage().contains('Service Unavailable')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch TedsException');
    }

    @IsTest
    static void testGetPassengerInfosForBooking() {
        String jsonResponse = '{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"CTCM","number":"+46701234567"}],"email":[{"type":"CTCE","address":"name@email.com"}]},"frequentTraveler":{"euroBonus":[{"segmentIds":["ST1"],"number":"544127491","tier":"EBB"}],"other":[{"segmentIds":["ST1"],"number":"S125891143","carrier":"LH"}]},"specialServiceRequests":[{"segmentIds":["ST1","ST2"],"type":"Wheelchair","code":"WCHR","text":"WCHR ASSISTANCE.PROVIDED REGULATIONS IN SALES PROCEDURES ARE MET"}],"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"SK0946-20200211-ORD-ARN","operatingId":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingId":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingId":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingId":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingId":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String bookingRef = 'P2WNNO-20200205';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(bookingRef);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assertEquals('P2WNNO', passengerInfo.bookingReference);
        System.assertEquals('ABC1234', passengerInfo.codsId);
        System.assert(passengerInfo.hasPhoneNumber);
        System.assert(passengerInfo.hasEmailAddress);
        System.assertEquals('+46701234567', passengerInfo.phoneNumber);
        System.assertEquals('name@email.com', passengerInfo.emailAddress);
        System.assert(!passengerInfo.hasThisSegment);
        System.assert(!passengerInfo.hasNextSegment);
        System.assertEquals('EBB', passengerInfo.ebLevel);
        System.assertEquals('WCHR', passengerInfo.SSR);
    }

    @IsTest
    static void testGetPassengerInfosForBooking_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(500, 'Internal Server Error'));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String bookingRef = 'P2WNNO-20200205';

        //When
        Boolean caughtException = false;
        try {
            IRR_SVC_TedsService.getPassengerInfosForBooking(bookingRef);
        }
        catch (IRR_SVC_TedsService.TedsException tedsException) {
            if (tedsException.getMessage().contains('Internal Server Error')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch TedsException');
    }

    @isTest
    static void testGetAirportCityNames() {
        String jsonResponse = '[{"id":"ARN","name":"Stockholm-Arlanda Airport","city":"Stockholm","country":{"code":"SE","name":"Sweden"},"coordinates":{"latitude":"59.651901245117","longitude":"17.918600082397"}},{"id":"CPH","name":"Copenhagen Kastrup Airport","city":"Copenhagen","country":{"code":"DK","name":"Denmark"},"coordinates":{"latitude":"55.617900848389","longitude":"12.656000137329"}}]';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),    
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
         Set<String> airportCodes = new Set<String>();
         airportCodes.add('ARN');
         airportCodes.add('CPH');

        //When
        Map<String,String> airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(airportCodes);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        System.assertEquals(2, airportInfoMap.size());
        System.assertEquals('Stockholm', airportInfoMap.get('ARN'));
        System.assertEquals('Copenhagen', airportInfoMap.get('CPH'));
        
    }

    @IsTest
    static void testgetPassengerInfosForBookingFilters() {
        String jsonResponse = '[{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"CTCM","number":"+46701234567"},{"type":"AP-unknown","number":"+4680000000"}],"email":[{"type":"CTCE","address":"name@email.com"},{"type":"AP-unknown","address":"ap@unknown.com"}]},"frequentTraveler":{"euroBonus":[{"segmentIds":["ST1"],"number":"544127491","tier":"EBB"}],"other":[{"segmentIds":["ST1"],"number":"S125891143","carrier":"LH"}]},"specialServiceRequests":[{"segmentIds":["ST1","ST2"],"type":"Wheelchair","code":"WCHR","text":"WCHR ASSISTANCE.PROVIDED REGULATIONS IN SALES PROCEDURES ARE MET"}],"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LH0946-20200211-ORD-ARN", "operatingId":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingId":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingId":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingId":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}]';
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),    
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.anyObject()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String departureStation = 'ARN';
        String arrivalStation = 'CPH';
        String fromDate = '2020-02-11T23:28:00.000Z';
        String toDate = '2020-02-12T23:28:00.000Z';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBookingFilters(
                departureStation,arrivalStation,fromDate,toDate);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.anyObject()
        );
        Map<String, Object> matchMap = new Map<String, Object>{
                'departureStation' => departureStation,
                'arrivalStation' => arrivalStation,
                'fromTimeUTC' => fromDate,
                'toTimeUTC' => toDate
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.eqString('/teds-booking/bookings'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.mapWithPath(matchMap)
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assertEquals('P2WNNO', passengerInfo.bookingReference);
        System.assertEquals('ABC1234', passengerInfo.codsId);
        System.assertEquals('MILLEY/SAM', passengerInfo.lastNameSlashFirstName);
        System.assert(passengerInfo.hasPhoneNumber);
        System.assert(passengerInfo.hasEmailAddress);
        System.assertEquals('+46701234567', passengerInfo.phoneNumber);
        System.assertEquals('name@email.com', passengerInfo.emailAddress);
        System.assertEquals('SK1407-20200212-ARN-CPH', passengerInfo.thisSegment.flightId);
        System.assertEquals('Y', passengerInfo.thisSegment.bookingClass);
        System.assertEquals('C', passengerInfo.thisSegment.serviceClass);
        System.assertEquals('TK', passengerInfo.thisSegment.statusCode);
        System.assertEquals(true, passengerInfo.thisSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.thisSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.thisSegment.ticketNumber);
        System.assertEquals('ARN', passengerInfo.thisSegment.stationDeparture);
        System.assertEquals('CPH', passengerInfo.thisSegment.stationArrival);
        System.assertEquals(true, passengerInfo.thisSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.thisSegment.status);
        System.assertEquals(true, passengerInfo.hasNextSegment);
        System.assertEquals('SK0559-20200212-CPH-CDG', passengerInfo.nextSegment.flightId);
        System.assertEquals('TK', passengerInfo.nextSegment.statusCode);
        System.assertEquals(true, passengerInfo.nextSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.nextSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.nextSegment.ticketNumber);
        System.assertEquals('CPH', passengerInfo.nextSegment.stationDeparture);
        System.assertEquals('CDG', passengerInfo.nextSegment.stationArrival);
        System.assertEquals(true, passengerInfo.nextSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.nextSegment.status);
        System.assertEquals('EBB', passengerInfo.ebLevel);
        System.assertEquals('LH', passengerInfo.otherFQTVCarrier);
        System.assertEquals('WCHR', passengerInfo.SSR);
    }

    @isTest

    static void testgetPassengerInfosForBookingFilters_throws() {

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor)mocks.mock(C_IntegrationExecutorRest.class);
        
        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                (String)fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.anyObject()))
        .thenReturn(new C_IntegrationExecutor.IntegrationResponse(503, 'Service Unavailable'));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String departureStation = 'ARN';
        String arrivalStation = 'CPH';
        String fromDate = '2021-03-09T09:28:00.000Z';
        String toDate = '2021-03-09T12:28:00.000Z';

        //when
        Boolean caughtException = false;
        try {
                IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation, arrivalStation, fromDate, toDate);
                
        } catch (IRR_SVC_TedsService.TedsException tedsException) {
                if (tedsException.getMessage().contains('Service Unavailable')) caughtException = true;
                
        }

        //Then
        System.assert(caughtException, 'Expected to catch TedsException');
    }

   @IsTest
    static void testGetFlightInfosForFlight() {
        String jsonResponse = '{"id":"SK0805-20230709-OSL-LHR","departureKey":"20230709OSL","carrier":"SK","flightNumber":"0805","callSign":"SAS805","operationalControlCentre":"SZS","serviceType":{"code":"J","application":"Scheduled"},"departure":{"scheduledTime":{"utc":"2023-07-09T11:15:00Z","local":"2023-07-09T13:15:00"},"status":"cancelled","station":"OSL","stand":"56","gate":"F32","cancellationTime":"2023-07-09T04:19:29.409Z","cancellationReasons":[{"reasonCode":"CREW","supplementaryInformation":"CCSTB"}],"delayedMinutes":0},"arrival":{"scheduledTime":{"utc":"2023-07-09T13:35:00Z","local":"2023-07-09T14:35:00"},"status":"cancelled","station":"LHR","delayedMinutes":0},"aircraft":{"owner":"SZS","version":"32H2","configuration":"C6M174","type":"32S","subType":"32N","typypeCode":"32C","registration":"---"},"metadata":{"lastReceivedMethod":"ASM","lastReceivedAction":"CNL","isOfficial":true},"passengerCapacity":{"C":24,"Y":0,"M":156}}';       //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);

        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.enableSASTracking()).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),    
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String flightId = 'SK0805-20230709-OSL-LHR';

        //When
         List<TEDSFlight> flightInfos = IRR_SVC_TedsService.getFlightInfos(flightId);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM_TEDS');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v2');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.isNull()
        );
       
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.eqString('/teds-flight/flights/'+flightId),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        System.assertEquals(1, flightInfos.size());
        TEDSFlight flightInfo = flightInfos[0];
        System.assertEquals('SK0805-20230709-OSL-LHR', flightInfo.id);
        System.assertEquals('0805', flightInfo.flightNumber);
        System.assertEquals('SAS805', flightInfo.callSign);
        System.assertEquals('J', flightInfo.serviceType.code);
        System.assertEquals('Scheduled', flightInfo.serviceType.application);
    }

 }