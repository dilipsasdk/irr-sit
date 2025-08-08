public inherited sharing class EmailMessagesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      EmailMessage.Id,
      EmailMessage.ParentId,
      EmailMessage.Status,
      EmailMessage.ToAddress,
      EmailMessage.FromAddress,
      EmailMessage.CcAddress,
      EmailMessage.BccAddress,
      EmailMessage.Subject,
      EmailMessage.HtmlBody,
      EmailMessage.TextBody
    };
  }

  public Schema.SObjectType getSObjectType() {
    return EmailMessage.SObjectType;
  }

  public static EmailMessagesSelector newInstance() {
    return (EmailMessagesSelector) SAS_Service_Application.Selector.newInstance(
      EmailMessage.SObjectType
    );
  }

  public List<EmailMessage> selectById(Set<Id> ids) {
    return (List<EmailMessage>) selectSObjectsById(ids);
  }

  /**
   * Selects all Emails for a specific Case
   */
  public List<EmailMessage> selectByParentId(Set<Id> ids) {
    return (List<EmailMessage>) Database.query(
      newQueryFactory().setCondition('ParentId in :ids').toSOQL()
    );
  }
  public List<EmailMessage> selectByParentIdAndStatus(
    Set<Id> ids,
    Set<Id> createdBy,
    String status
  ) {
    return (List<EmailMessage>) Database.query(
      newQueryFactory()
        .setCondition(
          'ParentId in :ids AND CreatedById = :createdBy AND Status = :status'
        )
        .selectField(EmailMessage.Status)
        .toSOQL()
    );
  }
}
