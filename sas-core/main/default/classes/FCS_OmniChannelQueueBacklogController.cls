/**
 * @author Anton Norell
 * @description Controller for component used to display queue status in in utility bar
 * @date 2020-04-20
 */
public with sharing class FCS_OmniChannelQueueBacklogController {
  /**
   * Used to retrieve Ids for all the queues that the supplied user is a member of, either directly or indirectly.
   * Indirect membership could be membership through a role or another public group.
   * @param userId Id of user to retrieve queues for.
   * @return List if Ids of the queues that the user is a member of. If no memberships are found, null is returned.
   */
  @AuraEnabled
  @TestVisible
  public static List<Id> getQueueIds(Id userId) {
    Set<Id> groupsWithUser = new Set<Id>();
    //Populating the Group with User with GroupId we are filtering only for Group of Type Regular,Role and RoleAndSubordinates
    for (GroupMember u : [
      SELECT GroupId
      FROM GroupMember
      WHERE
        UserOrGroupId = :userId
        AND (Group.Type = 'Regular'
        OR Group.Type = 'Role'
        OR Group.Type = 'RoleAndSubordinates')
    ]) {
      groupsWithUser.add(u.GroupId);
    }

    System.debug('Groups with user: ' + groupsWithUser);

    Map<Id, Id> groupRoleMap = new Map<Id, Id>();
    //Populating the Map with RelatedID(i.e.UserRoledId) as Key
    for (Group gr : [SELECT Id, RelatedId, Name FROM Group]) {
      groupRoleMap.put(gr.RelatedId, gr.Id);
    }

    Set<Id> memberOfGroupIds = new Set<Id>();
    for (User u : [SELECT UserRoleId FROM User WHERE Id = :userId]) {
      if (groupRoleMap.containsKey(u.UserRoleId)) {
        memberOfGroupIds.add(groupRoleMap.get(u.UserRoleId));
      }
    }

    memberOfGroupIds.addAll(groupsWithUser);

    //Traversing the whole list of Groups to check any other nested Group
    Map<Id, Id> grMap = new Map<Id, Id>();
    for (GroupMember gr : [
      SELECT Id, UserOrGroupId, GroupId
      FROM GroupMember
      WHERE
        Group.Type = 'Regular'
        OR Group.Type = 'Role'
        OR Group.Type = 'RoleAndSubordinates'
    ]) {
      grMap.put(gr.UserOrGroupId, gr.GroupId);
    }
    for (Id i : memberOfGroupIds) {
      if (grMap.containsKey(i)) {
        memberOfGroupIds.add(grMap.get(i));
      }
    }

    GroupMember[] queueMemberships = [
      SELECT Id, Group.Name, Group.Type, GroupId
      FROM GroupMember
      WHERE
        (UserOrGroupId IN :memberOfGroupIds
        OR UserOrGroupId = :userId)
        AND Group.QueueRoutingConfigId != NULL
    ];
    System.debug('Queues: ' + JSON.serializePretty(queueMemberships));
    Id[] queueIds = new List<Id>{};
    for (GroupMember member : queueMemberships) {
      queueIds.add(member.GroupId);
    }
    if (!queueIds.isEmpty())
      return queueIds;
    return null;
  }

  /**
   * Used to retrieve Queue status for supplied queue Ids. Generates a customer data structure containing informations
   * about the queue, such as name and number of items in queue.
   * @param queueIds Ids of queues to generate status records for
   * @return List of custom queue status data structure
   */
  @TestVisible
  @AuraEnabled
  public static QueueStatus[] getQueueStatus(Id[] queueIds) {
    Map<Id, QueueStatus> queueStatusById = new Map<Id, QueueStatus>();
    for (Group queue : [SELECT Id, Name FROM Group WHERE Id IN :queueIds]) {
      queueStatusById.put(queue.Id, new QueueStatus(queue.Id, queue.Name));
    }

    AggregateResult[] queueItems = new List<AggregateResult>{};
    AggregateResult[] messagingSessions = [
      SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name
      FROM MessagingSession
      WHERE OwnerId IN :queueIds AND Status IN ('New', 'Waiting')
      GROUP BY OwnerId, Owner.Name
    ];
    AggregateResult[] cases = [
      SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name
      FROM Case
      WHERE OwnerId IN :queueIds AND Status IN ('New', 'New Response')
      GROUP BY OwnerId, Owner.Name
    ];
    AggregateResult[] chatTranscripts = [
      SELECT COUNT(Id), MIN(CreatedDate), OwnerId, Owner.Name
      FROM LiveChatTranscript
      WHERE OwnerId IN :queueIds AND Status NOT IN ('Completed', 'Missed')
      GROUP BY OwnerId, Owner.Name
    ];
    queueItems.addAll(messagingSessions);
    queueItems.addAll(cases);
    queueItems.addAll(chatTranscripts);

    for (AggregateResult result : queueItems) {
      Id queueId = (String) result.get('OwnerId');
      Integer countWaiting = (Integer) result.get('expr0');
      Datetime oldestOpenTime = (Datetime) result.get('expr1');

      queueStatusById.get(queueId).addQueue(countWaiting, oldestOpenTime);
    }

    QueueStatus[] sortedQueueStatuses = queueStatusById.values();
    sortedQueueStatuses.sort();
    return sortedQueueStatuses;
  }

  /**
   * Custom class used as data structure to hold information about a queue, such as number of items waiting in queue.
   * The class is instantiated once per queue, but as queues can contain multiple SObject types which are retrieved separately,
   * the addQueue() method is used to supply information about queue.
   * Implements comparable interface to enable custom sorting.
   */
  @TestVisible
  private class QueueStatus implements Comparable {
    /**
     * Id of queue
     */
    @AuraEnabled
    public Id queueId { get; private set; }
    /**
     * Name of queue
     */
    @AuraEnabled
    public String queueName { get; private set; }
    /**
     * Number of items waiting in queue
     */
    @AuraEnabled
    public Integer countWaiting { get; private set; }
    /**
     * Datetime when the first item still waiting in queue was opened
     */
    private Datetime oldestOpenTime;
    /**
     * Formatted string to display the time since the first waiting item in the queue was opened.
     */
    @AuraEnabled
    public String longestWaitTime { get; private set; }

    /**
     * Constructor for class. Assigns initial values to class variables.
     * @param queueId Id of queue to hold information for
     * @param queueName Name of queue
     */
    public QueueStatus(Id queueId, String queueName) {
      this.queueId = queueId;
      this.queueName = queueName;
      this.countWaiting = 0;
      this.longestWaitTime = '--';
    }

    /**
     * Adds a new queue to the Queue status data structure. As records in queues are retrieved per object type,
     * this method is used to add e.g. queue status each object in the same queue.
     * @param countWaiting Number of items of a certain SObject type in queue
     * @param oldestOpenTime Datetime for when the oldest record  of a certain SObject type still waiting in queue was opened.
     */
    public void addQueue(Integer countWaiting, Datetime oldestOpenTime) {
      this.countWaiting += countWaiting;
      if (this.oldestOpenTime == null || this.oldestOpenTime > oldestOpenTime) {
        this.oldestOpenTime = oldestOpenTime;
        Integer minutesSinceOpen =
          (Integer) (Datetime.now().getTime() - this.oldestOpenTime.getTime()) /
          1000 /
          60;
        Integer days = minutesSinceOpen / 60 / 24;
        Integer hours = (minutesSinceOpen - days * 60 * 24) / 60;
        Integer minutes = minutesSinceOpen - days * 60 * 24 - hours * 60;
        this.longestWaitTime = '';
        if (days > 0)
          longestWaitTime += days + ' d, ';
        if (days > 0 || hours > 0)
          longestWaitTime += hours + ' h ';
        longestWaitTime += minutes + ' min';
      }
    }

    /**
     * Implementation if Comparable interface to enable custom sorting. Sorts QueueStatus depending on
     * number if items waiting in queue, where the most number of items should be first in a list.
     * @param compareTo QueueStatus data type to compare to
     * @return Sort order for compared record
     */
    public Integer compareTo(Object compareTo) {
      QueueStatus compareToQueueStatus = (QueueStatus) compareTo;
      if (this.countWaiting == compareToQueueStatus.countWaiting)
        return 0;
      if (this.countWaiting > compareToQueueStatus.countWaiting)
        return -1;
      return 1;
    }
  }
}
