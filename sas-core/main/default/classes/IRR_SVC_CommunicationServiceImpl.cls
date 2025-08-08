/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of Event functionality.
*/

public class IRR_SVC_CommunicationServiceImpl implements IRR_SVC_ICommunicationService {

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Initiates an Event Processor using Application factory and uses it for processing an event.
     *
     * @param eventType Type of Event to process
     * @param payload JSON Serialized event payload
     */
    public void processEvent(String eventType, String payload) {
        try {
            fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
            IRR_EVT_IEventProcessor eventProcessor = IRR_Application.EventProcessor.newInstance(eventType, payload);
            eventProcessor.validateEvent();
            eventProcessor.initiateEvent();
            //Stop processing event if there is an active manual override block
            if (eventProcessor.checkActiveBlock()) return;
            eventProcessor.processEvent();
            eventProcessor.processMessages();
            eventProcessor.finalizeEvent(uow);
            uow.commitWork();
        } catch (Exception e) {
            C_Log.HttpData httpData = new C_Log.HttpData();
            httpData.body = payload;
            httpData.resource = IRR_SVC_CommunicationService.EVENT_API_RESOURCE_URL + eventType;
            C_Log.logException(e, 'IRR', httpData);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Initiates an Event Processor using Application factory and uses it for processing an event.
     *
     * @param eventType Type of Event to process
     * @param payload De-serialized Event payload
     */
    public void processEvent(String eventType, Object payload) {
        fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
        IRR_EVT_IEventProcessor eventProcessor = IRR_Application.EventProcessor.newInstance(eventType, payload);
        eventProcessor.validateEvent();
        eventProcessor.initiateEvent();
        //Stop processing event if there is an active manual override block
        if (!eventProcessor.checkActiveBlock()) {
            eventProcessor.processEvent();
            eventProcessor.processMessages();
        }
        eventProcessor.finalizeEvent(uow);
        uow.commitWork();
    }

    /**
     * @author Ludvig Wälimaa, Deloitte
     * @date 2020
     *
     * @description Initiates process for removing Communiction Logs from Service Cloud and MC.
     *
     * @param idSet Ids of Communication Logs valid for deletion
     * @param lastRetentionDate The last retention date of a Communication Log
     */
    public void processGDPRLogs(Set<Id> idSet, DateTime lastRetentionDate) {
        List<IRR_CommunicationLog__c> logs = IRR_SEL_CommunicationLogsSelector.newInstance().selectSObjectsById(idSet);
        IRR_DOM_ICommunicationLogs domain = IRR_DOM_CommunicationLogs.newInstance(logs);
        fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
        domain.processGDPRLogs(uow, lastRetentionDate);

        uow.commitWork();
    }
}