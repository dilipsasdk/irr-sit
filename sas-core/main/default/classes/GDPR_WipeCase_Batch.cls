/**
Batch class which ensures that  cases and related entities wiped after X number of days after case close for an specified caseType. 
*/
global with sharing class GDPR_WipeCase_Batch extends SBS_ScheduledBatch {
  /**
The sobject name of the interaction sobject
*/
  private String sObjectName;
  /**
The date till the case and related object data needs to be retained without wiping
*/
  @TestVisible
  private DateTime lastRetentionDate;
  /**
The fields to clear for the case
*/
  private String[] fieldsToClear;
  /**
The Case Type in which batch job executes
*/
  private string caseType;
  /**
  The Name of the batch in GDPR Retention policy metaData, based on which related metadata will be retrived
  */
  private string batchName;
  /**
   Map to store the objectName and totdal number of records deleted for each batch
  */
  Map<String, Integer> mapSobjectToTalNumberOfRecordsWiped = new Map<String, Integer>();
  /**
    The ScheduleBatchRunComponent record id for this particualr batch
    used to update the record with totalNumberOfRecords Deleted
    */
  String scheduledBatchRunComponentId;

  global GDPR_WipeCase_Batch() {
  }

  /**
Overiding of the abstract method used to set the Batch class params
*/
  global override void setVariables(
    String obj,
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
    Schema.SObjectType sot = Schema.getGlobalDescribe().get(obj);
    this.sObjectName = sot + '';
    fieldsToClear = GDPR_Util.getCaseFieldsToClear(this.sObjectName);
    this.caseType = caseType;
    this.batchName = batchName;
    this.scheduledBatchRunComponentId = scheduledBatchRunComponentId;
  }

  /**
Iterates over all cases closed before the retention period
@param bc The batch context
*/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id FROM Case WHERE IsClosed=true AND ClosedDate<:lastRetentionDate AND FCS_CaseType__c=:caseType AND GDPR_Wiped__c!=true'
    );
  }
  /**
wipe the cases and any related interactions
- Chat Transcripts
- Emails
- Messaging Sessions
- Social Posts
@param bc The batchable context of the batch job
@param sObjScope The cases to delete
*/
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    Map<String, Integer> mapSobjecNumberOfWipedRecords = GDPR_WipeCaseService.wipeCases(
      (Case[]) sObjScope,
      fieldsToClear,
      batchName
    );
    for (String sObjName : mapSobjecNumberOfWipedRecords.keySet()) {
      if (mapSobjectToTalNumberOfRecordsWiped.containsKey(sObjName)) {
        Integer DeletedRecords =
          mapSobjectToTalNumberOfRecordsWiped.get(sObjName) +
          mapSobjectToTalNumberOfRecordsWiped.get(sObjName);
        mapSobjectToTalNumberOfRecordsWiped.put(sObjName, DeletedRecords);
      } else {
        mapSobjectToTalNumberOfRecordsWiped.put(
          sObjName,
          mapSobjecNumberOfWipedRecords.get(sObjName)
        );
      }
    }
  }
  global override void finishOverridable(Database.BatchableContext bc) {
    String TotalSobjectAndRecordsWiped;
    for (String SObjectName : mapSobjectToTalNumberOfRecordsWiped.keySet()) {
      if (TotalSobjectAndRecordsWiped != null) {
        TotalSobjectAndRecordsWiped =
          SObjectName +
          ':' +
          String.valueOf(mapSobjectToTalNumberOfRecordsWiped.get(SObjectName));
      } else {
        TotalSobjectAndRecordsWiped =
          TotalSobjectAndRecordsWiped +
          ', ' +
          SObjectName +
          ':' +
          String.valueOf(mapSobjectToTalNumberOfRecordsWiped.get(SObjectName));
      }
    }
    if (scheduledBatchRunComponentId != null) {
      SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
        Id = scheduledBatchRunComponentId,
        Total_Number_Of_Records_Processed__c = TotalSobjectAndRecordsWiped
      );

      update sbrc;
    }
  }
}
