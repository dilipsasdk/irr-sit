/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description TODO
*/

public class IRR_MOD_AutomatedRequest {

    @AuraEnabled
    public List<IRR_MOD_PassengerInfo> passengerInfos { get; set; }

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
    public String flightId { get; set; }

    @AuraEnabled
    public String flightRef { get; set; }

    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public String arrivalCity { get; set; }

    @AuraEnabled
    public String departureCity { get; set; }
}
