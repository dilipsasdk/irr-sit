/**
  Purpose : Used to close the case when customer not contacted in last 24 hours
            Also close the cases which are created due to chat error
         @author Thippeswamy A
*/

global with sharing class FCS_CloseFBMessgerCaseAfter24hr_Batch extends SBS_ScheduledBatch {
  /**
    dateTime is used to find the messagingsession ended in last 24 hours. 
  */
  DateTime lastRetentionDate;
  /**
   The origin of the case which needs to be retrived
  */
  string caseOrigin;
  /**
  The list of cases status which needs to considered for FB messenger cases of autoclosing
  */
  List<String> lstStatus = new List<String>{
    'New',
    'In Progress',
    'New Response'
  };

  /**
    The Case status which is to be removed
    */
  String closeStatus = 'Closed';
  global FCS_CloseFBMessgerCaseAfter24hr_Batch() {
  }
  /**
  overriding the absract method to set batch class Params
  */
  global override void setVariables(
    String Sobj,
    Integer retentionPeriod,
    string caseField,
    string caseType,
    string batchName,
    String scheduledBatchRunComponentId
  ) {
    lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-retentionPeriod),
      Time.newInstance(0, 0, 0, 0)
    );
  }
  public Database.QueryLocator start(Database.BatchableContext bc) {
    caseOrigin = 'Facebook Messenger';
    return Database.getQueryLocator(
      'Select Id, status from Case where Origin =: caseOrigin AND Status IN:lstStatus AND Status !=: closeStatus'
    );
  }

  public override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    System.debug('lastRetentionDate***' + lastRetentionDate);
    List<Case> lstCases = (List<Case>) sObjScope;
    Set<Id> setCaseIds = new Set<Id>();
    Set<Id> setUpdateCaseIds = new Set<Id>();
    List<Case> lstUpdatecases = new List<Case>();
    Map<Id, Case> mapRetaincases = new Map<Id, Case>();
    for (Case cse : lstCases) {
      setCaseIds.add(cse.Id);
    }
    List<MessagingSession> lstMessagingsessions = [
      SELECT Id, Status, CaseId, EndTime, AcceptTime, AgentMessageCount
      FROM MessagingSession
      WHERE CaseId = :setCaseIds
      ORDER BY CreatedDate
    ];
    if (!lstMessagingsessions.isEmpty()) {
      for (MessagingSession messgSession : lstMessagingsessions) {
        if (
          messgSession.Status == 'Active' &&
          messgSession.AcceptTime <= lastRetentionDate &&
          messgSession.AgentMessageCount == 0
        ) {
          setUpdateCaseIds.add(messgSession.caseId);
        } else if (
          (messgSession.Status == 'Active' &&
          messgSession.AcceptTime > lastRetentionDate)
        ) {
          mapRetaincases.put(
            messgSession.caseId,
            new Case(Id = messgSession.caseId)
          );
        } else if (
          messgSession.Status == 'Ended' &&
          messgSession.EndTime > lastRetentionDate
        ) {
          mapRetaincases.put(
            messgSession.caseId,
            new Case(Id = messgSession.caseId)
          );
        } else if (
          messgSession.Status == 'Ended' &&
          messgSession.EndTime <= lastRetentionDate &&
          !mapRetaincases.containsKey(messgSession.CaseId)
        ) {
          setUpdateCaseIds.add(messgSession.caseId);
        }
      }
    }
    if (setUpdateCaseIds.size() > 0) {
      List<Case> lstCses = [
        SELECT Id, Type, FCS_Case_Reason__c
        FROM Case
        WHERE Id IN :setUpdateCaseIds
      ];
      List<Case> tagCases = new List<Case>();
      for (Case cse : lstCses) {
        if (cse.FCS_Case_Reason__c == null || cse.FCS_Case_Reason__c == '') {
          cse.FCS_CaseType__c = 'Error';
          cse.FCS_Case_Reason__c = 'Disconnected customer';
          cse.FCS_CaseResolution__c = 'Completed';
          cse.Status = 'Closed';
          tagCases.add(cse);
        } else {
          cse.status = 'Closed';
          tagCases.add(cse);
        }
      }
      if (!tagCases.isEmpty()) {
        update tagCases;
      }
    }
  }
  public override void finishOverridable(Database.BatchableContext bc) {
  }
}
