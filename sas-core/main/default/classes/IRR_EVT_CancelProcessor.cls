/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Delay event. Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_CancelProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Cancel event info is missing: {0}';
    private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_CancelFlow';

   @TestVisible
   private IRR_MOD_CancelInfo cancelInfo;
   @TestVisible
   private List<IRR_Constant__mdt> cancelEventConstant;

   public String getEventName(){
       return 'Cancel';
   }

   /**
    * @author Niklas Lundkvist, Deloitte
    * @date 2020
    *
    * @description Validates event before processing.
    *      Throws Event Exception if event info is not complete.
    */
   public void validateEvent() {
       if (cancelInfo == null) {
           throwEventException(ERROR_NO_EVENT, cancelInfo);
       }
       if (String.isBlank(cancelInfo.flightId)) {
           throwEventException(ERROR_FLIGHT_ID, cancelInfo);
       }
       if (cancelInfo.scheduledTimeOfDepartureUTC == null || cancelInfo.scheduledTimeOfDepartureLocal == null) {
           throwEventException(ERROR_SCHD_TIME, cancelInfo);
       }
   }

   /**
    * @author Niklas Lundkvist, Deloitte
    * @date 2020
    *
    * @description Populates event object with additional information and initiates passengerInfo list.
    * Added AirportCityNames callout to TEDS to render citynames on the templates
    */
   public void initiateEvent() {
       IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
               new IRR_SVC_CommunicationService.FlightIdSplit(cancelInfo.flightId);
       cancelInfo.flightRef = flightIdSplit.flightNumber;
       cancelInfo.stationDeparture = flightIdSplit.stationDeparture;
       cancelInfo.stationArrival = flightIdSplit.stationArrival;

       //  //Retrieve Airport city names from TEDS
       if(cancelInfo.stationDeparture != null && cancelInfo.stationDeparture != '' 
               && cancelInfo.stationArrival != null && cancelInfo.stationArrival != ''){
       this.airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(new Set<String>{cancelInfo.stationDeparture,cancelInfo.stationArrival} );        
       cancelInfo.departureCity = airportInfoMap.get(cancelInfo.stationDeparture);
       cancelInfo.arrivalCity = airportInfoMap.get(cancelInfo.stationArrival);
       }

       //Calculate time difference of scheduled time of departure and estimated time of departure in minutes
       Long millisecondsToScheduledTime = cancelInfo.scheduledTimeOfDepartureUTC.getTime() - Datetime.now().getTime();
       cancelInfo.minutesToScheduledTime = (Integer) millisecondsToScheduledTime / 60000;

       //Retrieve passengers for flight
       this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(cancelInfo.flightId);
       
       //calling shorten url api
         IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
           if(passengerInfos != null && passengerInfos.size() > 0 ){
            for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
                            if(shortenUrl != null && shortenUrl.IRR_EU_Pass_Right_Short_URL__c != Null){
                              passengerInfo.passengerRightURL = shortenUrl.IRR_EU_Pass_Right_Short_URL__c;
                             }
                            else{
                                passengerInfo.passengerRightURL = System.Label.EU_Passenger_Right;
                            }
           }
        }

   }

   /**
    * @author Niklas Lundkvist, Deloitte
    * @date 2020
    *
    * @description Checks if any active manual override blocks exist for this flight.
    *
    * @return If any active manual overrides exist
    */
   public Boolean checkActiveBlock() {
       List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
               .selectActiveManualOverridesByFlightId(cancelInfo.flightId);
       return !manualOverrides.isEmpty();
   }

   /**
    * @author Niklas Lundkvist, Deloitte
    * @date 2020
    *
    * @description Executes flow with for each passenger with event specific information.
    */
   public void processEvent() {
       //Initiate variable container object for Flow
       IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
       flowVariables.cancelInfo = cancelInfo;

       //Process passengers
       for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
           //Only process passengers confirmed for this segment
           if (passengerInfo.thisSegment != null && !passengerInfo.thisSegment.isConfirmed) continue;

           //Set passenger info in flowVariables and execute flow
           flowVariables.passengerInfo = passengerInfo;
           executeFlow(EVENT_FLOW_NAME, flowVariables);
       }
   }

   public IRR_EVT_CancelProcessor(IRR_MOD_CancelInfo cancelInfo) {
       this.cancelInfo = cancelInfo;
      // cancelEventConstant = IRR_SEL_ConstantSelector.newInstance().getEventContant('Cancel');
      
   }

   public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
       public IRR_EVT_IEventProcessor newInstance(Object payload) {
           return (IRR_EVT_IEventProcessor) new IRR_EVT_CancelProcessor((IRR_MOD_CancelInfo) payload);
       }
   }
}