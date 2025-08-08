/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
* @description Apex Defined Data Structure for IRR Airport Change Flow and Message Templates.
*/
public class IRR_MOD_AirportChangeInfo {
    
    @AuraEnabled
    public String bookingId { get; set; }

    @AuraEnabled
    public String source { get; set; }

    @AuraEnabled
    public Datetime eventTime { get; set; }
    
    @AuraEnabled
    public String bookingReference { get; set; }
    
    @AuraEnabled
    public String year { get; set; }
}