public inherited sharing class ContentVersionsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      ContentVersion.Id,
      ContentVersion.ContentDocumentId,
      ContentVersion.PathOnClient,
      ContentVersion.Title,
      ContentVersion.VersionData,
      ContentVersion.FileExtension
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ContentVersion.SObjectType;
  }

  public static ContentVersionsSelector newInstance() {
    return (ContentVersionsSelector) SAS_Service_Application.Selector.newInstance(
      ContentVersion.SObjectType
    );
  }

  public List<ContentVersion> selectById(Set<Id> ids) {
    return (List<ContentVersion>) selectSObjectsById(ids);
  }

  /**
   * If withVersionData is true, returns also VersionData for the ContentVersions.
   */
  public List<ContentVersion> selectById(Set<Id> ids, Boolean withVersionData) {
    if (withVersionData) {
      return (List<ContentVersion>) Database.query(
        newQueryFactory()
          .setCondition('Id in :ids')
          .selectField(ContentVersion.VersionData)
          .toSOQL()
      );
    } else {
      return selectById(ids);
    }
  }

  public List<ContentVersion> selectByTitle(String name) {
    return (List<ContentVersion>) Database.query(
      newQueryFactory().setCondition('Title = :name').toSOQL()
    );
  }

  public List<ContentVersion> selectByContentDocumentId(Id contentDocumentId) {
    return (List<ContentVersion>) Database.query(
      newQueryFactory().setCondition('ContentDocumentId = :contentDocumentId AND IsLatest = TRUE').toSOQL()
    );
  }
}
