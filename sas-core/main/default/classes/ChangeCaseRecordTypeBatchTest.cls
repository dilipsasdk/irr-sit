@isTest
private class ChangeCaseRecordTypeBatchTest {
  @TestSetup
  static void createTestData() {
    List<Case> newCases = FCS_TestDataFactory.createCases(2, null, null, null);
    newCases[0].Origin = 'Chat';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_Chat;
    newCases[1].Origin = 'Facebook';
    newCases[1].RecordTypeId = C_RecordTypeHelper.CASE_Channel;

    insert newCases;
  }

  @isTest
  static void testChangeCaseRecordforChat() {
    Test.startTest();
    Database.executebatch(
      new ChangeCaseRecordTypeBatch('Chat', new List<String>{ 'Chat' })
    );
    Database.executebatch(
      new ChangeCaseRecordTypeBatch('Facebook', new List<String>{ 'CHANNEL' })
    );
    Test.StopTest();
  }
}
