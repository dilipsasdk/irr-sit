/**
 * Test class for the MID SMS Gateway testing the sending of SMS messages via the gateway
 * @author Peter Södergren
 */
@isTest
private class MID_SendSMS_Test {
    /**
     * Creates stubs for the SMS implementation
     * @param answerMock The mock answer implementation used to set the correct status
     */
    static void stubSMS(SMSAnswerMock answerMock){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ISFMCService smsMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, smsMock);
        mocks.startStubbing();
        mocks.when(smsMock.sendSMSMessages((List<IRR_SVC_SFMCService.SMSMessage>)fflib_Match.anyList())).thenAnswer(answerMock);
        mocks.stopStubbing();
    }
    /**
     * Sets up the rest request
     * @param body The request body
     */
    static void setupRequest(String body){
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
    /**
     * Parses the response from the REST response
     * @return The SMS response from the service
     */
    static SendSMSResponse parseResponse(){
        return (SendSMSResponse)JSON.deserialize(RestContext.response.responseBody.toString(), SendSMSResponse.class);
    }
    /**
     * Verifies the communication log data
     * @param numCreated The number of communication log entries with the status created
     * @param numError The number of communication log entries with the status error
     */
    static void verifyCommunicationLog(Integer numCreated, Integer numError){
        System.assertEquals(numCreated, [SELECT Id FROM IRR_CommunicationLog__c WHERE IRR_Status__c='Created'].size());
        System.assertEquals(numError, [SELECT Id FROM IRR_CommunicationLog__c WHERE IRR_Status__c='Error'].size());
    }
    /**
     * Checks the error logs in the test
     * @param shouldHaveErrors Whether the logs should have error log records
     */
    static void checkErrorLogs(Boolean shouldHaveErrors){
        C_Log__c[] logList = [SELECT Id,Severity__c,Message__c,StackTrace__c FROM C_Log__c WHERE Severity__c='Error'];
        for(C_Log__c log : logList){
            System.debug(log.Message__c);
            System.debug(log.StackTrace__c);
        }
        System.assertEquals(shouldHaveErrors,logList.size()>0,shouldHaveErrors ? 'Expected to find error logs but no error logs found' : 'Unexpected error logs found');
    }
    /**
     * Tests sending an SMS with no message
     */
    @isTest private static void sendSMSNoMessage(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTNoMessage1'},
            new Integer[]{null},
            new String[]{null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(true);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, smsMock.numCalls);
        System.assertEquals(0, smsMock.numSMS);
        verifyCommunicationLog(0,0);
    }
    /**
     * Tests sending an SMS with no recipients
     */
    @isTest private static void sendSMSNoRecipients(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTNoRecipients1'},
            new Integer[]{null},
            new String[]{null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(true);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, smsMock.numCalls);
        System.assertEquals(0, smsMock.numSMS);
        verifyCommunicationLog(0,0);
    }

    /**
     * Tests sending an SMS where the recipient has no phone number
     */
    @isTest private static void sendSMSNoPhoneNumber(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTNoPhoneNumber1'},
            new Integer[]{null},
            new String[]{null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(0, smsMock.numCalls);
        System.assertEquals(0, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(1,resp.result.size());
        System.assertEquals(null,resp.result[0].messageKey);
        System.assertEquals(false,resp.result[0].success);
        System.assertEquals(40001,resp.result[0].errorCode);
        System.assertNotEquals(null,resp.result[0].errorMessage);
        verifyCommunicationLog(0,1);
    }

    /**
     * Tests sending an SMS during system maintainence
     */
    @isTest private static void sendSMSSystemMaintainence(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSystemMaintainence1'},
            new Integer[]{null},
            new String[]{null}
        );
        stubSMS(smsMock);
        Test.setReadOnlyApplicationMode(true);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(503, RestContext.response.statusCode);
        System.assertEquals(0, smsMock.numCalls);
        System.assertEquals(0, smsMock.numSMS);
        verifyCommunicationLog(0,0);
    }

    /**
     * Tests sending a successful SMS to a single recipient
     */
    @isTest private static void sendSuccessfulSMSToSingleRecipient(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSend1'},
            new Integer[]{null},
            new String[]{null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, smsMock.numCalls);
        System.assertEquals(1, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(1,resp.result.size());
        System.assertEquals('TESTSend1',resp.result[0].messageKey);
        System.assertEquals(true,resp.result[0].success);
        System.assertEquals(null,resp.result[0].errorCode);
        System.assertEquals(null,resp.result[0].errorMessage);
        verifyCommunicationLog(1,0);
    }

    /**
     * Tests sending a failed SMS to a single recipient
     */
    @isTest private static void sendFailedSMSToSingleRecipient(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSendFail1'},
            new Integer[]{1001},
            new String[]{'TESTERROR'}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, smsMock.numCalls);
        System.assertEquals(1, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(1,resp.result.size());
        System.assertEquals('TESTSendFail1',resp.result[0].messageKey);
        System.assertEquals(false,resp.result[0].success);
        System.assertEquals(1001,resp.result[0].errorCode);
        System.assertEquals('TESTERROR',resp.result[0].errorMessage);
        verifyCommunicationLog(0,1);
    }

    /**
     * Tests sending a successful SMS to a single recipient
     */
    @isTest private static void sendSuccessfulSMSToMultipleRecipient(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"},{"phoneNumber":"+46700000001"},{"phoneNumber":"+46700000002"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSendMulti1','TESTSendMulti2','TESTSendMulti3'},
            new Integer[]{null,null,null},
            new String[]{null,null,null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, smsMock.numCalls);
        System.assertEquals(3, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(3,resp.result.size());
        System.assertEquals('TESTSendMulti1',resp.result[0].messageKey);
        System.assertEquals(true,resp.result[0].success);
        System.assertEquals(null,resp.result[0].errorCode);
        System.assertEquals(null,resp.result[0].errorMessage);
        System.assertEquals('TESTSendMulti2',resp.result[1].messageKey);
        System.assertEquals(true,resp.result[1].success);
        System.assertEquals(null,resp.result[1].errorCode);
        System.assertEquals(null,resp.result[1].errorMessage);
        System.assertEquals('TESTSendMulti3',resp.result[2].messageKey);
        System.assertEquals(true,resp.result[2].success);
        System.assertEquals(null,resp.result[2].errorCode);
        System.assertEquals(null,resp.result[2].errorMessage);
        verifyCommunicationLog(3,0);
    }

    /**
     * Tests sending a mixed result SMS to a single recipient
     */
    @isTest private static void sendMixedSMSToMultipleRecipient(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"},{"phoneNumber":"+46700000001"},{"phoneNumber":"+46700000002"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSendMultiMixed1','TESTSendMultiMixed2','TESTSendMultiMixed3'},
            new Integer[]{null,1001,null},
            new String[]{null,'TESTERROR',null}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, smsMock.numCalls);
        System.assertEquals(3, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(3,resp.result.size());
        System.assertEquals('TESTSendMultiMixed1',resp.result[0].messageKey);
        System.assertEquals(true,resp.result[0].success);
        System.assertEquals(null,resp.result[0].errorCode);
        System.assertEquals(null,resp.result[0].errorMessage);
        System.assertEquals('TESTSendMultiMixed2',resp.result[1].messageKey);
        System.assertEquals(false,resp.result[1].success);
        System.assertEquals(1001,resp.result[1].errorCode);
        System.assertEquals('TESTERROR',resp.result[1].errorMessage);
        System.assertEquals('TESTSendMultiMixed3',resp.result[2].messageKey);
        System.assertEquals(true,resp.result[2].success);
        System.assertEquals(null,resp.result[2].errorCode);
        System.assertEquals(null,resp.result[2].errorMessage);
        verifyCommunicationLog(2,1);
    }

    /**
     * Tests sending a failed SMS to a multiple recipient
     */
    @isTest private static void sendFailedSMSToMutipleRecipient(){
        MID_SendSMS.DISABLE_WHITELIST = true;
        setupRequest('{"message":"TEST MESSAGE","messageGroupId":"TEST1234567","messageType":"MID","recipients":[{"phoneNumber":"+46700000000"},{"phoneNumber":"+46700000001"},{"phoneNumber":"+46700000002"}]}');
        SMSAnswerMock smsMock = new SMSAnswerMock(
            new String[]{'TESTSendMultiFail1','TESTSendMultiFail2','TESTSendMultiFail3'},
            new Integer[]{1001,1002,1003},
            new String[]{'TESTERROR1','TESTERROR2','TESTERROR3'}
        );
        stubSMS(smsMock);
        MID_SendSMS.doPost();
        checkErrorLogs(false);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, smsMock.numCalls);
        System.assertEquals(3, smsMock.numSMS);
        SendSMSResponse resp = parseResponse();
        System.assertEquals(3,resp.result.size());
        System.assertEquals('TESTSendMultiFail1',resp.result[0].messageKey);
        System.assertEquals(false,resp.result[0].success);
        System.assertEquals(1001,resp.result[0].errorCode);
        System.assertEquals('TESTERROR1',resp.result[0].errorMessage);
        System.assertEquals('TESTSendMultiFail2',resp.result[1].messageKey);
        System.assertEquals(false,resp.result[1].success);
        System.assertEquals(1002,resp.result[1].errorCode);
        System.assertEquals('TESTERROR2',resp.result[1].errorMessage);
        System.assertEquals('TESTSendMultiFail3',resp.result[2].messageKey);
        System.assertEquals(false,resp.result[2].success);
        System.assertEquals(1003,resp.result[2].errorCode);
        System.assertEquals('TESTERROR3',resp.result[2].errorMessage);
        verifyCommunicationLog(0,3);
    }

    /**
     * Answer implementation to mock the SMS message results for the MC Service
     */
    private class SMSAnswerMock implements fflib_Answer{
        /**
         * The number of times the answer mock was called
         */
        Integer numCalls = 0;
        /**
         * The number sms messages sent to the sms mock
         */
        Integer numSMS = 0;
        /**
         * The message keys to set for each message
         */
        String[] messageKeyList;
        /**
         * The error codes to return for each sms (null for no error)
         */
        Integer[] errorCodeList;
        /**
         * The error message to return for each sms (null for no error)
         */
        String[] errorMessageList;
        /**
         * Creates an instance of the sms answer mock
         * @param messageKeyList The message keys to set for each message
         * @param errorCodeList The error codes to return for each sms (null for no error)
         * @param errorMessageList The error message to return for each sms (null for no error)
         */
        SMSAnswerMock(String[] messageKeyList,Integer[] errorCodeList,String[] errorMessageList){
            this.messageKeyList=messageKeyList;
            this.errorCodeList=errorCodeList;
            this.errorMessageList=errorMessageList;
        }

        /**
         * Processes the SMS objects sent to the method according to the properties supplied to the calss
         * @param invocation The invocation of the method containing the parameters used to invoce the method
         */
        public Object answer(fflib_InvocationOnMock invocation){
            numCalls++;
            List<IRR_SVC_SFMCService.SMSMessage> smsList = (List<IRR_SVC_SFMCService.SMSMessage>)invocation.getArgument(0);
            numSMS+=smsList.size();
            for(Integer i=0,sz=smsList.size();i<sz;i++){
                IRR_SVC_SFMCService.SMSMessage sms = smsList[i];
                sms.messageKey = messageKeyList[i];
                sms.errorCode = errorCodeList[i];
                sms.errorMessage = errorMessageList[i];
            }
            return smsList;
        }
    }

    /**
     * Class used to parse the response from the service
     */
    class SendSMSResponse{
        SendSMSResult[] result;
    }
    /**
     * Class used to parse the result of each sms
     */
    class SendSMSResult{
        Boolean success;
        String messageKey;
        Integer errorCode;
        String errorMessage;
    }
}
