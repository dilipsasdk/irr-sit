public with sharing class RouteAutomationStuckCasesBatchable implements Database.Batchable<LIA_Claim__c>, Database.AllowsCallouts, Database.Stateful {
  private Set<Id> caseIdsToManualHandling;

  public RouteAutomationStuckCasesBatchable() {
    this.caseIdsToManualHandling = new Set<Id>();
  }

  public Iterable<LIA_Claim__c> start(Database.BatchableContext jobId) {
    ClaimsSelector cl = ClaimsSelector.newInstance();
    List<LIA_Claim__c> claimsStuckFetchingData = cl.selectStuckUnhandledEU261ClaimsByDataStatus(
      'In Progress'
    );
    List<LIA_Claim__c> otherStuckClaims = cl.selectStuckEU261Claims();

    claimsStuckFetchingData.addAll(otherStuckClaims);
    return claimsStuckFetchingData;
  }

  public void execute(
    Database.BatchableContext bc,
    List<LIA_Claim__c> claimsToFetch
  ) {
    fflib_ISObjectUnitOfWork uowUpsert = SAS_Service_Application.UnitOfWork.newInstance();

    for (LIA_Claim__c c : claimsToFetch) {
      c.EU261_Handling_Status__c = 'Unable to handle';
      c.External_Data_Status__c = 'Unavailable';
      uowUpsert.registerDirty(c);
      caseIdsToManualHandling.add(c.Case__c);
    }
    uowUpsert.commitWork();
  }

  public void finish(Database.BatchableContext jobId) {
    if (caseIdsToManualHandling.size() > 0) {
      CaseService.assignPriorityAndRouteToQueue(caseIdsToManualHandling);
    }
  }
}
