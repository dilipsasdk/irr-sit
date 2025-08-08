/**
Extensible class used to wipe the deletion of interactions
The batch processes interactions which are not associated to a case
and ensures that wiping period should greate than Case wiping.
*/
global class GDPR_DeleteInteraction_Batch extends SBS_ScheduledBatch {
  /**
  The sobject name of the interaction sobject
  */
  private String sObjectName;
  /**
  The field which links the interaction with a case and thus should be excluded
  */
  private String caseField;
  /**
  SObject name of related SObject which should be removed as well
  */

  private String relSObjName;
  /**
  The field on the primary obejct which links the primary object to the parent object
  */
  private String relSObjField;
  /**
  The date until which to retain the record related to specified sobject
  */
  @testVisible
  private DateTime lastRetentionDate;
  /**
    The ScheduleBatchRunComponent record id for this particualr batch
    used to update the record with totalNumberOfRecords Deleted
    */
  String scheduledBatchRunComponentId;
  /**
    Used to count the totalnumber of records deleted.
    */
  Integer totalNumberOfRecordsDeleted = 0;
  /**
   Used to Count the totalnumber of related records deleted
   */
  Integer totalNumberOfRelatedRecordsDeleted = 0;

  global GDPR_DeleteInteraction_Batch() {
  }

  /**
  Overiding of the abstract method used to set the Batch class params
  */
  global override void setVariables(
    String sObj,
    Integer retentionPeriod,
    string caseField,
    String caseType,
    String batchName,
    String scheduledBatchRunComponentId
  ) {
    lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-retentionPeriod),
      Time.newInstance(0, 0, 0, 0)
    );
    Schema.SObjectType sot = Schema.getGlobalDescribe().get(sObj);
    this.sObjectName = sot + '';
    this.caseField = caseField != null ? caseField + '' : null;

    List<GDPR_Retention_Policy__mdt> lstMdtRelObject = [
      SELECT
        DeveloperName,
        GDPR_Related_Channel_Object__c,
        GDPR_Related_Channel_Object__r.Related_SObject_Name__c,
        GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c
      FROM GDPR_Retention_Policy__mdt
      WHERE
        GDPR_Related_Channel_Object__c != NULL
        AND DeveloperName = :batchName
      LIMIT 1
    ];
    if (!lstMdtRelObject.isEmpty()) {
      this.relSObjName = lstMdtRelObject[0]
        .GDPR_Related_Channel_Object__r.Related_SObject_Name__c;
      this.relSObjField = lstMdtRelObject[0]
        .GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c;
    }
  }

  /**
  Iterates over all interactions to be processed
  @param bc The batch context
  */
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String q = 'SELECT Id, CreatedDate';
    q = relSObjField != null ? q + ', ' + relSObjField : q;
    q += ' FROM ' + sObjectName + ' WHERE ';
    q = caseField != null ? q + caseField + '=null AND ' : q;
    q += 'LastModifiedDate<:lastRetentionDate';
    return Database.getQueryLocator(q);
  }

  /**
  Deletes the interactions which should be deleted according to the retention logic
  @param bc The batchable context of the batch job
  @param sObjScope The interactions to delete
  */
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    Set<Id> relIds = new Set<Id>();

    for (SObject sObj : sObjScope) {
      if (relSObjField != null) {
        Id relId = (Id) sObj.get(relSObjField);
        if (relId != null)
          relIds.add(relId);
      }
    }
    totalNumberOfRecordsDeleted =
      totalNumberOfRecordsDeleted + sObjScope.size();
    delete sObjScope;

    if (!relIds.isEmpty()) {
      SObject[] relRecs = Database.query(
        'SELECT Id FROM ' +
        relSObjName +
        ' WHERE Id IN :relIds AND Id NOT IN (SELECT ' +
        relSObjField +
        ' FROM ' +
        sObjectName +
        ' WHERE ' +
        relSObjField +
        ' IN :relIds)'
      );
      totalNumberOfRelatedRecordsDeleted =
        totalNumberOfRelatedRecordsDeleted + relRecs.size();
      delete relRecs;
    }
  }
  global override void finishOverridable(Database.BatchableContext bc) {
    if (scheduledBatchRunComponentId != null) {
      SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
        Id = scheduledBatchRunComponentId,
        Total_Number_Of_Records_Processed__c = sObjectName +
          ':' +
          String.valueOf(totalNumberOfRecordsDeleted) +
          ', ' +
          relSObjName +
          ':' +
          String.valueOf(totalNumberOfRelatedRecordsDeleted)
      );
      update sbrc;
    }
  }
}
