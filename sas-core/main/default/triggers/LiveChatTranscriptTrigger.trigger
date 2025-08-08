trigger LiveChatTranscriptTrigger on LiveChatTranscript(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(LiveChatTranscripts.class);
}
