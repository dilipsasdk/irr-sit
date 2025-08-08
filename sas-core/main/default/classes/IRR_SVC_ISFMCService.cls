/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ISFMCService {
    List<IRR_SVC_SFMCService.EmailMessage> sendEmailMessages(List<IRR_SVC_SFMCService.EmailMessage> messages);
    List<IRR_SVC_SFMCService.SMSMessage> sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages);
    Boolean deleteContacts(Set<String> contactKeys);
}