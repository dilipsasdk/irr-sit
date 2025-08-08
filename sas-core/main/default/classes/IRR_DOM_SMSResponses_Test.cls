/**
 * Test class for domain class for sms responses
 * @author Peter Södergrne
 */
@isTest private class IRR_DOM_SMSResponses_Test {
    /**
     * Creates the required communication log records to test the functionality
     */
    @testSetup static void setup(){
        String msg240 = 'TEST';
        for(Integer i=4;i<240;i++){
            msg240+='A';
        }
        IRR_CommunicationLog__c[] comLog = new IRR_CommunicationLog__c[]{
            new IRR_CommunicationLog__c(IRR_Status__c='Sent',IRR_Recipient__c='46700000000',IRR_ExternalId__c='SMSResponseTest0', IRR_ResponseMessage__c=true),
            new IRR_CommunicationLog__c(IRR_Status__c='Sent',IRR_Recipient__c='46700000001',IRR_ExternalId__c='SMSResponseTest1'),
            new IRR_CommunicationLog__c(IRR_Status__c='Sent',IRR_Recipient__c='46700000002',IRR_ExternalId__c='SMSResponseTest2',IRR_Response__c=msg240, IRR_ResponseMessage__c = true)
        };
        insert comLog;
        Datetime createdTime = Datetime.now().addHours(-1);
        Test.setCreatedDate(comLog[0].Id, createdTime);
        Test.setCreatedDate(comLog[1].Id, createdTime);
        Test.setCreatedDate(comLog[2].Id, createdTime);
    }

    /**
     * Tests that the most recent log is being used when associating a response to a log
     */
    @isTest static void selectMostRecentLog(){
        insert new IRR_CommunicationLog__c(IRR_Status__c='Sent',IRR_Recipient__c='46700000000',IRR_ExternalId__c='SMSResponseTest11', IRR_ResponseMessage__c=true);
        insert new IRR_SMSResponse__c(IRR_InfoMessageNouns__c='MSG1',IRR_InfoFrom__c='46700000000',IRR_DateUTC__c=Date.newInstance(2020,05,01),IRR_TimeUTC__c=Time.newInstance(8,30,24,0));
        IRR_CommunicationLog__c comLog0 = [SELECT Id,IRR_Status__c,IRR_LastResponseDate__c,IRR_Response__c FROM IRR_CommunicationLog__c WHERE IRR_ExternalId__c='SMSResponseTest0'];
        IRR_CommunicationLog__c comLog11 = [SELECT Id,IRR_Status__c,IRR_LastResponseDate__c,IRR_Response__c FROM IRR_CommunicationLog__c WHERE IRR_ExternalId__c='SMSResponseTest11'];
        System.assertEquals('Sent', comLog0.IRR_Status__c);
        System.assertEquals(null, comLog0.IRR_LastResponseDate__c);
        System.assertEquals(null, comLog0.IRR_Response__c);
        System.assertEquals('Responded', comLog11.IRR_Status__c);
        System.assertEquals(DateTime.newInstanceGmt(2020,05,01,8,30,24), comLog11.IRR_LastResponseDate__c);
        System.assertEquals('MSG1', comLog11.IRR_Response__c);
        
        System.assertEquals(0,[SELECT Id FROM C_Log__c].size());
    }

    /**
     * Tests that a response which cannot be associated to a log does not cause an error
     */
    @isTest static void noLogPresent(){
        insert new IRR_SMSResponse__c(IRR_InfoMessageNouns__c='MSG1',IRR_InfoFrom__c='46730000000',IRR_DateUTC__c=Date.newInstance(2020,05,01),IRR_TimeUTC__c=Time.newInstance(8,30,24,0));
        
        System.assertEquals(1,[SELECT Id FROM C_Log__c WHERE Severity__c='Warning'].size());
    }

    /**
     * Tests that message is properly truncated when too long to store
     */
    @isTest static void truncateMessage(){
        insert new IRR_CommunicationLog__c(IRR_Status__c='Sent',IRR_Recipient__c='46700000002',IRR_ExternalId__c='SMSResponseTest22', IRR_ResponseMessage__c=false);
        insert new IRR_SMSResponse__c(IRR_InfoMessageNouns__c='MESSAGE LONG ENOUGH TO BREAK 255 CHARS',IRR_InfoFrom__c='46700000002',IRR_DateUTC__c=Date.newInstance(2020,05,01),IRR_TimeUTC__c=Time.newInstance(8,30,24,0));
        IRR_CommunicationLog__c comLog2 = [SELECT Id,IRR_Status__c,IRR_LastResponseDate__c,IRR_Response__c FROM IRR_CommunicationLog__c WHERE IRR_ExternalId__c='SMSResponseTest2'];
        IRR_CommunicationLog__c comLog22 = [SELECT Id,IRR_Status__c,IRR_LastResponseDate__c,IRR_Response__c FROM IRR_CommunicationLog__c WHERE IRR_ExternalId__c='SMSResponseTest22'];
        System.assertEquals('Sent', comLog22.IRR_Status__c);
        System.assertEquals(null, comLog22.IRR_LastResponseDate__c);
        System.assertEquals(null, comLog22.IRR_Response__c);
        System.assertEquals('Responded', comLog2.IRR_Status__c);
        System.assertEquals(DateTime.newInstanceGmt(2020,05,01,8,30,24), comLog2.IRR_LastResponseDate__c);
        System.assertEquals(255, comLog2.IRR_Response__c.length());
        System.assertEquals(0,[SELECT Id FROM C_Log__c].size());
    }
}
