global without sharing class ExcludeClaimsFromAutomation {
  @InvocableMethod(label='Exclude Claims From Automation')
  global static void excludeClaimsFromAutomation(List<Id> proactivityId) {
    ClaimsSelector claimsSelectorInstance = ClaimsSelector.newInstance();
    claimsSelectorInstance.setfilterClosed(true);
    LIA_Claim__c[] claimsToExclude = claimsSelectorInstance.selectByProactivityId(proactivityId[0]);

    ClaimService.putOnHold(claimsToExclude);
  }
}