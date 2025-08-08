trigger Refund_RequestTrigger on Refund_Request__c(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(Refund_Requests.class);
}
