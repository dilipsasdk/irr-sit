trigger ContentVersionTrigger on ContentVersion(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(ContentVersions.class);
}
