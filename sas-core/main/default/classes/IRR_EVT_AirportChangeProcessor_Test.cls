/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
* @description Unit test class for the Airport Change event processor.
*/

@IsTest
private class IRR_EVT_AirportChangeProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        IRR_EVT_AirportChangeProcessor aChangeProcessor = (IRR_EVT_AirportChangeProcessor)
                new IRR_EVT_AirportChangeProcessor.Constructor().newInstance(airportChangeInfo);

        //When
        String eventName = aChangeProcessor.getEventName();

        //Then
        System.assertEquals('Airport Change', eventName);
    }


    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingId = 'TEST_BOOKING_ID';
        airportChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        airportChangeInfo.eventTime = Datetime.now();
        airportChangeInfo.source = 'Test';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        eventProcessor.validateEvent();

        //Then
        System.assert(true);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingRef() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingId = 'TEST_BOOKING_ID';
        airportChangeInfo.eventTime = Datetime.now();
        airportChangeInfo.source = 'Test';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Booking Reference is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoEventTime() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingId = 'TEST_BOOKING_ID';
        airportChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        airportChangeInfo.source = 'Test';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Event Time is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingId() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        airportChangeInfo.eventTime = Datetime.now();
        airportChangeInfo.source = 'Test';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Booking Id is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoIsDayChange() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingId = 'TEST_BOOKING_ID';
        airportChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        airportChangeInfo.eventTime = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Source is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testInitiateEvent() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID'))
                .thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.bookingId = 'TEST_BOOKING_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        System.assertEquals(passengerInfos, ((IRR_EVT_AirportChangeProcessor) eventProcessor).passengerInfos);
    }

    @IsTest
    static void testCheckActiveBlock() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AirportChangeProcessor.Constructor()
                .newInstance(airportChangeInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);
    }

    @IsTest
    static void testProcessEvent_Confirmed_SendSMSEmail() {
        //Given
        IRR_MOD_AirportChangeInfo airportChangeInfo = new IRR_MOD_AirportChangeInfo();
        airportChangeInfo.eventTime = Datetime.now();
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        passengerInfos[0].hasRXLine= false;
        IRR_EVT_AirportChangeProcessor eventProcessor =
                (IRR_EVT_AirportChangeProcessor) new IRR_EVT_AirportChangeProcessor.Constructor()
                    .newInstance(airportChangeInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
       /* System.assertEquals(2, messages.size());
        System.assertEquals('irr_airportChange_sms_01', messages[0].template);
        System.assertEquals('irr_airportChange_email_01', messages[1].template);
        System.assertEquals('Airport Change', messages[0].type);
        System.assertEquals('Airport Change', messages[1].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('airportChangeInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('airportChangeInfo'));*/
    }
}