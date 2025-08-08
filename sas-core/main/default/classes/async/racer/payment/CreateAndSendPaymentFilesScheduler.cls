public class CreateAndSendPaymentFilesScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    System.enqueueJob(
      new CreatePaymentFileQueueable(PaymentFileBuilder.PaymentCurrency.DKK)
    );
    System.enqueueJob(
      new CreatePaymentFileQueueable(PaymentFileBuilder.PaymentCurrency.NOK)
    );
    System.enqueueJob(
      new CreatePaymentFileQueueable(PaymentFileBuilder.PaymentCurrency.SEK)
    );
    System.enqueueJob(
      new CreatePaymentFileQueueable(PaymentFileBuilder.PaymentCurrency.OTH)
    );
    System.enqueueJob(
      new CreatePaymentFileQueueable(PaymentFileBuilder.PaymentCurrency.USD)
    );
  }
}
