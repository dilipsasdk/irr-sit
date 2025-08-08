/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_MOD_ManualRequest {

    @AuraEnabled
    public List<IRR_MOD_PassengerInfo> passengerInfos { get; set; }

    @AuraEnabled
    public Boolean responseMessage { get; set; }

    @AuraEnabled
    public Boolean sendSMSMessages { get; set; }

    @AuraEnabled
    public Datetime sendMessageTime { get; set; }

    @AuraEnabled
    public Boolean sendEmailMessages { get; set; }

    @AuraEnabled
    public String emailTemplate { get; set; }

    @AuraEnabled
    public String smsTemplate { get; set; }

    @AuraEnabled
    public IRR_MOD_DelayInfo delayInfo { get; set; }

    @AuraEnabled
    public IRR_MOD_CustomInfo customInfo { get; set; }

    @AuraEnabled
    public IRR_MOD_CancelInfo cancelInfo { get; set; }

    @AuraEnabled
    public IRR_MOD_ScheduledChangeInfo scheduledChangeInfo { get; set; }

    @AuraEnabled
    public IRR_MOD_NewInfo newInfo { get; set; }
}