public with sharing class TEDSReservation extends Reservation {
  private Map<String, List<IRR_MOD_TedsBooking.Segment>> segmentsPerPassenger {
    get;
    set;
  }
  private Map<String, List<IRR_MOD_TedsBooking.SpecialServiceRequests>> ssrPerPassenger {
    get;
    set;
  }

  public TEDSReservation(IRR_MOD_TedsBooking tedsBooking) {
    super();
    this.segmentsPerPassenger = new Map<String, List<IRR_MOD_TedsBooking.Segment>>();
    this.ssrPerPassenger = new Map<String, List<IRR_MOD_TedsBooking.SpecialServiceRequests>>();
    this.booking = constructBookingFromSourceData(tedsBooking);

    this.flights = constructFlightsFromSourceData(tedsBooking.trips);
    this.booking.flights = new Set<Flight>(this.flights.values());
    this.booking.passengers = constructPassengersFromSourceData(
      tedsBooking.passengers
    );
    this.booking.segments = constructSegmentsFromSourceData(tedsBooking.trips);
  }

  public override Booking constructBookingFromSourceData(Object sourceData) {
    IRR_MOD_TedsBooking tBooking = (IRR_MOD_TedsBooking) sourceData;

    Booking b = new Booking(
      new Booking__c(
        Booking_Reference__c = tBooking.reference,
        Created_at_Travel_Office_Id__c = tBooking?.audit?.created?.officeId ==
          null
          ? ''
          : tBooking.audit.created.officeId,
        Name = tBooking.id,
        TEDS_Identifier__c = tBooking.id,
        Type__c = tBooking.type,
        Is_Cancelled__c = tBooking.isCancelled
      )
    );
    return b;
  }
  public override List<Passenger> constructPassengersFromSourceData(
    List<Object> sourceData
  ) {
    List<IRR_MOD_TedsBooking.Passenger> tedsPassengers = (List<IRR_MOD_TedsBooking.Passenger>) sourceData;
    List<Passenger> passengers = new List<Passenger>();
    for (IRR_MOD_TedsBooking.Passenger tedsPassenger : tedsPassengers) {
      Passenger p = new Passenger(
        new Passenger__c(
          First_Name__c = tedsPassenger.firstName,
          Identifier__c = tedsPassenger.id,
          Last_Name__c = tedsPassenger.lastName
        )
      );
      p.firstName = tedsPassenger.firstName;
      p.lastName = tedsPassenger.lastName;
      p.identifier = tedsPassenger.id;
      if (tedsPassenger.frequentTraveler.euroBonus.size() > 0) {
        p.euroBonusNumber = tedsPassenger.frequentTraveler.euroBonus[0]
          .number_x;
      }

      if (tedsPassenger.contact.phone.size() > 0) {
        p.phone = tedsPassenger.contact.phone[0].number_x;
      }

      if (
        tedsPassenger.contact.email.size() > 0 &&
        StringUtils.isEmailAddress(tedsPassenger.contact.email[0].address)
      ) {
        p.email = tedsPassenger.contact.email[0].address;
      }
      this.segmentsPerPassenger.put(p.identifier, tedsPassenger.segments);
      if (tedsPassenger.specialServiceRequests.size() > 0) {
        this.ssrPerPassenger.put(
          p.identifier,
          tedsPassenger.specialServiceRequests
        );
      }
      passengers.add(p);
    }
    return passengers;
  }

  public override List<Segment> constructSegmentsFromSourceData(
    List<Object> sourceData
  ) {
    List<Segment> segments = new List<Segment>();
    List<IRR_MOD_TedsBooking.Trip> trips = (List<IRR_MOD_TedsBooking.Trip>) sourceData;
    Map<String, Map<String, IRR_MOD_TedsBooking.SegmentTrip>> segmentsPerTrip = new Map<String, Map<String, IRR_MOD_TedsBooking.SegmentTrip>>();
    Map<String, String> segmentToType = new Map<String, String>();
    for (IRR_MOD_TedsBooking.Trip trip : trips) {
      if (!segmentsPerTrip.containsKey(trip.type)) {
        segmentsPerTrip.put(
          trip.type,
          new Map<String, IRR_MOD_TedsBooking.SegmentTrip>()
        );
      }
      for (IRR_MOD_TedsBooking.SegmentTrip segment : trip.segments) {
        segmentsPerTrip.get(trip.type).put(segment.id, segment);
        segmentToType.put(segment.id, trip.type);
      }
    }
    for (Passenger p : this.booking.passengers) {
      for (
        IRR_MOD_TedsBooking.Segment segment : this.segmentsPerPassenger.get(
          p.identifier
        )
      ) {
        List<String> ssrs = new List<String>();

        if (ssrPerPassenger.containsKey(p.identifier)) {
          for (
            IRR_MOD_TedsBooking.SpecialServiceRequests ssr : ssrPerPassenger.get(
              p.identifier
            )
          ) {
            if (!ssr.segmentIds.contains(segment.segmentId)) {
              continue;
            }
            ssrs.add(ssr.code);
          }
        }

        IRR_MOD_TedsBooking.SegmentTrip segmentTrip = segmentsPerTrip.get(
            segmentToType.get(segment.segmentId)
          )
          .get(segment.segmentId);

        Integer baggage = (segment.baggage != null) &&
          (segment.baggage.quantity != null)
          ? segment.baggage.quantity.allowed + segment.baggage.quantity.extra
          : 0;

        Segment s = new Segment(
          new Segment__c(
            Baggage_Quantity__c = baggage,
            Booking_Class__c = segmentTrip.bookingClass,
            Check_In_Status__c = segment.checkin == null
              ? 'Unknown'
              : segment.checkin.status,
            Fare_Basis__c = segment.fare == null ? '' : segment.fare.basis,
            Identifier__c = segmentTrip.id + p.identifier,
            Is_Boarded__c = segment.isBoarded,
            Name = segmentTrip.flight.id,
            Seat__c = segment.seat,
            Segment_Status__c = segmentTrip.status,
            Segment_Status_Code__c = segmentTrip.statusCode,
            Service_Class__c = segmentTrip.serviceClass,
            Special_Service_Requests__c = String.join(ssrs, ','),
            Ticket_Number__c = segment.ticket == null
              ? ''
              : segment.ticket.number_x,
            Ticket_Type__c = segment.ticket == null ? '' : segment.ticket.type,
            Trip_Type__c = segmentToType.get(segmentTrip.id)
          )
        );
        s.flight = this.flights.get(segmentTrip.flight.id);
        segments.add(s);
      }
    }
    return segments;
  }

  public override Map<String, Flight> constructFlightsFromSourceData(
    List<Object> sourceData
  ) {
    List<IRR_MOD_TedsBooking.Trip> trips = (List<IRR_MOD_TedsBooking.Trip>) sourceData;
    Map<String, Flight> flights = new Map<String, Flight>();
    for (IRR_MOD_TedsBooking.Trip t : trips) {
      for (IRR_MOD_TedsBooking.SegmentTrip segmentTrip : t.segments) {
        if (
          segmentTrip.flight == null ||
          flights.containsKey(segmentTrip.flight.id)
        ) {
          continue;
        }
        String flightId = segmentTrip.flight.id.trim().toUpperCase();

        // Create flights
        Datetime arrivalDate = Datetime.valueOf(
          segmentTrip.flight.arrival.scheduledTime.utc.replace('T', ' ')
            .replace('Z', '')
        );
        Datetime departureDate = Datetime.valueOf(
          segmentTrip.flight.departure.scheduledTime.utc.replace('T', ' ')
            .replace('Z', '')
        );
        String scheduledArrivalDateLocal = segmentTrip.flight.arrival.scheduledTime
          ?.local
          ?.replace('Z', '');

        String scheduledDepartureDateLocal = segmentTrip.flight.departure.scheduledTime
          ?.local
          ?.replace('Z', '');

        Flight f = new Flight(
          new Flight__c(
            Name = flightId,
            Arrival_Airport__c = segmentTrip.flight.arrival.station,
            Departure_Airport__c = segmentTrip.flight.departure.station,
            Operating_Carrier__c = segmentTrip.flight.operatingCarrier,
            Scheduled_Arrival_Time__c = arrivalDate,
            Scheduled_Arrival_Time_Local__c = scheduledArrivalDateLocal,
            Scheduled_Departure_Time__c = departureDate,
            Scheduled_Departure_Time_Local__c = scheduledDepartureDateLocal,
            TEDS_Identifier__c = flightId
          )
        );
        flights.put(flightId, f);
      }
    }

    return flights;
  }
}
