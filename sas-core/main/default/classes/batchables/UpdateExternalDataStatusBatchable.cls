public without sharing class UpdateExternalDataStatusBatchable implements Database.Batchable<LIA_Claim__c> {
  List<LIA_Claim__c> claimsToUpdate;
  Claim.ExternalDataStatus status;

  public UpdateExternalDataStatusBatchable(
    List<LIA_Claim__c> claimsToUpdate,
    Claim.ExternalDataStatus status
  ) {
    this.claimsToUpdate = claimsToUpdate;
    this.status = status;
  }

  public Iterable<LIA_Claim__c> start(Database.BatchableContext bc) {
    return this.claimsToUpdate;
  }

  public void execute(
    Database.BatchableContext bc,
    List<LIA_Claim__c> claimsToUpdate
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Claims claimsDomain = Claims.newInstance(claimsToUpdate);
    claimsDomain.updateExternalDataStatus(this.status, uow);
    uow.commitWork();
  }

  public void finish(Database.BatchableContext bc) {
  }
}
