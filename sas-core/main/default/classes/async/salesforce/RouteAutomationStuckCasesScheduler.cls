public with sharing class RouteAutomationStuckCasesScheduler implements Schedulable {
  public static final Integer BATCH_SIZE = 1000;
  public void execute(SchedulableContext jobId) {
    Database.executeBatch(new RouteAutomationStuckCasesBatchable(), BATCH_SIZE);
  }
}
