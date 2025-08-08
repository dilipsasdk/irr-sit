trigger EmailMessageTrigger on EmailMessage(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(EmailMessages.class);
}
