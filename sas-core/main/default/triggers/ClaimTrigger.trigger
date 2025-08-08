trigger ClaimTrigger on LIA_Claim__c(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(Claims.class);
}
