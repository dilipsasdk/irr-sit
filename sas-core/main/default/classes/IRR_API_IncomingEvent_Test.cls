/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Incoming Event REST API.
*/

@IsTest
private class IRR_API_IncomingEvent_Test {

    @IsTest
    static void testHandleIncomingEvent_Success() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService) mocks.mock(IRR_SVC_CommunicationServiceImpl.class);

        //Given
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('TEST_EVENT_BODY');
        req.httpMethod = 'POST';
        req.requestURI = 'https://instance_name.salesforce.com/services/apexrest/EventAPI/testEventName';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        Test.startTest();
        IRR_API_IncomingEvent.handleIncomingEvent();
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock, 0)).processEvent('testEventName', 'TEST_EVENT_BODY');
        Test.stopTest();

        //Then
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock)).processEvent('testEventName', 'TEST_EVENT_BODY');
    }
}