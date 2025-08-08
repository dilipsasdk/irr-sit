/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
* @description Event Processor for the Airport Change. Inherits and uses functionality from EventProcessor abstract class.
*/
public class IRR_EVT_AirportChangeProcessor extends IRR_EVT_EventProcessor {
    
    private static final String ERROR_NO_EVENT = 'Airport Change event info is missing: {0}';
    private static final String ERROR_BOOKING_ID = 'Booking Id is missing from event: {0}';
    private static final String ERROR_SOURCE = 'Source is missing from event: {0}';
    private static final String ERROR_EVENT_TIME = 'Event Time is missing from event: {0}';
    private static final String ERROR_BOOKING_REFERENCE = 'Booking Reference is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_AirportChangeFlow';
    
    @TestVisible
    private IRR_MOD_AirportChangeInfo airportChangeInfo;
   
    public String getEventName(){
        return 'Airport Change';
    }

    /**
     * @author Ragbirendra Upadhyay, CoforgeTech
     * @date 2023
     *
     * @description Validates event before processing.
     * Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (airportChangeInfo == null) {
            throwEventException(ERROR_NO_EVENT, airportChangeInfo);
        }
        if (String.isBlank(airportChangeInfo.bookingId)) {
            throwEventException(ERROR_BOOKING_ID, airportChangeInfo);
        }
        if (airportChangeInfo.source == null) {
            throwEventException(ERROR_SOURCE, airportChangeInfo);
        }
        if (airportChangeInfo.eventTime == null) {
            throwEventException(ERROR_EVENT_TIME, airportChangeInfo);
        }
        if (airportChangeInfo.bookingReference == null) {
            throwEventException(ERROR_BOOKING_REFERENCE, airportChangeInfo);
        }
    }

    /**
     * @author Ragbirendra Upadhyay, CoforgeTech
     * @date 2023
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
       //Retrieve passengers for booking
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(airportChangeInfo.bookingId);
    }
   
    /**
     * @author Ragbirendra Upadhyay, CoforgeTech
     * @date 2023
     *
     * @description Checks if any active manual override blocks exist for this Booking Id.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
      //Active blocks are currently not applicable for Airport Change event
        return false;
    }

    /**
     * @author Ragbirendra Upadhyay, CoforgeTech
     * @date 2023
     *
     * @description Executes flow with for each passenger with event specific information.
     */
    public void processEvent() {
       //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.airportChangeInfo = airportChangeInfo;

        //Process passengers
        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            //Only process passengers confirmed for this segment
            if (passengerInfo.thisSegment != null && !passengerInfo.thisSegment.isConfirmed) continue;

            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);
        } 
    }

   public IRR_EVT_AirportChangeProcessor(IRR_MOD_AirportChangeInfo airportChangeInfo) {
        this.airportChangeInfo = airportChangeInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            IRR_MOD_AirportChangeInfo payloadAddCurrentYear = (IRR_MOD_AirportChangeInfo) payload;
            payloadAddCurrentYear.year = String.valueOf(System.Today().year());
            return (IRR_EVT_IEventProcessor) new IRR_EVT_AirportChangeProcessor((IRR_MOD_AirportChangeInfo) payload);
        }
    }
}