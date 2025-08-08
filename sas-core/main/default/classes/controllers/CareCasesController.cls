public without sharing class CareCasesController {
  @AuraEnabled
  public static List<CARE_Claim__c> searchCases(
    String caseId,
    String pir,
    String bookingReference
  ) {
    // TODO: Check if search has been made to EDW. If yes, just return results from SF DB.

    ClaimService.fetchCAREClaimsFromEDW(bookingReference, pir, caseId);

    return CAREClaimsSelector.newInstance()
      .selectByQuery(caseId, pir, bookingReference);
  }
}
