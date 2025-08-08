/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of SFMC integration functionality.
*/

public class IRR_SVC_SFMCServiceImpl implements IRR_SVC_ISFMCService {

    private static final String SMS_ENDPOINT = '/messaging/v1/sms/messages/';
    private static final String EMAIL_ENDPOINT = '/messaging/v1/email/messages/';
    private static final String CONTACT_DELETE_ENDPOINT = '/contacts/v1/contacts/actions/delete';
    private static final String EMAIL_SEND_DEFINITION = 'generic_transactional_email';
    private static final String NAMED_CREDENTIAL = 'callout:SAS_MC_API';
    private static final String NAMED_CREDENTIAL_MAIN_BU = 'callout:SAS_MC_API_MAIN_BU';
    private static final String DEFAULT_FROM_NAME = 'SAS';

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

    private static C_IIntegrationExecutor integrationExecutorMainBU {
        get {
            if (integrationExecutorMainBU == null) {
                integrationExecutorMainBU =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL_MAIN_BU)
                                .build();
            }
            return integrationExecutorMainBU;
        }
        private set;
    }

    public Boolean deleteContacts(Set<String> contactKeys) {
        Map<String, Object> requestBody = createDeleteContactsBody(contactKeys);
                                        
        Map<String, Object> queryParams = new Map<String, Object>{
            'type' => 'keys'
        };

        if (Test.isRunningTest()) {
            return true;
        } else {
            C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutorMainBU.executeRequest(
            CONTACT_DELETE_ENDPOINT, C_IntegrationExecutor.Method.POST, requestBody, queryParams);

            if(responseObject.statusCode>=200 && responseObject.statusCode<300){
                return true;
            }
            else {
                throw new IRR_SVC_SFMCService.SFMCException('Something went wrong deleting contacts in MC: ' + contactKeys);
                
            } 
        }
        
    }

    public List<IRR_SVC_SFMCService.EmailMessage> sendEmailMessages(List<IRR_SVC_SFMCService.EmailMessage> messages) {
        List<IRR_SVC_SFMCService.SFMCMessage> messagesWithRecipient = discardMessagesWithoutRecipient(messages);
        if (!messagesWithRecipient.isEmpty()) {
            Map<String, Object> requestBody = createEmailRequestBody(EMAIL_SEND_DEFINITION, messagesWithRecipient);
            sendSFMCMessages(requestBody, EMAIL_ENDPOINT, messagesWithRecipient);
        }
        return messages;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sorts messages by send definition country prefix and then makes individual calls to SFMC for each
     *      send definition.
     *
     * @param messages SMS Message list to send
     *
     * @return Input Message List
     */
    public List<IRR_SVC_SFMCService.SMSMessage> sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages) {
        List<IRR_SVC_SFMCService.SFMCMessage> messagesWithRecipient = discardMessagesWithoutRecipient(messages);
        if (!messagesWithRecipient.isEmpty()) {
            Map<String, List<IRR_SVC_SFMCService.SFMCMessage>> smsMessagesBySendDefinitions =
                    sortMessagesBySendDefinitions(messagesWithRecipient);
            for (String definition : smsMessagesBySendDefinitions.keySet()) {
                List<IRR_SVC_SFMCService.SFMCMessage> scopedMessages = smsMessagesBySendDefinitions.get(definition);
                Map<String, Object> requestBody = createSMSRequestBody(definition, scopedMessages);
                sendSFMCMessages(requestBody, SMS_ENDPOINT, scopedMessages);
            }
        }
        return messages;
    }

    private List<IRR_SVC_SFMCService.SFMCMessage> discardMessagesWithoutRecipient(
            List<IRR_SVC_SFMCService.SFMCMessage> messages) {
        List<IRR_SVC_SFMCService.SFMCMessage> messagesWithRecipients = new List<IRR_SVC_SFMCService.SFMCMessage>();
        for (IRR_SVC_SFMCService.SFMCMessage message : messages) {
            if (String.isNotBlank(message.recipient)) {
                messagesWithRecipients.add(message);
            }
            else {
                message.errorCode = 12002;
                message.errorMessage = 'No contact details available for passenger';
            }
        }
        return messagesWithRecipients;
    }

    private void sendSFMCMessages(Map<String, Object> requestBody, String endPoint,
            List<IRR_SVC_SFMCService.SFMCMessage> messages) {
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor.executeRequest(
                endPoint, C_IntegrationExecutor.Method.POST, requestBody, null);
        IRR_SVC_SFMCService.SFMCResponse response = (IRR_SVC_SFMCService.SFMCResponse)
                JSON.deserialize(responseObject.responseBody, IRR_SVC_SFMCService.SFMCResponse.class);
        //If global error then fill the message result by default with the global error
        if(responseObject.statusCode>=300){
            for(IRR_SVC_SFMCService.SFMCMessage msg : messages){
                msg.errorCode = response.errorcode != 0 ? response.errorcode : responseObject.statusCode;
                msg.errorMessage = response.message;
            }
        }
        Integer responsesSize = response.responses != null && !response.responses.isEmpty() ?
                response.responses.size() : 0;

        for (Integer i = 0; i < responsesSize; i++) {
            IRR_SVC_SFMCService.MessageResponse messageResponse = response.responses[i];
            messages[i].messageKey = messageResponse.messageKey;
            messages[i].errorCode = messageResponse.errorcode;
            if(messageResponse.errorcode!=null) {
                messages[i].errorMessage = messageResponse.message;
            }
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sorts messages by send definition country prefix based on phone number.
     *
     * @param messages Messages to process
     *
     * @return Map of SMS Messages by send definition key
     */
    private Map<String, List<IRR_SVC_SFMCService.SFMCMessage>> sortMessagesBySendDefinitions(
            List<IRR_SVC_SFMCService.SFMCMessage> messages) {
        if (smsDefinitionsCache == null) retrieveSMSDefinitions();
        Map<String, List<IRR_SVC_SFMCService.SFMCMessage>> smsMessagesBySendDefinitions =
                new Map<String, List<IRR_SVC_SFMCService.SFMCMessage>>();
        for (IRR_SVC_SFMCService.SFMCMessage message : messages) {
            String definition = null;
            String phoneNo = message.recipient;
            if(phoneNo!=null && phoneNo.length()>3){
                if(definition==null)definition = smsDefinitionsCache.get(phoneNo.substring(0, 3));
                if(definition==null)definition = smsDefinitionsCache.get(phoneNo.substring(0, 2));
                if(definition==null)definition = smsDefinitionsCache.get(phoneNo.substring(0, 1));
            }

            if(definition!=null){
                if (!smsMessagesBySendDefinitions.containsKey(definition)) {
                    smsMessagesBySendDefinitions.put(definition, new List<IRR_SVC_SFMCService.SFMCMessage>());
                }
                smsMessagesBySendDefinitions.get(definition).add(message);
            }
            else {
                message.errorCode = 12001;
                message.errorMessage = 'Unsupported country prefix for phone number';
            }
        }
        return smsMessagesBySendDefinitions;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves SMS send definitions and stores them by Country Prefix in a local cache map.
     */
    private void retrieveSMSDefinitions() {
        smsDefinitionsCache = new Map<String, String>();
        List<SFMC_SMSDefinition__mdt> smsDefinitions = IRR_SEL_SMSDefinitionsSelector.newInstance()
                .getAllSMSDefinitions();
        for (SFMC_SMSDefinition__mdt definition : smsDefinitions) {
            smsDefinitionsCache.put(definition.SFMC_CountryPrefix__c, definition.SFMC_DefinitionKey__c);
        }
    }

    /*
     * Cache Map of SMS Send definition keys by Country Prefix
     */
    private static Map<String, String> smsDefinitionsCache;

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates SFMC request body structure for a send definition and a list of SMS Messages.
     *
     * @param sendDefinition SFMC Send Definition key
     * @param messages List of SMS Messages
     *
     * @return SFMC Request body structure
     */
    private Map<String, Object> createSMSRequestBody(String sendDefinition,
            List<IRR_SVC_SFMCService.SFMCMessage> messages) {
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();
        for (IRR_SVC_SFMCService.SFMCMessage sfmcMessage : messages) {
            IRR_SVC_SFMCService.SMSMessage smsMessage = (IRR_SVC_SFMCService.SMSMessage) sfmcMessage;
            Map<String, Object> recipient = new Map<String, Object> {
                    'to' => smsMessage.recipient,
                    'contactKey' => smsMessage.contactKey,
                    'attributes' => new Map<String, Object> {
                            'content' => smsMessage.content,
                            //Set blank From Name for response messages to use long/short code instead of SAS
                            'from' => smsMessage.responseMessage ? '' : DEFAULT_FROM_NAME
                    }
            };
            recipients.add(recipient);
        }
        Map<String, Object> requestBody = new Map<String, Object>{
                'definitionKey' => sendDefinition,
                'recipients' => recipients,
                'content' => new Map<String, Object> { 'message' => '%%content%%' },
                'subscriptions' => new Map<String, Object> { 'resubscribe' => true }
        };
        return requestBody;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates SFMC request body structure for a send definition and a list of SMS Messages.
     *
     * @param sendDefinition SFMC Send Definition key
     * @param messages List of SMS Messages
     *
     * @return SFMC Request body structure
     */
    private Map<String, Object> createEmailRequestBody(String sendDefinition,
            List<IRR_SVC_SFMCService.SFMCMessage> messages) {
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();
        for (IRR_SVC_SFMCService.SFMCMessage message : messages) {
            IRR_SVC_SFMCService.EmailMessage emailMessage = (IRR_SVC_SFMCService.EmailMessage) message;
            Map<String, Object> recipient = new Map<String, Object> {
                    'to' => emailMessage.recipient,
                    'contactKey' => emailMessage.contactKey,
                    'attributes' => new Map<String, Object> {
                            'HTMLContent' => emailMessage.content,
                            'Subject' => emailMessage.subject
                    }
            };
            recipients.add(recipient);
        }
        Map<String, Object> requestBody = new Map<String, Object>{
                'definitionKey' => sendDefinition,
                'recipients' => recipients
        };
        return requestBody;
    }

    /**
     * @author Ludvig Wälimaa, Deloitte
     * @date 2020
     *
     * @description TODO
     *
     * @param sendDefinition SFMC Send Definition key
     * @param messages List of SMS Messages
     *
     * @return SFMC Request body structure
     */
    private Map<String, Object> createDeleteContactsBody(Set<String> contactKeys) {
        
        Map<String, Object> requestBody = new Map<String, Object>{
                'ContactTypeId' => '0',
                'values' => contactKeys,
                'DeleteOperationType' => 'ContactAndAttributes'
        };

        return requestBody;
    }
}