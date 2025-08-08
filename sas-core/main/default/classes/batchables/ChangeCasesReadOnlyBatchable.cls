public without sharing class ChangeCasesReadOnlyBatchable implements Database.Batchable<Case>, Database.Stateful {
  public List<C_Log__c> logs;
  public ChangeCasesReadOnlyBatchable() {
    logs = new List<C_Log__c>();
  }

  public Iterable<Case> start(Database.BatchableContext bc) {
    List<Case> allCases = new List<Case>();
    for (String department : Cases.allReadOnlyConfigs.keySet()) {
      allCases.addAll(
        CasesSelector.newInstance().selectInactiveByDepartment(department)
      );
    }
    return allCases;
  }

  public void execute(Database.BatchableContext bc, List<Case> caseToUpdate) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    try {
      Cases cases = Cases.newInstance(caseToUpdate);
      cases.markAsReadOnly(uow);
      uow.commitWork();
    } catch (Exception e) {
      C_Log__c l = C_Log.createLog(
        'Error',
        e.getMessage(),
        e.getStackTraceString(),
        'Case'
      );
      logs.add(l);
      throw e;
    }
  }

  public void finish(Database.BatchableContext BC) {
    insert logs;
  }
}
