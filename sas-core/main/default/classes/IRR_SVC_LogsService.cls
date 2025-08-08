/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
*/
public class IRR_SVC_LogsService {

    public static Map<Id,String> getFilesforEventLogs(List<IRR_EventLog__c> records){
        return service().getFilesforEventLogs(records);
    }
   
    
    private static IRR_SVC_ILogsService service() {
        return (IRR_SVC_ILogsService) IRR_Application.Service.newInstance(IRR_SVC_ILogsService.class);
    }

     public class EventException extends Exception { }
}