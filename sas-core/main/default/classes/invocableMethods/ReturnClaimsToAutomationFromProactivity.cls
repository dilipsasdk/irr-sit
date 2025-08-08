global without sharing class ReturnClaimsToAutomationFromProactivity {
  @InvocableMethod(label='Return Claims To Automation From Proactivity')
  global static void returnClaimsToAutomation(List<Id> proactivityId) {
    ClaimsSelector claimsSelectorInstance = ClaimsSelector.newInstance();
    claimsSelectorInstance.setfilterClosed(true);
    LIA_Claim__c[] claimsToReturn = claimsSelectorInstance.selectByProactivityId(proactivityId[0]);

    ClaimService.returnToAutomation(claimsToReturn);
  }
}