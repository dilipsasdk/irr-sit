/**
 * @author Anton Norell
 * @date 2020-01-24
 * @description Test class for MessagingSessions
 */
@IsTest
private class MessagingSessions_Test {
  /**
   * Setting up setup objects in setup method
   */
  @TestSetup
  static void createTestData() {
    insert new MessagingChannel(
      DeveloperName = 'FacebookChannel167',
      MasterLabel = 'Facebook1789',
      MessagingPlatformKey = '32167',
      MessageType = 'Facebook'
    );
  }

  /**
   * Asserts that cases are not created for MessageSessions that are of outbound origin
   */

  @IsTest
  static void shouldNotCreateCaseForOutboundChat() {
    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel167'
    ];
    MessagingEndUser messagingEndUser = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser;

    insert new MessagingSession(
      Origin = 'AgentInitiated',
      MessagingEndUserId = messagingEndUser.Id,
      Status = 'Active',
      MessagingChannelId = messagingChannel[0].Id
    );

    Case[] cases = [SELECT Id FROM Case];
    System.assertEquals(0, cases.size());
  }
}
