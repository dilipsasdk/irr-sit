public class IRR_SVC_LogsServiceImpl implements IRR_SVC_ILogsService{
    
    public  static Map<Id,String> getFilesforEventLogs(List<IRR_EventLog__c> records){

        IRR_DOM_IEventLogs eventLogs = IRR_DOM_EventLogs.newInstance(records);
        Set<Id> eventLogIds = eventLogs.getRecordIds();

        List<ContentDocumentLink> contentDocumentLinkRecords =
            IRR_SEL_ContentDocumentLinksSelector.newInstance().selectByLinkedEntityId(eventLogIds);
        
        IRR_DOM_IContentDocumentLinks contentDocumentLinks = 
            IRR_DOM_ContentDocumentLinks.newInstance(contentDocumentLinkRecords);
        
        Map<Id, String> bodyAsStringByLinkedEntityId =
            contentDocumentLinks.getBodyAsStringByLinkedEntityId();

            return bodyAsStringByLinkedEntityId;

    }
}