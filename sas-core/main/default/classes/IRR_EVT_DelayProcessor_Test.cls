/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the DelayProcessor class, also covers parts of EventProcessor abstract class.
*/

@IsTest
private class IRR_EVT_DelayProcessor_Test {

    @IsTest
    static void testInitiateEvent_Object() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();

        //When
        Object result = IRR_Application.EventProcessor.newInstance('flightDelayDeparture', delayInfo);

        //Then
        System.assert(result instanceof IRR_EVT_DelayProcessor, 'Expected result of type DelayProcessor');
    }

    @IsTest
    static void testInitiateEvent_JSON() {
        //Given
        String jsonPayload = '{}';

        //When
        Object result = IRR_Application.EventProcessor.newInstance('flightDelayDeparture', jsonPayload);

        //Then
        System.assert(result instanceof IRR_EVT_DelayProcessor, 'Expected result of type DelayProcessor');
    }

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        IRR_EVT_DelayProcessor delayProcessor = (IRR_EVT_DelayProcessor)
                new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);


        //When
        String eventName = delayProcessor.getEventName();

        //Then
        System.assertEquals('Delay', eventName);
    }

    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        delayInfo.delayedMinutes = 10;
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

        //When
        eventProcessor.validateEvent();
    }

    @IsTest
    static void testValidateEvent_ThrowsNoFlightId() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        delayInfo.delayedMinutes = 10;
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

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
    static void testValidateEvent_ThrowsNoDelayMinutes() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Delay minutes is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoDelayedTime() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        delayInfo.delayedMinutes = 10;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Estimated time of departure is missing from event')){
                caughtException = true;
            }
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoScheduledTime() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.delayedMinutes = 10;
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

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
    static void testInitiateEventNoPreviousDelay() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IDelayLogsSelector selectorMock = (IRR_SEL_IDelayLogsSelector) mocks.mock(
                IRR_SEL_DelayLogsSelector.class);
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        Map<String, Integer> delayMinutesByFlightIds = new Map<String, Integer>();
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_DelayLog__c.SObjectType);
        mocks.when(selectorMock.getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-ARN-CPH'}))
                .thenReturn(delayMinutesByFlightIds);
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        delayInfo.delayedMinutes = 10;
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(4);
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now().addHours(5);
        delayInfo.stationArrival='CPH';
        delayInfo.stationDeparture='ARN';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SEL_IDelayLogsSelector) mocks.verify(selectorMock))
                .getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-ARN-CPH'});
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new Set<String>{'ARN','CPH'});

        System.assertEquals(0, delayInfo.previousDelayedMinutes);
        System.assertEquals(10, delayInfo.delayDifference);
        System.assertEquals(10, delayInfo.delayedMinutes);
        System.assertEquals('SK1429', delayInfo.flightRef);
        System.assertEquals('ARN', delayInfo.stationDeparture);
        System.assertEquals('CPH', delayInfo.stationArrival);
        System.assert(delayInfo.firstDelay);
        System.assert(delayInfo.minutesToScheduledTime >= 179 && delayInfo.minutesToScheduledTime < 181);
        System.assertEquals('Copenhagen' ,airportInfoMap.get(delayInfo.stationArrival));
        System.assertEquals('Stockholm' ,airportInfoMap.get(delayInfo.stationDeparture));
    }

    @IsTest
    static void testInitiateEventWithPreviousDelay() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IDelayLogsSelector selectorMock = (IRR_SEL_IDelayLogsSelector) mocks.mock(
                IRR_SEL_DelayLogsSelector.class);
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        Map<String, Integer> delayMinutesByFlightIds = new Map<String, Integer>{'TEST_FLIGHT_ID' => 10};
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_DelayLog__c.SObjectType);
        mocks.when(selectorMock.getLatestDelayByFlightIds(new Set<String>{'TEST_FLIGHT_ID'}))
                .thenReturn(delayMinutesByFlightIds);
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID'))
                .thenReturn(passengerInfos);
        mocks.stopStubbing();
        
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.delayedMinutes = 10;
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(4);
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now().addHours(5);
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SEL_IDelayLogsSelector) mocks.verify(selectorMock))
                .getLatestDelayByFlightIds(new Set<String>{'TEST_FLIGHT_ID'});
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('TEST_FLIGHT_ID');
        System.assertEquals(10, delayInfo.previousDelayedMinutes);
        System.assertEquals(0, delayInfo.delayDifference);
        System.assertEquals(10, delayInfo.delayedMinutes);
        System.assert(!delayInfo.firstDelay);
        System.assert(delayInfo.minutesToScheduledTime >= 179 && delayInfo.minutesToScheduledTime < 181);
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
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

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
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

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
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.delayDifference = 20;
        delayInfo.minutesToScheduledTime = 100; 
        delayInfo.hasCouponBatchId = false;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].hasBoarded = false;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
      //  System.assertEquals('irr_delay_sms_01', messages[0].template);
        System.assertEquals('Delay', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        //System.assertEquals(messages[0].recipient, 'TEST_PHONE');
       // System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('delayInfo'));
    }

    @IsTest
    static void testProcessEventCloseToDeparture_Confirmed_SendSMS_NoPhone() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.delayDifference = 15;
        delayInfo.minutesToScheduledTime = 100;
        delayInfo.hasCouponBatchId = false;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = false;
        passengerInfos[0].phoneNumber = null;
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].hasBoarded = false;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
      //  System.assertEquals('irr_delay_sms_01', messages[0].template);
        System.assertEquals('Delay', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
      //  System.assertEquals(null, messages[0].recipient);
       // System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('delayInfo'));
    }

    @IsTest
    static void testProcessEventCloseToDeparture_Confirmed_NoSMS() {
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.delayDifference = 5;
        delayInfo.minutesToScheduledTime = 100;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(0, messages.size());
    }

    @IsTest
    static void testProcessEvent_NotConfirmed_NoMessage() {
        
        //Given
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.delayDifference = 10;
        delayInfo.minutesToScheduledTime = 100;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = false;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(0, messages.size());
    }
    

    @IsTest
    static void testFinalizeEvent_Message() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

         //Given
            IRR_EventLog__c eventLogs = new IRR_EventLog__c();
            eventLogs.IRR_ScheduleTime__c = System.Now().addHours(1);
            eventLogs.IRR_FlightId__c = 'SK1429-20191104-AGP-ARN' ;
            eventLogs.IRR_Event_Type__c = 'ICOUPON';
            eventLogs.IRR_Delayed_Minutes__c = 130;
            eventLogs.IRR_Station_Departure__c = 'ARN';
            eventLogs.IRR_Flight_Ref__c = 'SK1429';
            eventLogs.Is_Communication_Send__c = false;

            insert eventLogs;
        
        //Given
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(null, null, null);
        smsMessage.messageKey = 'TEST_MESSAGE_KEY';
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-AGP-ARN';
        delayInfo.delayedMinutes = 130;
        delayInfo.firstDelay = false;
        List<IRR_MOD_PassengerInfo> passengerInfo = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfo[0].hasThisSegment = true;
        passengerInfo[0].lastNameSlashFirstName = 'TEST_LAST_NAME/TEST_FIRST_NAME';
        passengerInfo[0].phoneNumber = 'TEST_PHONE';
        passengerInfo[0].emailAddress = 'TEST_EMAIL';
        passengerInfo[0].codsId = 'TEST_CODS_ID';
        passengerInfo[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfo[0].thisSegment.flightId = 'SK1429-20191104-AGP-ARN';
        passengerInfo[0].thisSegment.serviceClass = 'C';
        passengerInfo[0].thisSegment.boardingSequenceNumber = 002;
        passengerInfo[0].bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfo;
        IRR_MOD_Message message = new IRR_MOD_Message('TEST_STATUS', IRR_MOD_Message.MessageChannel.SMS, null, null,
                passengerInfo[0], 'TEST_TYPE', false);
        message.SFMCMessage = smsMessage;
        eventProcessor.messages.add(message);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        Map<SObjectField, Object> cLogMatcher = new Map<SObjectField, Object>{
                IRR_CommunicationLog__c.IRR_FlightId__c => 'SK1429-20191104-AGP-ARN',
                IRR_CommunicationLog__c.IRR_BookingReference__c => 'TEST_BOOKING_REFERENCE',
                IRR_CommunicationLog__c.IRR_CodsId__c => 'TEST_CODS_ID',
                IRR_CommunicationLog__c.IRR_Channel__c => 'SMS',
                IRR_CommunicationLog__c.IRR_ContactKey__c => 'TEST_EMAIL',
                IRR_CommunicationLog__c.IRR_MessageKey__c => 'TEST_MESSAGE_KEY',
                IRR_CommunicationLog__c.IRR_Recipient__c => 'TEST_PHONE',
                IRR_CommunicationLog__c.IRR_Status__c => 'TEST_STATUS',
                IRR_CommunicationLog__c.IRR_RecipientName__c => 'TEST_LAST_NAME/TEST_FIRST_NAME'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(cLogMatcher));
        Map<SObjectField, Object> dLogMatcher = new Map<SObjectField, Object>{
                IRR_DelayLog__c.IRR_DelayMinutes__c => 130,
                IRR_DelayLog__c.IRR_FlightId__c => 'SK1429-20191104-AGP-ARN'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_DelayLog__c.SObjectType));
      //  ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(dLogMatcher));
    }
    
     @IsTest
    static void testFinalizeEvent_Message2() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        
        //Given
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(null, null, null);
        smsMessage.messageKey = 'TEST_MESSAGE_KEY';
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-AGP-ARN';
        delayInfo.stationDeparture = 'AGP';
        delayInfo.delayedMinutes = 130;
        delayInfo.firstDelay = false;
        String eventDate ='2023-03-30T23:02:20Z';
        String scheduledTimeOfDepartureUTC ='2023-03-30T20:02:20Z';
        String estimatedTimeOfDepartureUTC ='2023-03-30T221:02:20Z';
        delayInfo.eventTime =  DateTime.ValueofGmt(eventDate.replace('T', ' ')); 
        delayInfo.scheduledTimeOfDepartureUTC =  DateTime.ValueofGmt(scheduledTimeOfDepartureUTC.replace('T', ' ')); 
        delayInfo.estimatedTimeOfDepartureUTC = DateTime.ValueofGmt(estimatedTimeOfDepartureUTC.replace('T', ' ')); 
        List<IRR_MOD_PassengerInfo> passengerInfo = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfo[0].hasThisSegment = true;
        passengerInfo[0].lastNameSlashFirstName = 'TEST_LAST_NAME/TEST_FIRST_NAME';
        passengerInfo[0].phoneNumber = 'TEST_PHONE';
        passengerInfo[0].emailAddress = 'TEST_EMAIL';
        passengerInfo[0].codsId = 'TEST_CODS_ID';
        passengerInfo[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfo[0].thisSegment.flightId = 'SK1429-20191104-AGP-ARN';
        passengerInfo[0].thisSegment.serviceClass = 'C';
        passengerInfo[0].thisSegment.boardingSequenceNumber = 002;
        passengerInfo[0].thisSegment.flightNumber = 'SK1429';
        passengerInfo[0].thisSegment.departureTimeUTC = String.valueOf(System.now());
        passengerInfo[0].bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        eventProcessor.passengerInfos = passengerInfo;
        IRR_MOD_Message message = new IRR_MOD_Message('TEST_STATUS', IRR_MOD_Message.MessageChannel.SMS, null, null,
                passengerInfo[0], 'TEST_TYPE', false);
        message.SFMCMessage = smsMessage;
        eventProcessor.messages.add(message);

        //When
        eventProcessor.finalizeEvent(uowMock);
        //Then
        Map<SObjectField, Object> cLogMatcher = new Map<SObjectField, Object>{
                IRR_CommunicationLog__c.IRR_FlightId__c => 'SK1429-20191104-AGP-ARN',
                IRR_CommunicationLog__c.IRR_BookingReference__c => 'TEST_BOOKING_REFERENCE',
                IRR_CommunicationLog__c.IRR_CodsId__c => 'TEST_CODS_ID',
                IRR_CommunicationLog__c.IRR_Channel__c => 'SMS',
                IRR_CommunicationLog__c.IRR_ContactKey__c => 'TEST_EMAIL',
                IRR_CommunicationLog__c.IRR_MessageKey__c => 'TEST_MESSAGE_KEY',
                IRR_CommunicationLog__c.IRR_Recipient__c => 'TEST_PHONE',
                IRR_CommunicationLog__c.IRR_Status__c => 'TEST_STATUS',
                IRR_CommunicationLog__c.IRR_RecipientName__c => 'TEST_LAST_NAME/TEST_FIRST_NAME'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(cLogMatcher));
        Map<SObjectField, Object> dLogMatcher = new Map<SObjectField, Object>{
                IRR_DelayLog__c.IRR_DelayMinutes__c => 130,
                IRR_DelayLog__c.IRR_FlightId__c => 'SK1429-20191104-AGP-ARN'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_DelayLog__c.SObjectType));
      //  ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(dLogMatcher));
    }

    @IsTest
    static void testFinalizeEvent_NoMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        
       
        //Given
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(null);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 0))
                .registerNew(fflib_Match.anySObject());
    }

    @IsTest
    static void testFinalizeEvent_Error() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
            IRR_EventLog__c eventLogs = new IRR_EventLog__c();
            eventLogs.IRR_ScheduleTime__c = System.Now().addHours(1);
            eventLogs.IRR_FlightId__c ='TEST_FLIGHT_ID' ;
            eventLogs.IRR_Event_Type__c = 'ICOUPON';
            eventLogs.IRR_Delayed_Minutes__c = 70;
            eventLogs.IRR_Station_Departure__c = 'ARN';
            eventLogs.IRR_Flight_Ref__c = 'SK1429';
            eventLogs.Is_Communication_Send__c = false;

            insert eventLogs;
        //Given
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(null, null, null);
        smsMessage.messageKey = 'TEST_MESSAGE_KEY';
        smsMessage.errorMessage = 'TEST_ERROR';
        smsMessage.errorCode = 9000;
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'TEST_FLIGHT_ID';
        delayInfo.delayedMinutes = 10;
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfo.thisSegment.flightId = 'TEST_FLIGHT_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(delayInfo);
        IRR_MOD_Message message = new IRR_MOD_Message('TEST_STATUS', IRR_MOD_Message.MessageChannel.SMS, null, null,
                passengerInfo, 'TEST_TYPE', false);
        message.SFMCMessage = smsMessage;
        eventProcessor.messages.add(message);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        Map<SObjectField, Object> cLogMatcher = new Map<SObjectField, Object>{
                IRR_CommunicationLog__c.IRR_FlightId__c => 'TEST_FLIGHT_ID',
                IRR_CommunicationLog__c.IRR_BookingReference__c => 'TEST_BOOKING_REFERENCE',
                IRR_CommunicationLog__c.IRR_CodsId__c => 'TEST_CODS_ID',
                IRR_CommunicationLog__c.IRR_Channel__c => 'SMS',
                IRR_CommunicationLog__c.IRR_ContactKey__c => 'TEST_EMAIL',
                IRR_CommunicationLog__c.IRR_MessageKey__c => 'TEST_MESSAGE_KEY',
                IRR_CommunicationLog__c.IRR_Recipient__c => 'TEST_PHONE',
                IRR_CommunicationLog__c.IRR_Status__c => 'Error',
                IRR_CommunicationLog__c.IRR_StatusCode__c => 9000,
                IRR_CommunicationLog__c.IRR_ErrorMessage__c => 'TEST_ERROR',
                IRR_CommunicationLog__c.IRR_ResponseMessage__c => false

        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(cLogMatcher));
        Map<SObjectField, Object> dLogMatcher = new Map<SObjectField, Object>{
                IRR_DelayLog__c.IRR_DelayMinutes__c => 10,
                IRR_DelayLog__c.IRR_FlightId__c => 'TEST_FLIGHT_ID'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_DelayLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(dLogMatcher));
    }

    @IsTest
    static void testProcessMessages_NotIsSandbox() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        MSG_IRenderer rendererMock = (MSG_IRenderer) mocks.mock(MSG_RendererEnhanced.class);
        MSG_ITemplateCache cacheMock = (MSG_ITemplateCache) mocks.mock(MSG_TemplateCache.class);
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);
        IRR_SEL_IOrganizationSelector selectorMock = (IRR_SEL_IOrganizationSelector)
                mocks.mock(IRR_SEL_OrganizationSelector.class);


        //Given
        Organization org = (Organization) C_TestDataFactory.createSObject(Organization.SObjectType,
                new Map<SObjectField, Object> { Organization.IsSandbox => false });
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Organization.SObjectType);
        mocks.when(selectorMock.selectOrganization()).thenReturn(org);
        mocks.stopStubbing();
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_MOD_Message message = new IRR_MOD_Message('Created', IRR_MOD_Message.MessageChannel.SMS, null,
                'TEST_TEMPLATE', passengerInfo, 'Delay', false);
        IRR_MOD_Message messageDuplicate = message.clone();
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(null);
        eventProcessor.messages.add(message);
        eventProcessor.messages.add(messageDuplicate);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);
        IRR_Application.MessageRenderer.setMock(rendererMock);
        IRR_Application.MessageRenderer.setMock(cacheMock);

        //When
        eventProcessor.processMessages();

        //Then
        System.assertEquals(1, eventProcessor.messages.size());
        ((MSG_ITemplateCache) mocks.verify(cacheMock)).loadTemplates(new Set<String>{'TEST_TEMPLATE'});
        ((MSG_IRenderer) mocks.verify(rendererMock)).renderMessage(message);
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.anyList());
    }

    @IsTest
    static void testProcessMessages_Whitelisted() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        MSG_IRenderer rendererMock = (MSG_IRenderer) mocks.mock(MSG_RendererEnhanced.class);
        MSG_ITemplateCache cacheMock = (MSG_ITemplateCache) mocks.mock(MSG_TemplateCache.class);
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);
        IRR_SEL_IOrganizationSelector selectorMock = (IRR_SEL_IOrganizationSelector)
                mocks.mock(IRR_SEL_OrganizationSelector.class);
        IRR_SEL_IRecipientWhitelistSelector whitelistMock = (IRR_SEL_IRecipientWhitelistSelector)
                mocks.mock(IRR_SEL_RecipientWhitelistSelector.class);


        //Given
        Organization org = (Organization) C_TestDataFactory.createSObject(Organization.SObjectType,
                new Map<SObjectField, Object> { Organization.IsSandbox => true });
        Set<String> recipientWhitelist = new Set<String>{'TEST_PHONE'};
        mocks.startStubbing();
        mocks.when(whitelistMock.sObjectType()).thenReturn(IRR_RecipientWhitelist__mdt.SObjectType);
        mocks.when(whitelistMock.getAllWhitelistedRecipients()).thenReturn(recipientWhitelist);
        mocks.when(selectorMock.sObjectType()).thenReturn(Organization.SObjectType);
        mocks.when(selectorMock.selectOrganization()).thenReturn(org);
        mocks.stopStubbing();
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_MOD_Message message = new IRR_MOD_Message('Created', IRR_MOD_Message.MessageChannel.SMS, null,
                'TEST_TEMPLATE', passengerInfo, 'Delay', false);
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(null);
        eventProcessor.messages.add(message);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Selector.setMock(whitelistMock);
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);
        IRR_Application.MessageRenderer.setMock(rendererMock);
        IRR_Application.MessageRenderer.setMock(cacheMock);

        //When
        eventProcessor.processMessages();

        //Then
        System.assertEquals('Created', message.status);
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.anyList());
    }

    @IsTest
    static void testProcessMessages_NotWhitelisted() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        MSG_IRenderer rendererMock = (MSG_IRenderer) mocks.mock(MSG_RendererEnhanced.class);
        MSG_ITemplateCache cacheMock = (MSG_ITemplateCache) mocks.mock(MSG_TemplateCache.class);
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);
        IRR_SEL_IOrganizationSelector selectorMock = (IRR_SEL_IOrganizationSelector)
                mocks.mock(IRR_SEL_OrganizationSelector.class);
        IRR_SEL_IRecipientWhitelistSelector whitelistMock = (IRR_SEL_IRecipientWhitelistSelector)
                mocks.mock(IRR_SEL_RecipientWhitelistSelector.class);


        //Given
        Organization org = (Organization) C_TestDataFactory.createSObject(Organization.SObjectType,
                new Map<SObjectField, Object> { Organization.IsSandbox => true });
        Set<String> recipientWhitelist = new Set<String>();
        mocks.startStubbing();
        mocks.when(whitelistMock.sObjectType()).thenReturn(IRR_RecipientWhitelist__mdt.SObjectType);
        mocks.when(whitelistMock.getAllWhitelistedRecipients()).thenReturn(recipientWhitelist);
        mocks.when(selectorMock.sObjectType()).thenReturn(Organization.SObjectType);
        mocks.when(selectorMock.selectOrganization()).thenReturn(org);
        mocks.stopStubbing();
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_MOD_Message message = new IRR_MOD_Message('Created', IRR_MOD_Message.MessageChannel.SMS, null,
                'TEST_TEMPLATE', passengerInfo, 'Delay', false);
        IRR_MOD_Message messageDuplicate = message.clone();
        IRR_EVT_DelayProcessor eventProcessor = (IRR_EVT_DelayProcessor) new IRR_EVT_DelayProcessor.Constructor()
                .newInstance(null);
        eventProcessor.messages.add(message);
        eventProcessor.messages.add(messageDuplicate);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Selector.setMock(whitelistMock);
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);
        IRR_Application.MessageRenderer.setMock(rendererMock);
        IRR_Application.MessageRenderer.setMock(cacheMock);

        //When
        eventProcessor.processMessages();

        //Then
        System.assertEquals('Not Whitelisted', message.status);
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock, 0))
                .sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.anyList());
    }
}