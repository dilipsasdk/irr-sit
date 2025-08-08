public interface IRR_SVC_ILogsService {
   
    Map<Id,String> getFilesforEventLogs(List<IRR_EventLog__c> records);
    
}