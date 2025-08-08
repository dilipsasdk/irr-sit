/**
Purpose : Since to enable the delegated admin to Change Workload capacty , it is required
to give Customize application permision , So to notify the Admin when there is change in metadata
Other than Omnichannel Changes.
@author Thippeswamy Aravinda
*/
global with sharing class FCS_SendMetadataChangeNotification_Batch extends SBS_ScheduledBatch {
  /**
private variable to get the FromDate to fetch Audit trail
*/
  private List<FCS_Audit_Trail__c> lstAuditTrail;
  /**
Users having the access to change metadata
*/
  private List<String> lstDelegatedAdminUsers;
  /**
admin user email address to send the notification if the metadata changes by delegated admins
*/
  private List<String> lstAdminUserEmail;
  /**
Orgwide address to represent it is from Salesforce.
*/
  private List<OrgWideEmailAddress> lstOrgWideAddr;
  /**
from date used to fetch audit trail, this will be updated after batch run.
*/
  private static Datetime fromDate;

  global FCS_SendMetadataChangeNotification_Batch() {
  }
  /**
   overriding the absract method to set batch class Params
   */
  public override void setVariables(
    String Sobj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    string batchName,
    String scheduledBatchRunComponentId
  ) {
  }
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String query = formQuery();
    return Database.getQueryLocator(query);
  }

  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    List<SetupAuditTrail> lstSetupAuditTrial = (List<SetupAuditTrail>) sObjScope;
    Messaging.SingleEmailMessage[] messages;
    if (!lstSetupAuditTrial.isEmpty()) {
      messages = new List<Messaging.SingleEmailMessage>();
      for (SetupAuditTrail setUpAuditTrail : lstSetupAuditTrial) {
        if (
          setUpAuditTrail.Section != 'Manage Users' &&
          !setUpAuditTrail.action.Contains('Presence Configuration')
        ) {
          Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
          msg.Subject = setUpAuditTrail.Action;
          msg.PlainTextBody =
            setUpAuditTrail.Action +
            ': ' +
            setUpAuditTrail.Display;
          msg.ToAddresses = lstAdminUserEmail;
          if (!lstOrgWideAddr.isEmpty()) {
            msg.setOrgWideEmailAddressId(lstOrgWideAddr[0].Id);
          }
          messages.add(msg);
        }
      }
    }
    if (!messages.isEmpty()) {
      try {
        Messaging.sendEmail(messages);
      } catch (Exception e) {
        System.debug('Exception' + e);
      }
    }
  }
  global override void finishOverridable(Database.BatchableContext bc) {
    try {
      lstAuditTrail[0].From_Date__c = System.now();
      update lstAuditTrail;
    } catch (Exception e) {
      System.debug('Exception' + e);
    }
  }

  private string formQuery() {
    String query;
    lstDelegatedAdminUsers = new List<String>();
    lstOrgWideAddr = new List<OrgWideEmailAddress>();
    lstOrgWideAddr = [
      SELECT Id, DisplayName
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'Salesforce Audit Trail'
      LIMIT 1
    ];
    List<Delegated_Administrator__mdt> lstDelegaAdmin = [
      SELECT Label, Delegated_Group__c, Type__c, Email__c
      FROM Delegated_Administrator__mdt
    ];
    if (!lstDelegaAdmin.isEmpty()) {
      lstAdminUserEmail = new List<String>();
      for (Delegated_Administrator__mdt delgAdmin : lstDelegaAdmin) {
        if (delgAdmin.Type__c == 'Delegated Admin') {
          lstDelegatedAdminUsers.add(delgAdmin.Label);
        } else if (delgAdmin.Type__c == 'Audit Trail Admin') {
          lstAdminUserEmail.add(delgAdmin.Email__c);
        }
      }
    }
    lstAuditTrail = FCS_Audit_Trail__c.getall().values();

    fromDate = lstAuditTrail[0].From_Date__c;
    if (Test.isRunningTest()) {
      query = 'SELECT Action,CreatedById,CreatedBy.Name,CreatedDate,Display,Id,Section from SetupAuditTrail Limit 50';
    } else {
      query = 'SELECT Action,CreatedById,CreatedBy.Name,CreatedDate,Display,Id,Section FROM SetupAuditTrail  WHERE CreatedDate >=:fromDate AND CreatedBy.Name IN : lstDelegatedAdminUsers ORDER BY CreatedDate';
    }
    return query;
  }
}