/**
    Deletes all accounts which no longer have any cases associated to it
    @author Peter Södergren
*/
global with sharing class GDPR_DeleteAccount_Batch extends SBS_ScheduledBatch {
  /**
        Iterates over all person accounts
        @param bc The batch context
    */
  /**
    The ScheduleBatchRunComponent record id for this particualr batch
    used to update the record with totalNumberOfRecords Deleted
    */
  String scheduledBatchRunComponentId;
  /**
    Used to count the totalnumber of records deleted.
    */
  Integer totalNumberOfRecordsDeleted = 0;

  global override void setVariables(
    String obj,
    Integer retentionPeriod,
    string caseField,
    String caseType,
    String batchName,
    String scheduledBatchRunComponentId
  ) {
    this.scheduledBatchRunComponentId = scheduledBatchRunComponentId;
  }
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id FROM Account WHERE IsPersonAccount=true'
    );
  }

  /**
        Deletes the accounts if they have no cases
        @param bc The batchable context of the batch job
        @param sObjScope The accounts to process whether they have cases or not
    */
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    Set<Id> accIds = C_Util.getIdSet(sObjScope);
    accIds.removeAll(
      C_Util.getIdSet(
        [
          SELECT Id
          FROM Account
          WHERE
            Id IN :accIds
            AND Id IN (SELECT AccountId FROM Case WHERE AccountId IN :accIds)
        ]
      )
    );
    accIds.removeAll(
      C_Util.getIdSet(
        [
          SELECT Id
          FROM Account
          WHERE
            Id IN :accIds
            AND Id IN (
              SELECT ParentId
              FROM SocialPersona
              WHERE ParentId IN :accIds
            )
        ]
      )
    );
    accIds.removeAll(
      C_Util.getIdSet(
        [
          SELECT Id
          FROM Account
          WHERE
            Id IN :accIds
            AND Id IN (
              SELECT AccountId
              FROM LiveChatTranscript
              WHERE AccountId IN :accIds
            )
        ]
      )
    );
    accIds.removeAll(
      C_Util.getIdSet(
        [
          SELECT Id
          FROM Account
          WHERE
            Id IN :accIds
            AND Id IN (
              SELECT AccountId
              FROM MessagingEndUser
              WHERE AccountId IN :accIds
            )
        ]
      )
    );
    accIds.removeAll(
      C_Util.getIdSet(
        [
          SELECT Id
          FROM Account
          WHERE
            Id IN :accIds
            AND Id IN (
              SELECT Account__c
              FROM Passenger__c
              WHERE Account__c IN :accIds
            )
        ]
      )
    );
    totalNumberOfRecordsDeleted = +accIds.size();
    delete [SELECT Id FROM Account WHERE Id IN :accIds];
  }
  global override void finishOverridable(Database.BatchableContext bc) {
    if (scheduledBatchRunComponentId != null) {
      SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
        Id = scheduledBatchRunComponentId,
        Total_Number_Of_Records_Processed__c = 'Account:' +
          String.valueOf(totalNumberOfRecordsDeleted)
      );
      update sbrc;
    }
  }
}
