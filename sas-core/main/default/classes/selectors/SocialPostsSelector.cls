public inherited sharing class SocialPostsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      SocialPost.Id,
      SocialPost.parentId,
      SocialPost.Provider
    };
  }

  public Schema.SObjectType getSObjectType() {
    return SocialPost.SObjectType;
  }

  public static SocialPostsSelector newInstance() {
    return (SocialPostsSelector) SAS_Service_Application.Selector.newInstance(
      SocialPost.SObjectType
    );
  }

  public List<SocialPost> selectById(Set<Id> ids) {
    return (List<SocialPost>) selectSObjectsById(ids);
  }
}
