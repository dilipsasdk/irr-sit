/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Delay Event Flow and Message Templates.
*/

public class IRR_MOD_DelayInfo {

    @AuraEnabled
    public String flightId { get; set; }

    @AuraEnabled
    public String flightRef { get; set; }

    @AuraEnabled
    public Datetime eventTime { get; set; }

    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }

    @AuraEnabled
    public Integer delayedMinutes { get; set; }

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public String delayReasonCode { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public Integer previousDelayedMinutes { get; set; }

    @AuraEnabled
    public Integer minutesToScheduledTime { get; set; }

    @AuraEnabled
    public Boolean firstDelay { get; set; }

    @AuraEnabled
    public Integer delayDifference { get; set; }

    @AuraEnabled
    public String arrivalCity { get; set; }

    @AuraEnabled
    public String departureCity { get; set; }

    @AuraEnabled
    public String couponBatchId { get; set; }

    @AuraEnabled
    public Boolean hasCouponBatchId { get; set; }
    
    @AuraEnabled
    public Boolean isResetEvent { get; set; }

}