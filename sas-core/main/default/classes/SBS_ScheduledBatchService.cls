/**
  Scheduled batch service which provies a service for running scheduled batches
  based upon a configured set of batches which run at most once per day
  at different intervals.
  The batch components are stored in the custom metadata object ScheduledBatchComponent__mdt
  The service ensures that the scheduled batches are run once and are run in the correct order,
  determined by the components priority.
  @author Peter Södergren
*/
global with sharing class SBS_ScheduledBatchService {
  private static final String SCHEDULE_DAILY = 'Daily';
  private static final String SCHEDULE_DAY_OF_WEEK = 'Day Of Week';
  private static final String SCHEDULE_DAY_OF_MONTH = 'Day Of Month';
  private static final String SCHEDULE_LAST_DAY_OF_MONTH = 'Last Day Of Month';
  private static final String SCHEDULE_DAY_OF_YEAR = 'Day Of Year';

  public static final String BATCH_RUN_STATUS_STARTED = 'Started';
  public static final String BATCH_RUN_STATUS_SUCCESS = 'Success';
  public static final String BATCH_RUN_STATUS_FAIL = 'Fail';
  public static final String BATCH_RUN_CMP_STATUS_SCHEDULED = 'Scheduled';
  public static final String BATCH_RUN_CMP_STATUS_STARTED = 'Started';
  public static final String BATCH_RUN_CMP_STATUS_INIT_ERROR = 'Init Error';
  public static final String BATCH_RUN_CMP_STATUS_SUCCESS = 'Success';
  public static final String BATCH_RUN_CMP_STATUS_FAIL = 'Fail';

  public static final String ASYNC_APEX_JOB_STATUS_COMPLETED = 'Completed';
  /**
        List of batch components which offers test classes the ability to override the scheduled batch components retrieved by the service
    */
  @TestVisible
  private static List<GDPR_Retention_Policy__mdt> BATCH_CMP_LIST_OVERRIDE;
  /**
    Override of the current date which enables test class to simulate another date than the actual date
  */
  @TestVisible
  private static Date CURRENT_DATE_OVERRIDE;

  /**
    Custom exception thrown due to errors in scheduled batch run internals.
  */
  public class ScheduledBatchRunException extends Exception {
  }

  /**
    Primary method for starting the scheduld batch
    Fetches the scheduled batch components and filters the list depending on day and time segment
    Then runs the batches sequnetially
    @param timeSegment The time segment for which to run the batches
  */
  public static void run(String timeSegment) {
    run(getBatchClassesForToday(timeSegment, true));
  }

  /**
    Fetches the batch classes to run at the current date based upon the contents of the batch component list
    filtered by the current date, and time segment and ordered in priority
    @param timeSegment The time segment for which to fetch the batches
    @param createRunRecords Whether records which store the run information should be created
    @return The list of batch classes to run in a scheduled batch run object
  */
  public static ScheduledBatchRun getBatchClassesForToday(
    String timeSegment,
    Boolean createRunRecords
  ) {
    List<GDPR_Retention_Policy__mdt> batchCmpList = BATCH_CMP_LIST_OVERRIDE !=
      null
      ? BATCH_CMP_LIST_OVERRIDE
      : [
          SELECT
            DeveloperName,
            Object__c,
            Related_Case_Field__c,
            Retention_Period_Days__c,
            Type__c,
            Scheduled_Batch_Component__r.Class__c,
            Scheduled_Batch_Component__r.Schedule__c,
            Scheduled_Batch_Component__r.DayOfWeek__c,
            Scheduled_Batch_Component__r.DayOfMonth__c,
            Scheduled_Batch_Component__r.MonthOfYear__c,
            Scheduled_Batch_Component__r.WorkingDayOffset__c,
            Scheduled_Batch_Component__r.OnlyExecuteOnWorkingDays__c,
            Scheduled_Batch_Component__r.ScopeSize__c,
            Scheduled_Batch_Component__r.Priority__c,
            Scheduled_Batch_Component__r.Group__c
          FROM GDPR_Retention_Policy__mdt
          WHERE
            Scheduled_Batch_Component__r.Active__c = TRUE
            AND Scheduled_Batch_Component__r.TimeSegment__c = :timeSegment
        ];
    List<BatchExecution> batches = new List<BatchExecution>();
    for (GDPR_Retention_Policy__mdt batchCmp : batchCmpList) {
      try {
        Type t = Type.forName(batchCmp.Scheduled_Batch_Component__r.Class__c);
        //Create new instance to ensure that the all components work
        //SBS_ScheduledBatch b = (SBS_ScheduledBatch)t.newInstance();
        Boolean include = false;
        if (batchCmp.Scheduled_Batch_Component__r.Schedule__c == SCHEDULE_DAILY)
          include = true;
        if (
          batchCmp.Scheduled_Batch_Component__r.Schedule__c ==
          SCHEDULE_DAY_OF_WEEK
        ) {
          Date occurrence = C_CalendarUtil.getPrevOccurrenceOfDay(
            Integer.valueOf(batchCmp.Scheduled_Batch_Component__r.DayOfWeek__c),
            getCurrentDate(),
            true
          );
          if (
            isCurrentDateWhenApplyingWorkingDayOffset(
              occurrence,
              Integer.valueOf(
                batchCmp.Scheduled_Batch_Component__r.WorkingDayOffset__c
              )
            )
          ) {
            include = true;
          }
        }
        if (
          batchCmp.Scheduled_Batch_Component__r.Schedule__c ==
          SCHEDULE_DAY_OF_MONTH
        ) {
          Date occurrence = getCurrentDate()
            .addDays(
              ((Integer) batchCmp.Scheduled_Batch_Component__r.DayOfMonth__c) -
              getCurrentDate().day()
            );
          if (occurrence > getCurrentDate())
            occurrence = occurrence.addMonths(-1);
          if (
            isCurrentDateWhenApplyingWorkingDayOffset(
              occurrence,
              Integer.valueOf(
                batchCmp.Scheduled_Batch_Component__r.WorkingDayOffset__c
              )
            )
          ) {
            include = true;
          }
        }
        if (
          batchCmp.Scheduled_Batch_Component__r.Schedule__c ==
          SCHEDULE_LAST_DAY_OF_MONTH
        ) {
          Date occurrence = getCurrentDate();
          if (occurrence.month() == occurrence.addDays(1).month()) {
            occurrence = occurrence.addDays(-occurrence.day());
          }
          if (
            isCurrentDateWhenApplyingWorkingDayOffset(
              occurrence,
              Integer.valueOf(
                batchCmp.Scheduled_Batch_Component__r.WorkingDayOffset__c
              )
            )
          ) {
            include = true;
          }
        }
        if (
          batchCmp.Scheduled_Batch_Component__r.Schedule__c ==
          SCHEDULE_DAY_OF_YEAR
        ) {
          Date occurrence = Date.newInstance(
            getCurrentDate().year(),
            Integer.valueOf(
              batchCmp.Scheduled_Batch_Component__r.MonthOfYear__c
            ),
            (Integer) batchCmp.Scheduled_Batch_Component__r.DayOfMonth__c
          );
          if (occurrence > getCurrentDate())
            occurrence = occurrence.addYears(-1);
          if (
            isCurrentDateWhenApplyingWorkingDayOffset(
              occurrence,
              Integer.valueOf(
                batchCmp.Scheduled_Batch_Component__r.WorkingDayOffset__c
              )
            )
          ) {
            include = true;
          }
        }
        if (include) {
          if (
            batchCmp.Scheduled_Batch_Component__r.OnlyExecuteOnWorkingDays__c
          ) {
            if (
              !C_CalendarUtil.isHoliday(getCurrentDate()) &&
              !C_CalendarUtil.isWeekend(getCurrentDate())
            ) {
              batches.add(
                new BatchExecution(
                  batchCmp.DeveloperName,
                  t,
                  (Integer) batchCmp.Scheduled_Batch_Component__r.ScopeSize__c,
                  batchCmp.Scheduled_Batch_Component__r.Group__c,
                  batchCmp.Object__c,
                  (Integer) batchCmp.Retention_Period_Days__c,
                  batchCmp.Related_Case_Field__c,
                  batchCmp.Type__c
                )
              );
            }
          } else {
            batches.add(
              new BatchExecution(
                batchCmp.DeveloperName,
                t,
                (Integer) batchCmp.Scheduled_Batch_Component__r.ScopeSize__c,
                batchCmp.Scheduled_Batch_Component__r.Group__c,
                batchCmp.Object__c,
                (Integer) batchCmp.Retention_Period_Days__c,
                batchCmp.Related_Case_Field__c,
                batchCmp.Type__c
              )
            );
          }
        }
      } catch (Exception e) {
        BatchExecution be = new BatchExecution(
          batchCmp.DeveloperName,
          null,
          null,
          null,
          null,
          null,
          null,
          null
        );
        be.customError = true;
        be.customErrorText = (e.getMessage() +
        '\n\n' +
        e.getStackTraceString());
        batches.add(be);
      }
    }
    ScheduledBatchRun sbr = new ScheduledBatchRun(batches);
    if (createRunRecords)
      sbr.setupRunRecord(timeSegment);
    return sbr;
  }

  /**
    Returns whether the supplied date with the given working day offset
    will become the current date.
    The values for the working day offet is
    - 0: No working day considerations
    - 1: The first working day from this date (including the date itself)
    - 2: The second working day from this date (including the date itself)
    ... and so on.
    @param d The date
    @param workingDayOffset The working day offset of the batch component
    @return Whether the supplied date is the current date when applying the working day offset
  */
  private static Boolean isCurrentDateWhenApplyingWorkingDayOffset(
    Date d,
    Integer workingDayOffset
  ) {
    while (workingDayOffset > 0) {
      if (!C_CalendarUtil.isHoliday(d) && !C_CalendarUtil.isWeekend(d)) {
        workingDayOffset--;
        if (workingDayOffset <= 0)
          break;
      }
      d = d.addDays(1);
    }
    return d == getCurrentDate();
  }

  /**
    Retrieves the durrent date with the possibility for test classes to override what day is the current date
    @return The current date
  */
  private static Date getCurrentDate() {
    return CURRENT_DATE_OVERRIDE != null ? CURRENT_DATE_OVERRIDE : Date.today();
  }

  /**
    Runs the first batch in the class chain and sets the subsequent batches to be a
    list of the current included class list except the batch currently run.
    This method is both called when starting the batch and by each dauly batch when finishing.
    This ensures that all batches in the chain are run once and are run in order.
    @param sbr The current scheduled batch run
  */
  public static void run(ScheduledBatchRun sbr) {
    if (sbr.executingBatchIdx != null) {
      BatchExecution be = sbr.batches[sbr.executingBatchIdx];
      if (be.jobId != null) {
        AsyncApexJob aaj = [
          SELECT Id, TotalJobItems, NumberOfErrors, Status, ExtendedStatus
          FROM AsyncApexJob
          WHERE Id = :be.jobId
        ];
        Boolean success =
          aaj.Status == ASYNC_APEX_JOB_STATUS_COMPLETED &&
          (aaj.NumberOfErrors == null ||
          aaj.NumberOfErrors == 0);
        be.success = be.customError != true && success;
        if (be.scheduledBatchRunComponentId != null) {
          //Retrieve stored errors to ensure that they are fetched as well.
          Integer storedErrors = Database.countQuery(
            'SELECT COUNT() FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c=\'' +
            be.scheduledBatchRunComponentId +
            '\''
          );
          if (storedErrors > 0)
            be.success = false;
          SBS_ScheduledBatchRunComponent__c sbrc = [
            SELECT Id, ApexJobId__c
            FROM SBS_ScheduledBatchRunComponent__c
            WHERE Id = :be.scheduledBatchRunComponentId
          ];
          sbrc.TotalBatches__c = aaj.TotalJobItems;
          sbrc.TotalErrors__c = aaj.NumberOfErrors + storedErrors;
          sbrc.FinishTime__c = DateTime.now();
          if (be.success) {
            sbrc.Status__c = BATCH_RUN_CMP_STATUS_SUCCESS;
          } else {
            sbrc.Status__c = BATCH_RUN_CMP_STATUS_FAIL;
            if (String.isBlank(be.customErrorText))
              sbrc.ErrorMessage__c = aaj.Status + '\n\n' + aaj.ExtendedStatus;
            else
              sbrc.ErrorMessage__c = be.customErrorText.abbreviate(30000);
          }
          update sbrc;
        }
      } else
        be.success = false;
      sbr.executingBatchIdx++;
    } else
      sbr.executingBatchIdx = 0;

    if (sbr.executingBatchIdx < sbr.batches.size()) {
      BatchExecution be = sbr.batches[sbr.executingBatchIdx];
      if (be.batchClass != null) {
        Id apexJobId = null;
        Boolean error = false;
        Boolean groupError = false;
        if (!String.isBlank(be.groupName)) {
          for (Integer i = 0; i < sbr.executingBatchIdx; i++) {
            if (
              sbr.batches[i].groupName == be.groupName &&
              !sbr.batches[i].success
            )
              groupError = true;
          }
        }
        if (groupError) {
          if (be.scheduledBatchRunComponentId != null) {
            SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
              Id = be.scheduledBatchRunComponentId
            );
            sbrc.Status__c = BATCH_RUN_CMP_STATUS_INIT_ERROR;
            sbrc.ErrorMessage__c = 'Cannot start batch since previous batches in group failed';
            update sbrc;
          }
          error = true;
        }
        if (!error) {
          if (be.scheduledBatchRunComponentId != null) {
            SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
              Id = be.scheduledBatchRunComponentId
            );
            sbrc.StartTime__c = DateTime.now();
            update sbrc;
          }
          try {
            SBS_ScheduledBatch b = (SBS_ScheduledBatch) be.batchClass.newInstance();
            b.setScheduledBatchRun(sbr);
            b.setVariables(
              be.batchJobObject,
              be.retentionPeriod,
              be.caseField,
              be.caseType,
              be.devName,
			  be.scheduledBatchRunComponentId
            );
            apexJobId = Database.executebatch(b, be.scopeSize);
          } catch (Exception e) {
            error = true;
            if (be.scheduledBatchRunComponentId != null) {
              SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
                Id = be.scheduledBatchRunComponentId
              );
              sbrc.Status__c = BATCH_RUN_CMP_STATUS_INIT_ERROR;
              sbrc.ErrorMessage__c = (e.getMessage() +
                '\n\n' +
                e.getStackTraceString())
                .abbreviate(30000);
              update sbrc;
            }
          }
        }
        if (apexJobId != null && !error) {
          if (be.scheduledBatchRunComponentId != null) {
            SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
              Id = be.scheduledBatchRunComponentId
            );
            sbrc.Status__c = BATCH_RUN_CMP_STATUS_STARTED;
            sbrc.StartTime__c = DateTime.now();
            sbrc.ApexJobId__c = '' + apexJobId;
            update sbrc;
          }
        }
        if (error) {
          be.success = false;
          run(sbr);
        }
      } else
        run(sbr);
    } else {
      if (sbr.scheduledBatchRunId != null) {
        List<SBS_ScheduledBatchRunComponent__c> sbrcList = [
          SELECT Id, Status__c
          FROM SBS_ScheduledBatchRunComponent__c
          WHERE ScheduledBatchRun__c = :sbr.scheduledBatchRunId
        ];
        Boolean allSuccess = true;
        for (SBS_ScheduledBatchRunComponent__c sbrc : sbrcList) {
          if (sbrc.Status__c != BATCH_RUN_CMP_STATUS_SUCCESS)
            allSuccess = false;
        }
        SBS_ScheduledBatchRun__c sbrRec = new SBS_ScheduledBatchRun__c(
          Id = sbr.scheduledBatchRunId
        );
        sbrRec.Status__c = allSuccess
          ? BATCH_RUN_STATUS_SUCCESS
          : BATCH_RUN_STATUS_FAIL;
        sbrRec.FinishTime__c = DateTime.now();
        update sbrRec;
      }
    }
  }
  /**
    Class representing a scheduled batch run
  */
  global class ScheduledBatchRun {
    /**
      Id of the scheduled batch run record
    */
    private Id scheduledBatchRunId;
    /**
      The batches scheduled for execution in this scheduled batch run
    */
    private BatchExecution[] batches;
    /**
      The index of the batch currently executing
    */
    private Integer executingBatchIdx;
    /**
      Creates a scheduled batch run
      @param batches The batch executions of the batch run
    */
    public ScheduledBatchRun(BatchExecution[] batches) {
      this.batches = batches;
    }
    /**
      Sets the id of the current job
      @param jobId The job id to set for the currently executing batch
    */
    public void setCurrentJobId(Id jobId) {
      batches[executingBatchIdx].jobId = jobId;
    }
    /**
      Marks the current batch as an error and sets a custom error text
      @param errorText The error text to set
    */
    public void setBatchError(String errorText) {
      if (
        executingBatchIdx != null &&
        batches[executingBatchIdx].customError != true
      ) {
        batches[executingBatchIdx].customError = true;
        batches[executingBatchIdx].customErrorText = errorText;
      }
    }

    /**
      Handles errors in the execute phase of the batch.
      If a batch component exists for the batch then the error is logged as a txn error
      otherwise it is rethrown to be picked up later as a batch error.
      @param e The exception thrown in the execute method
      @param sObjScope The scope of records to process in the execute method
    */
    public void handleExecuteException(Exception e, SObject[] sObjScope) {
      Id cmpId = batches[executingBatchIdx].scheduledBatchRunComponentId;
      if (cmpId != null) {
        insert (new BatchError(e, sObjScope)).generateTxnError(cmpId);
      } else
        throw e;
    }

    /**
      Adds the supplied error to the scheduled batch run
      The error is stored in a scheduled batch transaction error for the batch
      NOTE: An exception is thrown if the error cannot be added due to no scheduled batch run component
      @param errorList THe list of errors to create for the batch run
    */
    public void addErrors(BatchError[] errorList) {
      Integer sz = errorList.size();
      if (sz > 0) {
        Id cmpId = batches[executingBatchIdx].scheduledBatchRunComponentId;
        if (cmpId != null) {
          SBS_ScheduledBatchRunTxnError__c[] errList = new List<SBS_ScheduledBatchRunTxnError__c>(
            sz
          );
          for (Integer i = 0; i < sz; i++) {
            errList[i] = errorList[i].generateTxnError(cmpId);
          }
          insert errList;
        } else
          throw new ScheduledBatchRunException(
            'Failed to register batch error, first error: ' +
            errorList[0].errorMessage
          );
      }
    }

    /**
      Creates a scheduled batch run record with the supplied run components for the scheduled batch run
      @param timeSegment The time segment to set for the run record (may be null)
    */
    public void setupRunRecord(String timeSegment) {
      SBS_ScheduledBatchRun__c sbrRec = new SBS_ScheduledBatchRun__c();
      sbrRec.Status__c = BATCH_RUN_STATUS_STARTED;
      sbrRec.StartTime__c = DateTime.now();
      sbrRec.TimeSegment__c = timeSegment;
      insert sbrRec;
      scheduledBatchRunId = sbrRec.Id;
      Integer sz = batches.size();
      SBS_ScheduledBatchRunComponent__c[] sbrcList = new List<SBS_ScheduledBatchRunComponent__c>(
        sz
      );
      for (Integer i = 0; i < sz; i++) {
        sbrcList[i] = batches[i].createRecord(scheduledBatchRunId, i + 1);
      }
      insert sbrcList;
      for (Integer i = 0; i < sz; i++) {
        batches[i].scheduledBatchRunComponentId = sbrcList[i].Id;
      }
    }
  }
  /**
    Class representing a batch to be executed
  */
  global class BatchExecution {
    /**
      The name of the batch
    */
    private String devName;
    /**
      The batch class to be executed
    */
    private Type batchClass;
    /**
      The size of the batch scope
    */
    private Integer scopeSize;
    /**
      The scheduled batch batch run component where the run information is stored
    */
    private Id scheduledBatchRunComponentId;
    /**
      The group of the batch execution
    */
    private String groupName;
    /**
      Whether the batch execution was successful
    */
    private Boolean success;
    /**
      The id of the batch job
    */
    private Id jobId;
    /**
      Indicates that an error did occur in the batch despite the status of the batch job (i.e. when it is caught)
    */
    private Boolean customError;
    /**
      The text describing the custom error
    */
    private String customErrorText;
    /**
     Batch job Object
    */
    private String batchJobObject;
    /**
      The number of days in which data needs to retained
    */
    private Integer retentionPeriod;
    /**
     The field is the APIName of the caselookUp field
     */
    private string caseField;
    /**
        SObject name of related Child SObject which should be removed as well
    */

    private String relSObjName;
    /**
        The field on the child Sobejct which links the primary object.
    */
    private String relSObjField;
    /**
     The Case type of the case Object
   */
    private string caseType;
    /**
      Creates a batch execution instance
      @param batchClass The batch class to be executed (must extend SBS_ScheduledBatch and conform to the rules for scheduled batches)
      @param scopeSize The size of the batch scope
      @param groupName The name of the group that this batch belongs to
    */
    public BatchExecution(
      Type batchClass,
      Integer scopeSize,
      String groupName,
      String batchJobObject,
      Integer retentionPeriod,
      String caseField,
      String caseType
    ) {
      this(
        null,
        batchClass,
        scopeSize,
        groupName,
        batchJobObject,
        retentionPeriod,
        caseField,
        caseType
      );
    }
    /**
      Creates a batch execution instance
      @param devName The developer name of the batch
      @param batchClass The batch class to be executed (must extend SBS_ScheduledBatch and conform to the rules for scheduled batches)
      @param scopeSize The size of the batch scope
      @param groupName The name of the group that this batch belongs to
      @param batchJobObject The SobjectName of the batch class.
      @param retentionPeriod, The number of days in which data needs ti be retains.
      @param caseField The Lookfield related case and Other Sobejct.
      @param relSobjField The LooksField which related BatchObject and Child Object(For Eample: LiveChatTranscript and LiveChatVisitor)
      @param relSObjName The SobjectName of the Child Object.(Example BatchJobSobject : LiveChatTranscript, relSObjName=LiveChatVisitor)
    */
    public BatchExecution(
      String devName,
      Type batchClass,
      Integer scopeSize,
      String groupName,
      String batchJobObject,
      Integer retentionPeriod,
      String caseField,
      String caseType
    ) {
      this.devName = devName;
      this.batchClass = batchClass;
      this.scopeSize = scopeSize;
      this.groupName = groupName;
      this.customError = false;
      this.batchJobObject = batchJobObject;
      this.retentionPeriod = retentionPeriod;
      this.caseField = caseField;
      this.casetype = caseType;
    }

    /**
      Creates a scheduled batch run component record for the batch execution object
      @param sbrId The scheduled batch run record to assign the component to
      @param runOrder The run order to set for the component record
      @return The component record (not inserted)
    */
    private SBS_ScheduledBatchRunComponent__c createRecord(
      Id sbrId,
      Integer runOrder
    ) {
      SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c();
      sbrc.Name = devName;
      sbrc.Status__c = BATCH_RUN_CMP_STATUS_SCHEDULED;
      sbrc.ScheduledBatchRun__c = sbrId;
      sbrc.RunOrder__c = runOrder;
      if (customError) {
        sbrc.Status__c = BATCH_RUN_CMP_STATUS_INIT_ERROR;
        sbrc.ErrorMessage__c = customErrorText != null
          ? customErrorText.abbreviate(30000)
          : null;
      }
      return sbrc;
    }
  }

  /**
    Represents an error in a batch execution
  */
  global class BatchError {
    /**
      The error message
    */
    String errorMessage;
    /**
      Stack trace of the error
    */
    String stackTrace;
    /**
      The scope of sobjects which generated the error
    */
    SObject[] sObjScope;
    /**
      Creates a batch error instance
      @param errorMessage The error message
      @param stackTrace Stack trace of the error
      @param sObjScope The scope of sobjects which generated the error
    */
    public BatchError(
      String errorMessage,
      String stackTrace,
      SObject[] sObjScope
    ) {
      this.errorMessage = errorMessage;
      this.stackTrace = stackTrace;
      this.sObjScope = sObjScope;
    }
    /**
      Creates a batch error instance generated by an exception
      @param e The caught exception of the error
      @param The scope of sobjects which generated the error
    */
    public BatchError(Exception e, SObject[] sObjScope) {
      this(e.getMessage(), e.getStackTraceString(), sObjScope);
    }
    /**
      Returns abbreviated version of the error message
      @param size The abbreviated size of the string
      @return Abbreviated version of the error message
    */
    private String getErrorMessageAbbr(Integer size) {
      return String.isBlank(errorMessage)
        ? null
        : errorMessage.abbreviate(size);
    }

    /**
      Returns abbreviated version of the stack trace
      @param size The abbreviated size of the string
      @return Abbreviated version of the stack trace
    */
    private String getStackTraceAbbr(Integer size) {
      return String.isBlank(stackTrace) ? null : stackTrace.abbreviate(size);
    }

    /**
      Returns abbreviated version of serialized string representation of the scope
      @param size The abbreviated size of the string
      @return Abbreviated version of serialized string representation of the scope
    */
    private String getScopeStringAbbr(Integer size) {
      return sObjScope == null
        ? null
        : JSON.serialize(sObjScope).abbreviate(size);
    }
    /**
      Generates a transaction error record for the batch error
      @param cmpId THe id of the scheduled batch run component for which to register the error
      @return The scheduled batch run transaction error record
    */
    private SBS_ScheduledBatchRunTxnError__c generateTxnError(Id cmpId) {
      return new SBS_ScheduledBatchRunTxnError__c(
        ScheduledBatchRunComponent__c = cmpId,
        ErrorMessage__c = getErrorMessageAbbr(4000),
        StackTrace__c = getStackTraceAbbr(4000),
        Scope__c = getScopeStringAbbr(100000)
      );
    }
  }
}