public with sharing class RunEU261AutomationScheduler implements Schedulable {
  public void execute(SchedulableContext jobId) {
    List<LIA_Claim__c> claimsToAutomate = ClaimsSelector.newInstance()
      .selectClaimsReadyForEU261Automation();
    Set<Id> claimIds = new Map<Id, LIA_Claim__c>(claimsToAutomate).keySet();
    EU261Service.newInstance().batchProcessEU261Claims(claimIds);
  }
}
