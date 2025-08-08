trigger SocialPostTrigger on SocialPost(
  after delete,
  after insert,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(SocialPosts.class);
}
