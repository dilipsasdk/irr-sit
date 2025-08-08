/**
Extensible class used to wipe the of interactions
The batch processes interactions which are not associated to a case
and ensures that wiping period should greate than Case wiping.
*/
global class GDPR_WipeInteraction_Batch extends SBS_ScheduledBatch {
  /**
The sobject name of the interaction sobject
*/
  private String sObjectName;
  /**
The field which links the interaction with a case and thus should be excluded
*/
  private String caseField;
  /**
The date till which interaction will be retained with wiping.
*/
  @TestVisible
  private DateTime lastRetentionDate;
  /**
The list of fields needs to be wiped for batch job Object
*/
  private List<String> lstFieldsToClear;
  /**
The ScheduleBatchRunComponent record id for this particualr batch
    used to update the record with totalNumberOfRecords Deleted
    */
  String scheduledBatchRunComponentId;
  /**
Used to count the totalnumber of records Wiped.
    */
  Integer totalNumberOfRecordsWiped = 0;

  global GDPR_WipeInteraction_Batch() {
  }
  /**
Overiding of the abstract method used to set the Batch class params
*/
  global override void setVariables(
    String SObj,
    Integer retentionPeriod,
    string caseField,
    string caseType,
    String batchName,
    String scheduledBatchRunComponentId
  ) {
    lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-retentionPeriod),
      Time.newInstance(0, 0, 0, 0)
    );
    Schema.SObjectType sot = Schema.getGlobalDescribe().get(SObj);
    this.sObjectName = sot + '';
    this.caseField = caseField != null ? caseField + '' : null;
    lstFieldsToClear = GDPR_Util.getCaseFieldsToClear(this.sObjectName);
  }

  /**
Iterates over all interactions to be processed
@param bc The batch context
*/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String q = 'SELECT Id, CreatedDate';
    q += ' FROM ' + sObjectName + ' WHERE ';
    q = caseField != null ? q + caseField + '=null AND ' : q;
    q += 'lastModifieddate<:lastRetentionDate AND GDPR_Wiped__c!=true';
    return Database.getQueryLocator(q);
  }

  /**
wipe the interactions of the Channel object records without case
@param bc The batchable context of the batch job
@param sObjScope The interactions to delete
*/
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    List<SObject> lstSobjects = GDPR_Util.createSobjectFieldsToClear(
      sObjScope,
      sObjectName
    );

    totalNumberOfRecordsWiped = totalNumberOfRecordsWiped + lstSobjects.size();

    update lstSobjects;
  }

  global override void finishOverridable(Database.BatchableContext bc) {
    if (scheduledBatchRunComponentId != null) {
      SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
        Id = scheduledBatchRunComponentId,
        Total_Number_Of_Records_Processed__c = sObjectName +
          ':' +
          String.valueOf(totalNumberOfRecordsWiped)
      );
      update sbrc;
    }
  }
}
