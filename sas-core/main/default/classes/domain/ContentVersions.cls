public without sharing class ContentVersions extends ApplicationDomain {
  public ContentVersions(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<ContentVersion>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new ContentVersions(records);
    }
  }

  private List<ContentVersion> instanceRecords;

  public static ContentVersions newInstance(List<ContentVersion> sObjectList) {
    return (ContentVersions) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public override void onAfterInsert() {
    handleRacerFiles();
    handleCurrencyFiles();
  }

  /**
   * Moves the records to the ContentFolder with the given Id.
   *
   * ContentDocuments are linked to folders through a ContentFolderMember
   * record.
   */
  public void moveToFolder(Id folderToMoveTo) {
    List<ContentFolderMember> toUpdate = new List<ContentFolderMember>();

    Set<Id> recordIds = new Set<Id>();

    for (ContentVersion cv : instanceRecords) {
      recordIds.add(cv.ContentDocumentId);
    }

    List<ContentFolderMember> existingFolderMemberships = [
      SELECT Id, ParentContentFolderId
      FROM ContentFolderMember
      WHERE ChildRecordId IN :recordIds
    ];

    for (ContentFolderMember cfm : existingFolderMemberships) {
      cfm.ParentContentFolderId = folderToMoveTo;
      toUpdate.add(cfm);
    }

    if (!toUpdate.isEmpty()) {
      try {
        update toUpdate;
      } catch (Exception e) {
        C_Log.log(
          C_Log.Severity.Error,
          e.getMessage(),
          null,
          'ContentVersions',
          null
        );
      }
    }
  }

  /**
   * Moves the records to the ContentWorkspace with the given Id.
   *
   * ContentDocuments are linked to workspaces through a ContentDocumentLink
   * record.
   */
  public void moveToWorkspace(Id workspaceToMoveTo) {
    List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();

    for (ContentVersion cv : instanceRecords) {
      if (cv.ContentDocumentId != null) {
        toInsert.add(
          new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = workspaceToMoveTo,
            Visibility = 'AllUsers'
          )
        );
      }
    }

    if (!toInsert.isEmpty()) {
      try {
        insert toInsert;
      } catch (DmlException e) {
        C_Log.log(
          C_Log.Severity.Error,
          e.getMessage(),
          null,
          'ContentVersions',
          null
        );
      }
    }
  }

  private void handleRacerFiles() {
    List<Id> racerFileIds = new List<Id>();

    for (ContentVersion cv : instanceRecords) {
      if (RacerResponseHandlers.isARacerFile(cv.Title, cv.OwnerId)) {
        racerFileIds.add(cv.Id);
      }
    }
    if (racerFileIds.size() > 0) {
      System.enqueueJob(
        new RacerResponseHandlers.HandleRacerResponseQueueable(racerFileIds)
      );
    }
  }

  private void handleCurrencyFiles() {
    List<Id> currencyFileIds = new List<Id>();

    for (ContentVersion cv : (List<ContentVersion>) Records) {
      if (cv.Title.startsWith(ExchangeRates.CURRENCY_FILE_NAME)) {
        currencyFileIds.add(cv.Id);
      }
    }
    if (currencyFileIds.size() > 0) {
      ExchangeRates.handleCurrencyFiles(currencyFileIds);
    }
  }
}
