/*
* Batch class which ensures that all manual queued messages are processed
* @author Chetan Singh
*
* @Updated by Ragbirendra Upadhyay , CoforgeTech
* @date July 2023
* @description Added logic for checking flight current status before sending
* email or SMS, if flight is cancelled , Removing customer from customer list.
*/

global with sharing class IRR_BCH_ScheduledEvent extends SBS_ScheduledBatch implements Schedulable {
    private String eventType = 'manualCommunication';
    private String CANCELLED = 'cancelled';
    /**
    overriding the absract method to set batch class Params
    */
    global override void setVariables(
        String obj,
        Integer retentionPeriod,
        string caseField,
        String caseType,
        String batchName,
        String scheduledBatchRunComponentId
    )
    {
    }
    
    /**
    Iterates over all Event Logs in the queued Status for manual communication
    @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        this.setUseTransactionControl(false);
        return IRR_SEL_EventLogsSelector.newInstance()
            .getQueuedManualQueryLocator();
    }
    
     /**
     Processes the Event Logs for scheduled manual messages
     @param bc The batchable context of the batch job
     @param sObjScope The scheduled Event Logs to process
    */
    global override void executeScope(
        Database.BatchableContext bc,
        SObject[] sObjScope
    ) {
        List<IRR_EventLog__c> allEventLog = sObjScope;
        List<IRR_EventLog__c> eventLogToBeProcess = new List<IRR_EventLog__c>();
        Set<String> flightIdSet = new Set<String>();
        
        for(IRR_EventLog__c eachEvent : allEventLog){
            List<String> lstFlightId = (eachEvent.IRR_FlightId__c).split(',');
            
            for(String flightId : lstFlightId)  {
                List<TEDSFlight> flightInfosList = IRR_SVC_TedsService.getFlightInfos(flightId.trim()); 
                String currentStatus = flightInfosList.size() > 0 ? flightInfosList[0].departure.status:'';
                if(currentStatus.equalsIgnoreCase(CANCELLED)  && String.isNotEmpty(currentStatus)){
                    flightIdSet.add(flightId.trim());
                }
            }
            eventLogToBeProcess.add(eachEvent);
        }
        if(eventLogToBeProcess.size()>0){
            Map<Id, String> bodyAsStringByLinkedEntityId = IRR_SVC_LogsService.getFilesforEventLogs(
                eventLogToBeProcess
            ); 
            for (Id evId : bodyAsStringByLinkedEntityId.keySet()) {
                String payload = bodyAsStringByLinkedEntityId.get(evId);
                IRR_MOD_ManualRequest cInfo = (IRR_MOD_ManualRequest) JSON.deserialize(
                    payload,
                    IRR_MOD_ManualRequest.class
                );
                cInfo.sendMessageTime = null;
                
                for (Integer i = (cInfo.passengerInfos.size()-1) ; i>= 0 ; i--){
                    String passangerFlightId = cInfo.passengerInfos[i].thisSegment.flightId;
                    if(flightIdSet.contains(passangerFlightId)){
                        (cInfo.passengerInfos).remove(i);
                    }
                } 
                if(cInfo.passengerInfos.size()>0)
                IRR_SVC_CommunicationService.processEvent(eventType, cInfo);
            }
        }
        delete sObjScope;
    }
    
    global override void finishOverridable(Database.BatchableContext bc) {
    }
    
    global void execute(SchedulableContext ctx) {
        SBS_ScheduledBatch processQueuedManual = new IRR_BCH_ScheduledEvent();
        ID batchprocessid = Database.executeBatch(processQueuedManual, 1);
    }
}