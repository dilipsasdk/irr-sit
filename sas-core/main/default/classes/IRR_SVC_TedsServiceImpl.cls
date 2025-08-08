/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of Teds Service functionality.
*/

public class IRR_SVC_TedsServiceImpl implements IRR_SVC_ITedsService {

    private static final String NAMED_CREDENTIAL = 'callout:SAS_APIM_TEDS';

    private static String APIM_SUBSCRIPTION_KEY {
        get {
            if (APIM_SUBSCRIPTION_KEY == null) {
                Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
                APIM_SUBSCRIPTION_KEY = org.IsSandbox || Test.isRunningTest() ? 'b8568217401c49acb3931605cea78835' :
                    '992845b5bd6144b0980ade19ac8902f5';
            }
            return APIM_SUBSCRIPTION_KEY;
        }
        private set;
    }

    private static final String API_VERSION = 'v2';

    private static final String BOOKING_ENDPOINT_TEMPLATE = '/teds-booking/bookings/{0}';
    private static final String BOOKINGS_FILTER_ENDPOINT = '/teds-booking/bookings';
    private static final String AIRPORTCODE_ENDPOINT_TEMPLATE = '/teds-airport/airports?ids=';
    private static final String FLIGHT_INFOS_ENDPOINT = '/teds-flight/flights';

    private static final String INTEGRATION_ERROR_TEMPLATE = 'Integration Response: {0} - {1}';

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .setAPIVersion(API_VERSION)
                                .setAPIMSubscriptionKey(APIM_SUBSCRIPTION_KEY)
                                .enableSASTracking()
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

    /**
     * @author Chetan Singh, Coforgetech
     * @date 2020
     *
     * @description Retrieves Airport Information from Teds.
     *
     * @param iataCodes airport codes received in the event info
     *
     * @return Retrieved Airport Details
     */
    public Map<String,String> getAirportCityNames(Set<String> iataCodes) {
        
        Map<String,String> airportInfoMap = new Map<String, String>();
        if(iataCodes != null && iataCodes.size() > 0){

            String endpointURL = AIRPORTCODE_ENDPOINT_TEMPLATE + String.join((Iterable<String>)iataCodes,',');
            C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                    .executeRequest(endpointURL, C_IntegrationExecutor.Method.GET, null, null);
            if (responseObject.statusCode >= 300 || responseObject.statusCode<200) {
                throwTedsException(responseObject);
            }
            List<IRR_MOD_AirportInfo> airportNames = IRR_MOD_AirportInfo.parseArray(responseObject.responseBody);
            for(IRR_MOD_AirportInfo apInfo : airportNames){
                airportInfoMap.put(apInfo.id,apInfo.city);
            }
        }
        return airportInfoMap;
    }

     /**
     * @author Ragbirendra Upadhyay, Coforgetech
     * @date 2023
     *
     * @description Retrieves flight Information from Teds.
     *
     * @param flightId flight codes received in the Scheduled batch
     *
     * @return Retrieved flight Details
     */
    public List<TEDSFlight> getFlightInfos(String flightId) {
        
        List<TEDSFlight> flightList = new List<TEDSFlight>();
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(FLIGHT_INFOS_ENDPOINT+'/'+flightId, C_IntegrationExecutor.Method.GET, null, null);
        if (responseObject.statusCode >= 300 || responseObject.statusCode < 200) {
            throwTedsException(responseObject);
        }
        flightList.add(TEDSFlight.parse(responseObject.responseBody));
        return flightList;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves Booking Details by booking reference.
     *
     * @param bookingId Booking Reference to retrieve details for
     *
     * @return Retrieved Booking Details
     */
    private IRR_MOD_TedsBooking getBookingDetails(String bookingId) {
        String endpointURL = String.format(BOOKING_ENDPOINT_TEMPLATE, new List<String>{bookingId});
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(endpointURL, C_IntegrationExecutor.Method.GET, null, null);
        if (responseObject.statusCode >= 300 || responseObject.statusCode<200) {
            throwTedsException(responseObject);
        }
        IRR_MOD_TedsBooking parsedResponse = IRR_MOD_TedsBooking.parse(responseObject.responseBody);
        return parsedResponse;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves booking details and creates Passenger Infos for all passengers in a booking.
     *
     * @param bookingId Flight Id to retrieve bookings for
     *
     * @return List of Retrieved Booking Details
     */
    public List<IRR_MOD_PassengerInfo> getPassengerInfosForBooking(String bookingId) {
        IRR_MOD_TedsBooking bookings = getBookingDetails(bookingId);
        return initiatePassengerInfos(new List<IRR_MOD_TedsBooking>{bookings}, null,null,null,null,null);
    }

    /**
     * @author Chetan Singh, Coforge
     * @date 2021
     *
     * @description Retrieves Booking Details by Advanced booking filters.
     *
     * @param departureStation returns bookings that have a flight departing from a station
     * @param arrivalStation returns bookings that have a flight arriving to the station
     * @param fromTimeUTC returns bookings that have a flight departing/arriving from that time in UTC
     * @param toTimeUTC returns bookings that have a flight departing/arriving to that time in UTC
     * @return Retrieved Booking Details fetched from TEDS based on filters
     */
    private List<IRR_MOD_TedsBooking> getBookingDetailsWithFilters(String departureStation, 
                                                                    String arrivalStation,
                                                                    String fromTimeUTC,
                                                                    String toTimeUTC) {
        Map<String, String> queryParams = new Map<String, String>{
            'departureStation' => departureStation,
            'arrivalStation' => arrivalStation,
            'fromTimeUTC' => fromTimeUTC,
            'toTimeUTC' => toTimeUTC
            
        };
        Set<String> mapKeystoRemove = new Set<String> ();
        for(String key : queryParams.keySet()){
            if(queryParams.get(key) == null || queryParams.get(key) == 'undefined' ){
                mapKeystoRemove.add(key);
            }
        }
        // The Map class only comes with a remove() method, which only removes one item from the
        //   map at a time.
        // It's not a great idea to modify a collection while you're iterating over it.
        // The solution is to get the map's keyset, then use the set class's removeAll() method.
        // This has the effect of removing multiple items from the map in one shot.
        queryParams.keySet().removeAll(mapKeystoRemove);

        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(BOOKINGS_FILTER_ENDPOINT, C_IntegrationExecutor.Method.GET, null, queryParams);
        if (responseObject.statusCode >= 300 || responseObject.statusCode<200) {
            throwTedsException(responseObject);
        }
        //mutating the large JSON string prior to deserialization was resulting in "Regex too complicated pattern"
        //Hence the decision to desrialize it directly rather than using the parseArray method
        String responseBody = responseObject.responseBody.replace('"number"', '"number_x"'); 
               responseBody = responseBody.replace('"group"', '"GroupInfo"');
        List<IRR_MOD_TedsBooking> tedsBookings = (List<IRR_MOD_TedsBooking>)JSON.deserialize(responseBody, List<IRR_MOD_TedsBooking>.class);
        return tedsBookings;
    }

    /**
     * @author Chetan Singh, Coforge
     * @date 2021
     *
     * @description Retrieves booking details based on filters and creates Passenger Infos for all passengers in a booking.
     *
     * @param departureStation returns bookings that have a flight departing from a station
     * @param arrivalStation returns bookings that have a flight arriving to the station
     * @param fromTimeUTC returns bookings that have a flight departing/arriving from that time in UTC
     * @param toTimeUTC returns bookings that have a flight departing/arriving to that time in UTC
     *
     * @return List of Retrieved Booking Details
     */
    public List<IRR_MOD_PassengerInfo> getPassengerInfosForBookingFilters(String departureStation, 
                                                                            String arrivalStation,
                                                                            String fromTimeUTC,
                                                                            String toTimeUTC) {
        List<IRR_MOD_TedsBooking> bookings = getBookingDetailsWithFilters(departureStation, arrivalStation,fromTimeUTC,toTimeUTC);
        departureStation = departureStation == 'undefined' ? null : departureStation;
        arrivalStation = arrivalStation == 'undefined' ? null : arrivalStation;
        return initiatePassengerInfos(bookings, null, departureStation, arrivalStation ,fromTimeUTC,toTimeUTC);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves a list of booking details by flight id.
     *
     * @param flightId Flight Id to retrieve bookings for
     *
     * @return List of retrieved Booking Details
     */
    private List<IRR_MOD_TedsBooking> getBookingDetailsForFlight(String flightId) {
        Map<String, String> queryParams = new Map<String, String>{
                'flightId' => flightId
        };
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(BOOKINGS_FILTER_ENDPOINT, C_IntegrationExecutor.Method.GET, null, queryParams);
        if (responseObject.statusCode >= 300 || responseObject.statusCode < 200) {
            throwTedsException(responseObject);
        }

        // US 26582: https://dev.azure.com/flysas/Irregularity%20Communication/_workitems/edit/26582/
        
        // List<IRR_MOD_TedsBooking> tedsBookings = IRR_MOD_TedsBooking.parseArray(responseObject.responseBody);
        String responseBody = responseObject.responseBody.replace('"number"', '"number_x"');
               responseBody = responseBody.replace('"group"', '"GroupInfo"');
        List<IRR_MOD_TedsBooking> tedsBookings = (List<IRR_MOD_TedsBooking>)JSON.deserialize(responseBody,List<IRR_MOD_TedsBooking>.class);
        return tedsBookings;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves booking details and creates Passenger Infos for all passengers of a flight.
     *
     * @param flightId Flight Id to retrieve bookings for
     *
     * @return List of Retrieved Booking Details
     * 
     */
    public List<IRR_MOD_PassengerInfo> getPassengerInfosForFlight(String flightId) {
        List<IRR_MOD_TedsBooking> tedsBookings = getBookingDetailsForFlight(flightId);
        return initiatePassengerInfos(tedsBookings, flightId, null, null,null,null);
    }

    private void throwTedsException(C_IntegrationExecutor.IntegrationResponse response) {
        throw new IRR_SVC_TedsService.TedsException(String.format(INTEGRATION_ERROR_TEMPLATE, new List<String>{
                String.valueOf(response.statusCode), response.responseBody}));
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @author Chetan Singh, Coforge
     * @date 2020
     *
     * @description Initiates Passenger Infos from list of TedsBookings.
     *      - Processes trips in the booking to find the current, next and previous segments (if possible)
     *      - Instantiates a Passenger Info object for each passenger in the booking
     *      - Processes Addvanced booking filter inputs to find current, SK operated segments
     *
     * @param tedsBookings List of bookings to create Passenger Infos for
     * @param flightId Current flight id to find segments for (optional)
     * @param departureStation From Station for Advanced Booking Filters(optional)
     * @param arrivalStation To Station for Advanced Booking Filters(optional)
     * @param fromTimeUTC flight departing/arriving from that time in UTC (optional)
     * @param toTimeUTC flight departing/arriving to that time in UTC (optional)
     *
     * @return List of Passenger Infos
     */
    private List<IRR_MOD_PassengerInfo> initiatePassengerInfos(List<IRR_MOD_TedsBooking> tedsBookings,
                                                                String flightId,
                                                                String departureStation,
                                                                String arrivalStation,
                                                                String fromTimeUTC,
                                                                String toTimeUTC ){

        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
        for (IRR_MOD_TedsBooking booking : tedsBookings) {
            IRR_MOD_TedsBooking.SegmentTrip thisSegment;
            IRR_MOD_TedsBooking.SegmentTrip nextSegment;
            IRR_MOD_TedsBooking.SegmentTrip prevSegment;
            Boolean hasFlightId = String.isNotBlank(flightId);
            Boolean hasDeparturesStation = String.isNotBlank(departureStation);
            Boolean hasArrivalStation = String.isNotBlank(arrivalStation);
            List<IRR_MOD_TripInfo> itinerary = new List<IRR_MOD_TripInfo>();
            for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
                //For Advanced Booking Filter ,need to show SK operated FlightIds for all the matching segments
                String cFlightId = '';
                //Using De Morgan's law and XOR operation ,we optimize the entire if else logic.For detailed analysis,
                //check :https://sas-digital.atlassian.net/wiki/spaces/ISol/pages/2180218883/Code+Optimization+decisons
                if (hasFlightId) {
                } else if(!(hasDeparturesStation | hasArrivalStation)) {
                } else {
                    for (IRR_MOD_TedsBooking.SegmentTrip sTrip : trip.segments) {
                        if (!((hasDeparturesStation ^ departureStation == sTrip.flight.departure.station) |
                            (hasArrivalStation ^ arrivalStation == sTrip.flight.arrival.station) ) )  {
                            cFlightId = sTrip.flight.id;
                            break;
                        }
                    }
                }
                //Only process current and next segments when they have not been found and flightId is available
                if ((hasFlightId || String.isNotBlank(cFlightId)) && thisSegment == null) {
                    for (Integer i = 0; i < trip.segments.size(); i++) {
                        IRR_MOD_TedsBooking.SegmentTrip segment = trip.segments[i];
                        if ((segment.flight.operatingId == flightId || segment.flight.id == flightId) || 
                                (segment.flight.operatingId == cFlightId || segment.flight.id == cFlightId)) {
                            thisSegment = segment;
                            //Use previous segment in trip as previous segment if available
                            if (i != 0 && segment.status == IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED) {
                                prevSegment = trip.segments[i-1];
                            }
                            continue;
                        }
                        //Discard unconfirmed segments when looking for next segment
                        if (segment.status != IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED) continue;
                        if (thisSegment!=null) {
                            nextSegment = segment;
                            break;
                        }
                    }
                }
                //Process Itinerary
                List<IRR_MOD_SegmentInfo> tripSegments = new List<IRR_MOD_SegmentInfo>();
                for (IRR_MOD_TedsBooking.SegmentTrip segment : trip.segments) {

                    //Discard unconfirmed segments when constructing itinerary
                    if (segment.status != IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED) continue;
                    tripSegments.add(createSegmentInfo(segment, null));
                }
                if (!tripSegments.isEmpty()) itinerary.add(createTripInfo(trip, tripSegments));

            }
            

            for (IRR_MOD_TedsBooking.Passenger passenger : booking.passengers) {
                IRR_MOD_PassengerInfo passengerInfo = createPassengerInfo(booking, passenger, thisSegment,
                        nextSegment, prevSegment, itinerary);
              //Need to show SK operated flights and only the flights within the departure and arrival time(not flown flights),
             //for Advanced booking filters
                if(!(hasDeparturesStation | hasArrivalStation)){
                    passengerInfos.add(passengerInfo);
                }else {
                    Datetime fromDate = Datetime.valueOfGmt(fromTimeUTC.replace('T' , ' '));
                    Datetime toDate = Datetime.valueOfGmt(toTimeUTC.replace('T' , ' '));
                    Datetime departureDate = Datetime.valueOfGmt(thisSegment.flight.departure.scheduledTime.utc.replace('T', ' '));
                    Datetime arrivalDate = Datetime.valueOfGmt(thisSegment.flight.arrival.scheduledTime.utc.replace('T', ' '));
                    if(thisSegment.flight.operatingCarrier == 'SK' && departureDate >= fromDate &&
                    arrivalDate <= toDate) passengerInfos.add(passengerInfo);
                      }


                  
            }
            //creating group booking pass and adding in list 
             if(
                   booking.passengers.size() > 0 &&   
                   booking.isGroupBooking != null && 
                   booking.isGroupBooking && booking.groupInfo != null && 
                   booking.GroupInfo.contact != null && 
                   booking.GroupInfo.contact.email != null && 
                   booking.GroupInfo.Name != null &&
                   booking.GroupInfo.contact.email.size()>0){

                  Integer i=1;
                  for(IRR_MOD_TedsBooking.Email email : booking.GroupInfo.contact.email){
                    IRR_MOD_PassengerInfo groupingPassInfo = new  IRR_MOD_PassengerInfo();
                    groupingPassInfo = createPassengerInfo(booking, booking.passengers[0], thisSegment,
                    nextSegment, prevSegment, itinerary);
                    groupingPassInfo.lastNameSlashFirstName = booking.GroupInfo.Name ;
                    groupingPassInfo.emailAddress = email.address ;
                    groupingPassInfo.firstName = booking.GroupInfo.Name ;
                    groupingPassInfo.lastName = booking.GroupInfo.Name ;
                    groupingPassInfo.passengerId = 'GroupBooking' + i;
                    groupingPassInfo.codsId = 'deletePass';
                    passengerInfos.add(groupingPassInfo);
                    i++; 
                }
                   
               
                }
        }

      

        return passengerInfos;
    }

    private IRR_MOD_TripInfo createTripInfo(IRR_MOD_TedsBooking.Trip trip, List<IRR_MOD_SegmentInfo> segments) {
        IRR_MOD_TripInfo tripInfo = new IRR_MOD_TripInfo();
        tripInfo.segments = segments;
        tripInfo.tripType = trip.type;
        return tripInfo;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a Segment Info object from TedsBooking segments.
     *
     * @param tripSegment Detailed trip segment booking details
     * @param passengerSegment Passenger specific segment booking details
     *
     * @return Segment Info object
     */
    private IRR_MOD_SegmentInfo createSegmentInfo(IRR_MOD_TedsBooking.SegmentTrip tripSegment,
            IRR_MOD_TedsBooking.Segment passengerSegment) {
        IRR_MOD_SegmentInfo segmentInfo = new IRR_MOD_SegmentInfo();
        if (passengerSegment != null && passengerSegment.ticket != null) {
            segmentInfo.ticketNumber = passengerSegment.ticket.number_x;
        }
         //Added by Gauraav 
        segmentInfo.segmentId = tripSegment.id;
        segmentInfo.flightId = String.isNotBlank(tripSegment.flight.operatingId) ? tripSegment.flight.operatingId :
                tripSegment.flight.id;
        segmentInfo.flightNumber = segmentInfo.flightId.split('-')[0];
        segmentInfo.arrivalTimeLocal = tripSegment.flight.arrival.scheduledTime.local;
        segmentInfo.departureTimeLocal = tripSegment.flight.departure.scheduledTime.local;
        segmentInfo.departureTimeUTC = tripSegment.flight.departure.scheduledTime.utc;
        segmentInfo.arrivalTimeUTC = tripSegment.flight.departure.scheduledTime.utc;
        segmentInfo.stationArrival = tripSegment.flight.arrival.station;
        segmentInfo.stationDeparture = tripSegment.flight.departure.station;
        segmentInfo.status = tripSegment.status;
        segmentInfo.statusCode = tripSegment.statusCode;
        segmentInfo.bookingClass = tripSegment.bookingClass;
        segmentInfo.serviceClass = tripSegment.serviceClass;
                if(passengerSegment !=null && passengerSegment.seat != null){
                    segmentInfo.seat = passengerSegment.seat;
                }
                //Added by Gaurav Icoupan
                if(passengerSegment !=null && passengerSegment.boardingSequenceNumber !=null){
                      segmentInfo.boardingSequenceNumber = passengerSegment.boardingSequenceNumber;
                }
                if(passengerSegment !=null && passengerSegment.checkin != null){
                    segmentInfo.checkInStatus = passengerSegment.checkin.status;
                }
      
        if(tripsegment.remarks != null ) {
            for( IRR_MOD_TedsBooking.Remark remark : tripsegment.remarks) {
                if(remark.type.contains('RXDISRUPT')){
                    segmentInfo.rxType = remark.type;
                    break;
                }
            }
        }

        segmentInfo.isConfirmed = segmentInfo.status == IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED;
        if (String.isNotBlank(segmentInfo.ticketNumber)) {
            segmentInfo.isSASTicket = segmentInfo.ticketNumber.startsWith(IRR_SVC_TedsService.TICKET_IDENTIFIER_SAS);
            segmentInfo.isWideroeTicket = segmentInfo.ticketNumber.startsWith(
                    IRR_SVC_TedsService.TICKET_IDENTIFIER_WIDEROE);
        }
        else {
            segmentInfo.isSASTicket = false;
            segmentInfo.isWideroeTicket = false;
        }
        return segmentInfo;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a single Passenger Info object.
     *
     * @param booking Teds Booking details
     * @param passenger Passenger specific booking details
     * @param tripThisSegment Current trip segment details (optional)
     * @param tripNextSegment Next trip segment details (optional)
     * @param tripPrevSegment Previous trip segment details (optional)
     * @param itinerary Booking Itinerary (optional)
     *
     * @return Passenger Info object
     */
    private IRR_MOD_PassengerInfo createPassengerInfo(IRR_MOD_TedsBooking booking,
            IRR_MOD_TedsBooking.Passenger passenger, IRR_MOD_TedsBooking.SegmentTrip tripThisSegment,
            IRR_MOD_TedsBooking.SegmentTrip tripNextSegment, IRR_MOD_TedsBooking.SegmentTrip tripPrevSegment,
            List<IRR_MOD_TripInfo> itinerary) {

        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.passengerId = booking.id + passenger.id;
        passengerInfo.bookingReference = booking.reference;
        passengerInfo.codsId = booking.codsId;
        passengerInfo.title = passenger.title;
        passengerInfo.firstName = passenger.firstName;
        passengerInfo.lastName  = passenger.lastName;
        passengerInfo.lastNameSlashFirstName = (passengerInfo.lastName + '/' + passengerInfo.firstName).toUpperCase();
        passengerInfo.itinerary = itinerary;

        if (passenger.frequentTraveler != null && passenger.frequentTraveler.euroBonus != null &&
                !passenger.frequentTraveler.euroBonus.isEmpty()) {
            passengerInfo.ebLevel = passenger.frequentTraveler.euroBonus[0].tier;
            passengerInfo.euroBonusNumber = passenger.frequentTraveler.euroBonus[0].number_x;
        }
    
        if (passenger.frequentTraveler != null && passenger.frequentTraveler.other != null) {
            passengerInfo.otherFQTVCarrier = '';
            for (IRR_MOD_TedsBooking.OtherFQTV otherFQTV : passenger.frequentTraveler.other) {
                if (String.isNotBlank(passengerInfo.otherFQTVCarrier)) passengerInfo.otherFQTVCarrier += '; ';
                passengerInfo.otherFQTVCarrier += otherFQTV.carrier;
            }
        }

        if (passenger.specialServiceRequests != null) {
            passengerInfo.SSR = '';
            for (IRR_MOD_TedsBooking.SpecialServiceRequests request : passenger.specialServiceRequests) {
                if (String.isNotBlank(passengerInfo.SSR)) passengerInfo.SSR += '; ';
                passengerInfo.SSR += request.code;
                
                if(request.frequentTraveler != null && 
                    !request.frequentTraveler.isEmpty() &&
                    request.frequentTraveler.size() >= 2 &&
                    request.frequentTraveler[1].tier != null && 
                    request.frequentTraveler[0].carrier != 'SK' &&
                    request.frequentTraveler[1].tier.level != null){
                    passengerInfo.ebLevel = request.frequentTraveler[1].tier.level;
            }

            }
        }

        String phoneAP;
        String phoneCTC;
        for (IRR_MOD_TedsBooking.Phone phone  : passenger.contact.phone) {
            if (String.isBlank(phone.type)) continue;
            if (phone.type.startsWith('CTC')) {
                phoneCTC = phone.number_x;
            }
            else if (phone.type.startsWith('AP')) {
                phoneAP = phone.number_x;
            }
        }
        passengerInfo.phoneNumber = String.isNotBlank(phoneCTC) ? phoneCTC : phoneAP;


        String emailAP;
        String emailCTC;
        for (IRR_MOD_TedsBooking.Email email : passenger.contact.email) {
            if (String.isBlank(email.type)) continue;
            if (email.type.startsWith('CTC')) {
                emailCTC = email.address;
            }
            else if (email.type.startsWith('AP')) {
                emailAP = email.address;
            }
        }
        passengerInfo.emailAddress = String.isNotBlank(emailCTC) ? emailCTC : emailAP;

        if (tripThisSegment != null) {
            IRR_MOD_TedsBooking.Segment passengerThisSegment;
            IRR_MOD_TedsBooking.Segment passengerNextSegment;
            IRR_MOD_TedsBooking.Segment passengerPrevSegment;

            for (IRR_MOD_TedsBooking.Segment segment : passenger.segments) {
                
                if (segment.segmentId == tripThisSegment.id) {
                    passengerThisSegment = segment;
                    //added by Gaurav Icoupon
                    passengerThisSegment.boardingSequenceNumber = segment.boardingSequenceNumber;
                    passengerInfo.hasBoarded = segment.isBoarded;
                    if(segment.seat != null){
                        passengerThisSegment.seat = segment.seat;
                    }
                }
                if (tripNextSegment != null && segment.segmentId == tripNextSegment.id) passengerNextSegment = segment;
                if (tripPrevSegment != null && segment.segmentId == tripPrevSegment.id) passengerPrevSegment = segment;
            }

            passengerInfo.thisSegment = createSegmentInfo(tripThisSegment, passengerThisSegment);

            if (tripNextSegment!=null && passengerNextSegment!=null) {
                passengerInfo.nextSegment = createSegmentInfo(tripNextSegment, passengerNextSegment);
            }

            if (tripPrevSegment!=null && passengerPrevSegment != null) {
                passengerInfo.prevSegment = createSegmentInfo(tripPrevSegment, passengerPrevSegment);
            }
        }

        passengerInfo.hasThisSegment = passengerInfo.thisSegment != null;
        passengerInfo.hasPhoneNumber = String.isNotBlank(passengerInfo.phoneNumber);
        passengerInfo.hasEmailAddress = String.isNotBlank(passengerInfo.emailAddress);
        passengerInfo.hasNextSegment = passengerInfo.nextSegment != null;
        passengerInfo.hasPrevSegment = passengerInfo.prevSegment != null;
        for(IRR_MOD_TripInfo tripInfo : passengerInfo.itinerary ){
            Boolean hasRxdisrupt = false;
            for(IRR_MOD_SegmentInfo segment : tripInfo.segments ) {
                passengerInfo.hasRXLine  = segment.rxType != null;
                hasRxdisrupt = passengerInfo.hasRXLine;
                break;
            }
            if(hasRxdisrupt) break;
        }

        return passengerInfo;
    }
}