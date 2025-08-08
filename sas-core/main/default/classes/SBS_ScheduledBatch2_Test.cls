/**
    Test batch variant to check that it is possible to run the batch without an overriding finish method or a constructor
    @author Peter Södergren
*/
global class SBS_ScheduledBatch2_Test extends SBS_ScheduledBatch {
  /**
        Starts batch on a list of a single user
        @param bc The batch context
    */
  global override void setVariables(
    String obj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    string batchName,
    string scheduledBatchRunComponentId
  ) {
  }
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
  }
  /**
        Main execution which runs according to the static setting
        @param bc The batch context
        @param sObjScope The sobjects which should be processed
    */
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
  }
}