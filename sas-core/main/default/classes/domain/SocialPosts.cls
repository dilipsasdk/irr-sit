public without sharing class SocialPosts extends ApplicationDomain {
  public SocialPosts(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<SocialPost>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new SocialPosts(records);
    }
  }

  private List<SocialPost> instanceRecords;

  @TestVisible
  private static final String STATUS_REVIEWED = 'Reviewed';
  @TestVisible
  private static final String STATUS_IGNORE = 'Ignore';
  @TestVisible
  private static final String STATUS_NEEDED = 'Needed';
  @TestVisible
  private static final String STATUS_HIDDEN = 'HIDDEN';

  public override void onBeforeInsert() {
    setFieldsOnCreate();
  }

  public override void onAfterInsert() {
    updatePostStatusOnParent();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    updatePostStatus((List<SocialPost>) existingRecords.values());
  }

  /**
    Method to update status fields on social post when an action is taken (from User)
    @param oldSocialPost list of new version of the social post i.e. the Trigger.old variable
    */
  private void updatePostStatus(List<SocialPost> oldSocialPostList) {
    Integer sz = instanceRecords.size();
    for (Integer i = 0; i < sz; i++) {
      Boolean handled;
      SocialPost newSp = instanceRecords[i];
      SocialPost oldSp = oldSocialPostList[i];
      //If post is updated to hidden - the status is updated to hidden and marked as reviewed
      if (
        (newSp.Status != oldSp.Status && newSp.Status == STATUS_HIDDEN) ||
        (newSp.FCS_PostHidden__c != oldSp.FCS_PostHidden__c &&
        newSp.FCS_PostHidden__c)
      ) {
        newSp.FCS_PostHidden__c = true;
        handled = true;
      }
      //If post is updated to unhidden, the post is unmarked done if not other action is taken
      if (
        newSp.Status != oldSp.Status && oldSp.Status == STATUS_HIDDEN ||
        (newSp.FCS_PostHidden__c != oldSp.FCS_PostHidden__c &&
        !newSp.FCS_PostHidden__c)
      ) {
        newSp.FCS_PostHidden__c = false;
        if (
          !newSp.FCS_PostIgnored__c &&
          !newSp.FCS_CaseCreated__c &&
          !newSp.FCS_PostReplied__c &&
          !newSp.FCS_PostLiked__c
        ) {
          handled = false;
        }
      }
      //If post is updated to ignore - the status is ignored and marked as reviewed
      if (
        newSp.ReviewedStatus != oldSp.ReviewedStatus &&
        newSp.ReviewedStatus == STATUS_IGNORE
      ) {
        newSp.FCS_PostIgnored__c = true;
        handled = true;
      }
      //If parent case is deleted - updated checkbox case created and unmark Done if no other action is taken
      if (newSp.ParentId != oldSp.ParentId && newSp.ParentId == null) {
        newSp.FCS_CaseCreated__c = false;
        if (
          !newSp.FCS_PostIgnored__c &&
          !newSp.FCS_PostHidden__c &&
          !newSp.FCS_PostReplied__c &&
          !newSp.FCS_PostLiked__c
        ) {
          handled = false;
        }
      }
      //If post is updated to liked - The status is updated to liked and marked as reviewed
      if (newSp.Recipient == newSp.LikedBy && newSp.LikedBy != oldSp.LikedBy) {
        newSp.FCS_PostLiked__c = true;
        handled = true;
      }
      if (handled != null && handled) {
        newSp.ReviewedStatus = STATUS_REVIEWED;
        newSp.FCS_Done__c = true;
        if (!oldSp.FCS_Done__c) {
          newSp.FCS_ClosedDate__c = System.now();
        }
      }
      if (handled != null && !handled) {
        newSp.ReviewedStatus = STATUS_NEEDED;
        newSp.FCS_Done__c = false;
        if (oldSp.FCS_Done__c) {
          newSp.FCS_ClosedDate__c = null;
          newSp.FCS_Reopened__c = true;
        }
      }
    }
  }

  /**
   Method to set fields on the post when replying to a post (creating a reply record)
   @param newSocialPost list of new version of the social post i.e. the Trigger.new variable
   @param oldSocialPost list of old version of the social post i.e. the Trigger.old variable
   */
  private void updatePostStatusOnParent() {
    Set<Id> parentIds = new Set<Id>();
    List<SocialPost> spRecords = instanceRecords;
    if (spRecords != null) {
      for (SocialPost sp : spRecords) {
        if (sp.IsOutbound && sp.ReplyToId != null) {
          parentIds.add(sp.ReplyToId);
        }
      }
    }
    if (parentIds != null || parentIds.isEmpty()) {
      List<SocialPost> parentPosts = [
        SELECT Id, Status
        FROM SocialPost
        WHERE Id = :parentIds
      ];
      List<SocialPost> updatedSocialPosts = new List<SocialPost>();
      for (SocialPost sp : parentPosts) {
        sp.FCS_PostReplied__c = true;
        sp.ReviewedStatus = STATUS_REVIEWED;
        sp.FCS_Done__c = true;
        sp.FCS_ClosedDate__c = System.now();
        updatedSocialPosts.add(sp);
        if (instanceRecords == null) {
          sp.FCS_PostReplied__c = false;
          if (
            !sp.FCS_PostIgnored__c &&
            !sp.FCS_PostHidden__c &&
            !sp.FCS_PostLiked__c &&
            !sp.FCS_PostReplied__c
          ) {
            sp.ReviewedStatus = STATUS_NEEDED;
            updatedSocialPosts.add(sp);
          }
        }
      }
      update updatedSocialPosts;
    }
  }

  /**
       Method to set default fields on insert on Social Post.
       1. If the Post is a SAS-post it is marked as SASPost, Outbound and with no review status
       2. If the post is a comment on a SAS-post it is marked as Comment on SAS Post
       3. If the post is a reply on a SAS-post it is marked as a Comment on SAS Post
       4. For both comment and replies parent posts is added for added context
       5. If default Social Social Inbound Social Post Handler has set ParentId it is updated to null and Review Status updated to Needed
       @param newSocialPost list of new version of the social post i.e. the Trigger.new variable
       */
  private void setFieldsOnCreate() {
    List<C_GeneralSetting__mdt> socialPages = [
      // TODO: Move out
      SELECT Value__c
      FROM C_GeneralSetting__mdt
      WHERE Group__c = 'Social Accounts'
    ];
    List<Group> soMeQueue = [
      // TODO: Move out
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
    ];
    List<Id> parentIds = new List<Id>();
    List<Id> parentIdsNext = new List<Id>();
    for (SocialPost sp : instanceRecords) {
      parentIds.add(sp.ReplyToId);
      for (C_GeneralSetting__mdt socialPage : socialPages) {
        if (socialPage.Value__c == sp.Handle && !sp.IsOutbound == true) {
          sp.IsOutbound = true;
          sp.FCS_SASPost__c = true;
          sp.ReviewedStatus = null;
        }
      }
      sp.OwnerId = soMeQueue[0].Id;
      sp.FCS_PreviousQueue__c = soMeQueue[0].Id;
      if (sp.ParentId != null && sp.IsOutbound == false) {
        sp.ParentId = null;
        sp.ReviewedStatus = STATUS_NEEDED;
      }
    }
    List<SocialPost> parentPosts = [
      SELECT Id, ReplyToId, Content, Provider, Handle
      FROM SocialPost
      WHERE Id = :parentIds
    ];
    for (SocialPost parentSP : parentPosts) {
      parentIdsNext.add(parentSp.ReplyToId);
    }
    List<SocialPost> parentPostsNext = [
      SELECT Id, ReplyToId, Content, Provider, Handle
      FROM SocialPost
      WHERE Id = :parentIdsNext
    ];
    for (Integer i = 0, sz = parentPosts.size(); i < sz; i++) {
      if (parentIdsNext[i] != null) {
        for (C_GeneralSetting__mdt socialPage : socialPages) {
          if (
            socialPage.Value__c == parentPostsNext[i].Handle &&
            instanceRecords[i].FCS_SASPostComment__c == true
          ) {
            instanceRecords[i].FCS_SASPostComment__c = true;
          }
        }
        instanceRecords[i].FCS_ParentMessage__c = parentPostsNext[i].Content;
        instanceRecords[i].FCS_ParentCommentMessage__c = parentPosts[i].Content;
        if (
          instanceRecords[i].FCS_ParentCommentMessage__c != null &&
          instanceRecords[i].FCS_ParentCommentMessage__c != ''
        ) {
          instanceRecords[i].FCS_IsReply__c = true;
        }
      } else if (parentIds[i] != null) {
        for (C_GeneralSetting__mdt socialPage : socialPages) {
          if (
            socialPage.Value__c == parentPosts[i].Handle &&
            !instanceRecords[i].FCS_SASPostComment__c == true
          ) {
            instanceRecords[i].FCS_SASPostComment__c = true;
          }
        }
        instanceRecords[i].FCS_ParentMessage__c = parentPosts[i].Content;
      }
    }
  }
}
