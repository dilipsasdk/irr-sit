public class SendPaymentFileQueueable implements Queueable, Database.AllowsCallouts {
  public final Id fileId;

  public SendPaymentFileQueueable(Id fileId) {
    this.fileId = fileId;
  }

  public void execute(QueueableContext qc) {
    SettlementService.sendPaymentFile(fileId);
  }
}
