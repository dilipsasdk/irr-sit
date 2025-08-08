@isTest
private class MigrateCaseTagsBatchTest {
  @TestSetup
  static void createTestData() {
    OldCaseTagtoNewCaseTags__c customsetting = new OldCaseTagtoNewCaseTags__c();
    customsetting.Old_Case_Reason__c = 'Corporate';
    customsetting.Old_Case_Sub_Reason__c = 'Agreement related question*';
    customsetting.New_Case_Type__c = 'Travel Pass';
    customsetting.New_Case_Reason__c = 'Booking';
    customsetting.Name = 'test12';

    insert customsetting;
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    newCases[0].Origin = 'Email - Corporate Support Scandinavia';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    newCases[0].Department__c = 'Corporate';
    newCases[0].Team__c = 'Support Scandinavia';
    newCases[0].FCS_CaseReason__c = 'Corporate';
    newCases[0].FCS_CaseSubReason__c = 'Agreement related question*';
    newCases[0].Type = 'Channel';
    newCases[0].SuppliedFirstname__c = 'Test';
    newCases[0].SuppliedLastname__c = 'Testsson';

    insert newCases;
  }

  @isTest
  static void testChangeCaseRecordforChat() {
    Test.startTest();
    database.executebatch(
      new MigrateCaseTagsBatch(
        new List<String>{
          'Email',
          'Chat',
          'Facebook',
          'Facebook Messenger',
          'Phone',
          'Twitter',
          'Web',
          'Manual'
        },
        'Corporate',
        'Channel'
      )
    );

    Test.StopTest();
  }
}
