/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the New Info event.
 *      Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_NewInfoProcessor extends IRR_EVT_EventProcessor {

    //private static final String ERROR_NO_EVENT = 'New Info event details are missing: {0}';
    //private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    //private static final String ERROR_NEW_INFO_TIME = 'New Info time is missing from event: {0}';
    //private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';

    //private static final String EVENT_FLOW_NAME = 'IRR_EVT_NewInfoFlow';
   // private static final String CANADA_PAX_RIGHT_URL = 'Find out more about your European Passenger Rights at https://www.flysas.com/en/legal-info/eu-passenger-rights/ and your Canadian Passenger Rights at https://www.flysas.com/en/legal-info/us-canada/canada-air-passenger-protection-rules/.';
    //private static final String EU_PAX_RIGHT_URL = 'https://www.flysas.com/en/legal-info/eu-passenger-rights/';

    @TestVisible
    private IRR_MOD_NewInfo newInfo;
    @TestVisible
    private List<IRR_Constant__mdt> newInfoEventConstant;

    public String getEventName(){
        return 'New Info';
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
       
        if (newInfo == null) {
            throwEventException(newInfoEventConstant[0].ERROR_NO_EVENT__c, newInfo);
        }
        if (String.isBlank(newInfo.flightId)) {
            throwEventException(newInfoEventConstant[0].ERROR_FLIGHT_ID__c, newInfo);
        }
        if (newInfo.newInfoTimeLocal == null || newInfo.newInfoTimeUTC == null) {
            throwEventException(newInfoEventConstant[0].ERROR_NEW_INFO_TIME__c, newInfo);
        }
        if (newInfo.scheduledTimeOfDepartureUTC == null || newInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(newInfoEventConstant[0].ERROR_SCHD_TIME__c, newInfo);
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
                new IRR_SVC_CommunicationService.FlightIdSplit(newInfo.flightId);
        newInfo.flightRef = flightIdSplit.flightNumber;
        newInfo.stationDeparture = flightIdSplit.stationDeparture;
        newInfo.stationArrival = flightIdSplit.stationArrival;

        //Retrieve Airport city names from TEDS
        if(newInfo.stationDeparture != null && newInfo.stationDeparture != '' 
                && newInfo.stationArrival != null && newInfo.stationArrival != ''){
        this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames(new Set<String>{newInfo.stationDeparture,newInfo.stationArrival} );        
        newInfo.departureCity = airportInfoMap.get(newInfo.stationDeparture);
        newInfo.arrivalCity = airportInfoMap.get(newInfo.stationArrival);
        }

        //Retrieve passengers for flight
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(newInfo.flightId);
         //calling shorten url api
         IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
         if(passengerInfos != null && passengerInfos.size() > 0 ){
            for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
                if(passengerInfo.hasThisSegment != null && passengerInfo.hasThisSegment == true){
                    if(shortenUrl != null && shortenUrl.IRR_EU_Pass_Right_Short_URL__c != Null){
                        passengerInfo.passengerRightURL = shortenUrl.IRR_EU_Pass_Right_Short_URL__c;
                    }
                    else{
                        passengerInfo.passengerRightURL = System.Label.EU_Passenger_Right;
                    }
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
                .selectActiveManualOverridesByFlightId(newInfo.flightId);
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
        flowVariables.newInfo = newInfo;

        //Process passengers
        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            //Only process passengers confirmed for this segment
            if (passengerInfo.thisSegment == null || !passengerInfo.thisSegment.isConfirmed) continue;

            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(newInfoEventConstant[0].EVENT_FLOW_NAME__c, flowVariables);
        }
    }

    public IRR_EVT_NewInfoProcessor(IRR_MOD_NewInfo newInfo) {
        this.newInfo = newInfo;
        newInfoEventConstant = IRR_SEL_ConstantSelector.newInstance().getEventContant('New_Info');

    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_NewInfoProcessor((IRR_MOD_NewInfo) payload);
        }
    }
}