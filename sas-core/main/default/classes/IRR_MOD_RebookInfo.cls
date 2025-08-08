/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for Disruption Rebook Flow and Message Templates.
*/

public class IRR_MOD_RebookInfo {

    @AuraEnabled
    public String bookingId { get; set; }

    @AuraEnabled
    public String bookingReference { get; set; }

    @AuraEnabled
    public Datetime eventTime { get; set; }

    @AuraEnabled
    public List<String> addedSegments { get; set; }

    @AuraEnabled
    public String isEnableCanada { get; set; }
    
     @AuraEnabled
    public String smsCanada { get; set; }

}