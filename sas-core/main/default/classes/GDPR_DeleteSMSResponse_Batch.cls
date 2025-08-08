/**
    Batch class which ensures that all Communication Logs are deleted after
    X number of days of created date.
    @author Ludvig Wälimaa
*/
global with sharing class GDPR_DeleteSMSResponse_Batch extends SBS_ScheduledBatch {
  /**
        The date at which Communication Logs will be removed
    */
  private DateTime lastRetentionDate;
  /**
        Initiates the batch class and extracts the date used to filter out Communication Logs for removal
    */
  global GDPR_DeleteSMSResponse_Batch() {
    this.setUseTransactionControl(false);
  }
  /**
   overriding the absract method to set batch class Params
   */
  global override void setVariables(
    String obj,
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
  }

  /**
        Iterates over all Communication Logs before the retention period
        @param bc The batch context
    */
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return IRR_SEL_SMSResponsesSelector.newInstance()
      .getGDPRLogsQueryLocator(lastRetentionDate);
  }

  /**
        Deletes the Communication Logs 
        @param bc The batchable context of the batch job
        @param sObjScope The Communication Logs to delete
    */
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    delete sObjScope;
  }
}