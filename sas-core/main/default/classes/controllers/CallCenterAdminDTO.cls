public with sharing class CallCenterAdminDTO {

    @AuraEnabled
    public String userName { get; set; }
    @AuraEnabled
    public String userId { get; set; }
    @AuraEnabled
    public String contactCenterGroupName { get; set; }
    @AuraEnabled
    public String contactCenterGroupNameId { get; set; }

}