public without sharing class LiveChatTranscripts extends ApplicationDomain {
  public LiveChatTranscripts(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<LiveChatTranscript>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new LiveChatTranscripts(records);
    }
  }

  private C_Settings.SettingsGroup sgChat = C_Settings.getSettings(
    'CHAT LANGUAGE'
  );
  private C_Settings.SettingsGroup sgSurvey = C_Settings.getSettings(
    'SURVEY LANGUAGE'
  );

  private List<LiveChatTranscript> instanceRecords;

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    deleteMissedTranscripts();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    checkIpWhitelist();
    createCasesForTranscripts();
  }
  /**
   * Checks the Ip whitelisting of the chats
   */
  private void checkIpWhitelist() {
    if (System.Test.isRunningTest() || C_Util.isSandbox()) {
      return;
    }
    C_Settings.SettingsGroup sgIpRestriction = C_Settings.getSettings(
      'ChatIpWhitelist'
    );

    Set<String> ipWhiteList = new Set<String>();

    for (String k : sgIpRestriction.keySet()) {
      ipWhiteList.add(sgIpRestriction.get(k));
    }

    if (ipWhiteList.size() > 0) {
      for (LiveChatTranscript lct : instanceRecords) {
        if (!ipWhiteList.contains(lct.IpAddress) && !C_Util.isSandbox()) {
          lct.addError('Ip Address Not Allowed: ' + lct.IpAddress);
        }
      }
    }
  }

  private void createCasesForTranscripts() {
    try {
      List<Case> casesToInsert = new List<Case>();
      List<LiveChatTranscript> lctsForCases = new List<LiveChatTranscript>();

      List<Id> chatButtonIds = new List<Id>();
      for (LiveChatTranscript lct : instanceRecords) {
        chatButtonIds.add(lct.LiveChatButtonId);
      }

      Map<Id, LiveChatButton> lcbMap = new Map<Id, LiveChatButton>(
        [
          SELECT Id, toLabel(windowLanguage)
          FROM LiveChatButton
          WHERE Id IN :chatButtonIds
        ]
      );

      for (LiveChatTranscript lct : instanceRecords) {
        if (lct.LiveChatButtonId != null) {
          lct.FCS_Language__c = sgChat.get(
            lcbMap.get(lct.LiveChatButtonId).windowLanguage
          );
        }
        if (lct.CaseId == null && lct.Status == 'InProgress') {
          casesToInsert.add(createCaseFromTranscript(lct));
          lctsForCases.add(lct);
        }
      }

      insert casesToInsert;

      //Relating Case to LiveChatTranscript
      for (Integer i = 0; i < casesToInsert.size(); i++) {
        lctsForCases[i].CaseId = casesToInsert[i].Id;
      }
    } catch (Exception e) {
      C_Log.logException(e, null, null);
    }
  }

  private void deleteMissedTranscripts() {
    try {
      List<Case> lsecasetoDelete = new List<Case>();
      for (LiveChatTranscript lct : instanceRecords) {
        if (lct.Status == 'Missed' && lct.CaseId != null) {
          lsecasetoDelete.add(new Case(Id = lct.CaseId));
        }
      }
      if (!lsecasetoDelete.isEmpty()) {
        delete lsecasetoDelete;
      }
    } catch (Exception e) {
      C_Log.logException(e, null, null);
    }
  }

  private Case createCaseFromTranscript(LiveChatTranscript lct) {
    Case c = new Case(
      FCS_EBNumber__c = lct.FCS_EBNumber__c,
      FCS_CODSId__c = lct.FCS_CODSId__c,
      GDPR_Consent__c = lct.GDPR_Consent__c,
      Status = 'In Progress',
      Origin = 'Chat',
      FCS_Language__c = lct.FCS_Language__c,
      FCS_SurveyLanguage__c = sgSurvey.get(lct.FCS_Language__c),
      RecordTypeId = C_RecordTypeHelper.CASE_CHAT
    );

    if (lct.Initially_Provided_PNR__c != null) {
      c.Initially_Provided_PNR__c = lct.Initially_Provided_PNR__c.toUpperCase();
    }
    if (lct.TURI_Chat_User_Id__c != null) {
      c.TURI_Chat_User_Id__c = lct.TURI_Chat_User_Id__c;
    }

    return c;
  }
}
