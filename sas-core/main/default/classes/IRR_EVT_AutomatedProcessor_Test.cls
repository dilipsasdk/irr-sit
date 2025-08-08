/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Unit test class for Automated message event.
*/
@isTest
private class IRR_EVT_AutomatedProcessor_Test {

    @IsTest
    static void testGetEventName(){

        //Given
        IRR_EVT_AutomatedProcessor automatedProcessor = (IRR_EVT_AutomatedProcessor) 
                new IRR_EVT_AutomatedProcessor.Constructor().newInstance(null);

        //when
        String eventName = automatedProcessor.getEventName();

        //Then
        System.assertEquals('Automated', eventName);
    }
    
    @isTest
    static void testValidateEvent_Success() {

        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.emailTemplate = 'EMAIL_TEMPLATE';
        automatedRequest.smsTemplate = 'SMS_TEMPLATE';
        automatedRequest.sendEmailMessages = false;
        automatedRequest.sendSMSMessages = true;
        automatedRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(automatedRequest);
        
        //When
        eventProcessor.validateEvent();
    }
    @isTest
    static void testValidateEvent_NullEvent_Throws() {
        //Given
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(null);

        //When
        Boolean caughtException = false;
        try{
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Automated message request is missing')) caughtException = true;
        }

        //Then
        System.assert(caughtException);

    }

    @isTest
    static void testValidateEvent_NoPassengers_Throws() {

        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.emailTemplate = 'EMAIL_TEMPLATE';
        automatedRequest.smsTemplate = 'SMS_TEMPLATE';
        automatedRequest.sendEmailMessages = false;
        automatedRequest.sendSMSMessages = true;
        automatedRequest.passengerInfos = null;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(automatedRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No passengers to send message to')) caughtException = true;
        }
        //Then
        System.assert(caughtException);
    }

    @IsTest 
    static void testValidateEvent_NoEmailTemplate_Throws(){

         //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.emailTemplate = null;
        automatedRequest.smsTemplate = 'SMS_TEMPLATE';
        automatedRequest.sendEmailMessages = true;
        automatedRequest.sendSMSMessages = true;
        automatedRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(automatedRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No Email template selected')) caughtException = true;
        }
        //Then
        System.assert(caughtException);

    }

    @isTest
    static void testValidateEvent_NoSMSTemplate_Throws() {
        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.emailTemplate = 'EMAIL_TEMPLATE';
        automatedRequest.smsTemplate = null;
        automatedRequest.sendEmailMessages = false;
        automatedRequest.sendSMSMessages = true;
        automatedRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(automatedRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No SMS template selected')) caughtException = true;
        }
        //Then
        System.assert(caughtException);
    }

    @isTest
    static void testValidateEvent_NoMessageToSend_Throws() {
        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.sendEmailMessages = false;
        automatedRequest.sendSMSMessages = false;
        automatedRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_AutomatedProcessor.Constructor().newInstance(automatedRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('There is no message to send')) caughtException = true;
        }
        //Then
        System.assert(caughtException);
    }
    
    @isTest
    static void testInitiateEvent_NoEventInfo() {

        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.sendEmailMessages = null;
        automatedRequest.sendSMSMessages = null;
        IRR_EVT_AutomatedProcessor eventProcessor = new IRR_EVT_AutomatedProcessor(automatedRequest);
        
        //When
        eventProcessor.initiateEvent();

        //Then
        System.assertEquals(false, eventProcessor.automatedRequest.sendEmailMessages);
        System.assertEquals(false, eventProcessor.automatedRequest.sendSMSMessages);



    }

    @isTest
    static void testCheckActiveBlock() {

        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        IRR_EVT_AutomatedProcessor eventProcessor = new IRR_EVT_AutomatedProcessor(automatedRequest);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);
    }

    @isTest
    static void testProcessEvent_Confirmed_SendSMS() {

        //Given
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.sendSMSMessages = true;
        automatedRequest.sendEmailMessages =false;
        automatedRequest.smsTemplate = 'SMS_TEMPLATE';
        automatedRequest.emailTemplate = 'EMAIL_TEMPLATE';
        automatedRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        automatedRequest.passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        automatedRequest.passengerInfos[0].thisSegment.isConfirmed = true;
        automatedRequest.passengerInfos[0].hasPhoneNumber = true;
        automatedRequest.passengerInfos[0].hasEmailAddress = true;
        automatedRequest.passengerInfos[0].phoneNumber = 'TEST_PHONE';
        automatedRequest.passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_AutomatedProcessor eventProcessor = (IRR_EVT_AutomatedProcessor) new IRR_EVT_AutomatedProcessor.Constructor()
                .newInstance(automatedRequest);

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
        System.assertEquals('Automated', messages[0].type);
        System.assertEquals(automatedRequest.passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals('TEST_PHONE', messages[0].recipient);

    }




}
