/**
    Abstract class for scheduled batches which defines the require functionailty for scheduled batches
    Subclasses of this class can be run in isolation but the abstract class provides methods
    to register a set of subsequent classes which are processed on batch finish @see SecheduledBatchService

    Note:
    - Subclasses of this class must specify a constructor without parameters.
    - Subclasses of this class may not specify a finish method if the finish method does not call the implementation in this class

    @author Peter Södergren
*/
global abstract class SBS_ScheduledBatch implements Database.Batchable<sObject> , Database.allowsCallouts, Database.stateful{

    /**
        The scheduled batch run under which this batch is included
    */
    private SBS_ScheduledBatchService.ScheduledBatchRun scheduledBatchRun;
    /**
        Whether the batch should use transaction control
    */
    private Boolean useTransactionControl=true;
    /**
        Custom batch errors generated for the batch
    */
    private List<SBS_ScheduledBatchService.BatchError> errList;

    /**
        Sets the scheduled batch run under which this batch is included
        @param scheduledBatchRun The scheduled batch run under which this batch is included
    */
    global void setScheduledBatchRun(SBS_ScheduledBatchService.ScheduledBatchRun scheduledBatchRun){
        this.scheduledBatchRun = scheduledBatchRun;
    }

    /**
        Sets whether the batch should use transaction control
        A batch not using transaction control
        @param useTransactionControl Whether the batch should use transaction control
    */
    global void setUseTransactionControl(Boolean useTransactionControl){
        this.useTransactionControl = useTransactionControl;
    }
    /**
    Required abstract method used to set the parameters for batch classes.
    @Sobj The Specific Object name in which batch class to be executed.
    @retentionPeriod The number of days untill which data needs to be retained.
    @caseField API name of the lookfield between case and related SObject,
      This is null if there is no relation between case and related Sobject.
    @caseType Since the GDPR retention is different for different caseTypes, this paramter refers to CaseType of the Case.
              Usually this is having value only for Case related batch classes.
    @relSObjField This refers to child Object lookup for the Batch Class Object.
    @relSobjName This is the Child Object name of the related Batch class Object
    */
     global abstract void setVariables(String Sobj, Integer retentionPeriod, string caseField, string caseType, string batchName,String scheduleBatchCompId);          

    /**
        Required execute method which processes the scope of records in the batch
        @param bc The batchable context of the batch job
        @param sObjScope The scope of records to process
    */
    global abstract void executeScope(Database.BatchableContext bc, SObject[] sObjScope);
    
    /**
        Method for each execution which calls the extending class's execute method
        @param bc The batchable context of the batch job
        @param sObjScope The scope of records to process
    */
    global void execute(Database.BatchableContext bc, SObject[] sObjScope) {
        Savepoint sp = useTransactionControl ? Database.setSavepoint() : null;
        try{
            executeScope(bc,sObjScope);
        }
        catch(Exception e){
            if(scheduledBatchRun!=null){
                if(sp!=null)Database.rollback(sp);
                //This may also fail but should then be picked up as a batch error and still fail the batch run as a whole
                scheduledBatchRun.handleExecuteException(e,sObjScope);
            }
            else {
                throw e;
            }
        }
        commitErrors();
    }

    /**
        Registers a manual error in the batch execution
        Can be used for both manual and automatic transaction control
        Adding an error marks the entire batch as failed.
        NOTE: Errors are commited at the end of the transaction or manually through the batch implementation.
        @param message The error message to set for the error
        @param stackTrace The string containing the optional stack trace
        @param sObjScope The scope of sobjects which caused the error.
    */
    protected void addError(String message,String stackTrace,SObject[] sObjScope){
        if(scheduledBatchRun!=null){
            if(errList==null)errList = new List<SBS_ScheduledBatchService.BatchError>();
            errList.add(new SBS_ScheduledBatchService.BatchError(message,stackTrace,sObjScope));
        }
        else throw new SBS_ScheduledBatchService.ScheduledBatchRunException('Failed to register batch error: '+message);
    }

    /**
        Commits the custom errors added by the batch implementation
    */
    protected void commitErrors(){
        if(scheduledBatchRun!=null && errList!=null)scheduledBatchRun.addErrors(errList);
        errList=null;
    }

    /**
        Overridable finish logic
        Ensures that the finish method is not overridden but still allows logic to be placed in the finish method
        This method will be called upon batch finish before registering the result and before starting the next batch
        @param bc The batch context
    */
    global virtual void finishOverridable(Database.BatchableContext bc){}

    /**
        Calls the scheduled batch service with the list of subsequent batch classes
        to be run after the batch has finished
        @param bc The batch context
    */
    global void finish(Database.BatchableContext bc) {
        try{
            finishOverridable(bc);
        }
        catch(Exception e){
            if(scheduledBatchRun!=null)scheduledBatchRun.setBatchError(e.getMessage()+'\n\n'+e.getStackTraceString());
            else throw e;
        }
        if(scheduledBatchRun!=null){
            scheduledBatchRun.setCurrentJobId(bc.getJobId());
            SBS_ScheduledBatchService.run(scheduledBatchRun);
        }
    }

}