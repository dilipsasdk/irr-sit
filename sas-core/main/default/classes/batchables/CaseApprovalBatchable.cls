public without sharing class CaseApprovalBatchable implements Database.Batchable<Case> {
  List<Case> casesToApprove;
  public CaseApprovalBatchable(List<Case> casesToApprove) {
    this.casesToApprove = casesToApprove;
  }

  public Iterable<Case> start(Database.BatchableContext bc) {
    return this.casesToApprove;
  }
  public void execute(Database.BatchableContext bc, List<Case> cases) {
    for (Case c : cases) {
      Map<String, Case> flowInputs = new Map<String, Case>();
      flowInputs.put('incomingCaseRecord', c);
      Flow.Interview.CLAIM_Case_Approval_Handler approvalFlow = new Flow.Interview.CLAIM_Case_Approval_Handler(
        flowInputs
      );
      approvalFlow.start();
    }
  }
  public void finish(Database.BatchableContext bc) {
  }
}
