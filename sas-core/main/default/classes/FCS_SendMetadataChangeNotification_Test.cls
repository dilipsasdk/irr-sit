@isTest
private class FCS_SendMetadataChangeNotification_Test {
    @TestSetup
    static void setUpData(){
        // insert custom setting for Audit trial from date
        FCS_Audit_Trail__c fcsAuditTrilCustSetting =  New  FCS_Audit_Trail__c();
        fcsAuditTrilCustSetting.Name = 'Fcs Audit trial Date';
        fcsAuditTrilCustSetting.From_Date__c = System.now().addDays(-1);
        insert fcsAuditTrilCustSetting;  
        
    }  
    static testMethod void TestAuditTrail(){
        Test.startTest();
        Database.executeBatch(new FCS_SendMetadataChangeNotification_Batch());         
        Test.stopTest();
        
    } 
}