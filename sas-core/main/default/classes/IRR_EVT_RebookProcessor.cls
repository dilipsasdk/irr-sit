/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Disruption Rebook event.
*      Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_RebookProcessor extends IRR_EVT_EventProcessor {

   // private static final String ERROR_NO_EVENT = 'Rebook event details are missing: {0}';
   // private static final String ERROR_BOOKING_ID = 'Booking Id is missing from event: {0}';
   // private static final String ERROR_BOOKING_REF = 'Booking Ref is missing from event: {0}';
   // private static final String ERROR_NO_EVENT_TIME = 'Event time is missing from event: {0}';
   //private static final String ERROR_NO_ADDED_SEGMENTS = 'Added Segments are missing from event: {0}';

   // private static final String EVENT_FLOW_NAME = 'IRR_EVT_RebookFlow';
    @TestVisible
    private IRR_MOD_RebookInfo rebookInfo;
    @TestVisible
    private List<IRR_Constant__mdt> rebookEventConstant;

    public String getEventName() {
        return 'Rebook';
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (rebookInfo == null) {
            throwEventException(rebookEventConstant[0].ERROR_NO_EVENT__c, rebookInfo);
        }
        if (String.isBlank(rebookInfo.bookingId)) {
            throwEventException(rebookEventConstant[0].ERROR_BOOKING_ID__c, rebookInfo);
        }
        if (String.isBlank(rebookInfo.bookingReference)) {
            throwEventException(rebookEventConstant[0].ERROR_BOOKING_REF__c, rebookInfo);
        }
        if (rebookInfo.eventTime == null) {
            throwEventException(rebookEventConstant[0].ERROR_NO_EVENT_TIME__c, rebookInfo);
        }
        if (rebookInfo.addedSegments == null || rebookInfo.addedSegments.isEmpty()) {
            throwEventException(rebookEventConstant[0].ERROR_NO_ADDED_SEGMENTS__c, rebookInfo);
        }
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
        Boolean  canadaStation =false;
        //Retrieve passengers for booking
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(rebookInfo.bookingId);
        if(passengerInfos != null && passengerInfos.size() > 0){
            for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
                if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0){
                    for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary){
                        if(tripInfo.segments != null && tripInfo.segments.size() > 0){
                            for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments){
                                if(segmentInfo.stationArrival =='YYZ' || segmentInfo.stationDeparture =='YYZ'){
                                     canadaStation = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        //calling shorten url api
        IRR_MOD_ShortenURL shrtenUrlRes = new IRR_MOD_ShortenURL();
        if(canadaStation){
            shrtenUrlRes = IRR_SVC_ShortenURLService.generateShortenUrl(new List<String> {System.Label.CA_Passenger_Right});
            if(shrtenUrlRes != null && shrtenUrlRes.shortenedUrls != null){
                for(IRR_MOD_ShortenURL.ShortURL shortURL : shrtenUrlRes.shortenedUrls){
                  rebookInfo.smsCanada = shortURL.shortenedUrl;
                }
            }
            else{
                rebookInfo.smsCanada = System.Label.CA_Passenger_Right;
            }
        }
        else{
            IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
            if(shortenUrl != null && shortenUrl.IRR_EU_Pass_Right_Short_URL__c != null){
                rebookInfo.smsCanada = shortenUrl.IRR_EU_Pass_Right_Short_URL__c;
            }
            else{
                rebookInfo.smsCanada = System.Label.EU_Passenger_Right;
            }
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for Rebook event
        return false;
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Executes flow with for each passenger with event specific information.
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.rebookInfo = rebookInfo;
        Set<String> airportCodes = new Set<String>();
        
        //Process passengers
        if(passengerInfos != null && passengerInfos.size() > 0){
            for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
                if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0){
                    for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary){
                        if(tripInfo.segments != null && tripInfo.segments.size() > 0){
                            for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments){
                                airportCodes.add(segmentInfo.stationArrival);
                                airportCodes.add(segmentInfo.stationDeparture);
                            }
                        }

                    }

                }
            }
        }
                this.airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(airportCodes);

            //Get the equivalent airport city names and set it in passenger info so that they are accesible in reboooking templates
        for(IRR_MOD_PassengerInfo passengerInfo : passengerInfos){
            if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0){
                for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary){
                    if(tripInfo.segments != null && tripInfo.segments.size() > 0){
                        for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments){
                           segmentInfo.arrivalCity = this.airportInfoMap.get(segmentInfo.stationArrival);
                           segmentInfo.departureCity = this.airportInfoMap.get(segmentInfo.stationDeparture);
                           //New requirement for a link to info on passenger rights for passengers with disabilities when traveling to/from the USA
                           String usStation =String.valueOf(System.Label.US_Station);
                           if(segmentInfo.segmentId !=null &&
                             rebookInfo.addedSegments !=null && 
                             rebookInfo.addedSegments.contains(segmentInfo.segmentId) && 
                             usStation.split(';').contains(segmentInfo.stationArrival) ||
                             usStation.split(';').contains(segmentInfo.stationDeparture)
                             ){
                                passengerInfo.isRebookUSStation = true;

                             }
                        }
                    }

                }

            }
            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(rebookEventConstant[0].EVENT_FLOW_NAME__c, flowVariables);  
        }
                
            

        
        
    }

    public IRR_EVT_RebookProcessor(IRR_MOD_RebookInfo rebookInfo) {
        this.rebookInfo = rebookInfo;
        rebookEventConstant = IRR_SEL_ConstantSelector.newInstance().getEventContant('Rebook');
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_RebookProcessor((IRR_MOD_RebookInfo) payload);
        }
    }
}