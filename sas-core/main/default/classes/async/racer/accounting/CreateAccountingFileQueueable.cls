public class CreateAccountingFileQueueable implements Queueable {
  public final AccountingFileBuilder.PaymentCurrency fileCurrency;

  public CreateAccountingFileQueueable(
    AccountingFileBuilder.PaymentCurrency fileCurrency
  ) {
    this.fileCurrency = fileCurrency;
  }

  public void execute(QueueableContext qc) {
    Id accountingFileId = SettlementService.createAccountingFile(fileCurrency);
    if (accountingFileId != null) {
      System.enqueueJob(new SendAccountingFileQueueable(accountingFileId));
    }
  }
}
