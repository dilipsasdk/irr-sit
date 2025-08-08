public without sharing class Trip {
  public Airport originAirport;
  public Airport destinationAirport;
  public List<Leg> sortedLegs;
  public Boolean SASIsOnlyOperatingCarrier;
  public CancellationTime cancellationTimeInfo;
  public Boolean isDirty = false;

  /**
   * Returns an ordered list of all trips in a booking.
   *
   * If the specified time is null a "dirty" trip is created which takes into account all flights, active or not.
   * This type of trip is only useful for analysis.
   *
   * Divides the flights in the booking into different trips. If there is an issue, the booking's trip(s) get set to null.
   * If the booking is a OneWay there should only be one trip.
   * If the booking is a Roundtrip or Dayreturn there should be two trips.
   * If the booking is a MultiCity there can be 1(?) or more trips.
   *
   * The compensation should, logically, be calculated with respect to each "final destination" in the booking (see EU261 Article 2 h: https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * When a pax stays in a city for more than 24 hours it counts as a "final destination" according to internal SAS policy (TODO: find a good source).
   * After 24 hours the booking is considered a "package" under EU law (Council Directive 90/314/EEC Article 2 §1: https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=celex%3A31990L0314)
   *
   * TODO: Find a solid source for the 24 hour policy.
   * TODO: Think about implementation: When there is a cancelled flight and a customers trip becomes e.g.
   * ARN -> CPH (Delay 200 minutes + Wait >24hrs because of cancellation) -> LAX (Delay 260 minutes).
   * The customer could, according to this implementation, claim compensation for both ARN -> CPH and CPH -> LAX.
   * This seems fair. However, I think there is a good case for us not needing to provide them with more compensation.
   *
   * @return A map of booking id to each trip in booking
   */
  public static List<Trip> createFromBooking(Booking b, Datetime theTime) {
    if (b.segments == null) {
      throw new InsufficientDataException(
        'You must fetch the segments for the booking.'
      );
    }

    for (Segment s : b.segments) {
      if (s.flight == null) {
        throw new InsufficientDataException(
          'You must fetch flights for the segments in the booking.'
        );
      }
      if (
        s.flight.departureAirportObject == null ||
        s.flight.arrivalAirportObject == null
      ) {
        throw new InsufficientDataException(
          'You must fetch airports for the segments in the booking.'
        );
      }
      if (s.getEvents() == null) {
        throw new InsufficientDataException(
          'You must fetch events for the segments in the booking.'
        );
      }
    }

    List<Segment> segments = b.segments.clone();
    if (theTime != null) {
      segments = b.getActiveSegmentsAtTime(theTime);
    }

    List<Trip> toReturn = divideSegmentsIntoTrips(segments);

    for (Trip t : toReturn) {
      if (theTime == null) {
        t.isDirty = true;
      }
      if (!t.isValid()) {
        throw new InvalidException('One or more of the trips are invalid');
      }
    }

    return toReturn;
  }

  public Boolean hasFlightWithUNBeforeTime(Datetime theTime) {
    for (Leg l : sortedLegs) {
      Segment sampleSegment = l.segments[0]; // If one segment is unconfirmed, all segments are unconfirmed.
      if (sampleSegment.getStatus(theTime) == Segment.Status.Unconfirmed) {
        return true;
      }
    }

    return false;
  }

  public static List<Trip> mergeSimilarTrips(List<Trip> trips) {
    // Merge the trips with the same origin and destination airport.

    Map<String, List<Trip>> tripsByOriginAndDestination = new Map<String, List<Trip>>();
    for (Trip t : trips) {
      String key =
        t.originAirport.tedsIdentifier + t.destinationAirport.tedsIdentifier;
      if (!tripsByOriginAndDestination.containsKey(key)) {
        tripsByOriginAndDestination.put(key, new List<Trip>());
      }
      tripsByOriginAndDestination.get(key).add(t);
    }

    List<Trip> toReturn = new List<Trip>();
    for (String key : tripsByOriginAndDestination.keySet()) {
      List<Trip> tripsWithSameOriginAndDestination = tripsByOriginAndDestination.get(
        key
      );

      List<Leg> mergedSortedLegs = new List<Leg>();
      for (Trip t : tripsWithSameOriginAndDestination) {
        mergedSortedLegs.addAll(t.sortedLegs);
      }

      mergedSortedLegs.sort();

      Trip mergedTrip = new Trip(mergedSortedLegs);
      mergedTrip.originAirport = tripsWithSameOriginAndDestination[0]
        .originAirport;
      mergedTrip.destinationAirport = mergedTrip.destinationAirport = tripsWithSameOriginAndDestination[0]
        .destinationAirport;
      mergedTrip.isDirty = true;

      toReturn.add(mergedTrip);
    }

    return toReturn;
  }

  public Datetime getFirstDepartureOverlappingWith(Datetime theTime) {
    if (!isDirty) {
      throw new InvalidException(
        'Tried to get first departure at time of a non-dirty trip'
      );
    }

    Datetime firstDeparture;
    for (Leg l : sortedLegs) {
      Flight f = l.flight;
      Datetime arrivalTime;
      if (f.actualArrivalTime != null) {
        arrivalTime = f.actualArrivalTime;
      } else {
        arrivalTime = f.scheduledArrivalTime;
      }

      // Set the departure time to the lowest of the actual departure and scheduled departure
      Datetime departureTime;
      if (
        f.actualDepartureTime != null &&
        f.actualDepartureTime < f.scheduledDepartureTime
      ) {
        departureTime = f.actualDepartureTime;
      } else {
        departureTime = f.scheduledDepartureTime;
      }

      Boolean isInFlightDuringTime =
        departureTime <= theTime &&
        arrivalTime > theTime;

      if (isInFlightDuringTime) {
        if (
          f.scheduledDepartureTime < firstDeparture ||
          firstDeparture == null
        ) {
          firstDeparture = f.scheduledDepartureTime;
        }
      }
    }

    return firstDeparture;
  }

  /**
   * Gets all active segments at a specific time and re-calculates the trip.
   * This should only be used for dirty trips.
   */
  public Trip getDirtyTripSnapshotAtTime(Datetime theTime) {
    // Remove all legs that are not active at theTime
    // This is done by extracting all active segments and
    // then dividing them into trips again.

    if (!isDirty) {
      throw new InvalidException(
        'Tried to get snapshot at time of a non-dirty trip'
      );
    }

    List<Segment> activeSegments = new List<Segment>();
    for (Leg l : sortedLegs) {
      for (Segment s : l.segments) {
        if (s.getStatus(theTime) == Segment.Status.Confirmed) {
          activeSegments.add(s);
        }
      }
    }

    List<Trip> snapshotTrips = divideSegmentsIntoTrips(activeSegments);

    if (snapshotTrips.size() != 1) {
      throw new InvalidException(
        'A trip got split into multiple trips at a specific time'
      );
    }

    Trip toReturn = snapshotTrips[0];

    if (!toReturn.isValid()) {
      throw new InvalidException('One or more of the trips are invalid');
    } else if (
      toReturn.originAirport != this.originAirport ||
      toReturn.destinationAirport != this.destinationAirport
    ) {
      throw new InvalidException('The origin or destination airport changed');
    }

    return toReturn;
  }

  public class InsufficientDataException extends Exception {
  }

  public class InvalidException extends Exception {
  }

  public class BookingTypeNotSupportedException extends Exception {
  }

  public class RouteException extends Exception {
  }

  public class ResponsibilityException extends Exception {
  }

  private Trip(List<Leg> legsInOrder) {
    // make some checks about the booking to make it clear what all we need.
    // should have all data by now, just populate the properties.
    if (legsInOrder.size() == 0) {
      throw new InsufficientDataException('A trip must have at least one leg');
    }

    this.sortedLegs = legsInOrder;
    this.SASIsOnlyOperatingCarrier = true;

    List<Flight> fs = new List<Flight>();
    for (Leg l : legsInOrder) {
      fs.add(l.flight);
    }

    for (Flight f : fs) {
      if (!f.isOperatedBySAS()) {
        SASIsOnlyOperatingCarrier = false;
        break;
      }
    }
  }

  // GENERAL LOGIC
  public Boolean containsFlight(Flight flight) {
    for (Leg l : this.sortedLegs) {
      if (l.flight == flight) {
        return true;
      }
    }
    return false;
  }

  public Flight getFlightToFinalDestination() {
    return sortedLegs[sortedLegs.size() - 1].flight;
  }

  public Flight getFirstFlight() {
    return sortedLegs[0].flight;
  }

  public Boolean isIntraCommunity() {
    return originAirport.isEU261Applicable &&
      destinationAirport.isEU261Applicable;
  }

  public Boolean isIntraSEorIntraNO() {
    Boolean isWithinOneCountry = (originAirport.countryCode ==
    destinationAirport.countryCode);
    Boolean originsInSwedenOrNorway = (originAirport.countryCode == 'SE' ||
    originAirport.countryCode == 'NO');
    return (isWithinOneCountry && originsInSwedenOrNorway);
  }

  public void logJSON(String additionalInfo) {
    System.debug(
      '--------- TRIP-DEBUG (' +
      additionalInfo +
      ') START ---------\n' +
      JSON.serialize(this) +
      '\n---------- TRIP-DEBUG (' +
      additionalInfo +
      ') END ----------\n'
    );
  }

  public Boolean equals(Object other) {
    if (!(other instanceof Trip)) {
      return false;
    }
    Trip otherT = (Trip) other;

    if (this.sortedLegs.size() != otherT.sortedLegs.size()) {
      return false;
    }

    for (Integer i = 0; i < this.sortedLegs.size(); i++) {
      if (this.sortedLegs[i].flight != otherT.sortedLegs[i].flight) {
        return false;
      }
    }

    return true;
  }

  public Boolean hasRouteFromOriginToDestination() {
    FlightHistory fh = new FlightHistory(this.sortedLegs);
    return fh.canFlyFromOriginToDestination(isDirty);
  }

  public class FakeAirport {
    String IATACode;
    List<Leg> availableRoutesFromAirport = new List<Leg>{};

    public FakeAirport(String IATACode) {
      this.IATACode = IATACode;
    }

    public Boolean equals(Object obj) {
      return obj instanceof FakeAirport &&
        this.IATACode == ((FakeAirport) obj).IATACode;
    }
  }

  public class FlightHistory {
    Map<String, FakeAirport> codeToAirport = new Map<String, FakeAirport>{};
    FakeAirport originAirport;
    FakeAirport destinationAirport;

    public FlightHistory(List<Leg> tripLegs) {
      List<String> addedAirports = new List<String>{};
      for (Leg l : tripLegs) {
        if (!addedAirports.contains(l.flight.departureAirport)) {
          FakeAirport newAirport = new FakeAirport(l.flight.departureAirport);
          codeToAirport.put(l.flight.departureAirport, newAirport);
          addedAirports.add(l.flight.departureAirport);
        }
        if (!addedAirports.contains(l.flight.arrivalAirport)) {
          FakeAirport newAirport = new FakeAirport(l.flight.arrivalAirport);
          codeToAirport.put(l.flight.arrivalAirport, newAirport);
          addedAirports.add(l.flight.arrivalAirport);
        }

        FakeAirport departureAirport = codeToAirport.get(
          l.flight.departureAirport
        );
        departureAirport.availableRoutesFromAirport.add(l);
      }

      this.originAirport = codeToAirport.get(
        tripLegs[0].flight.departureAirport
      );
      this.destinationAirport = codeToAirport.get(
        tripLegs[tripLegs.size() - 1].flight.arrivalAirport
      );
    }

    public Boolean hasTwoOrMoreDeparturesFromOneAirport() {
      for (FakeAirport a : codeToAirport.values()) {
        if (a.availableRoutesFromAirport.size() > 1) {
          return true;
        }
      }
      return false;
    }

    public Leg getRouteFromAirportAfterFlight(Flight f) {
      Leg routeFromAirportAfterFlight;
      FakeAirport airport = codeToAirport.get(f.arrivalAirport);

      if (airport.availableRoutesFromAirport.size() == 1) {
        routeFromAirportAfterFlight = airport.availableRoutesFromAirport[0];
      } else {
        // There should not be more than one active route from one airport to another.
        throw new RouteException(
          'More or less than one active route from one airport to another'
        );
      }

      return routeFromAirportAfterFlight;
    }

    public Boolean canFlyFromOriginToDestination(Boolean tripIsDirty) {
      FakeAirport currentAirport = originAirport;
      FakeAirport nextAirport;
      List<Leg> routes = currentAirport.availableRoutesFromAirport;
      Integer noIterations = 0;
      while (routes.size() != 0) {
        Leg currentLeg;
        if (routes.size() == 1 || tripIsDirty) {
          currentLeg = routes[0];
        } else {
          // There should not be more than one active route from one airport to another if the trip is not dirty.
          return false;
        }
        nextAirport = this.codeToAirport.get(currentLeg.flight.arrivalAirport);
        routes = nextAirport.availableRoutesFromAirport;
        currentAirport = nextAirport;
        noIterations += 1;
        if (noIterations == 200) {
          throw new RouteException('Likely infinite loop');
        }
      }

      return currentAirport.IATACode == destinationAirport.IATACode;
    }
  }

  public Datetime getFinalDestinationArrivalTime() {
    Flight lastFlight = getFlightToFinalDestination();
    if (
      lastFlight.actualArrivalTime != null &&
      lastFlight.actualArrivalTime > Datetime.newInstance(1950, 1, 1)
    ) {
      return lastFlight.actualArrivalTime;
    }
    return lastFlight.scheduledArrivalTime;
  }

  public Datetime getDeparture() {
    Flight firstFlight = getFirstFlight();
    if (
      firstFlight.actualDepartureTime != null &&
      firstFlight.actualDepartureTime > Datetime.newInstance(1950, 1, 1)
    ) {
      return firstFlight.actualDepartureTime;
    }
    return firstFlight.scheduledDepartureTime;
  }

  public Datetime getScheduledDeparture() {
    return getFirstFlight().scheduledDepartureTime;
  }

  public Datetime getScheduledArrival() {
    return getFlightToFinalDestination().scheduledArrivalTime;
  }

  public Boolean allFlightsAreBoarded() {
    for (Leg l : this.sortedLegs) {
      for (Segment s : l.segments) {
        if (s.isBoarded == null) {
          throw new InsufficientDataException(
            'there is no info about boarding status'
          );
        }
        if (!s.isBoarded) {
          return false;
        }
      }
    }
    return true;
  }

  // INITIALIZATION LOGIC
  /*
   * Class used to combine different passengers' segments into one.
   */
  public class Leg implements Comparable {
    public List<Segment> segments;
    public Flight flight;

    public Leg(List<Segment> segments) {
      this.segments = segments;
      this.flight = segments[0].flight;
    }

    public Integer compareTo(Object obj) {
      Leg otherLeg = (Leg) obj;
      if (
        this.flight.scheduledDepartureTime ==
        otherLeg.flight.scheduledDepartureTime
      ) {
        return 0;
      } else if (
        this.flight.scheduledDepartureTime <
        otherLeg.flight.scheduledDepartureTime
      ) {
        return -1;
      } else {
        return 1;
      }
    }
  }

  public enum RootCauseType {
    CANCELLATION,
    DELAYMISSEDCONNECTION,
    DELAYPLACEDONOTHERFLIGHT,
    SHORTDELAY,
    SIMPLEDELAY
  }

  public class RootCause {
    public Flight flight;
    public RootCauseType type;
    public String description;
    public Trip originalTrip;
    public Trip resultingTrip;

    public RootCause(Flight flight, RootCauseType type, String description) {
      this.flight = flight;
      this.type = type;
      this.description = description;
    }

    public String getDescription() {
      List<String> codeDescriptions = new List<String>();
      String irregularityDescriptionTemplate = '{0} ({1})';
      for (FlightIrregularity irr : flight.irregularities) {
        List<String> irrDescription = new List<String>{ irr.code };
        if (irr.cancellationTime != null) {
          irrDescription.add(
            StringUtils.dateTimeToReadable(irr.cancellationTime)
          );
        } else {
          irrDescription.add(String.valueOf(irr.durationMinutes));
        }

        codeDescriptions.add(
          String.format(irregularityDescriptionTemplate, irrDescription)
        );
      }
      String codesString = String.join(codeDescriptions, ', ');

      String descriptionTemplate = '{0} ({1}: {2})';

      String toReturn = String.format(
        descriptionTemplate,
        new List<String>{ description, flight.getFlightNumber(), codesString }
      );

      return toReturn;
    }
  }

  public class CancellationTime {
    public Datetime affectedByIrregularity;
    public Datetime unconfirmed;
    public Datetime removed;
    public String officeUnconfirming;
    public String officeRemoving;

    public CancellationTime(
      Datetime affectedByIrregularity,
      Datetime unconfirmed,
      Datetime removed,
      String officeUnconfirming,
      String officeRemoving
    ) {
      this.affectedByIrregularity = affectedByIrregularity;
      this.unconfirmed = unconfirmed;
      this.removed = removed;
      this.officeUnconfirming = officeUnconfirming;
      this.officeRemoving = officeRemoving;
    }

    public Boolean removedBeforeIrregularity() {
      Boolean wasRemoved = removed != null;
      return wasRemoved && removed < affectedByIrregularity;
    }
  }

  /*
   * Function used to combine different passengers' segments into one.
   * E.g.
   * Jonas ARN->CPH 2022-01-01 00:00 Oneway
   * Fanny ARN->CPH 2022-01-01 00:00 Oneway
   * Becomes:
   * ARN->CPH 2022-01-01 00:00 Oneway
   *
   * This is done to simplify cancellation compensation handling.
   */
  public static List<Leg> createLegsFromSegments(List<Segment> segments) {
    segments.sort();
    String departureAirport = segments[0].flight.departureAirport;
    String arrivalAirport = segments[0].flight.arrivalAirport;
    Datetime departureTime = segments[0].flight.scheduledDepartureTime;
    Datetime arrivalTime = segments[0].flight.scheduledArrivalTime;

    List<Leg> toReturn = new List<Leg>{};
    List<Segment> segmentsInCurrentLeg = new List<Segment>{};
    Boolean isNewLeg = true;
    for (Segment s : segments) {
      if (
        s.flight.departureAirport == departureAirport &&
        s.flight.arrivalAirport == arrivalAirport &&
        s.flight.scheduledDepartureTime == departureTime &&
        s.flight.scheduledArrivalTime == arrivalTime
      ) {
        segmentsInCurrentLeg.add(s);
      } else {
        toReturn.add(new Leg(segmentsInCurrentLeg));

        segmentsInCurrentLeg = new List<Segment>{ s }; // Clear current leg
        departureAirport = s.flight.departureAirport;
        arrivalAirport = s.flight.arrivalAirport;
        departureTime = s.flight.scheduledDepartureTime;
        arrivalTime = s.flight.scheduledArrivalTime;
      }
    }
    if (segmentsInCurrentLeg.size() > 0) {
      toReturn.add(new Leg(segmentsInCurrentLeg));
    }

    return toReturn;
  }

  /*
   * Divides all segments into trips. A trip is identified by
   * the scheduled arrival and departure of two segments being more than 24 hours apart.
   *
   * @param segments A List<Segment> that needs the connected Flight__r.
   *
   * @return a List<Trip> of the trips sorted in order.
   */
  @TestVisible
  private static List<Trip> divideSegmentsIntoTrips(List<Segment> segments) {
    if (segments.size() == 0) {
      return new List<Trip>();
    }
    List<Leg> sortedLegs = createLegsFromSegments(segments);

    List<Trip> tripsToReturn = new List<Trip>{};
    Leg latestLeg;
    List<Leg> legsInCurrentTrip = new List<Leg>();
    for (Leg leg : sortedLegs) {
      if (latestLeg == null) {
        latestLeg = leg;
        legsInCurrentTrip.add(leg);
        continue;
      }

      Boolean moreThan24HoursAtAirport = DateUtils.isMoreThan24HoursBetween(
        latestLeg.flight.scheduledDepartureTime,
        leg.flight.scheduledArrivalTime
      );

      if (moreThan24HoursAtAirport) {
        tripsToReturn.add(new Trip(legsInCurrentTrip));
        legsInCurrentTrip = new List<Leg>();
      }

      latestLeg = leg;
      legsInCurrentTrip.add(leg);
    }

    tripsToReturn.add(new Trip(legsInCurrentTrip));

    addAirports(tripsToReturn);

    if (
      tripsToReturn.size() == 1 &&
      tripsToReturn[0].originAirport == tripsToReturn[0].destinationAirport
    ) {
      tripsToReturn = divideDayreturn(tripsToReturn);
    }

    return tripsToReturn;
  }

  private static void addAirports(List<Trip> tripsToReturn) {
    for (Trip t : tripsToReturn) {
      Flight firstFlight = t.sortedLegs[0].flight;
      Flight finalFlight = t.getFlightToFinalDestination();

      t.originAirport = firstFlight.departureAirportObject;
      t.destinationAirport = finalFlight.arrivalAirportObject;
    }
  }

  /**
   * Trips where there is no stop over 24 hours and the last flights destination airport
   * is the same as the first flights origin ariport are considered dayreturn bookings.
   * We divide these bookings into two, where we consider the destination to be the
   * airport where the customer is scheduled to stay the longest.
   */
  public static List<Trip> divideDayreturn(List<Trip> dayreturnTrip) {
    if (dayreturnTrip.size() != 1 || dayreturnTrip[0].sortedLegs.size() < 2) {
      throw new InvalidException('Invalid dayreturn trip');
    }

    Trip tripToDivide = dayreturnTrip[0];
    Integer longestStopInMinutes = 0;
    String longestStopAirport;
    Datetime latestArrival;
    for (Leg l : tripToDivide.sortedLegs) {
      if (latestArrival != null) {
        Integer stopInMinutes = Dateutils.getMinutesBetween(
          latestArrival,
          l.flight.scheduledDepartureTime
        );
        if (stopInMinutes > longestStopInMinutes) {
          longestStopInMinutes = stopInMinutes;
          longestStopAirport = l.flight.departureAirport;
        }
      }
      latestArrival = l.flight.scheduledArrivalTime;
    }

    List<Leg> outBoundLegs = new List<Leg>();
    List<Leg> inboundBoundLegs = new List<Leg>();
    Boolean isOutBound = true;
    for (Leg l : tripToDivide.sortedLegs) {
      if (isOutBound) {
        outBoundLegs.add(l);
        if (l.flight.arrivalAirport == longestStopAirport) {
          isOutBound = false;
        }
      } else {
        inboundBoundLegs.add(l);
      }
    }

    List<Trip> toReturn = new List<Trip>{
      new Trip(outBoundLegs),
      new Trip(inboundBoundLegs)
    };
    addAirports(toReturn);

    return toReturn;
  }

  public Trip getOfferedRebooking(List<Segment> activeSegments) {
    if (activeSegments.size() == 0) {
      return null;
    }

    List<Leg> sortedLegs = createLegsFromSegments(activeSegments);

    // Add all flights scheduled between (and including) the flight with the same origin as
    // the original trip and the flight with the same destination of the original trip.
    Trip replacementTrip;
    Boolean addFlight = false;
    List<Leg> legsInCurrentTrip = new List<Leg>();
    for (Leg leg : sortedLegs) {
      if (leg.flight.departureAirport == this.originAirport.tedsIdentifier) {
        addFlight = true; // If the departure no longer exists there will be an issue. TODO: implement special case.
      }
      if (addFlight) {
        legsInCurrentTrip.add(leg);
      }
      if (leg.flight.arrivalAirport == this.destinationAirport.tedsIdentifier) {
        if (legsInCurrentTrip.size() > 0) {
          replacementTrip = new Trip(legsInCurrentTrip);
        }
        break;
      }
    }

    if (replacementTrip == null) {
      if (legsInCurrentTrip.size() > 0) {
        throw new RouteException(
          'could not find route from origin to destination'
        );
      } else {
        return null;
      }
    }

    replacementTrip.originAirport = this.originAirport;
    replacementTrip.destinationAirport = this.destinationAirport;

    checkIfValidReplacement(this, replacementTrip);

    return replacementTrip;
  }

  public static Trip getTripWithFlight(
    List<Trip> trips,
    Flight cancelledFlight
  ) {
    for (Trip t : trips) {
      if (t.containsFlight(cancelledFlight)) {
        return t;
      }
    }
    return null;
  }

  // Deprecated
  public static List<Trip> getTripBeforeAndAfterCancelledFlight(
    List<Trip> tripsBefore,
    List<Trip> tripsAfter,
    Flight cancelledFlight
  ) {
    // Identify and set trip with flight and the replacement trip
    Integer tripIndex;
    Trip tripWithCancelledFlight;
    for (Integer i = 0; i < tripsBefore.size(); i++) {
      Trip tripBeforeIrregularity = tripsBefore[i];
      if (tripBeforeIrregularity.containsFlight(cancelledFlight)) {
        tripWithCancelledFlight = tripBeforeIrregularity;
        tripIndex = i;
        break;
      }
    }

    Trip tripWithCancelledFlightReplacement;
    if (tripsAfter.size() > 0 && tripIndex != null) {
      if (tripsBefore.size() != tripsAfter.size()) {
        throw new InvalidException(
          'Interpretation of booking changed after cancellation'
        );
      }

      tripWithCancelledFlightReplacement = tripsAfter[tripIndex];

      checkIfValidReplacement(
        tripWithCancelledFlight,
        tripWithCancelledFlightReplacement
      );
    }

    return new List<Trip>{
      tripWithCancelledFlight,
      tripWithCancelledFlightReplacement
    };
  }

  private Boolean arrivesBeforeDeparture() {
    return getDeparture() > getFinalDestinationArrivalTime();
  }

  private Boolean hasInvalidTime() {
    Datetime departure = getDeparture();
    Datetime arrival = getFinalDestinationArrivalTime();
    Datetime ninteenFifty = Datetime.newInstance(1950, 1, 1);
    if (departure == null || arrival == null) {
      return true;
    } else if (departure < ninteenFifty || arrival < ninteenFifty) {
      return true;
    }

    return false;
  }

  public Boolean isValid() {
    return !hasInvalidTime() &&
      !arrivesBeforeDeparture() &&
      hasRouteFromOriginToDestination();
  }

  public static void checkIfValidReplacement(Trip t, Trip replacement) {
    if (t == null || replacement == null) {
      throw new InvalidException('The trip and/or its replacement is null');
    }

    if (!t.isValid() || !replacement.isValid()) {
      throw new InvalidException(
        'The trip and/or its replacement are not valid'
      );
    } else if (
      t.originAirport != replacement.originAirport ||
      t.destinationAirport != replacement.destinationAirport
    ) {
      throw new InvalidException(
        'The replacement has a different origin or destination'
      );
    }
  }

  public Boolean isUncertainWhoCancelled() {
    try {
      customerCancelled();
    } catch (ResponsibilityException e) {
      return true;
    }
    return false;
  }

  public Boolean customerCancelled() {
    if (!cancellationTimeInfo.removedBeforeIrregularity()) {
      return false;
    }

    String officeResponsible = cancellationTimeInfo.officeRemoving;

    if (officeResponsible == null) {
      throw new ResponsibilityException(
        'No office is responsible for cancelling the flight'
      );
    }

    Boolean cancelledByCustomer = SegmentEvent.customerResponsibleForEvent(
      officeResponsible
    );

    if (cancelledByCustomer == null) {
      throw new ResponsibilityException(
        'It is uncertain who is responsible for cancelling the flight'
      );
    }

    return cancelledByCustomer;
  }

  public Boolean hasTwoOrMoreDeparturesFromOneAirport() {
    FlightHistory flightHistory = new FlightHistory(sortedLegs);
    return flightHistory.hasTwoOrMoreDeparturesFromOneAirport();
  }

  public List<FlightIrregularity> getSortedCancellations() {
    List<FlightIrregularity> cancellations = new List<FlightIrregularity>{};
    for (Leg l : sortedLegs) {
      cancellations.addAll(l.flight.getCancellations());
    }

    cancellations.sort();

    return cancellations;
  }

  /**
   * 4.1 Step through the final trip and compare with original trip.
        This has been rewamped. The current logic is the following:
        1. Find the last common flight between the original and resulting trip.
        2. If a common flight cannot be found, assume that the first flight is the root cause.
        3. If a common flight is found, there are three scenarios:
        3.a. (Delayed) If the arrival airport of the trip and the flight are the same -> the final flight is the root cause.
        3.b. (Rebooked) If the original flight from the airport (actually) leaves the airport after the 
             replacement flight the root cause is the original flight from the airport.
        3.c. (Missed connection) If the original flight from the airport departs before the replacement flight, 
             the root cause is the flight before to the aiport (the flight before).
    
    TODO: Check boarding status
   */
  public static RootCause getRootCauseDelay(
    Trip originalTrip,
    Trip resultingTrip
  ) {
    // 4.0. Clean up the trips (duplicate departure etc)
    // If there are multiple departures from 1 airport a flight which should have been removed is still in the trip.
    // Currently, we just don't handle it, future: look at boarded status.
    FlightHistory originalFlightHistory = new FlightHistory(
      originalTrip.sortedLegs
    );
    FlightHistory resultingFlightHistory = new FlightHistory(
      resultingTrip.sortedLegs
    );

    if (
      originalFlightHistory.originAirport !=
      resultingFlightHistory.originAirport
    ) {
      throw new InvalidException('The origin airports are not the same');
    }
    if (
      originalFlightHistory.destinationAirport !=
      resultingFlightHistory.destinationAirport
    ) {
      throw new InvalidException('The destination airports are not the same');
    }

    List<Flight> originalFlights = new List<Flight>{};
    for (Leg l : originalTrip.sortedLegs) {
      originalFlights.add(l.flight);
    }

    Flight lastMatchingFlight;
    for (Leg l : resultingTrip.sortedLegs) {
      if (originalFlights.contains(l.flight)) {
        lastMatchingFlight = l.flight;
      }
    }

    RootCause cause;
    if (lastMatchingFlight == null) {
      // No matching flight, the first flight is the cause
      cause = new RootCause(
        originalTrip.sortedLegs[0].flight,
        RootCauseType.DELAYPLACEDONOTHERFLIGHT,
        'The first flight was the cause of the delay.'
      );
    } else if (
      lastMatchingFlight.arrivalAirport ==
      originalFlightHistory.destinationAirport.IATACode
    ) {
      // The last flight was delayed and is the cause
      cause = new RootCause(
        lastMatchingFlight,
        RootCauseType.SIMPLEDELAY,
        'The last flight was the cause of the delay.'
      );
    } else {
      // Either the last matching flight was delayed and caused the pax to miss the next flight.
      // Or the flight after the last matching flight caused the pax to be placed on another flight.
      Leg originalRouteFromAirport = originalFlightHistory.getRouteFromAirportAfterFlight(
        lastMatchingFlight
      );
      Leg resultingRouteFromAirport = resultingFlightHistory.getRouteFromAirportAfterFlight(
        lastMatchingFlight
      );

      if (originalRouteFromAirport.flight.actualDepartureTime == null) {
        throw new InvalidException(
          'The original flight has no actual departure time'
        );
      }

      if (
        originalRouteFromAirport.flight.actualDepartureTime >
        resultingRouteFromAirport.flight.scheduledDepartureTime
      ) {
        // The original flight from airport was delayed (likely)
        cause = new RootCause(
          originalRouteFromAirport.flight,
          RootCauseType.DELAYPLACEDONOTHERFLIGHT,
          originalRouteFromAirport.flight.getFlightNumber() +
          ' was delayed, causing the pax to be placed on another flight.'
        );
      } else {
        // The previous flight to airport was delayed causing the pax to miss the next flight (likely)
        cause = new RootCause(
          lastMatchingFlight,
          RootCauseType.DELAYMISSEDCONNECTION,
          lastMatchingFlight.getFlightNumber() +
          ' was delayed, causing the pax to miss the next flight.'
        );
      }
    }

    // Note, this does not handle this scenario well:
    // Original trip:
    // SK0001 LLA -> ARN
    // SK0002 ARN -> CPH
    // Resulting trip:
    // SK0003 LLA -> ARN (arriving in time for SK0002)
    // SK0004 ARN -> CPH (SK0002 is delayed, causing the pax to be placed on SK0004)
    // The root cause will in this case be identified as SK0001, which is not perfect, could be argued though.
    // The "minimum time at airport" really screws this up

    cause.originalTrip = originalTrip;
    cause.resultingTrip = resultingTrip;

    return cause;
  }
}
