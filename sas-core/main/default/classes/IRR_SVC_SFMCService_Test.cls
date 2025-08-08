/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for SFMC Service.
*/

@IsTest
private class IRR_SVC_SFMCService_Test {

    @IsTest
    static void testSendSMSMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);

        //Given
        IRR_SVC_SFMCService.SMSMessage message = new IRR_SVC_SFMCService.SMSMessage('TEST_CONTENT', 'TEST_RECIPIENT',
                'TEST_CONTACT_KEY', false);
        mocks.startStubbing();
        mocks.when(serviceMock.sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.anyList()))
                .thenReturn(new List<IRR_SVC_SFMCService.SMSMessage>{message});
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);

        //When
        IRR_SVC_SFMCService.SMSMessage result = IRR_SVC_SFMCService.sendSMSMessage('TEST_CONTENT', 'TEST_RECIPIENT',
                'TEST_CONTACT_KEY');

        //Then
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.anyList());
        List<Map<String, Object>> messageMatch = new List<Map<String, Object>> {
                new Map<String, Object> {
                        'content' => message.content,
                        'recipient' => message.recipient,
                        'contactKey' => message.contactKey,
                        'responseMessage' => message.responseMessage
                }
        };
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>) fflib_Match.objectsWithPath(messageMatch));
        System.assertEquals(message, result);
    }

    @IsTest
    static void testSendSMSMessages() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);
        IRR_SEL_ISMSDefinitionsSelector selectorMock = (IRR_SEL_ISMSDefinitionsSelector) mocks.mock(
                IRR_SEL_SMSDefinitionsSelector.class);

        //Given
        List<SFMC_SMSDefinition__mdt> smsDefinitions = new List<SFMC_SMSDefinition__mdt>{
                new SFMC_SMSDefinition__mdt(SFMC_CountryPrefix__c = 'TES', SFMC_DefinitionKey__c='TES_DEF_KEY'),
                new SFMC_SMSDefinition__mdt(SFMC_CountryPrefix__c = 'O', SFMC_DefinitionKey__c='O_DEF_KEY')
        };
        C_IntegrationExecutor.IntegrationResponse response = new C_IntegrationExecutor.IntegrationResponse(
                202, '{"requestId": "ccdb94bf-fcac-4fef-b194-08f534a2079a", "errorcode": 0, "responses": [{"messageKey": "GV1LhQ6NFkqFUAE1IsoQ9Q"}]}');
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(response);
        mocks.when(selectorMock.getAllSMSDefinitions()).thenReturn(smsDefinitions);
        mocks.when(selectorMock.sObjectType()).thenReturn(SFMC_SMSDefinition__mdt.SObjectType);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(
                'TEST_CONTENT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY', false);
        IRR_SVC_SFMCService.SMSMessage smsMessageOther = new IRR_SVC_SFMCService.SMSMessage(
                'OTHER_CONTENT', 'OTHER_RECIPIENT', 'OTHER_CONTACT_KEY', true);

        //When
        IRR_SVC_SFMCService.sendSMSMessages(new List<IRR_SVC_SFMCService.SMSMessage>{smsMessage, smsMessageOther});

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_MC_API');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock, 2)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        Map<String, Object> recipientMatch = new Map<String, Object>{
                'recipients[0].to' => 'TEST_RECIPIENT',
                'recipients[0].contactKey' => 'TEST_CONTACT_KEY',
                'recipients[0].attributes.content' => 'TEST_CONTENT',
                'recipients[0].attributes.from' => 'SAS',
                'definitionKey' => 'TES_DEF_KEY'
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                fflib_Match.eqString('/messaging/v1/sms/messages/'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                fflib_Match.mapWithPath(recipientMatch),
                (Map<String, Object>) fflib_Match.isNull());
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', smsMessage.messageKey);
        Map<String, Object> otherRecipientMatch = new Map<String, Object>{
                'recipients[0].to' => 'OTHER_RECIPIENT',
                'recipients[0].contactKey' => 'OTHER_CONTACT_KEY',
                'recipients[0].attributes.content' => 'OTHER_CONTENT',
                'recipients[0].attributes.from' => '',
                'definitionKey' => 'O_DEF_KEY'
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                fflib_Match.eqString('/messaging/v1/sms/messages/'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                fflib_Match.mapWithPath(otherRecipientMatch),
                (Map<String, Object>) fflib_Match.isNull());
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', smsMessageOther.messageKey);
    }

    @IsTest
    static void testSendSMSMessages_NoRecipient() {
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(
                'TEST_CONTENT', null, 'TEST_CONTACT_KEY', false);

        //When
        IRR_SVC_SFMCService.sendSMSMessages(new List<IRR_SVC_SFMCService.SMSMessage>{smsMessage});

        //Then
        System.assertEquals(12002, smsMessage.errorCode);
        System.assertEquals('No contact details available for passenger', smsMessage.errorMessage);
    }

    @IsTest
    static void testSendEmailMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);

        //Given
        IRR_SVC_SFMCService.EmailMessage message = new IRR_SVC_SFMCService.EmailMessage('TEST_CONTENT', 'TEST_SUBJECT',
                'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        mocks.startStubbing();
        mocks.when(serviceMock.sendEmailMessages((List<IRR_SVC_SFMCService.EmailMessage>) fflib_Match.anyList()))
                .thenReturn(new List<IRR_SVC_SFMCService.EmailMessage>{message});
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);

        //When
        IRR_SVC_SFMCService.EmailMessage result = IRR_SVC_SFMCService.sendEmailMessage('TEST_CONTENT', 'TEST_SUBJECT',
                'TEST_RECIPIENT', 'TEST_CONTACT_KEY');

        //Then
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendEmailMessages((List<IRR_SVC_SFMCService.EmailMessage>) fflib_Match.anyList());
        List<Map<String, Object>> messageMatch = new List<Map<String, Object>> {
                new Map<String, Object> {
                        'content' => message.content,
                        'recipient' => message.recipient,
                        'contactKey' => message.contactKey
                }
        };
        ((IRR_SVC_ISFMCService) mocks.verify(serviceMock))
                .sendEmailMessages((List<IRR_SVC_SFMCService.EmailMessage>) fflib_Match.objectsWithPath(messageMatch));
        System.assertEquals(message, result);
    }

    @IsTest
    static void testSendEmailMessages() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);

        //Given
        C_IntegrationExecutor.IntegrationResponse response = new C_IntegrationExecutor.IntegrationResponse(
                202, '{"requestId": "ccdb94bf-fcac-4fef-b194-08f534a2079a", "errorcode": 0, "responses": [{"messageKey": "GV1LhQ6NFkqFUAE1IsoQ9Q"}, {"messageKey": "RzxUwLXL8E2_DUKNPjsqlQ"}]}');
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(response);
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.EmailMessage emailMessage = new IRR_SVC_SFMCService.EmailMessage(
                'TEST_CONTENT', 'TEST_SUBJECT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        IRR_SVC_SFMCService.EmailMessage emailMessageOther = new IRR_SVC_SFMCService.EmailMessage(
                'OTHER_CONTENT', 'OTHER_SUBJECT','OTHER_RECIPIENT', 'OTHER_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{emailMessage, emailMessageOther});

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_MC_API');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        Map<String, Object> recipientMatch = new Map<String, Object>{
                'recipients[0].to' => 'TEST_RECIPIENT',
                'recipients[0].contactKey' => 'TEST_CONTACT_KEY',
                'recipients[0].attributes.HTMLContent' => 'TEST_CONTENT',
                'recipients[0].attributes.Subject' => 'TEST_SUBJECT',
                'recipients[1].to' => 'OTHER_RECIPIENT',
                'recipients[1].contactKey' => 'OTHER_CONTACT_KEY',
                'recipients[1].attributes.HTMLContent' => 'OTHER_CONTENT',
                'recipients[1].attributes.Subject' => 'OTHER_SUBJECT',
                'definitionKey' => 'generic_transactional_email'
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                fflib_Match.eqString('/messaging/v1/email/messages/'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                fflib_Match.mapWithPath(recipientMatch),
                (Map<String, Object>) fflib_Match.isNull());
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', emailMessage.messageKey);
        System.assertEquals('RzxUwLXL8E2_DUKNPjsqlQ', emailMessageOther.messageKey);
    }

    @IsTest
    static void testSendEmailMessagesRequestError() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);

        //Given
        C_IntegrationExecutor.IntegrationResponse response = new C_IntegrationExecutor.IntegrationResponse(
                404, '{"message":"MCMS_UTM_Runtime_ObjectNotFound: TriggeredSend definition, definitionKey=test","errorcode":30003,"documentation":""}');
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(response);
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.EmailMessage emailMessage = new IRR_SVC_SFMCService.EmailMessage(
                'TEST_CONTENT', 'TEST_SUBJECT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        IRR_SVC_SFMCService.EmailMessage emailMessageOther = new IRR_SVC_SFMCService.EmailMessage(
                'OTHER_CONTENT', 'OTHER_SUBJECT', 'OTHER_RECIPIENT', 'OTHER_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{emailMessage, emailMessageOther});

        //Then
        System.assertEquals(30003, emailMessage.errorCode);
        System.assertEquals('MCMS_UTM_Runtime_ObjectNotFound: TriggeredSend definition, definitionKey=test',
                emailMessage.errorMessage);
        System.assertEquals(30003, emailMessageOther.errorCode);
        System.assertEquals('MCMS_UTM_Runtime_ObjectNotFound: TriggeredSend definition, definitionKey=test',
                emailMessageOther.errorMessage);
    }

    @IsTest
    static void testSendEmailMessagesRequestHttpError() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);

        //Given
        C_IntegrationExecutor.IntegrationResponse response = new C_IntegrationExecutor.IntegrationResponse(
                401, '{"documentation":"https://developer.salesforce.com/docs/atlas.en-us.mc-apis.meta/mc-apis/error-handling.htm","errorcode":0,"message":"Not Authorized"}');
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(response);
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.EmailMessage emailMessage = new IRR_SVC_SFMCService.EmailMessage(
                'TEST_CONTENT', 'TEST_SUBJECT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        IRR_SVC_SFMCService.EmailMessage emailMessageOther = new IRR_SVC_SFMCService.EmailMessage(
                'OTHER_CONTENT', 'OTHER_SUBJECT', 'OTHER_RECIPIENT', 'OTHER_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{emailMessage, emailMessageOther});

        //Then
        System.assertEquals(401, emailMessage.errorCode);
        System.assertEquals('Not Authorized', emailMessage.errorMessage);
        System.assertEquals(401, emailMessageOther.errorCode);
        System.assertEquals('Not Authorized', emailMessageOther.errorMessage);
    }

    @IsTest
    static void testSendEmailMessages_NoRecipient() {
        IRR_SVC_SFMCService.EmailMessage emailMessage = new IRR_SVC_SFMCService.EmailMessage(
                'TEST_CONTENT', 'TEST_SUBJECT', null, 'TEST_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{emailMessage});

        //Then
        System.assertEquals(12002, emailMessage.errorCode);
        System.assertEquals('No contact details available for passenger', emailMessage.errorMessage);
    }

    @IsTest
    static void testSendEmailMessagesMixedErrorResponse() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);

        //Given
        C_IntegrationExecutor.IntegrationResponse response = new C_IntegrationExecutor.IntegrationResponse(
                202, '{"requestId": "ccdb94bf-fcac-4fef-b194-08f534a2079a", "errorcode": 0, "responses": [{"messageKey": "GV1LhQ6NFkqFUAE1IsoQ9Q","errorcode": 109106,"message": "MCMS_UTM_Validation_MissingRequiredField_to: Invalid subscriber"}, {"messageKey": "RzxUwLXL8E2_DUKNPjsqlQ"}]}');
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(response);
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.EmailMessage emailMessage = new IRR_SVC_SFMCService.EmailMessage(
                'TEST_CONTENT', 'TEST_SUBJECT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        IRR_SVC_SFMCService.EmailMessage emailMessageOther = new IRR_SVC_SFMCService.EmailMessage(
                'OTHER_CONTENT', 'OTHER_SUBJECT', 'OTHER_RECIPIENT', 'OTHER_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{emailMessage, emailMessageOther});

        //Then
        System.assertEquals(109106, emailMessage.errorCode);
        System.assertEquals('MCMS_UTM_Validation_MissingRequiredField_to: Invalid subscriber',
                emailMessage.errorMessage);
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', emailMessage.messageKey);
        System.assertEquals(null, emailMessageOther.errorCode);
        System.assertEquals(null, emailMessageOther.errorMessage);
        System.assertEquals('RzxUwLXL8E2_DUKNPjsqlQ', emailMessageOther.messageKey);
    }
}