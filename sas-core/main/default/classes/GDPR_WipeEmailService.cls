/**
Service class providing the functionality related to EmailMessage
@author Thippeswamy A 
**/
global with sharing class GDPR_WipeEmailService {
  /**
used the delete the sensitive attachment related to email message
@param list of EmailMessage
*/
  global static void deleteEmailMessageAttachmentandFiles(
    EmailMessage[] emailmesgList
  ) {
    Set<Id> setEmailMsgIds = C_Util.getIdSet(emailmesgList);
    deleteRelatedEntities(setEmailMsgIds);
  }
  /**
delete related entities of EmailMessage
@Param set of EmailMessageIds
*/
  global static void deleteRelatedEntities(Set<Id> emailMsgIds) {
    List<Attachment> lstAttchments = [
      SELECT Id
      FROM Attachment
      WHERE parentId = :emailMsgIds
    ];
    Set<Id> setContDocIds; // set to identify duplicate content document
    ContentDocumentLink[] cdlList = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :emailMsgIds
    ];
    if (!cdlList.isEmpty()) {
      setContDocIds = new Set<Id>();
      for (ContentDocumentLink cdl : cdlList) {
        {
          setContDocIds.add(cdl.ContentDocumentId);
        }
      }
      delete [SELECT Id FROM ContentDocument WHERE Id IN :setContDocIds];
    }
    delete lstAttchments;
  }
}
