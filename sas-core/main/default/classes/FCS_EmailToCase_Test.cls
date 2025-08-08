/**
    Test method for the process Case Set priority Urgent that sets the priority
    to urgent based on input from customer in Subject field or if Email is Flagged as important.
*/
@isTest
private class FCS_EmailToCase_Test {
  /**
        Set up the STOPQ-Escalation Queue
        @author Josephine Ding - Deloitte
     */
  @testSetup
  static void setup() {
    // Create common test accounts
    Group g1 = new Group(Name = 'STOPQ Escalations', type = 'Queue');
    insert g1;
    QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
    insert q1;

    Group testGroup = new Group(Name = 'test group', Type = 'Queue');
    insert testGroup;
    QueueSObject testQueue = new QueueSObject(
      QueueID = testGroup.id,
      SobjectType = 'Case'
    );
    insert testQueue;
  }

  /**
        Test creating a Case as it would be created via Email-To-Case to the STOPQ Escalation-Queue without Urgent in subject
        @author Philip Ossler - Deloitte
    */
  @isTest
  static void setCaseNotUrgentTest() {
    Group g = [SELECT Id FROM Group WHERE Name = 'STOPQ Escalations' LIMIT 1];
    Case c1 = new Case(
      Status = 'New',
      Origin = 'Email',
      Subject = 'Test subject',
      OwnerId = g.Id,
      SuppliedFirstname__c = 'Test',
      SuppliedLastname__c = 'Testsson'
    );
    Test.startTest();
    insert c1;
    Test.stopTest();
    System.assertNotEquals(
      'Urgent',
      [SELECT Priority FROM Case WHERE Id = :c1.Id]
      .Priority
    );
  }
}
