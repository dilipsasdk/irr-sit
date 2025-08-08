/**
    Contains test batches used to test scheduled batch service
    @author Peter Södergren
*/
global class SBS_ScheduledBatch_Test extends SBS_ScheduledBatch {
  /**
        Set to true to throw an exception on init
    */
  global static Boolean THROW_INIT_EXCEPTION = false;
  /**
        Set to true to throw an exception on execute
    */
  global static Boolean THROW_EXCEPTION = false;
  /**
        Set to true to throw an exception on finish
    */
  global static Boolean THROW_FINISH_EXCEPTION = false;
  /**
        Whether to disabled transaction control for the batch
    */
  global static Boolean DISABLE_TRANSACTION_CONTROL = false;
  /**
        Counter for the number of times which the start method has fired.
    */
  global static Integer START_COUNT = 0;
  /**
        Counter for the number of times which the execute method has fired.
    */
  global static Integer EXECUTE_COUNT = 0;
  /**
        Counter for the number of times which the finish method has fired.
    */
  global static Integer FINISH_COUNT = 0;
  /**
        Set to true to add a custom error
    */
  global static Boolean CUSTOM_ERROR = false;
  /**
        Initializes the batch job
    */
  global SBS_ScheduledBatch_Test() {
    START_COUNT++;
    if (DISABLE_TRANSACTION_CONTROL)
      setUseTransactionControl(false);
    if (THROW_INIT_EXCEPTION)
      throw new TypeException('TEST INIT EXCEPTION');
  }
  global override void setVariables(
    String obj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    string batchName,
    String scheduledBatchRunComponentId
  ) {
  }
  /**
        Starts batch on a list of a single user
        @param bc The batch context
    */
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
    EXECUTE_COUNT++;
    if (THROW_EXCEPTION)
      throw new TypeException('TEST EXCEPTION');
    else if (CUSTOM_ERROR)
      addError('ERROR MESSAGE', null, sObjScope);
  }

  /**
        Custom logic on batch finish
        @param bc The batch context
    */
  global override void finishOverridable(Database.BatchableContext bc) {
    FINISH_COUNT++;
    if (THROW_FINISH_EXCEPTION)
      throw new TypeException('TEST FINISH EXCEPTION');
  }
}