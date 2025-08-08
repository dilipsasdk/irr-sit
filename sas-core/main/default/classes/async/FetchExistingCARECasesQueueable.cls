public class FetchExistingCARECasesQueueable implements Queueable, Database.AllowsCallouts {
  public List<String> allPnrsToProcess;
  private List<String> pnrsToProcess;

  public FetchExistingCARECasesQueueable(List<String> pnrsToProcess) {
    this.pnrsToProcess = pnrsToProcess;
  }

  public void execute(QueueableContext context) {
    String thisPnr = this.pnrsToProcess[0];
    try {
      ClaimService.fetchCAREClaimsFromEDW(thisPnr, null, null);
      C_Log.log(
        C_Log.Severity.Info,
        'Fetched CARE claim for PNR: ' + thisPnr,
        null,
        'CARE',
        null
      );
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        'Failed to fetch CARE claims for PNR: ' + thisPnr,
        null,
        'CARE',
        null
      );
    }

    if (this.pnrsToProcess.size() > 1) {
      List<String> newList = new List<String>();

      for (String pnr : this.pnrsToProcess) {
        if (pnr != thisPnr) {
          newList.add(pnr);
        }
      }

      if (newList.size() > 0) {
        System.enqueueJob(new FetchExistingCARECasesQueueable(newList));
      }
    }
  }
}
