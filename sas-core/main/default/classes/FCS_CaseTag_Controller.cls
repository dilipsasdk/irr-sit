public class FCS_CaseTag_Controller {
  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );
  static SocialPostsSelector socialPosts = (SocialPostsSelector) SAS_Service_Application.Selector.newInstance(
    SocialPost.SObjectType
  );
  public FCS_CaseTag_Controller() {
  }
  @AuraEnabled(cacheable=true)
  public static Case findCase(string recordId) {
    List<Case> lstCases = new List<Case>();
    if (recordId.startsWith('500')) {
      lstCases = cases.selectById(new Set<Id>{ recordId });
    } else if (recordId.startsWith('570')) {
      lstCases = cases.selectByChatId(new Set<Id>{ recordId });
    } else if (recordId.startsWith('0Mw')) {
      lstCases = cases.selectByMessagingId(new Set<Id>{ recordId });
    } else if (recordId.startsWith('0ST')) {
      lstCases = cases.selectBySocialPostId(new Set<Id>{ recordId });
      if (!lstCases.isEmpty() && lstCases.size() > 0) {
        return lstCases[0];
      } else {
        Case cse = new Case(
          Department__c = System.Label.Social_Post_Department,
          Team__c = System.Label.Social_Post_Team,
          RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL
        );
        lstCases.add(cse);
      }
    } else if (recordId.startsWith('0LQ')) {
      VoiceCall callRecord = [
        SELECT Id, Case__c
        FROM VoiceCall
        WHERE Id = :recordId
      ];
      lstCases = cases.selectById(new Set<Id>{ callRecord.Case__c });
    }
    return lstCases[0];
  }
  @AuraEnabled
  public static Id createCaseRecord(Case newRecord, String recordId) {
    List<SocialPost> lstSocialPosts = socialPosts.selectById(
      new Set<Id>{ recordId }
    );
    newRecord.origin = lstSocialPosts[0].Provider;
    newRecord.Team__c = System.Label.Social_Post_Team;
    newRecord.RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    newRecord.status = 'Closed';
    insert newRecord;

    SocialPost sc = new SocialPost(
      Id = lstSocialPosts[0].Id,
      parentId = newRecord.Id
    );
    update sc;
    return newRecord.Id;
  }
}
