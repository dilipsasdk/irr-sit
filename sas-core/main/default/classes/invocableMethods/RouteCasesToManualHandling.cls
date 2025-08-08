global without sharing class RouteCasesToManualHandling {
  @InvocableMethod(label='Route Cases to Manual Handling')
  global static void routeCasesToManualHandling(List<Id> proactivityId) {
    List<LIA_Claim__c> liaClaims = retrieveRecords(proactivityId[0]);
    prepareClaimsForManualHandling(liaClaims);
    routeCases(liaClaims);
  }

  private static List<LIA_Claim__c> retrieveRecords(Id proactivityId) {
    ClaimsSelector claimsSelectorInstance = ClaimsSelector.newInstance();
    claimsSelectorInstance.setfilterClosed(true);
    return claimsSelectorInstance.selectByProactivityId(proactivityId);
  }

  private static void prepareClaimsForManualHandling(List<LIA_Claim__c> liaClaims) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Claims.newInstance(liaClaims).prepareForManualHandling(uow);
    uow.commitWork();
  }

  private static void routeCases(List<LIA_Claim__c> liaClaims) {
    Set<Id> caseIds = new Set<Id>();
    for (LIA_Claim__c claim: liaClaims) {
      caseIds.add(claim.Case__c);
    }

    CaseService.assignPriorityAndRouteToQueue(CasesSelector.newInstance().selectById(caseIds));
  }
}