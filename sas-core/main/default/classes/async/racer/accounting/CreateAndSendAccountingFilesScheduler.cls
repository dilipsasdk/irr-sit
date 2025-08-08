public class CreateAndSendAccountingFilesScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    System.enqueueJob(
      new CreateAccountingFileQueueable(
        AccountingFileBuilder.PaymentCurrency.DKK
      )
    );
    System.enqueueJob(
      new CreateAccountingFileQueueable(
        AccountingFileBuilder.PaymentCurrency.NOK
      )
    );
    System.enqueueJob(
      new CreateAccountingFileQueueable(
        AccountingFileBuilder.PaymentCurrency.SEK
      )
    );
    System.enqueueJob(
      new CreateAccountingFileQueueable(
        AccountingFileBuilder.PaymentCurrency.OTH
      )
    );
  }
}
