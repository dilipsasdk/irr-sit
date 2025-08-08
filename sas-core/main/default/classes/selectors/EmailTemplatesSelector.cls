public inherited sharing class EmailTemplatesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      EmailTemplate.Id,
      EmailTemplate.Body,
      EmailTemplate.HtmlValue,
      EmailTemplate.Name,
      EmailTemplate.Subject
    };
  }

  public Schema.SObjectType getSObjectType() {
    return EmailTemplate.SObjectType;
  }

  public static EmailTemplatesSelector newInstance() {
    return (EmailTemplatesSelector) SAS_Service_Application.Selector.newInstance(
      EmailTemplate.SObjectType
    );
  }

  public List<EmailTemplate> selectById(Set<Id> ids) {
    return (List<EmailTemplate>) selectSObjectsById(ids);
  }

  public List<EmailTemplate> selectByName(Set<String> names) {
    return (List<EmailTemplate>) Database.query(
      newQueryFactory().setCondition('Name in :names').toSOQL()
    );
  }
}
