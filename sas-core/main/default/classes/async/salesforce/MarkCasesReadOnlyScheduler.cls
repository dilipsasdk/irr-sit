public class MarkCasesReadOnlyScheduler implements Schedulable {
  public void execute(SchedulableContext ctx) {
    ChangeCasesReadOnlyBatchable b = new ChangeCasesReadOnlyBatchable();
    Database.executeBatch(b, 2000);
  }
}
