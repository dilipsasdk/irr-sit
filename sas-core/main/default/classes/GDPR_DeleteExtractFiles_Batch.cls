/**
 * @author Anton Norell
 * @date 2019-01-09
 * @description Batch class used to delete files generates when performing an extract of Personal Data from Account
 */
global with sharing class GDPR_DeleteExtractFiles_Batch extends SBS_ScheduledBatch {

     /**
   overriding the absract method to set batch class Params
   */
  global override void setVariables(
    String obj,
    Integer retentionPeriod,
    string caseField,
    string caseType,
    String batchName,
	String scheduledBatchRunComponentId
  ) {
  }
    /**
        Generates querylocator that selects all existing extract files
        @param bc The batch context
    */
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id, ContentDocumentId FROM ContentVersion WHERE IsGDPRExtract__c = TRUE'
    );
  }

  /**
   * Performs deletion of provided Content Documents
   * @param bc The batch context
   * @param sObjScope Content Documents to delete
   */

  public override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    Set<Id> contentDocumentsToDelete = new Set<Id>();
    for (ContentVersion contentVersion : (ContentVersion[]) sObjScope) {
      contentDocumentsToDelete.add(contentVersion.ContentDocumentId);
    }
    delete [
      SELECT Id
      FROM ContentDocument
      WHERE Id IN :contentDocumentsToDelete
    ];
  }
}