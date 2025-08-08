trigger ClaimExpenseTrigger on Claim_Expense__c(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(ClaimExpenses.class);
}
