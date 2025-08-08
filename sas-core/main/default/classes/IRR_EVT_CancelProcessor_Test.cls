/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit tests for the Cancel Processor class.
*/

@IsTest
private class IRR_EVT_CancelProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        IRR_EVT_CancelProcessor newInfoProcessor = (IRR_EVT_CancelProcessor)
                new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        String eventName = newInfoProcessor.getEventName();

        //Then
        System.assertEquals('Cancel', eventName);
    }

    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'TEST_FLIGHT_ID';
        cancelInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        cancelInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        eventProcessor.validateEvent();
    }

    @IsTest
    static void testValidateEvent_ThrowsNoFlightId() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        cancelInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Flight Id is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoLocalScheduledTime() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'TEST_FLIGHT_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Scheduled time of departure is missing from event')){
                caughtException = true;
            }
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
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();   
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'SK1429-20191104-ARN-CPH';
        cancelInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new Set<String>{'ARN','CPH'});

        System.assertEquals('SK1429', cancelInfo.flightRef);
        System.assertEquals('ARN', cancelInfo.stationDeparture);
        System.assertEquals('CPH', cancelInfo.stationArrival);
        System.assert(cancelInfo.minutesToScheduledTime >= 179 && cancelInfo.minutesToScheduledTime < 181);
        System.assertEquals('Copenhagen' ,airportInfoMap.get(cancelInfo.stationArrival));
        System.assertEquals('Stockholm' ,airportInfoMap.get(cancelInfo.stationDeparture));
    }

    @IsTest
    static void testCheckActiveBlock_Block() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualOverridesSelector selectorMock = (IRR_SEL_IManualOverridesSelector) mocks.mock(
                IRR_SEL_ManualOverridesSelector.class);

        //Given
        mocks.startStubbing();
        mocks.when(selectorMock.selectActiveManualOverridesByFlightId(fflib_Match.anyString()))
                .thenReturn(new List<IRR_ManualOverride__c>{new IRR_ManualOverride__c()});
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualOverride__c.SObjectType);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        ((IRR_SEL_IManualOverridesSelector) mocks.verify(selectorMock))
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');
        System.assertEquals(true, result);
    }

    @IsTest
    static void testCheckActiveBlock_NoBlock() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualOverridesSelector selectorMock = (IRR_SEL_IManualOverridesSelector) mocks.mock(
                IRR_SEL_ManualOverridesSelector.class);

        //Given
        mocks.startStubbing();
        mocks.when(selectorMock.selectActiveManualOverridesByFlightId(fflib_Match.anyString()))
                .thenReturn(new List<IRR_ManualOverride__c>());
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualOverride__c.SObjectType);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CancelProcessor.Constructor().newInstance(cancelInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        ((IRR_SEL_IManualOverridesSelector) mocks.verify(selectorMock))
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');
        System.assertEquals(false, result);
    }

    @IsTest
    static void testProcessEventCloseToDeparture_Confirmed_SendSMSEmail() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'SK1429-20191104-ARN-CPH';
        cancelInfo.minutesToScheduledTime = 100;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_CancelProcessor eventProcessor = (IRR_EVT_CancelProcessor) new IRR_EVT_CancelProcessor.Constructor()
                .newInstance(cancelInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assertEquals('irr_cancellation_sms_01', messages[0].template);
        System.assertEquals('irr_cancellation_email_01', messages[1].template);
        System.assertEquals('Cancel', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('cancelInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('cancelInfo'));
    }

    @IsTest
    static void testProcessEventFarFromDeparture_Confirmed_NoMessages() {
        //Given
        IRR_MOD_CancelInfo cancelInfo = new IRR_MOD_CancelInfo();
        cancelInfo.flightId = 'SK1429-20191104-ARN-CPH';
        cancelInfo.minutesToScheduledTime = 3000;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_CancelProcessor eventProcessor = (IRR_EVT_CancelProcessor) new IRR_EVT_CancelProcessor.Constructor()
                .newInstance(cancelInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(0, messages.size());
    }
}