@isTest
private class EmailProcessHelper_Test {
  // Has to exist as a Department picklist value & as a queue
  private static final String TEST_QUEUE_NAME = 'EuroBonus';

  /**
   * UpdateCaseOwnerToDepartmentQueue function should update case owner correctly for a
   * single case.
   */
  @isTest
  static void shouldUpdateOwnerForSingleEntry() {
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    testCase.Department__c = TEST_QUEUE_NAME;

    Test.startTest();
    insert testCase;

    List<EmailProcessHelper.UpdateCaseArgs> updateArgs = new List<EmailProcessHelper.UpdateCaseArgs>();
    updateArgs.add(new EmailProcessHelper.UpdateCaseArgs(testCase.Id));

    EmailProcessHelper.UpdateCaseOwnerToDepartmentQueue(updateArgs);
    Test.stopTest();

    Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
    List<Group> queue = [
      SELECT Id
      FROM Group
      WHERE Name = :TEST_QUEUE_NAME AND Type = 'Queue'
    ];

    System.assertEquals(updatedCase.OwnerId, queue[0].Id);
  }

  /**
   * UpdateCaseOwnerToDepartmentQueue function should update case owner correctly for a list
   * of multiple cases.
   */
  @isTest
  static void shouldUpdateOwnerForBatch() {
    Case testCase1 = FCS_TestDataFactory.createCases(1, null, null, null)[0];
    Case testCase2 = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    testCase1.Department__c = TEST_QUEUE_NAME;
    testCase2.Department__c = TEST_QUEUE_NAME;

    List<Case> casesToInsert = new List<Case>();
    casesToInsert.add(testCase1);
    casesToInsert.add(testCase2);

    Test.startTest();
    insert casesToInsert;

    List<EmailProcessHelper.UpdateCaseArgs> updateArgs = new List<EmailProcessHelper.UpdateCaseArgs>();
    updateArgs.add(new EmailProcessHelper.UpdateCaseArgs(testCase1.Id));
    updateArgs.add(new EmailProcessHelper.UpdateCaseArgs(testCase2.Id));

    EmailProcessHelper.UpdateCaseOwnerToDepartmentQueue(updateArgs);
    Test.stopTest();

    Case updatedCase1 = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase1.Id];
    Case updatedCase2 = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase2.Id];
    List<Group> queue = [
      SELECT Id
      FROM Group
      WHERE Name = :TEST_QUEUE_NAME AND Type = 'Queue'
    ];

    System.assertEquals(updatedCase1.OwnerId, queue[0].Id);
    System.assertEquals(updatedCase2.OwnerId, queue[0].Id);
  }

  /**
   * UpdateCaseOwnerToDepartmentQueue function shouldn't blow up even with an
   * empty list of cases to update.
   */ @isTest
  static void shouldWorkForEmptyArgs() {
    List<EmailProcessHelper.UpdateCaseArgs> updateArgs = new List<EmailProcessHelper.UpdateCaseArgs>();
    EmailProcessHelper.UpdateCaseOwnerToDepartmentQueue(updateArgs);
  }
}
