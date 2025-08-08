/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Event processor for the Automated messages event.
*/

public class IRR_EVT_AutomatedProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Automated message request is missing';
    private static final String ERROR_NO_PASSENGERS = 'No passengers to send message to';
    private static final String ERROR_NO_EMAIL_TEMPLATE = 'No Email template selected';
    private static final String ERROR_NO_SMS_TEMPLATE = 'No SMS template selected';
    private static final String ERROR_NO_MESSAGE_TO_SEND = 'There is no message to send';

    @TestVisible
    private Boolean isQueued = false;

    @TestVisible
    private IRR_MOD_AutomatedRequest AutomatedRequest;

    public String getEventName() {
        return 'Automated';
    }

    public void validateEvent() {
        if (AutomatedRequest == null) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EVENT);
        }
        if (AutomatedRequest.passengerInfos == null || AutomatedRequest.passengerInfos.isEmpty()) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_PASSENGERS);
        }
        if (AutomatedRequest.sendEmailMessages != null && AutomatedRequest.sendEmailMessages &&
                String.isBlank(AutomatedRequest.emailTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EMAIL_TEMPLATE);
        }
        if (AutomatedRequest.sendSMSMessages != null && AutomatedRequest.sendSMSMessages &&
                String.isBlank(AutomatedRequest.smsTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_SMS_TEMPLATE);
        }
        if (!AutomatedRequest.sendSMSMessages && !AutomatedRequest.sendEmailMessages) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_MESSAGE_TO_SEND);
        }
    }

    public void initiateEvent() {
        if (AutomatedRequest.sendEmailMessages == null) AutomatedRequest.sendEmailMessages = false;
        if (AutomatedRequest.sendSMSMessages == null) AutomatedRequest.sendSMSMessages = false;

    }

    /**
     * @author Chetan Singh, Coforge
     * @date 2021
     *
     * @description Checks if any active manual override blocks exist for this flight.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for Manual Message event
        return this.isQueued;
    }

    /**
     * @author Chetan Singh, Coforge
     * @date 2021
     *
     * @description Process passenger infos and create messages according to event info and passenger contact info.
     */
        public void processEvent() {

            IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
                for (IRR_MOD_PassengerInfo passengerInfo : AutomatedRequest.passengerInfos) {
                Boolean sendEmail = AutomatedRequest.sendEmailMessages;
                Boolean sendSMS = AutomatedRequest.sendSMSMessages;
                    if (sendEmail || sendSMS) {
                        flowVariables.passengerInfo = passengerInfo;


                        createMessages(sendSMS, AutomatedRequest.smsTemplate, sendEmail, AutomatedRequest.emailTemplate,
                            flowVariables,false);
                    }
                }
        }

    public IRR_EVT_AutomatedProcessor(IRR_MOD_AutomatedRequest AutomatedRequest) {
        this.AutomatedRequest = AutomatedRequest;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_AutomatedProcessor((IRR_MOD_AutomatedRequest) payload);
        }
    }
}
