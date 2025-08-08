/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for Manual Communication Custom Message Templates.
*/

public class IRR_MOD_CustomInfo {
    @AuraEnabled
    public String content { get; set; }

    @AuraEnabled
    public String subject { get; set; }
}