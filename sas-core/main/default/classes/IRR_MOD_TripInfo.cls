/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_TripInfo {

    @AuraEnabled
    public String tripType { get; set; }

    @AuraEnabled
    public List<IRR_MOD_SegmentInfo> segments { get; set; }

}