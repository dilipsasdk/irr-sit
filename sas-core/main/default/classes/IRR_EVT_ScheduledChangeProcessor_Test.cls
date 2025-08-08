/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit test class for the Scheduled Change event processor.
*/

@IsTest
private class IRR_EVT_ScheduledChangeProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        IRR_EVT_ScheduledChangeProcessor sChangeProcessor = (IRR_EVT_ScheduledChangeProcessor)
                new IRR_EVT_ScheduledChangeProcessor.Constructor().newInstance(scheduledChangeInfo);

        //When
        String eventName = sChangeProcessor.getEventName();

        //Then
        System.assertEquals('Scheduled Change', eventName);
    }


    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingId = 'TEST_BOOKING_ID';
        scheduledChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        scheduledChangeInfo.eventTime = Datetime.now();
        scheduledChangeInfo.isDayChange = true;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

        //When
        eventProcessor.validateEvent();

        //Then
        System.assert(true);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingRef() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingId = 'TEST_BOOKING_ID';
        scheduledChangeInfo.eventTime = Datetime.now();
        scheduledChangeInfo.isDayChange = true;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Booking Ref is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoEventTime() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingId = 'TEST_BOOKING_ID';
        scheduledChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        scheduledChangeInfo.isDayChange = true;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Event time is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingId() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        scheduledChangeInfo.eventTime = Datetime.now();
        scheduledChangeInfo.isDayChange = true;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

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
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingId = 'TEST_BOOKING_ID';
        scheduledChangeInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        scheduledChangeInfo.eventTime = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Is Day Change is missing from event')) caughtException = true;
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
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.bookingId = 'TEST_BOOKING_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        System.assertEquals(passengerInfos, ((IRR_EVT_ScheduledChangeProcessor) eventProcessor).passengerInfos);
    }

    @IsTest
    static void testCheckActiveBlock() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ScheduledChangeProcessor.Constructor()
                .newInstance(scheduledChangeInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);
    }

    @IsTest
    static void testProcessEvent_Confirmed_SendSMSEmail() {
        //Given
        IRR_MOD_ScheduledChangeInfo scheduledChangeInfo = new IRR_MOD_ScheduledChangeInfo();
        scheduledChangeInfo.eventTime = Datetime.now();
        scheduledChangeInfo.eventTime = Datetime.now();
        scheduledChangeInfo.largeChangeFromOriginalSTD = true;
        scheduledChangeInfo.rebookableOnline = true;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        passengerInfos[0].hasRXLine= false;
        IRR_EVT_ScheduledChangeProcessor eventProcessor =
                (IRR_EVT_ScheduledChangeProcessor) new IRR_EVT_ScheduledChangeProcessor.Constructor()
                    .newInstance(scheduledChangeInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
       /* System.assertEquals(2, messages.size());
        System.assertEquals('irr_schedule_change_sms_RX', messages[0].template);
        System.assertEquals('irr_schedule_change_email_RX', messages[1].template);
        System.assertEquals('Scheduled Change', messages[0].type);
        System.assertEquals('Scheduled Change', messages[1].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('scheduledChangeInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('scheduledChangeInfo'));*/
    }
}