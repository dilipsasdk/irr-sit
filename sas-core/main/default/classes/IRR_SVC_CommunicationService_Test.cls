/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for EventService class.
*/

@IsTest
private class IRR_SVC_CommunicationService_Test {

    @IsTest
    static void testProcessEventJSONPayload_NotBlocked() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        mocks.startStubbing();
        mocks.when(eventMock.checkActiveBlock()).thenReturn(false);
        mocks.stopStubbing();
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', 'TEST_PAYLOAD');

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).checkActiveBlock();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    static void testProcessEventJSONPayload_Blocked() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        mocks.startStubbing();
        mocks.when(eventMock.checkActiveBlock()).thenReturn(true);
        mocks.stopStubbing();
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', 'TEST_PAYLOAD');

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).checkActiveBlock();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 0)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 0)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 0)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 0)).commitWork();
    }

    @IsTest
    static void testProcessEventJSONPayload_ErrorLog() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        mocks.startStubbing();
        ((IRR_EVT_IEventProcessor) mocks.doThrowWhen(
                new IRR_SVC_CommunicationService.EventException('TEST_EVENT_EXCEPTION'), eventMock))
                .validateEvent();
        mocks.stopStubbing();
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', 'TEST_PAYLOAD');

        //Then
        List<C_Log__c> logs = [SELECT HttpBody__c, HttpResource__c, Message__c FROM C_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('TEST_PAYLOAD', logs[0].HttpBody__c);
        System.assertEquals('/services/apexrest/EventAPI/TEST_EVENT', logs[0].HttpResource__c);
        System.assertEquals('IRR_SVC_CommunicationService.EventException: TEST_EVENT_EXCEPTION', logs[0].Message__c);
    }

    @IsTest
    static void testProcessEventObjectPayload_NotBlocked() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        mocks.startStubbing();
        mocks.when(eventMock.checkActiveBlock()).thenReturn(false);
        mocks.stopStubbing();
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', (Object) new Map<String, Object>());

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).checkActiveBlock();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    static void testProcessEventObjectPayload_Blocked() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        mocks.startStubbing();
        mocks.when(eventMock.checkActiveBlock()).thenReturn(true);
        mocks.stopStubbing();
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', (Object) new Map<String, Object>());

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).checkActiveBlock();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 0)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 0)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock, 1)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 1)).commitWork();
    }
}