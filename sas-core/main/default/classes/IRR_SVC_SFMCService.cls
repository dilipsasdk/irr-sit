/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Entry point for SFMC Integration functionality.
*/

public class IRR_SVC_SFMCService {

    public static IRR_SVC_SFMCService.EmailMessage sendEmailMessage(String content, String subject, String recipient,
            String contactKey) {
        IRR_SVC_SFMCService.EmailMessage message = new IRR_SVC_SFMCService.EmailMessage(
                content, subject, recipient, contactKey);
        return sendEmailMessages(new List<IRR_SVC_SFMCService.EmailMessage>{message})[0];
    }

    public static List<IRR_SVC_SFMCService.EmailMessage> sendEmailMessages(List<IRR_SVC_SFMCService.EmailMessage> messages) {
        return service().sendEmailMessages(messages);
    }

    public static IRR_SVC_SFMCService.SMSMessage sendSMSMessage(String content, String recipient, String contactKey) {
        return sendSMSMessage(content, recipient, contactKey, false);
    }

    public static IRR_SVC_SFMCService.SMSMessage sendSMSMessage(String content, String recipient, String contactKey,
            Boolean responseMessage) {
        IRR_SVC_SFMCService.SMSMessage message = new IRR_SVC_SFMCService.SMSMessage(
                content, recipient, contactKey, responseMessage);
        return sendSMSMessages(new List<IRR_SVC_SFMCService.SMSMessage>{message})[0];
    }

    public static List<IRR_SVC_SFMCService.SMSMessage> sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages) {
        return service().sendSMSMessages(messages);
    }

    public static Boolean deleteContacts(Set<String> contactKeys) {
        return service().deleteContacts(contactKeys);
    }

    private static IRR_SVC_ISFMCService service() {
        return (IRR_SVC_ISFMCService) IRR_Application.Service.newInstance(IRR_SVC_ISFMCService.class);
    }

    public class SFMCResponse {
        public List<MessageResponse> responses;
        public Integer errorcode;
        public String message;
        public String requestId;
    }

    public class MessageResponse {
        public String messageKey;
        public Integer errorcode; //The error code in case of an error
        public String message; //The error message in case of an error
    }

    public abstract class SFMCMessage {
        public String content;
        public String recipient;
        public String contactKey;
        public String messageKey;
        public String externalId;
        public Integer errorCode; //The error code returned by marketing cloud in case of an error
        public String errorMessage; //The error message returned by marketing cloud in case of an error

        public SFMCMessage(IRR_MOD_Message message) {
            this.content = message.content;
            this.recipient = message.recipient;
            this.contactKey = message.recipient;
            message.SFMCMessage = this;
        }

        public SFMCMessage(String content, String recipient, String contactKey) {
            this.content = content;
            this.recipient = recipient;
            this.contactKey = contactKey;
        }
    }

    public class SMSMessage extends SFMCMessage {
        public Boolean responseMessage;

        public SMSMessage(String content, String recipient, String contactKey, Boolean responseMessage) {
            super(content, recipient, contactKey);
            this.responseMessage = responseMessage;
        }

        public SMSMessage(String content, String recipient, String contactKey) {
            super(content, recipient, contactKey);
            this.responseMessage = false;
        }

        public SMSMessage(IRR_MOD_Message message) {
            super(message);
            responseMessage = message.responseMessage;
        }
    }

    public class EmailMessage extends SFMCMessage {
        public String subject;

        public EmailMessage(String content, String subject, String recipient, String contactKey) {
            super(content, recipient, contactKey);
            this.subject = subject;
        }

        public EmailMessage(IRR_MOD_Message message) {
            super(message);
            this.subject = message.subject;
        }
    }

    public class SFMCException extends Exception { }
}