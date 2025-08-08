trigger MessagingSessionTrigger on MessagingSession (
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(MessagingSessions.class);
}
