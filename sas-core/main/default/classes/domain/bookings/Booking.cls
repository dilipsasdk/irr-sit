public without sharing class Booking extends AbstractSObjectWrapper {
  public Booking__c underlyingSObject { get; private set; }

  public String bookingReference;
  public String createdAtTravelOfficeId;
  public Boolean isCancelled = false;
  public Boolean isStaffBooking = false;
  public String tedsIdentifier;
  public Type type;

  public List<Segment> segments;
  public List<Passenger> passengers;

  @TestVisible
  public Set<Flight> flights {
    get {
      if (this.segments == null) {
        return null;
      }
      Set<Flight> toReturn = new Set<Flight>();

      for (Segment s : this.segments) {
        if (s.flight != null) {
          toReturn.add(s.flight);
        }
      }

      return toReturn;
    }
    set;
  }

  public enum Type {
    DayReturn,
    MultiCity,
    OneWay,
    RoundTrip,
    Unknown
  }

  @TestVisible
  private Booking() {
    this.underlyingSObject = new Booking__c();
  }

  public Booking(Booking__c b) {
    super(b);
    this.underlyingSObject = b;

    this.bookingReference = b.Booking_Reference__c;
    this.createdAtTravelOfficeId = b.Created_at_Travel_Office_Id__c;
    this.isCancelled = b.Is_Cancelled__c;
    this.isStaffBooking = b.Is_Staff_Booking__c;
    this.tedsIdentifier = b.TEDS_Identifier__c;
    this.type = TYPE_PICKLIST_VALUE_TO_ENUM.get(b.Type__c);

    if (b.Segments__r != null) {
      List<Segment> segmentsForBooking = new List<Segment>();
      List<Flight> flightsForBooking = new List<Flight>();
      for (Segment__c segmentSObject : b.Segments__r) {
        Segment s = new Segment(segmentSObject);
        segmentsForBooking.add(s);
      }

      segmentsForBooking.sort();
      this.segments = segmentsForBooking;
    }

    if (b.Passengers__r != null) {
      List<Passenger> passengersForBooking = new List<Passenger>();
      for (Passenger__c p : b.Passengers__r) {
        passengersForBooking.add(new Passenger(p));
      }
      this.passengers = passengersForBooking;
    }
  }

  private static final Map<String, Type> TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, Type>{
    'DayReturn' => Type.DayReturn,
    'MultiCity' => Type.MultiCity,
    'OneWay' => Type.OneWay,
    'RoundTrip' => Type.RoundTrip,
    'Unknown' => Type.Unknown
  };

  private static final Map<Type, String> TYPE_ENUM_TO_PICKLIST_VALUE = new Map<Type, String>{
    Type.DayReturn => 'DayReturn',
    Type.MultiCity => 'MultiCity',
    Type.OneWay => 'OneWay',
    Type.RoundTrip => 'RoundTrip',
    Type.Unknown => 'Unknown'
  };

  public override void updateSObjectFields() {
    this.underlyingSObject.Booking_Reference__c = this.bookingReference;
    this.underlyingSObject.Created_at_Travel_Office_Id__c = this.createdAtTravelOfficeId;
    this.underlyingSObject.Is_Cancelled__c = this.isCancelled;
    this.underlyingSObject.Is_Staff_Booking__c = this.isStaffBooking;
    this.underlyingSObject.TEDS_Identifier__c = this.tedsIdentifier;
    this.underlyingSObject.Type__c = TYPE_ENUM_TO_PICKLIST_VALUE.get(this.type);
  }

  public class UnsupportedException extends Exception {
  }

  /**
   * Returns true if given flight exists in the booking.
   *
   * @param flightId A flight in the format of Flight Number-Flight Date (ex. SK0001-20201010)
   * @throws MissingDataException if this booking instance doesn't have flights set.
   */
  public Boolean containsFlight(String flightId) {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (f.tedsIdentifier.substring(0, 15) == flightId) {
        return true;
      }
    }

    return false;
  }

  /**
   * Returns true if a passenger with the given last name exists in this booking.
   * Case insensitive.
   *
   * @param passengerLastName Last name of the passenger to check
   * @throws MissingDataException if this booking instance doesn't have passengers set.
   */
  public Boolean containsPassenger(String passengerLastName) {
    if (this.passengers == null) {
      throw new MissingDataException('Missing passengers.');
    }

    for (Passenger p : this.passengers) {
      if (p.lastName.toLowerCase() == passengerLastName.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /**
   * Returns true if any flights in this booking have been delayed or cancelled.
   *
   * @throws MissingDataException if this booking doesn't have flights set.
   */
  public Boolean hasDelayedOrCancelledFlights() {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (f.isDelayedOrCancelled()) {
        return true;
      }
    }

    return false;
  }

  /**
   * Whether the booking has a non Star Alliance operating carrier for at
   * least one leg in the booking.
   *
   * Needs flights to be populated.
   *
   * @return A map from booking id to whether that booking has non Star
   * Alliance operating carriers as a part of the journey.
   */
  public Boolean hasNonStarAllianceOperatingCarriers() {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (!f.isOperatedByStarAlliance()) {
        return true;
      }
    }
    return false;
  }

  public void setAirports(Map<String, Airport> airportCodeToAirportObjects) {
    for (Segment s : segments) {
      if (s.flight == null) {
        continue;
      }
      s.flight.departureAirportObject = airportCodeToAirportObjects.get(
        s.flight.departureAirport
      );
      s.flight.arrivalAirportObject = airportCodeToAirportObjects.get(
        s.flight.arrivalAirport
      );
    }
  }

  /**
   * Divides the flights in the booking into different trips. If there is an issue, the booking's trip(s) get set to null.
   * If the booking is a OneWay there should only be one trip.
   * If the booking is a Roundtrip or Dayreturn there should be two trips.
   * If the booking is a MultiCity there can be 1(?) or more trips.
   *
   * The compensation should, logically, be calculated with respect to each "final destination" in the booking (see EU261 Article 2 h: https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * When a pax stays in a city for more than 24 hours it counts as a "final destination" according to internal SAS policy.
   * After 24 hours the booking is considered a "package" under EU law (Council Directive 90/314/EEC Article 2 §1: https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=celex%3A31990L0314)
   *
   * @return A list of trips based on the status of all segments at the current time
   */
  public List<Trip> getTrips() {
    return getTripsAtTime(System.now());
  }

  /**
   * Like getTrips() but you can get the trips at a specific time. E.g. before a cancellation.
   */
  public List<Trip> getTripsAtTime(Datetime theTime) {
    return Trip.createFromBooking(this, theTime);
  }

  /**
   * A "dirty" trip takes into account all flights, active or not.
   * This type of trip is only useful for analysis.
   */
  public List<Trip> getTripsDirty() {
    return Trip.createFromBooking(this, null);
  }

  public List<Segment> getSegmentsForFlight(Flight f) {
    List<Segment> claimSegments = new List<Segment>();
    for (Segment s : this.segments) {
      if (s.flight == f) {
        claimSegments.add(s);
      }
    }
    return claimSegments;
  }

  public Trip.CancellationTime getCancellationTime(Flight f) {
    List<FlightIrregularity> cancellations = f.getCancellations();

    if (cancellations.size() > 1) {
      throw new UnsupportedException(
        'Bookings with flights which have more than one cancellation are not supported'
      );
    }

    FlightIrregularity cancellation = cancellations[0];
    if (cancellation.cancellationTime == null) {
      throw new MissingDataException(
        'Cancellation does not have a cancellation time'
      );
    }

    // Make sure all segments for the flight have the same history
    Datetime segmentUnconfirmed;
    Datetime segmentRemoved;
    String officeUnconfirming;
    String officeRemoving;
    for (Segment s : getSegmentsForFlight(f)) {
      SegmentEvent unconfirmedEvent = s.getUnconfirmedEvent();
      SegmentEvent removedEvent = s.getRemovedEvent();

      Datetime currentSegmentUnconfirmed;
      if (unconfirmedEvent != null) {
        currentSegmentUnconfirmed = unconfirmedEvent.updateDate;
        officeUnconfirming = unconfirmedEvent.officeCode;
      }
      Datetime currentSegmentRemoved;
      if (removedEvent != null) {
        currentSegmentRemoved = removedEvent.updateDate;
        officeRemoving = removedEvent.officeCode;
      }

      if (
        currentSegmentUnconfirmed != segmentUnconfirmed &&
        segmentUnconfirmed != null
      ) {
        throw new Trip.InvalidException(
          'Segments with the same flight were unconfirmed at different times'
        );
      }
      segmentUnconfirmed = currentSegmentUnconfirmed;

      if (currentSegmentRemoved != segmentRemoved && segmentRemoved != null) {
        throw new Trip.InvalidException(
          'Segments with the same flight were removed at different times'
        );
      }
      segmentRemoved = currentSegmentRemoved;
    }

    if (segmentUnconfirmed == null && segmentRemoved == null) {
      throw new Trip.InvalidException(
        'Was not able to get segment cancellation time'
      );
    }

    return new Trip.CancellationTime(
      cancellation.cancellationTime,
      segmentUnconfirmed,
      segmentRemoved,
      officeUnconfirming,
      officeRemoving
    );
  }

  /**
   * Calculates the trip with the cancelled flight before the cancellation and the replacement trip
   *
   * @throws Trip.InvalidException if the trips calculated are invalid.
   * @throws Trip.BookingTypeNotSupportedException if the booking type is not yet supported.
   * @throws Segment.UnsupportedException if there are unsupported segment event statuses
   * @throws Trip.RouteException if there is an error when checking the trip validity (infinite loop)
   * @throws AbstractSObjectWrapper.MissingDataException if there is no cancellation time
   * @throws Booking.UnsupportedException if there is more than one cancellation
   */
  public List<Trip> getTripsBeforeAndAfterCancellation(Flight cancelledFlight) {
    Trip.CancellationTime cancellationTimeInfo = getCancellationTime(
      cancelledFlight
    );
    Datetime unconfirmed = cancellationTimeInfo.unconfirmed;
    Datetime removed = cancellationTimeInfo.removed;

    List<Trip> tripsBeforeIrregularity;
    if (unconfirmed != null) {
      tripsBeforeIrregularity = getTripsAtTime(unconfirmed.addMinutes(-5)); // Arbitrary
    } else {
      tripsBeforeIrregularity = getTripsAtTime(removed.addMinutes(-5));
    }

    Trip tripWithCancelledFlight = Trip.getTripWithFlight(
      tripsBeforeIrregularity,
      cancelledFlight
    );
    tripWithCancelledFlight.cancellationTimeInfo = cancellationTimeInfo;

    if (tripWithCancelledFlight == null) {
      throw new Trip.InvalidException(
        'was not able to set trip with claim flight'
      );
    }

    // First try to calculate this based on the UN time, then the removed time
    Trip replacementTrip;
    try {
      List<Segment> activeSegments = getActiveSegmentsAtTime(unconfirmed);

      replacementTrip = tripWithCancelledFlight.getOfferedRebooking(
        activeSegments
      );
      if (replacementTrip == null) {
        throw new Trip.InvalidException('No replacement');
      }
    } catch (Trip.InvalidException e) {
      List<Segment> activeSegments = getActiveSegmentsAtTime(removed);

      // Typically happens when an agent has manually rebooked the passengers
      replacementTrip = tripWithCancelledFlight.getOfferedRebooking(
        activeSegments
      );
    }

    return new List<Trip>{ tripWithCancelledFlight, replacementTrip };
  }

  public Trip getTripWithFlight(Flight f) {
    return Trip.getTripWithFlight(getTrips(), f);
  }

  public Boolean hasReinstated(Flight f) {
    List<Segment> segments = this.getSegmentsForFlight(f);

    for (Segment s : segments) {
      if (s.hasBeenReinstated()) {
        return true;
      }
    }
    return false;
  }

  /**
   * Returns true if the given string is a valid booking reference.
   *
   * Valid booking reference is 5-6 alphanumeric characters. There are also
   * stricter limitations, but just in case they aren't fully universal, this
   * is a relatively lenient check.
   */
  public static Boolean isValidBookingReference(String bookingReference) {
    if (String.isBlank(bookingReference)) {
      return false;
    }

    return Pattern.compile('[a-zA-Z0-9]{5,6}')
      .matcher(bookingReference)
      .matches();
  }

  public static List<Booking> createFromList(List<Booking__c> bookings) {
    List<Booking> toReturn = new List<Booking>();

    for (Booking__c b : bookings) {
      toReturn.add(new Booking(b));
    }

    return toReturn;
  }

  public List<Segment> getActiveSegmentsAtTime(Datetime theTime) {
    U.verifyNotNull(segments);

    List<Segment> activeSegments = new List<Segment>();
    for (Segment s : segments) {
      if (s.getStatus(theTime) == Segment.Status.Confirmed) {
        activeSegments.add(s);
      }
    }

    return activeSegments;
  }

  public class InsufficientDataException extends Exception {
  }

  /**
   * Returns an overview of the booking history
   */
  public String getReadableAmadeusHistory() {
    // 1. Sort out segments so we don't have any duplicates, only one segment per flight__c
    Set<Segment> segSet = new Set<Segment>();
    Set<Id> flightIds = new Set<Id>();
    for (Segment seg : this.segments) {
      if (!flightIds.contains(seg.flightId)) {
        segSet.add(seg);
      }
    }

    if (this.segments == null) {
      return 'No segments found'; // Do not throw, there might not be segments
    }

    // Template strings:
    String flightInfoTemplate = '{0} {1}';
    String irregularityTemplate = '{0} ({1})';
    String fullFlightTemplate = '{0} | {1} -> {2} | ({3} -> {4}) ({5}) ({6})';
    String eventTemplate = '{0}: {1}, {2}, {3}';

    // 2. Construct a readable string for each segment. It should Look like this:
    //   Flight: SK1234, Departure: 07/12 12:00, Arrival: 07/12 13:00
    //   Events:
    //   1: NEW_STATUS, PREVIOUS_STATUS, 07/01 12:00
    //   2: NEW_STATUS, PREVIOUS_STATUS, 07/01 12:00
    List<String> result = new List<String>();
    for (Segment seg : new List<Segment>(segSet)) {
      // Make date and time readable
      String depTime = StringUtils.dateTimeToReadable(
        seg.flight.scheduledDepartureTime
      );
      String arrTime = StringUtils.dateTimeToReadable(
        seg.flight.scheduledArrivalTime
      );
      String actualDepTime = StringUtils.dateTimeToReadable(
        seg.flight.actualDepartureTime
      );
      String actualArrTime = StringUtils.dateTimeToReadable(
        seg.flight.actualArrivalTime
      );

      String teds = seg.flight.tedsIdentifier;
      String airportInfo = teds.substringAfter('-')
        .substringAfter('-')
        .replace('-', ' -> ');
      String flightInfo = String.format(
        flightInfoTemplate,
        new List<String>{ teds.substringBefore('-'), airportInfo }
      );

      String irregString = '';
      if (seg.flight.irregularities == null) {
        throw new InsufficientDataException('Irregularities not set');
      }

      List<FlightIrregularity> uniqueIrregularities = FlightIrregularity.unique(
        seg.flight.irregularities
      );
      List<String> irregInfo = new List<String>();

      for (FlightIrregularity irreg : uniqueIrregularities) {
        String additionalInfo;
        if (irreg.cancellationTime == null) {
          // Likely delay or invalid
          additionalInfo = irreg.durationMinutes + ' minutes';
        } else {
          // Cancellation
          additionalInfo = StringUtils.dateTimeToReadable(
            irreg.cancellationTime
          );
        }

        irregInfo.add(
          String.format(
            irregularityTemplate,
            new List<String>{ irreg.code, additionalInfo }
          )
        );
      }

      irregString = String.join(irregInfo, ', ');

      if (irregInfo.size() == 0) {
        irregString = 'No irregularities';
      }

      String boardedInfo = seg.isBoarded ? 'Boarded' : 'Not boarded';
      if (seg.isBoarded == null)
        boardedInfo = 'Boarded?';
      if (flightInfo.substring(0, 2) != 'SK')
        boardedInfo = 'Boarded?';

      String fullFlight = String.format(
        fullFlightTemplate,
        new List<String>{
          flightInfo,
          depTime,
          arrTime,
          actualDepTime,
          actualArrTime,
          boardedInfo,
          irregString
        }
      );

      result.add(fullFlight);

      if (seg.getEvents() == null) {
        throw new InsufficientDataException('Events not set');
      }

      for (SegmentEvent segEvent : seg.getEvents()) {
        String eventInfo = String.format(
          eventTemplate,
          new List<Object>{
            segEvent.updateNumber,
            segEvent.newStatus,
            segEvent.operationType,
            StringUtils.dateTimeToReadable(segEvent.updateDate)
          }
        );
        result.add(eventInfo);
      }
    }

    String toReturn = String.join(result, '\n');

    return toReturn;
  }

  /**
    1. Search for cancellation to find original and replacement.

    (IF CANCELLATION (if finalTrip != null)) 2 a.
    2a.1. Do cancellation logic (return)

    (IF NOT) 2 b.
    2b.1. Get trip with claim flight at current time. (after)
    2b.2. Get trip with at (or a little before, 1h?) the time of the first scheduled departure of this trip. (before, not perfect)
        ! If there are more than one flight from one airport -> UnableToHandle (maybe)

    3. Check delay time -> deny? (return)
    3.1 Compare the scheduled arrival of the last flight in the original booking with the actual (if possible) arrival of the last flight in the final booking.

    4. Find root cause
        Rewamped, see Trip

    Notes:
    * Check boarded! (might be a solution for more than one TK from one airport). Boarded data is waaay to poisoned to be used.
    * If a flight is added to a booking, the flight(s) it replaces are UN:ed (if SAS does the booking)
    * HX -> customer did not arrive in time from a flight (non SK)
    * The customer is never(ish) re-booked before we know they will be late.
    * Sometimes the flight is diverted or buses are introduced (which is not reflected in the PNR history)
    * Checkin status should be checked
   */
  public Trip.RootCause getRootCauseAndEffect(Flight flightInAffectedTrip) {
    // 0. Get the trip with the flight in it.
    List<Trip> dirtyTrips = getTripsDirty();
    List<Trip> mergedDirtyTrips = Trip.mergeSimilarTrips(dirtyTrips);
    Trip affectedTripDirty = Trip.getTripWithFlight(
      mergedDirtyTrips,
      flightInAffectedTrip
    );

    // 1. Search for cancellation to find original and replacement.
    Trip.RootCause cancellationRootCause = checkIfCancellationIsRootCause(
      affectedTripDirty
    );

    if (cancellationRootCause != null) {
      return cancellationRootCause;
    }

    // When the trip reaches the destination, there should be a snapshot of the resulting trip.
    Datetime affectedTripDirtyArrival = affectedTripDirty.getFinalDestinationArrivalTime();
    Trip resultingTrip = affectedTripDirty.getDirtyTripSnapshotAtTime(
      affectedTripDirtyArrival
    ); // This is solid, at least relatively

    // This is done to account for multiple re-bookings
    // One scenario that can be handled incorrectly using this method is if the PAX gets a flight with a departure
    // before the original departure of the first flight in the original trip and this causes the pax to arrive late.
    // If the flight is also added more than an hour before its departure it might lead to an incorrect denial.
    Datetime originalDeparture = affectedTripDirty.getFirstDepartureOverlappingWith(
      resultingTrip.getDeparture()
    );
    Datetime timeWhenTripShouldBeUnaffected = originalDeparture.addHours(-1); // Can't be extended too long (late bookings + rebookings)
    Trip originalTrip = affectedTripDirty.getDirtyTripSnapshotAtTime(
      timeWhenTripShouldBeUnaffected
    );

    if (resultingTrip == null || originalTrip == null) {
      throw new Trip.InvalidException(
        'The resulting or original trip does not have any active flights despite there being no cancellations.'
      );
    } else if (resultingTrip.originAirport != originalTrip.originAirport) {
      throw new Trip.InvalidException(
        'The resulting and original trip does not have the same origin airport.'
      );
    } else if (
      resultingTrip.destinationAirport != originalTrip.destinationAirport
    ) {
      throw new Trip.InvalidException(
        'The resulting and original trip does not have the same destination airport.'
      );
    } else if (
      affectedTripDirty.hasFlightWithUNBeforeTime(
        timeWhenTripShouldBeUnaffected
      )
    ) {
      throw new Trip.InvalidException(
        'The affected trip has a flight which could have been removed because of a future delay'
      );
    }

    // 3. Check delay time -> deny? (return)
    Datetime originalTripLastArrival = originalTrip.getFlightToFinalDestination()
      .scheduledArrivalTime;
    Datetime finalTripLastArrival = resultingTrip.getFinalDestinationArrivalTime();

    Decimal arrivalDifferenceHours = DateUtils.getHoursBetween(
      originalTripLastArrival,
      finalTripLastArrival
    );

    if (originalTrip.hasTwoOrMoreDeparturesFromOneAirport()) {
      throw new Trip.InvalidException(
        'There are multiple departures from one airport in the original trip'
      );
    } else if (resultingTrip.hasTwoOrMoreDeparturesFromOneAirport()) {
      throw new Trip.InvalidException(
        'There are multiple departures from one airport in the resulting trip'
      );
    }

    if (
      arrivalDifferenceHours < 3 ||
      originalTripLastArrival > finalTripLastArrival
    ) {
      Trip.RootCause cause = new Trip.RootCause(
        null,
        Trip.RootCauseType.SHORTDELAY,
        'Delay is less than 3 hours'
      );
      cause.originalTrip = originalTrip;
      cause.resultingTrip = resultingTrip;
      return cause; // TODO: extend
    }

    // 4. Find root cause
    return Trip.getRootCauseDelay(originalTrip, resultingTrip);
  }

  private Trip.RootCause checkIfCancellationIsRootCause(
    Trip affectedTripDirty
  ) {
    Map<Id, Flight> idToFlight = new Map<Id, Flight>();
    for (Flight f : flights) {
      idToFlight.put(f.id, f);
    }

    // TODO: check for hidden cancellation, currently filtered out above

    Trip originalTrip;
    Trip replacementTrip;
    Trip.RootCause rootCause;
    List<FlightIrregularity> sortedCancellations = affectedTripDirty.getSortedCancellations();
    Integer cancellationNumber = 0;
    for (FlightIrregularity irr : sortedCancellations) {
      // TODO: handle null codes
      Flight affectedFlight = idToFlight.get(irr.flightId);

      // It is not amazing to compare to affectedFlight.scheduledDepartureTime as this flight might
      // we should really compare to the first scheduled departure of the trip. However, we cannot
      // do that as we do not have the trip yet.
      // Either occured within 14 days of departure or after the scheduled departure (very rare)
      Boolean isRelevantForEU261 =
        DateUtils.getHoursBetween(
          affectedFlight.scheduledDepartureTime,
          irr.cancellationTime
        ) < 14 * 24 ||
        affectedFlight.scheduledDepartureTime < irr.cancellationTime;

      if (isRelevantForEU261) {
        Boolean isFirstCancellation = cancellationNumber == 0;
        Boolean isLastCancellation =
          cancellationNumber == sortedCancellations.size() - 1;

        List<Trip> beforeAndAfter = getTripsBeforeAndAfterCancellation(
          affectedFlight
        );
        Trip before = beforeAndAfter[0];
        Trip after = beforeAndAfter[1];

        if (isFirstCancellation) {
          originalTrip = before;
          rootCause = new Trip.RootCause(
            affectedFlight,
            Trip.RootCauseType.CANCELLATION,
            'The first cancellation in this booking is the root cause'
          );
        }
        if (isLastCancellation) {
          replacementTrip = after;
        }
        cancellationNumber++;
      }
    }

    // 2.a
    if (originalTrip != null) {
      // 2.a.1
      // originalTrip
      // replacementTrip
      // rootCause
      // Do cancellation logic (return)
      if (replacementTrip == null) {
        rootCause.description += '(no replacement trip)';
      }
      return rootCause; // TODO
    }

    return null;
  }

  public Boolean hasHiddenCancellation() {
    // Some bookings have flights which were removed from the booking not as a result of a missed conneciton
    // or a flight with an irregularity. But from a cancellation which is not in our database.
    // This function identifies these cancellations (as well as some valid ones accidentally).

    // The the flight should have a UN code without an actual departure / actual arrival and no cancellation irregularity

    Set<Flight> flightsWithoutIrregularitiesAndActualTimes = new Set<Flight>();
    for (Flight f : flights) {
      if (
        f.irregularities.size() == 0 &&
        f.actualDepartureTime == null &&
        f.actualArrivalTime == null
      ) {
        flightsWithoutIrregularitiesAndActualTimes.add(f);
      }
    }

    Map<Id, List<Segment>> flightIdToSegments = new Map<Id, List<Segment>>();
    for (Segment s : segments) {
      if (!flightIdToSegments.containsKey(s.flightId)) {
        flightIdToSegments.put(s.flightId, new List<Segment>());
      }
      flightIdToSegments.get(s.flightId).add(s);
    }

    Set<Segment> segmentsWithFlightWithoutIrregularities = new Set<Segment>();
    for (Flight f : flightsWithoutIrregularitiesAndActualTimes) {
      if (flightIdToSegments.containsKey(f.id)) {
        segmentsWithFlightWithoutIrregularities.addAll(
          flightIdToSegments.get(f.id)
        );
      }
    }

    for (Segment s : segmentsWithFlightWithoutIrregularities) {
      SegmentEvent unableEvent = s.getUnconfirmedEvent();
      if (unableEvent != null) {
        return true;
      }
    }

    return false;
  }

  public Boolean hasFlightWithoutTimes() {
    for (Flight f : flights) {
      if (f.scheduledDepartureTime == null || f.scheduledArrivalTime == null) {
        return true;
      }
    }
    return false;
  }
}
