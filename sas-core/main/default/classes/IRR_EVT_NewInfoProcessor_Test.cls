/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the NewInfoProcessor class.
*/

@IsTest
private class IRR_EVT_NewInfoProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        IRR_EVT_NewInfoProcessor newInfoProcessor = (IRR_EVT_NewInfoProcessor)
                new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);


        //When
        String eventName = newInfoProcessor.getEventName();

        //Then
        System.assertEquals('New Info', eventName);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoFlightId() {
        //Given
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        newInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        newInfo.newInfoTimeLocal = Datetime.now();
        newInfo.newInfoTimeUTC = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);

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
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        newInfo.newInfoTimeLocal = Datetime.now();
        newInfo.newInfoTimeUTC = Datetime.now();
        newInfo.flightId = 'TEST_FLIGHT_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Scheduled time of departure is missing from event')) {
                caughtException = true;
            }
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoLocalNewInfoTime() {
        //Given
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        newInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        newInfo.newInfoTimeUTC = Datetime.now();
        newInfo.flightId = 'TEST_FLIGHT_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('New Info time is missing from event')) {
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
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.flightId = 'SK1429-20191104-ARN-CPH';
        newInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(-3);
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
        Test.setMock(HttpCalloutMock.class, new IRR_SVC_ICouponMockClass());
        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new Set<String>{'ARN','CPH'});
        System.assertEquals('SK1429', newInfo.flightRef);
        System.assertEquals('ARN', newInfo.stationDeparture);
        System.assertEquals('CPH', newInfo.stationArrival);
        System.assertEquals('Copenhagen' ,airportInfoMap.get(newInfo.stationArrival));
        System.assertEquals('Stockholm' ,airportInfoMap.get(newInfo.stationDeparture));
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
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);

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
        IRR_MOD_NewInfo newInfo = new IRR_MOD_NewInfo();
        newInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_NewInfoProcessor.Constructor().newInstance(newInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        ((IRR_SEL_IManualOverridesSelector) mocks.verify(selectorMock))
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');
        System.assertEquals(false, result);
    }

    @IsTest
    static void testProcessEvent_Confirmed_SendSMS() {
        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_NewInfoProcessor eventProcessor = (IRR_EVT_NewInfoProcessor) new IRR_EVT_NewInfoProcessor.Constructor()
                .newInstance(null);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
        System.assertEquals('irr_new_info_sms_01', messages[0].template);
        System.assertEquals('New Info', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('newInfo'));
    }

    @IsTest
    static void testProcessEvent_NotConfirmed_NoMessage() {
        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = false;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_NewInfoProcessor eventProcessor = (IRR_EVT_NewInfoProcessor) new IRR_EVT_NewInfoProcessor.Constructor()
                .newInstance(null);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(0, messages.size());
    }
}