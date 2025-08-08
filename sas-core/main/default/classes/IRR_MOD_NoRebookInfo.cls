/**
* @author Chetan Singh, Coforge
* @date 2022
*
* @description Apex Defined Data Structure for Disruption No Rebook Flow and Message Templates.
*/

public class IRR_MOD_NoRebookInfo {

    @AuraEnabled
    public String bookingId { get; set; }

    @AuraEnabled
    public String bookingReference { get; set; }

    @AuraEnabled
    public Datetime eventTime { get; set; }

    @AuraEnabled
    public Integer minutesToScheduledTime { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public String cancelledSegment { get; set; }

    @AuraEnabled
    public List<String> cancelledSegments { get; set; }

}
