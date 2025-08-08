/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ICommunicationService {
    void processEvent(String eventType, String payload);
    void processEvent(String eventType, Object payload);
    void processGDPRLogs(Set<Id> idSet, DateTime lastRetentionDate);
}