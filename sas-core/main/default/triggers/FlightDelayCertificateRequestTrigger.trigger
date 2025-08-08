trigger FlightDelayCertificateRequestTrigger on Flight_Delay_Certificate_Request__c(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(FlightDelayCertificateRequests.class);
}
