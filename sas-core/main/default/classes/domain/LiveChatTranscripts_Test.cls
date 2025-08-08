/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Test class for the LiveChatTranscriptTriggerHandler and ConsoleAutomationController
 * tested through this class.
 */
@IsTest
public with sharing class LiveChatTranscripts_Test {
  /**
   * Testing LiveChatTranscriptTriggerHandler that will NOT create
   * a new Case for all LiveChatTranscripts with no attached Case.
   */
  @IsTest
  static void testCaseNotCreated() {
    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;
    LiveChatTranscript lct = new LiveChatTranscript();
    lct.LiveChatVisitorId = lcv.Id;
    insert lct;
    Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id]
    .CaseId;
    System.assertEquals(expCaseId, null);
  }

  /**
   * Testing LiveChatTranscriptTriggerHandler that will create
   * a new Case for all LiveChatTranscripts with no attached Case.
   */
  @IsTest
  static void testCaseCreated() {
    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;
    LiveChatTranscript lct = new LiveChatTranscript();
    lct.LiveChatVisitorId = lcv.Id;
    insert lct;
    lct.Status = 'InProgress';
    update lct;
    Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id]
    .CaseId;
    System.assertNotEquals(expCaseId, null);
  }
  /**
   * Testing LiveChatTranscriptTriggerHandler that will
   * a delete the Case for all LiveChatTranscripts with status as Missed.
   */
  @IsTest
  static void testLiveChatMissed() {
    List<Case> lstcases = FCS_TestDataFactory.createCases(1, null, null, null);
    insert lstcases;
    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;
    LiveChatTranscript lct = new LiveChatTranscript();
    lct.LiveChatVisitorId = lcv.Id;
    lct.CaseId = lstcases[0].Id;
    insert lct;
    lct.Status = 'Missed';
    update lct;
    Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id]
    .CaseId;
    System.assertEquals(expCaseId, null);
  }
}
