public class CreatePaymentFileQueueable implements Queueable {
  public final PaymentFileBuilder.PaymentCurrency fileCurrency;

  public CreatePaymentFileQueueable(
    PaymentFileBuilder.PaymentCurrency fileCurrency
  ) {
    this.fileCurrency = fileCurrency;
  }

  public void execute(QueueableContext qc) {
    Id paymentFileId = SettlementService.createPaymentFile(fileCurrency);
    if (paymentFileId != null) {
      System.enqueueJob(new SendPaymentFileQueueable(paymentFileId));
    }
  }
}
