/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for Scheduled Change Flow and Message Templates.
*/

public class IRR_MOD_ScheduledChangeInfo {
    
    @AuraEnabled
    public String bookingId { get; set; }
    
    @AuraEnabled
    public String bookingReference { get; set; }
    
    @AuraEnabled
    public Datetime eventTime { get; set; }
    
    @AuraEnabled
    public Boolean isDayChange { get; set; }
    
    @AuraEnabled
    public Boolean largeChangeFromOriginalSTD { get; set; }
    
    @AuraEnabled
    public Boolean rebookableOnline { get; set; }
    
    @AuraEnabled
    public Boolean isOvernightStay { get; set; }
    
    @AuraEnabled
    public Boolean isReacc { get; set; }
    
    @AuraEnabled
    public Boolean isAirportChange { get; set; }
    
    @AuraEnabled
    public Boolean hasCancelledFlight { get; set; }
}