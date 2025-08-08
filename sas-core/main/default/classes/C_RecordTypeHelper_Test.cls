/**
    Test class for C_RecordTypeHelper class
    @author Philip Ossler - Deloitte
*/
@isTest
private class C_RecordTypeHelper_Test {
    @isTest
    static void shouldReturnCorrectCaseRecordType(){
        List<RecordType> rtypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case'];
        Map<String, ID> caseRecordTypes = new Map<String, ID>{};
        for(RecordType rt : rtypes) caseRecordTypes.put(rt.DeveloperName, rt.Id);

        System.assertEquals(C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, caseRecordTypes.get('Internal_Backoffice'));
    }

    @isTest
    static void shouldReturnCorrectAccountRecordType(){
        List<RecordType> rtypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account'];
        Map<String, ID> accountRecordTypes = new Map<String, ID>{};
        for(RecordType rt : rtypes) accountRecordTypes.put(rt.DeveloperName, rt.Id);

        System.assertEquals(C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER, accountRecordTypes.get('EBCustomer'));
        System.assertEquals(C_RecordTypeHelper.ACCOUNT_PERSON_ANONYMOUS, accountRecordTypes.get('AnonymousCustomer'));
    }
}
