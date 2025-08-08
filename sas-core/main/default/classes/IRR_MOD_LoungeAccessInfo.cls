public class IRR_MOD_LoungeAccessInfo {

   @auraenabled
    public string emailAddress{get;set;}
    @auraenabled
    public String caseId{get;set;}
    @AuraEnabled
    public String comment { get; set; }
    @AuraEnabled
    public String subject { get; set; }
    @AuraEnabled
    public String deactivateId { get; set;}
    @AuraEnabled
    public String htmlContent { get; set; }
    @AuraEnabled
    public String agentName{ get; set; }
    @AuraEnabled
    public boolean isError{ get; set; }
    @AuraEnabled
    public String errorMessage{ get; set; }
}