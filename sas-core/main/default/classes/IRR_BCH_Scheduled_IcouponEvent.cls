global with sharing class IRR_BCH_Scheduled_IcouponEvent extends SBS_ScheduledBatch implements Schedulable {
  public Static String eventType = 'flightDelayDeparture';
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
      .getQueuedIcouponBatchQueryLocator();
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
        List<IRR_EventLog__c> eventLogMap = new List<IRR_EventLog__c>();
        IRR_EventLog__c evtLog = new IRR_EventLog__c();
        for(SObject sObj : sObjScope){
            evtLog = (IRR_EventLog__c)sObj;
          
            IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
            delayInfo.stationDeparture = evtLog.IRR_Station_Departure__c;
            delayInfo.delayedMinutes = (Integer)evtLog.IRR_Delayed_Minutes__c;
            delayInfo.scheduledTimeOfDepartureUTC = evtLog.IRR_ScheduleTime__c;
            delayInfo.scheduledTimeOfDepartureLocal = evtLog.IRR_ScheduleTime__c;
            delayInfo.flightRef = evtLog.IRR_Flight_Ref__c;
            delayInfo.flightId = evtLog.IRR_FlightId__c;
            delayInfo.estimatedTimeOfDepartureLocal = System.now();
            delayInfo.estimatedTimeOfDepartureUTC = evtLog.IRR_EstimatedTime_Of_DepartureUTC__c;
            delayInfo.eventTime = evtLog.IRR_EventTime__c;


              //Retrieve previous delay and calculate difference
            Integer totalDelays = IRR_SEL_DelayLogsSelector.newInstance()
            .getDelayByFlightIds(new Set<String>{delayInfo.flightId});
            Boolean firstDelay = totalDelays == 1 ? true : false;

            List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
           
            Long millisecondsToEstimatedTime = delayInfo.estimatedTimeOfDepartureUTC.getTime() - delayInfo.eventTime.getTime();
            Integer minutesToEstimatedTime = (Integer) millisecondsToEstimatedTime / 60000;
            System.debug('firstDelay ++++ ' + firstDelay);
            System.debug('minutesToEstimatedTime ++++ ' + minutesToEstimatedTime);
            if((firstDelay == false && minutesToEstimatedTime > = 75) || (firstDelay == true )){
            passengerInfos =  IRR_SVC_TedsService.getPassengerInfosForFlight(evtLog.IRR_FlightId__c);
            IRR_SVC_CommunicationService.processEvent(eventType, delayInfo);
            }

            Integer topSequenceNo = 0 ;
            Boolean isFindPax = false; 
            for(IRR_MOD_PassengerInfo passenger :passengerInfos){
              if(passenger.hasThisSegment == true && 
                  passenger.thisSegment.serviceClass != null&& 
                  passenger.thisSegment.boardingSequenceNumber != null &&
                  passenger.hasBoarded == false 
                  
                ){
                    
                    if(topSequenceNo < passenger.thisSegment.boardingSequenceNumber){
                      topSequenceNo = passenger.thisSegment.boardingSequenceNumber;
                    }
                    isFindPax = true;
                  
                }
          }
          if( evtLog.Is_Communication_Send__c == false && evtLog.Is_Second_Communication_Send__c == false && evtLog.MinuteDiff__c > 60 && isFindPax){
            evtLog.Is_Communication_Send__c = true;
            evtLog.Last_Boarding_Sequence_Number__c = topSequenceNo;
          }
          if(evtLog.Is_Communication_Send__c == true && evtLog.Is_Second_Communication_Send__c == false && evtLog.MinuteDiff__c <= 60 && isFindPax){
            evtLog.Is_Second_Communication_Send__c = true;
            evtLog.Last_Boarding_Sequence_Number__c = topSequenceNo;
          }
          if(evtLog.Is_Communication_Send__c == false && evtLog.Is_Second_Communication_Send__c == false && evtLog.MinuteDiff__c <= 60 && isFindPax){
            evtLog.Is_Second_Communication_Send__c = true;
            evtLog.Is_Communication_Send__c = true;
            evtLog.Last_Boarding_Sequence_Number__c = topSequenceNo;
          }
          eventLogMap.add(evtLog); 
        }
          Update eventLogMap;
      }


    global override void finishOverridable(Database.BatchableContext bc) {
    }
  
    global void execute(SchedulableContext ctx) {
      SBS_ScheduledBatch processQueuedManual = new IRR_BCH_Scheduled_IcouponEvent();
      ID batchprocessid = Database.executeBatch(processQueuedManual, 1);
    }
}