/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_NewInfo {

    @AuraEnabled
    public String flightId { get; set; }

    @AuraEnabled
    public String flightRef { get; set; }

    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }

    @AuraEnabled
    public Datetime newInfoTimeLocal { get; set; }

    @AuraEnabled
    public Datetime newInfoTimeUTC { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public String arrivalCity { get; set; }

    @AuraEnabled
    public String departureCity { get; set; }

    @AuraEnabled
    public String paxURL { get; set; }

}