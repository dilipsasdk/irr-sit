public inherited sharing class MessagingSessionsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      MessagingSession.Id,
      MessagingSession.caseId,
      MessagingSession.messagingEndUserId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return MessagingSession.SObjectType;
  }

  public static MessagingSessionsSelector newInstance() {
    return (MessagingSessionsSelector) SAS_Service_Application.Selector.newInstance(
      MessagingSession.SObjectType
    );
  }

  public List<MessagingSession> selectById(Set<Id> ids) {
    return (List<MessagingSession>) selectSObjectsById(ids);
  }

  public List<MessagingSession> selectByMessagingEndUserId(
    Set<Id> mesgEndUserIds
  ) {
    fflib_QueryFactory mesgSessionsQF = newQueryFactory()
      .setCondition('messagingEndUserId in :mesgEndUserIds');
    return (List<MessagingSession>) Database.query(mesgSessionsQF.toSOQL());
  }
}
