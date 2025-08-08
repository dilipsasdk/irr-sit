@isTest
public class FCS_CaseTag_Controller_Test {
  @TestSetup
  static void testDataSetUP() {
    MessagingChannel messagingChannel = new MessagingChannel(
      DeveloperName = 'FacebookChannel6778',
      MasterLabel = 'Facebook156',
      MessagingPlatformKey = '32156',
      MessageType = 'Facebook'
    );
    insert messagingChannel;
  }

  static testMethod void testFindCaseUsingChatTransId() {
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    newCases[0].Subject = 'TestCase 2';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    insert newCases;

    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;

    LiveChatTranscript lct = new LiveChatTranscript();
    lct.LiveChatVisitorId = lcv.Id;
    lct.caseId = newcases[0].Id;
    insert lct;

    Test.startTest();

    Case cse = FCS_CaseTag_Controller.findCase(lct.Id);
    System.AssertEquals(cse.Id, lct.CaseId);

    Test.stopTest();
  }
  static testMethod void testFindCaseUsingCaseId() {
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    newCases[0].Subject = 'TestCase 2';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    insert newCases;

    Test.startTest();

    Case case1 = FCS_CaseTag_Controller.findCase(newCases[0].Id);
    System.AssertEquals(newCases[0].Id, case1.Id);

    Test.stopTest();
  }
  static testMethod void testFindCaseUsingMessagingId() {
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    newCases[0].Subject = 'TestCase 2';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
    insert newCases;

    List<MessagingChannel> lstMessagChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel6778'
    ];

    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = lstMessagChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;

    MessagingSession sessions = new MessagingSession(
      Origin = 'InboundInitiated',
      MessagingEndUserId = messagingEndUser1.Id,
      Status = 'Active',
      MessagingChannelId = lstMessagChannel[0].Id,
      caseId = newCases[0].Id
    );

    insert sessions;

    Test.startTest();

    Case case1 = FCS_CaseTag_Controller.findCase(sessions.Id);

    Test.stopTest();
  }
  static testMethod void testCreateCaseUsingSocialPost() {
    List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(1);
    insert socialPosts;
    Case newRecord = new Case();
    newRecord.Department__c = System.Label.Social_Post_Department;
    newRecord.Team__c = System.Label.Social_Post_Team;
    newRecord.FCS_CaseType__c = 'New Booking';
    newRecord.FCS_Case_Reason__c = 'Inquiry';
    newRecord.FCS_CaseResolution__c = 'Availability';

    Test.startTest();

    Case case1 = FCS_CaseTag_Controller.findCase(socialPosts[0].Id);
    System.AssertEquals(null, case1.Id);
    try {
      String caseId = FCS_CaseTag_Controller.createCaseRecord(
        newRecord,
        socialPosts[0].Id
      );
    } catch (Exception e) {
    }
    // SocialPost sc = [Select Id,ParentId from SocialPost];
    //System.AssertEquals(caseId, sc.ParentId);
    Test.stopTest();
  }
}
