/**
 * SMS Gateway implementation for MID
 * Allows the sending of SMS messages routed via Marketing Cloud
 * @author Peter Södergren
 */
@RestResource(urlMapping='/mid/sendsms')
global without sharing class MID_SendSMS {
    /**
     * Set by test classes to disable whitelisting functionality
     *
     * Note: 2020-05-19 Disable Whitelist due to MID team request, approved by Michaela Fritofsson
     */
    @TestVisible static Boolean DISABLE_WHITELIST = true;
    /**
     * POST
     * Allows the caller to send an SMS to multiple recipients routed via marketing cloud
     */
    @HttpPost
    global static void doPost(){
        if(System.getApplicationReadWriteMode()==System.ApplicationReadWriteMode.READ_ONLY)C_RestUtil.set(503,'Service Unavailable');
        else {
            try{
                C_RestUtil.init(false);
                SendSMSRequest req = (SendSMSRequest)C_RestUtil.getJSONBody(SendSMSRequest.class);
                if(String.isBlank(req.message))C_RestUtil.badRequest('Must specify a message');
                if(String.isBlank(req.messageType))req.messageType='MID';
                if(req.recipients==null || req.recipients.size()==0)C_RestUtil.badRequest('Must specify a recipients');

                Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
                Set<String> whitelistedRecipients = !org.IsSandbox || DISABLE_WHITELIST ? null : IRR_SEL_RecipientWhitelistSelector.newInstance().getAllWhitelistedRecipients();

                Integer recSz = req.recipients.size();
                SMSResultWrapper[] resultWrapperList = new SMSResultWrapper[recSz];
                List<IRR_SVC_SFMCService.SMSMessage> messages = new List<IRR_SVC_SFMCService.SMSMessage>();
                for(Integer i=0;i<recSz;i++){
                    SendSMSRecipient rec = req.recipients[i];
                    SMSResultWrapper smsw = new SMSResultWrapper();
                    resultWrapperList[i] = smsw;
                    if(String.isBlank(rec.phoneNumber)){
                        smsw.errorCode = 40001;
                        smsw.errorMessage = 'No phone number specified';
                    }
                    else {
                        if(rec.phoneNumber.startsWith('+'))rec.phoneNumber=rec.phoneNumber.substring(1);
                        if(whitelistedRecipients==null || whitelistedRecipients.contains(rec.phoneNumber)){
                            smsw.sms = new IRR_SVC_SFMCService.SMSMessage(req.message,rec.phoneNumber,rec.phoneNumber);
                            smsw.sms.externalId = rec.externalId;
                            messages.add(smsw.sms);
                            smsw.smsIdx = messages.size()-1;
                        }
                        else {
                            smsw.errorCode = 40002;
                            smsw.errorMessage = 'Phone number not in whitelist';
                        }
                    }
                }
                if(!messages.isEmpty())IRR_SVC_SFMCService.sendSMSMessages(messages);

                fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
                IRR_SVC_CommunicationService.CommunicationLogFactory logFactory = new IRR_SVC_CommunicationService.CommunicationLogFactory(uow);

                SendSMSResponse resp = new SendSMSResponse();
                resp.result = new SendSMSResult[recSz];
                for(Integer i=0;i<recSz;i++){
                    SendSMSRecipient rec = req.recipients[i];
                    SMSResultWrapper smsw = resultWrapperList[i];
                    SendSMSResult res = new SendSMSResult();
                    if(smsw.smsIdx!=null){
                        IRR_SVC_SFMCService.SMSMessage sms = messages[smsw.smsIdx];
                        res.success = sms.errorCode==null;
                        res.messageKey = sms.messageKey;
                        res.errorCode = sms.errorCode;
                        res.errorMessage = sms.errorMessage;
                        logFactory.add(sms, req.messageType, req.messageGroupId);
                    }
                    else {
                        res.success = false;
                        res.errorCode = smsw.errorCode;
                        res.errorMessage = smsw.errorMessage;
                        logFactory.addSMSError(
                            rec.phoneNumber, 
                            rec.phoneNumber, 
                            req.message, 
                            req.messageType, 
                            req.messageGroupId, 
                            smsw.errorCode==40002, 
                            smsw.errorCode, 
                            smsw.errorMessage);
                    }
                    resp.result[i] = res;
                }
                uow.commitWork();

                C_RestUtil.set(200, JSON.serialize(resp));

            }
            catch(Exception e){
                C_RestUtil.handleException(e);
            }
        }
    }
    /**
     * Utility class to help collect the response for sms sends
     */
    class SMSResultWrapper{
        /**
         * Custom error code set before sending the sms to marketing cloud
         */
        Integer errorCode;
        /**
         * Custom error message set before sending the sms to marketing cloud
         */
        String errorMessage;
        /**
         * THe index of the SMS object in the messages list
         */
        Integer smsIdx;
        /**
         * The sms message sent
         */
        IRR_SVC_SFMCService.SMSMessage sms;
    }

    /**
     * Representation of the JSON Request data for sending SMS
     */
    class SendSMSRequest{
        /**
         * The message to send
         */
        String message;
        /**
         * A custom id to set for all messages in the request (optional)
         */
        String messageGroupId;
        /**
         * The type of message being sent (optional)
         */
        String messageType;
        /**
         * The list of recipients of the message
         */
        SendSMSRecipient[] recipients;
    }
    /**
     * Representation of the JSON request data for each recipient of an sms message
     */
    class SendSMSRecipient{
        /**
         * The phone number to which to send the sms message
         */
        String phoneNumber;
        /**
         * The external id to set for the message sent to the recipient
         */
        String externalId;
    }
    /**
     * Representation of the JSON response data for sending SMS
     */
    class SendSMSResponse{
        /**
         * The result for forwarding each message for each recipient in the request (in the same order as in the request)
         */
        SendSMSResult[] result;
    }
    /**
     * Representation of the JSON response data contain the result of a single recipient
     */
    class SendSMSResult{
        /**
         * Whether the message was forawrded to Marketing Cloud successfully
         */
        Boolean success;
        /**
         * The id of the message sent (only set if successful)
         */
        String messageKey;
        /**
         * The error code (only set if not successful)
         */
        Integer errorCode;
        /**
         * The error message (only set if not successful)
         */
        String errorMessage;
    }
}