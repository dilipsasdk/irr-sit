public with sharing class MessagingSessionController {
  static MessagingSessionsSelector messagSessSelector = (MessagingSessionsSelector) SAS_Service_Application.Selector.newInstance(
    MessagingSession.SObjectType
  );
  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );
  @AuraEnabled(cacheable=true)
  public static List<Case> findCases(string recordId) {
    List<Case> lstCases;
    Set<Id> setMesgSesIds = new Set<Id>();
    List<MessagingSession> lstMsgSession = messagSessSelector.selectById(
      new Set<Id>{ recordId }
    );
    List<MessagingSession> lstMsgSessions = messagSessSelector.selectByMessagingEndUserId(
      new Set<Id>{ lstMsgSession[0].messagingEndUserId }
    );
    for (MessagingSession msgSess : lstMsgSessions) {
      setMesgSesIds.add(msgSess.Id);
    }
    lstCases = cases.selectByMessagingId(setMesgSesIds);
    return lstCases;
  }
}
