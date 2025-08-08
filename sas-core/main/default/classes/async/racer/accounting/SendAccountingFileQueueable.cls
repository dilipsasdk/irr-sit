public class SendAccountingFileQueueable implements Queueable, Database.AllowsCallouts {
  public final Id fileId;

  public SendAccountingFileQueueable(Id fileId) {
    this.fileId = fileId;
  }

  public void execute(QueueableContext qc) {
    SettlementService.sendAccountingFile(fileId);
  }
}
