/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Controller class for the hidden utility to open a case subtab under a chat transcript tab in the SAS Service-console.  
 */
public class FCS_ConsoleAutomationController {

    /**
     * Returns a list of object prefixes that are subject to automatically open a tab with a related object. 
     * 
     * @return 			List of object prefixes.		
     */
    @AuraEnabled
    public static List<String> retrievePrefixes(){
        List<String> prefixList = new List<String>();
        prefixList.add(LiveChatTranscript.SObjectType.getDescribe().getKeyPrefix());
        prefixList.add(MessagingSession.SObjectType.getDescribe().getKeyPrefix());
        return prefixList;
    }

    /**
     * Returns a list of Object id's to open subtabs for in the Service Cloud console.
     * 
     * @param transcriptId 	An Object Id to open  
     * @return 				The case Id to open a new subtab for.		
     */
    @AuraEnabled
    public static List<Id> retrieveRelated(Id objId){
        List<Id> returnObjIds = new List<Id>();
        SObjectType objType = objId.getSobjectType();

        if(objType == LiveChatTranscript.SObjectType){
            LiveChatTranscript lct = [SELECT Status, CaseId, OwnerId FROM LiveChatTranscript WHERE Id = :objId];
            if(lct.Status == 'InProgress'){
                Case c = new Case(Id = lct.CaseId);
                c.OwnerId = lct.OwnerId;
                update c;
                returnObjIds.add(c.Id);
            }
        } else if (objType == MessagingSession.SObjectType){
            MessagingSession ms = [SELECT Id, Status, CaseId, OwnerId FROM MessagingSession WHERE Id = :objId];
            if(ms.Status == 'Active'){
                Case c = new Case(Id = ms.CaseId);
                c.OwnerId = ms.OwnerId;
                update c;
                returnObjIds.add(c.Id);
            }
        }
        return returnObjIds;        
    }
}