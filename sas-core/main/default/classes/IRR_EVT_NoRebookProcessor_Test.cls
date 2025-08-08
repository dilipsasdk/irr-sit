/**
* @author Chetan Singh, Coforge
* @date 2022
*
* @description Unit test class for the NoAlternativeUN(NoRebook) event processor.
*/

@isTest
private class IRR_EVT_NoRebookProcessor_Test {

    @isTest
    static void testGetEventName() {

        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        IRR_EVT_NoRebookProcessor noRebookInfoProcessor = (IRR_EVT_NoRebookProcessor)
                new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        String eventName = noRebookInfoProcessor.getEventName();

        //Then
        System.assertEquals('No Alternative Rebooking', eventName);

    }

    @isTest
    static void testValidateEvent_Success() { 
        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingId ='TEST_BOOKING_ID';
        noRebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        noRebookInfo.eventTime = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        noRebookInfo.cancelledSegment = 'CANCELLED_SEGMENT';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        eventProcessor.validateEvent();

        //Then
        System.assert(true);
    }

    @isTest
    static void testValidateEvent_ThrowsNoEventTime() { 
        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingId ='TEST_BOOKING_ID';
        noRebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        noRebookInfo.cancelledSegment = 'CANCELLED_SEGMENT';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        } 
        catch (IRR_SVC_CommunicationService.EventException e) {
            if (e.getMessage().contains('Event time is missing from event')) {
                caughtException = true;
            }
        }
        //Then
        System.assert(caughtException,true);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoScheduledTime() {
        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingId ='TEST_BOOKING_ID';
        noRebookInfo.eventTime = Datetime.now();
        noRebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException e) {
            if (e.getMessage().contains('Scheduled time of departure is missing from event')){
                caughtException = true;
            }
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoBookingRef() {
        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingId ='TEST_BOOKING_ID';
        noRebookInfo.eventTime = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException e) {
            if (e.getMessage().contains('Booking Ref is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoBookingId() {
        //Given
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);


        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException e) {
            if (e.getMessage().contains('Booking Id is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }
    @isTest

    static void testInitiateEvent() {

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.bookingId ='TEST_BOOKING_ID';
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();

        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService)mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');

    }


    @isTest
    static void testCheckActiveBlock() {

        //Given
        IRR_MOD_NoRebookInfo noRebookInfo= new IRR_MOD_NoRebookInfo();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NoRebookProcessor.Constructor().newInstance(noRebookInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);

    }


    @IsTest
    static void testProcessEvent_Confirmed_SendSMSEmail() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        mocks.startStubbing();
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_NoRebookInfo noRebookInfo = new IRR_MOD_NoRebookInfo();
        noRebookInfo.eventTime = Datetime.now();
        noRebookInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        passengerInfos[0].itinerary = new List<IRR_MOD_TripInfo>();
        IRR_MOD_TripInfo tripInfo = new IRR_MOD_TripInfo();
        List<IRR_MOD_SegmentInfo> segments = new List<IRR_MOD_SegmentInfo>();
        IRR_MOD_SegmentInfo segmentInfo = new IRR_MOD_SegmentInfo();
        segmentInfo.stationArrival= 'ARN';
        segmentInfo.stationDeparture= 'CPH';
        segments.add(segmentInfo);
        tripInfo.segments = segments;
        passengerInfos[0].itinerary.add(tripInfo);
        IRR_EVT_NoRebookProcessor eventProcessor = (IRR_EVT_NoRebookProcessor) new IRR_EVT_NoRebookProcessor.Constructor()
                .newInstance(noRebookInfo);
        eventProcessor.passengerInfos = passengerInfos;
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.processEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new Set<String>{'ARN','CPH'});
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assertEquals('irr_noalternativeUN_sms_01', messages[0].template);
        System.assertEquals('irr_noalternativeUN_email_01', messages[1].template);
        System.assertEquals('No Alternative Rebooking', messages[0].type);
        System.assertEquals('No Alternative Rebooking', messages[1].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('noRebookInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('noRebookInfo'));
    }
}



