/**
 * @author Anton Norell
 * @description Test class for FCS_OmniChannelQueueBacklogController
 */
@IsTest
private class FCS_OmniChannelQueueBacklogControll_Test {
  @TestSetup
  static void createTestData() {
    QueueRoutingConfig routingConfig = [
      SELECT Id
      FROM QueueRoutingConfig
      LIMIT 1
    ];

    Group queue1 = new Group(
      Type = 'Queue',
      Name = 'Test_Queue1',
      QueueRoutingConfigId = routingConfig.Id
    );
    Group queue2 = new Group(
      Type = 'Queue',
      Name = 'Test_Queue2',
      QueueRoutingConfigId = routingConfig.Id
    );
    insert queue1;
    insert queue2;

    insert new QueueSobject(
      QueueId = queue1.Id,
      SobjectType = 'LiveChatTranscript'
    );
    insert new QueueSobject(QueueId = queue1.Id, SobjectType = 'Case');
  }

  /**
   * Asserts that Queue Ids are returned for queues that the supplied user is a member of, either directly or
   * via another public group.
   */
  @IsTest
  static void shouldReturnQueueIdsBasedOnMembership() {
    User u = FCS_TestDataFactory.createUsers(1)[0];
    insert u;
    Group pg = new Group(Type = 'Regular', Name = 'PG');
    insert pg;
    Group[] queues = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND Name LIKE 'Test_Queue%'
      ORDER BY Name ASC
    ];
    insert new GroupMember(UserOrGroupId = pg.Id, GroupId = queues[1].Id);
    GroupMember directMemberShip = new GroupMember(
      UserOrGroupId = u.Id,
      GroupId = queues[0].Id
    );
    insert directMemberShip;
    GroupMember publicGroupMemberShip = new GroupMember(
      UserOrGroupId = u.Id,
      GroupId = pg.Id
    );
    insert publicGroupMemberShip;

    Id[] queueIds = FCS_OmniChannelQueueBacklogController.getQueueIds(u.Id);

    System.assertNotEquals(null, queueIds);
    System.assertEquals(2, queueIds.size());
    System.assert(queueIds.contains(queues[0].Id));
    System.assert(queueIds.contains(queues[1].Id));
  }

  /**
   * Asserts that the correct queue status is returned for each queue of which the Ids are supplied
   */
  @IsTest
  static void shouldReturnQueueStatusBasedOnQueueId() {
    Group[] queues = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND Name LIKE 'Test_Queue%'
      ORDER BY Name ASC
    ];
    LiveChatVisitor visitor = new LiveChatVisitor();
    insert visitor;
    insert new LiveChatTranscript(
      LiveChatVisitorId = visitor.Id,
      OwnerId = queues[0].Id
    );
    Case[] cases = FCS_TestDataFactory.createCases(3, null, null, null);
    for (Case c : cases) {
      c.OwnerId = queues[0].Id;
    }
    insert cases;

    FCS_OmniChannelQueueBacklogController.QueueStatus[] queueStatuses = FCS_OmniChannelQueueBacklogController.getQueueStatus(
      new List<Id>{ queues[0].Id, queues[1].Id }
    );

    System.assertEquals(2, queueStatuses.size());
    System.assertEquals(4, queueStatuses[0].countWaiting);
    System.assertEquals(0, queueStatuses[1].countWaiting);
    System.assertEquals('--', queueStatuses[1].longestWaitTime);
  }
}
