@isTest
public class FCS_CloseFBMessgerCaseAfter24hr_Test {
  /**
   * Setting up setup objects in setup method
   */
  @TestSetup
  static void createTestData() {
    insert new MessagingChannel(
      DeveloperName = 'FacebookChannel28',
      MasterLabel = 'Facebook232',
      MessagingPlatformKey = '123',
      MessageType = 'Facebook'
    );
  }
  /*
           scenario : If the customer contacts after 24 hours once the chat ended, Old Case will be closed  with Case tag
           If in case, case is not tagged
        */
  public static testMethod void testAutoCloseCaseWithoutCaseTag() {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1, null, null, null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    lstCases[0].FCS_Case_Reason__c = null;
    insert lstCases;

    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel28'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-2),
      Time.newInstance(0, 0, 0, 0)
    );
    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser1.Id,
        Status = 'Ended',
        caseid = lstCases[0].Id,
        MessagingChannelId = messagingChannel[0].Id,
        EndTime = lastRetentionDate
      )
    );

    insert sessions;
    FCS_CloseFBMessgerCaseAfter24hr_Batch fcsCloseFBMessgr = new FCS_CloseFBMessgerCaseAfter24hr_Batch();
    fcsCloseFBMessgr.setVariables('Case', 1, null, null, null, null);
    Test.StartTest();
    Database.executeBatch(fcsCloseFBMessgr);
    Test.StopTest();
    Case cse = [SELECT Id, Status FROM Case WHERE Id = :lstCases[0].Id];
    System.assertEquals('Closed', cse.Status);
  }
  /*
            scenario : If the customer contacts after 24 hours once the chat ended, Old Case will be closed  
         */
  public static testMethod void testAutoCloseCaseWithCaseTag() {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1, null, null, null);

    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    lstCases[0].Department__c = 'SoMe Support';
    lstCases[0].FCS_CaseType__c = 'Baggage';
    lstCases[0].FCS_Case_Reason__c = 'Allowance';
    lstCases[0].FCS_CaseResolution__c = 'Referred to webpage';
    insert lstCases;

    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel28'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-3),
      Time.newInstance(0, 0, 0, 0)
    );
    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser1.Id,
        Status = 'Ended',
        caseid = lstCases[0].Id,
        MessagingChannelId = messagingChannel[0].Id,
        EndTime = lastRetentionDate
      )
    );
    insert sessions;
    FCS_CloseFBMessgerCaseAfter24hr_Batch fcsCloseFBMessgr = new FCS_CloseFBMessgerCaseAfter24hr_Batch();
    fcsCloseFBMessgr.setVariables('Case', 1, null, null, null, null);
    Test.StartTest();
    Database.executeBatch(fcsCloseFBMessgr);
    Test.StopTest();
    Case cse = [SELECT Id, Status FROM Case WHERE Id = :lstCases[0].Id];
    System.assertEquals('Closed', cse.Status);
  }
  /**
          If the customer contacts with in 24 hours then case will not be in closed
        */
  public static testMethod void testFBMessangerWithin24hours() {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1, null, null, null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    insert lstCases;

    lstCases[0].FCS_CaseType__c = 'Baggage';
    lstCases[0].FCS_Case_Reason__c = 'Other';
    update lstCases;

    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel28'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(
      Date.today(),
      Time.newInstance(0, 0, 0, 0)
    );
    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser1.Id,
        Status = 'Ended',
        caseid = lstCases[0].Id,
        MessagingChannelId = messagingChannel[0].Id,
        EndTime = lastRetentionDate
      )
    );

    insert sessions;
    Test.StartTest();
    Database.executeBatch(new FCS_CloseFBMessgerCaseAfter24hr_Batch());
    Test.StopTest();
    Case cse = [SELECT Id, Status FROM Case WHERE Id = :lstCases[0].Id];
    System.assertEquals('New', cse.Status);
  }
  /**
          If the Agent not able to reply due to problem in Chat 
          then case will close after 24 hours
        */
  public static testMethod void testChatEndedDueToError() {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1, null, null, null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_CaseType__c = 'Error';
    lstCases[0].FCS_Case_Reason__c = 'Disconnected customer';
    lstCases[0].FCS_CaseResolution__c = 'Completed';
    lstCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    insert lstCases;

    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel28'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-2),
      Time.newInstance(0, 0, 0, 0)
    );
    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser1.Id,
        Status = 'Active',
        caseid = lstCases[0].Id,
        MessagingChannelId = messagingChannel[0].Id,
        AcceptTime = lastRetentionDate
      )
    );

    insert sessions;
    FCS_CloseFBMessgerCaseAfter24hr_Batch fcsCloseFBMessgr = new FCS_CloseFBMessgerCaseAfter24hr_Batch();
    fcsCloseFBMessgr.setVariables('Case', 1, null, null, null, null);
    Test.StartTest();
    Database.executeBatch(fcsCloseFBMessgr);
    Test.StopTest();
    Case cse = [SELECT Id, Status FROM Case WHERE Id = :lstCases[0].Id];
    System.assertEquals('Closed', cse.Status);
  }
  /**
    If the Agent contact with in 24 hours then case will not be closed
  */
  public static testMethod void testFBMessangerActive() {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1, null, null, null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_Case_Reason__c = 'Disconnected customer';
    lstCases[0].FCS_CaseType__c = 'Error';
    lstCases[0].FCS_CaseResolution__c = 'Completed';
    lstCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    insert lstCases;

    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel28'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(
      Date.today(),
      Time.newInstance(0, 0, 0, 0)
    );
    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser1.Id,
        Status = 'Active',
        caseid = lstCases[0].Id,
        MessagingChannelId = messagingChannel[0].Id,
        AcceptTime = lastRetentionDate
      )
    );

    insert sessions;
    Test.StartTest();
    Database.executeBatch(new FCS_CloseFBMessgerCaseAfter24hr_Batch());
    Test.StopTest();
    Case cse = [SELECT Id, Status FROM Case WHERE Id = :lstCases[0].Id];
    System.assertEquals('New', cse.Status);
  }
}
