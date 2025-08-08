/**
Unit tests for GDPR delete batches to ensure that the correct entities are deleted
@author Peter Södergren
*/
@isTest
private class GDPR_Delete_Test {
  /**
Creates the records used to tests data deletion
*/
  @testSetup
  static void setup() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Account[] accs = FCS_TestDataFactory.createFrequentFlyers(2);
    accs[0].LastName = 'TESTACC1';
    accs[1].LastName = 'TESTACC2';
    insert accs;

    Case[] cList = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      C_RecordTypeHelper.CASE_CHANNEL
    );
    cList[0].origin = 'Email - Group Sales IS';
    cList[0].FCS_CaseType__c = 'Baggage';
    cList[0].FCS_Case_Reason__c = 'Transfer';
    cList[0].FCS_CaseResolution__c = 'Completed';

    insert cList;

    List<EmailMessage> emlst = new List<EmailMessage>();
    EmailMessage emailMsge = new EmailMessage(
      FromAddress = 'test@example.com.invalid',
      FromName = 'Test',
      Incoming = true,
      Subject = 'TestSubject',
      TextBody = 'TestBody',
      ToAddress = 'test@sas.se'
    );
    emlst.add(emailMsge);

    EmailMessage emailMsge1 = new EmailMessage(
      FromAddress = 'test@example.com.invalid',
      FromName = 'Test',
      Incoming = true,
      Subject = 'TestSubject',
      TextBody = 'TestBody',
      ToAddress = 'test@sas.se',
      ParentId = cList[0].Id
    );

    emlst.add(emailMsge1);

    insert emlst;

    List<LiveChatTranscript> lstLct = new List<LiveChatTranscript>();

    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;

    LiveChatTranscript lct = new LiveChatTranscript(
      Body = 'Test',
      Status = 'Completed',
      LiveChatVisitorId = lcv.Id
    );
    LiveChatTranscript lct1 = new LiveChatTranscript(
      Body = 'Test',
      Status = 'Completed',
      LiveChatVisitorId = lcv.Id,
      caseId = cList[0].Id
    );
    lstLct.add(lct);
    lstLct.add(lct1);

    insert lstLct;
    List<MessagingChannel> lstMsgCh = new List<MessagingChannel>();

    MessagingChannel mc = new MessagingChannel(
      DeveloperName = 'TESTFB12356',
      IsActive = false,
      MasterLabel = 'TESTFB123',
      MessageType = 'Facebook',
      MessagingPlatformKey = 'TESTFB1244567'
    );
    MessagingChannel mc1 = new MessagingChannel(
      DeveloperName = 'TESTFB123rerrt',
      IsActive = false,
      MasterLabel = 'TESTFB123er',
      MessageType = 'Facebook',
      MessagingPlatformKey = 'TESTFB124456767'
    );
    lstMsgCh.add(mc);
    lstMsgCh.add(mc1);

    User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(u) {
      insert lstMsgCh;
    }
    List<MessagingEndUser> lstMsgEndUser = new List<MessagingEndUser>();

    MessagingEndUser meu = new MessagingEndUser(
      MessageType = 'Facebook',
      Name = 'Test',
      MessagingPlatformKey = 'TESTXYZ',
      MessagingChannelId = mc.Id
    );

    MessagingEndUser meu1 = new MessagingEndUser(
      MessageType = 'Facebook',
      Name = 'Test',
      MessagingPlatformKey = 'TESTXYZ',
      MessagingChannelId = mc1.Id
    );

    lstMsgEndUser.add(meu);
    lstMsgEndUser.add(meu1);

    insert lstMsgEndUser;

    List<MessagingSession> lstMsg = new List<MessagingSession>();

    MessagingSession session = new MessagingSession(
      MessagingEndUserId = meu.Id,
      Status = 'Ended',
      MessagingChannelId = mc.Id
    );

    MessagingSession session1 = new MessagingSession(
      CaseId = cList[0].Id,
      MessagingEndUserId = meu1.Id,
      Status = 'Ended',
      MessagingChannelId = mc1.Id
    );

    lstMsg.add(session1);
    lstMsg.add(session);

    insert lstMsg;

    SocialPost[] spList = FCS_TestDataFactory.createSocialPosts(2);
    spList[1].Content = 'test';
    spList[0].Content = 'test1';

    insert spList;
    spList[1].ParentId = cList[0].Id;
    update spList;
    Group_Travel_Request__c grt = new Group_Travel_Request__c(
      Name = 'Test GRP',
      Comments_From_Customer__c = 'Group Travel Form',
      From_Airport__c = 'Bng'
    );
    insert grt;

    Refund_Request__c rf = new Refund_Request__c(
      Country_of_Purchase__c = 'Indoa',
      Ticket_Numbers__c = 'T-123456'
    );

    insert rf;

    Special_Service_Request__c ssr = new Special_Service_Request__c(
      Name = 'Test Animal',
      Type_Of_Service_Animal__c = 'Domestic',
      Type_Of_Special_Baggage__c = 'Animal'
    );
    insert ssr;
    //Case cs = new case(Id =cList[0].Id, Group_Travel_Request__c=grt.Id,Refund_Request__c=rf.Id,Special_Service_Request__c=ssr.Id, status='Closed');
    Case cs = new Case(
      Id = cList[0].Id,
      status = 'Closed',
      Group_Travel_Request__c = grt.Id,
      Refund_Request__c = rf.Id,
      Special_Service_Request__c = ssr.Id
    );
    update cs;
  }
  /**
Tests deletion of accounts (Should only occur when the account has no cases or interactions)
*/
  @isTest
  static void deleteAccount() {
    Test.startTest();
    Database.executeBatch(new GDPR_DeleteAccount_Batch());
    Test.stopTest();
    Account[] accList = [SELECT Id, LastName FROM Account];
    System.assertEquals(0, accList.size());
    //System.assertNotEquals('TESTACC2', accList[0].LastName);
  }
  /**
Tests wiping of ChatTranscript (Should only occur when the ChatTranscript has no cases or interactions)
*/
  @isTest
  static void wipeChatTranscript() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'Body' };
    gdprwipeInt.setVariables(
      'LiveChatTranscript',
      1,
      'CaseId',
      null,
      null,
      null
    );
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    LiveChatTranscript[] lctList = [
      SELECT Id, body
      FROM LiveChatTranscript
      WHERE CaseId = NULL
    ];
    System.assertEquals(null, lctList[0].body);
  }
  /**
Tests wiping of EmailMessage(Should only occur when the EmailMessage has no cases or interactions)
*/
  @isTest
  static void wipeEmailMessage() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'TextBody' };
    gdprwipeInt.setVariables('EmailMessage', 1, 'parentId', null, null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    EmailMessage[] lctem = [
      SELECT Id, TextBody
      FROM EmailMessage
      WHERE parentId = NULL
    ];
    System.assertEquals(null, lctem[0].TextBody);
  }

  /**
Tests wiping of SocialPost(Should only occur when the SocialPost has no cases or interactions)
*/
  @isTest
  static void wipeSocialPost() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'Content' };
    gdprwipeInt.setVariables('SocialPost', 1, 'parentId', null, null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    SocialPost[] lctSp = [
      SELECT Id, Content
      FROM SocialPost
      WHERE parentId = NULL
    ];
    System.assertEquals(null, lctSp[0].Content);
  }
  /**
Tests wiping of MessagingSession(Should only occur when the MessagingSession has no cases or interactions)
*/
  @isTest
  static void wipeMessagingSession() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    gdprwipeInt.setVariables('MessagingSession', 1, 'caseId', null, null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    MessagingSession[] lctMs = [
      SELECT Id, GDPR_Wiped__c
      FROM MessagingSession
      WHERE caseId = NULL
    ];
    System.assertEquals(true, lctMs[0].GDPR_Wiped__c);
  }

  /**
Tests deletion of LiveChatTranscript (Should only occur when the LiveChatTranscript has no cases or interactions)
*/
  @isTest
  static void deleteChatTranscript() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables(
      'LiveChatTranscript',
      1,
      'CaseId',
      null,
      'Delete_Chat_Transcript_Batch',
      null
    );
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM LiveChatTranscript WHERE CaseId = NULL]
    );
  }
  /**
Tests deletion of EmailMessage (Should only occur when the EmailMessage has no cases or interactions)
*/
  @isTest
  static void deleteEmailMessage() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables(
      'EmailMessage',
      1,
      'parentId',
      null,
      'Delete_Email_Message_Batch',
      null
    );
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM EmailMessage WHERE parentId = NULL]
    );
  }
  /**
Tests deletion of SocialPost(Should only occur when the SocialPost has no cases or interactions)
*/
  @isTest
  static void deleteSocialPost() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables(
      'SocialPost',
      1,
      'parentId',
      null,
      'Delete_Social_Post_Batch',
      null
    );
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM SocialPost WHERE parentId = NULL]
    );
  }
  /**
Tests deletion of MessagingSession(Should only occur when the MessagingSession has no cases or interactions)
*/
  @isTest
  static void deleteMessagingSession() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables(
      'MessagingSession',
      1,
      'caseId',
      null,
      'Delete_Messaging_Session_Batch',
      null
    );
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM MessagingSession WHERE caseId = NULL]
    );
  }

  /**
    Test the Wiping of case and retalted Channel Object
    */
  @isTest
  static void wipeCaseAndAssociatedEntites() {
    GDPR_WipeCase_Batch gdprWipeCaseBatch = new GDPR_WipeCase_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{
      'Body',
      'Content',
      'Comments_From_Customer__c',
      'Ticket_Numbers__c',
      'Type_Of_Special_Baggage__c',
      'SuppliedPhone'
    };
    gdprWipeCaseBatch.setVariables(
      'Case',
      2,
      null,
      'Baggage',
      'Wipe_Case_Batch_Baggage',
      null
    );
    gdprWipeCaseBatch.lastRetentionDate = dateTime.now().addDays(4);
    Test.startTest();
    Database.executeBatch(gdprWipeCaseBatch);
    Test.stopTest();
    System.assertEquals(
      true,
      [SELECT Id, GDPR_Wiped__c FROM Case WHERE status = 'Closed' LIMIT 1]
      .GDPR_Wiped__c
    );
    System.assertEquals(
      null,
      [SELECT Id, SuppliedPhone FROM Case WHERE status = 'Closed' LIMIT 1]
      .SuppliedPhone
    );
    System.assertEquals(
      null,
      [SELECT Id, Body FROM LiveChatTranscript WHERE caseId != NULL LIMIT 1]
      .Body
    );
    System.assertEquals(
      null,
      [SELECT Id, Content FROM SocialPost WHERE ParentId != NULL LIMIT 1]
      .Content
    );
    System.assertEquals(
      true,
      [
        SELECT Id, GDPR_Wiped__c
        FROM MessagingSession
        WHERE caseId != NULL
        LIMIT 1
      ]
      .GDPR_Wiped__c
    );
    System.assertEquals(
      null,
      [
        SELECT Id, Comments_From_Customer__c
        FROM Group_Travel_Request__c
        LIMIT 1
      ]
      .Comments_From_Customer__c
    );
    System.assertEquals(
      null,
      [SELECT Id, Ticket_Numbers__c FROM Refund_Request__c LIMIT 1]
      .Ticket_Numbers__c
    );
    System.assertEquals(
      null,
      [
        SELECT Id, Type_Of_Special_Baggage__c
        FROM Special_Service_Request__c
        LIMIT 1
      ]
      .Type_Of_Special_Baggage__c
    );
  }
  /**
Tests deletion of MessagingSession(Should only occur when the MessagingSession has no cases or interactions)
*/
  @isTest
  static void deleteCaseAndAssociatedEntities() {
    GDPR_DeleteCase_Batch gdprDelCaseBatch = new GDPR_DeleteCase_Batch();
    gdprDelCaseBatch.setVariables(
      'Case',
      1,
      null,
      'Baggage',
      'Delete_Case_Batch_Baggage',
      null
    );
    gdprDelCaseBatch.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelCaseBatch);
    Test.stopTest();
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Case
        WHERE status = 'Closed' AND FCS_CaseType__c = 'Baggage'
      ]
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM LiveChatTranscript
        WHERE case.status = 'Closed' AND case.FCS_CaseType__c = 'Baggage'
      ]
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM MessagingSession
        WHERE case.status = 'Closed' AND case.FCS_CaseType__c = 'Baggage'
      ]
    );
  }
  public static testMethod void testSpamSocialPost() {
    Set<Id> setSpIds;
    Social_Post_Spam_Hash_Tags__c custSett = new Social_Post_Spam_Hash_Tags__c();
    custSett.Spam_Hash_Tag__c = '#BoycottEthiopianAirlines';
    custSett.Name = 'Twitter_BoycottEthiopianAirlines';
    insert custSett;

    SocialPost[] spList = FCS_TestDataFactory.createSocialPosts(2);
    spList[1].Content = 'test#BoycottEthiopianAirlinestestgsvc';
    spList[1].ReviewedStatus = 'Needed';
    spList[0].Content = 'test1';
    spList[0].ReviewedStatus = 'Needed';

    insert spList;
    Test.startTest();
    database.executeBatch(new Delete_SpamSocialPost_Batch());
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM SocialPost WHERE id = :spList[1].Id]
    );
  }
}
