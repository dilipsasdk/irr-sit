/**
* @author Chetan Singh, Coforge
* @date 2022
*
* @description Event Processor for the 'No Alternative to Rebooking' event. Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_NoRebookProcessor extends IRR_EVT_EventProcessor {
    
    private static final String ERROR_NO_EVENT = 'Norebooking event details are missing : {0}';
    private static final String ERROR_BOOKING_ID = 'Booking Id is missing from event : {0}';
    private static final String ERROR_BOOKING_REF = 'Booking Ref is missing from event : {0}';
    private static final String ERROR_NO_EVENT_TIME = 'Event time is missing from event : {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';
    private static final String ERROR_NO_CANCELLED_SEGMENT = 'cancelled Segments are missing from event: {0}';



    private static final String EVENT_FLOW_NAME = 'IRR_EVT_NoAlternativeUNFlow';

    @TestVisible
    private IRR_MOD_NoRebookInfo noRebookInfo;

    public String getEVentName() {
        return 'No Alternative Rebooking';
    }


    /**
     * @author Chetan Singh, Coforge
     * @date 2022
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */

     public void validateEvent() {
         if(noRebookInfo == null) {
            throwEventException(ERROR_NO_EVENT, noRebookInfo);
         }
         if(String.isBlank(noRebookInfo.bookingId)) {
            throwEventException(ERROR_BOOKING_ID, noRebookInfo);
         }
         if(String.isBlank(noRebookInfo.bookingReference)) {
            throwEventException(ERROR_BOOKING_REF, noRebookInfo);
         }
         if(noRebookInfo.eventTime == null) {
            throwEventException(ERROR_NO_EVENT_TIME, noRebookInfo);
         }
         if(noRebookInfo.scheduledTimeOfDepartureUTC == null || noRebookInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(ERROR_SCHD_TIME, noRebookInfo);
         }
         if (noRebookInfo.cancelledSegment == null) {
            throwEventException(ERROR_NO_CANCELLED_SEGMENT, noRebookInfo);
        }

     }

     /**
     * @author Chetan Singh, Coforge
     * @date 2022
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
        noRebookInfo.cancelledSegments = new List<String>();
        noRebookInfo.cancelledSegments.add(noRebookInfo.cancelledSegment);

        // The time remaining for flight departure should be less or equal to 48 hours
        Long millisecondsToScheduledTime = noRebookInfo.scheduledTimeOfDepartureUTC.getTime() - Datetime.now().getTime();
        noRebookInfo.minutesToScheduledTime = (Integer)millisecondsToScheduledTime / (1000 * 60);
        //Retrieve passengers for booking
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(noRebookInfo.bookingId);

        //calling shorten url api
        IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
         if(passengerInfos != null && passengerInfos.size() > 0 ){
           for(IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
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
     * @author Chetan Singh, Coforge
     * @date 2022
     *
     * @description Checks if any active manual override blocks exist.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for No Alternative UN event 
        return false;
    }

    /**
     * @author Chetan Singh, Coforge
     * @date 2022
     *
     * @description Executes flow with for each passenger with event specific information.
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.noRebookInfo = noRebookInfo;
        Set<String> airportCodes = new Set<String>();

        //Get the equivalent airport city names and set it in passenger info so that they are accesible in noreboooking templates
        if(passengerInfos.size() >0 && !passengerInfos.isEmpty()) {
            for(IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
                if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0) {
                    for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary) {
                        if(tripInfo.segments != null && tripInfo.segments.size() > 0) {
                            for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments) {
                                if(!airportCodes.contains(segmentInfo.stationArrival)) {
                                    airportCodes.add(segmentInfo.stationArrival);
                                }
                                if(!airportCodes.contains(segmentInfo.stationDeparture)) {
                                    airportCodes.add(segmentInfo.stationDeparture);
                                }
                               
                            }
                        }
                    }
                }
            }
        }
         this.airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(airportCodes);

        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0) {
                for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary) {
                    if(tripInfo.segments != null && tripInfo.segments.size() > 0) {
                        for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments) {
                            segmentInfo.arrivalCity = this.airportInfoMap.get(segmentInfo.stationArrival);
                            segmentInfo.departureCity = this.airportInfoMap.get(segmentInfo.stationDeparture);
                             //New requirement for a link to info on passenger rights for passengers with disabilities when traveling to/from the USA
                             if(noRebookInfo.cancelledSegment ==segmentInfo.segmentId){
                                passengerInfo.cancelledStationArrival = segmentInfo.stationArrival;
                                passengerInfo.cancelledStationDeparture= segmentInfo.stationDeparture;
                             }
                        }
                    }
                }

            }
            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);
        }
    }
    public IRR_EVT_NoRebookProcessor(IRR_MOD_NoRebookInfo noRebookInfo) {
        this.noRebookInfo = noRebookInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_NoRebookProcessor((IRR_MOD_NoRebookInfo) payload);
        }
    }

}