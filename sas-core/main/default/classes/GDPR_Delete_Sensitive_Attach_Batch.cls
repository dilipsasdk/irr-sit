/**
Batch class which ensures that Sensitive attachment deleted beased on Case Origin
after X number of days of case closure
@author Thippeswamy Aravinda March-12-21

*/
global with sharing class GDPR_Delete_Sensitive_Attach_Batch extends SBS_ScheduledBatch {
  /**
The date at which sensitive attachment on email will be deleted
*/
  private DateTime lastRetentionDate;
  /**
CaseOrigins to delete the sesitive attachment
*/
  private List<String> caseOrigins;
  /**
Initiates the batch class and extracts the date used to filter out cases for removal
*/
  global GDPR_Delete_Sensitive_Attach_Batch() {
    caseOrigins = new List<string>();
    List<Del_Sensitive_Data_Based_on_Case_Origin__mdt> lstCaseOriginMdt = [
      SELECT Id, Case_Origin__c
      FROM Del_Sensitive_Data_Based_on_Case_Origin__mdt
      WHERE Data_Object__c = 'Attachment'
    ];
    if (!lstCaseOriginMdt.isEmpty()) {
      for (
        Del_Sensitive_Data_Based_on_Case_Origin__mdt obj : lstCaseOriginMdt
      ) {
        caseOrigins.add(obj.Case_Origin__c);
      }
    }
    
  }
  /**
   overriding the absract method to set batch class Params
   */
  global override void setVariables(
    String obj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    String batchName,
	String scheduledBatchRunComponentId
  ) {
  lastRetentionDate = DateTime.newInstance(
      Date.today()
        .addDays(-wipingPeriod),
      Time.newInstance(0, 0, 0, 0)
    );
  }

  /**
Iterates over all cases closed before the retention period
@param bc The batch context
*/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id,ParentId FROM EmailMessage WHERE Parent.ClosedDate<:lastRetentionDate and HasAttachment = true and Incoming = true and parent.Origin=:caseOrigins'
    );
  }

  /**
Deletes Email message related entities
Attachments

**/
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    GDPR_WipeEmailService.deleteEmailMessageAttachmentandFiles(
      (EmailMessage[]) sObjScope
    );
  }
}