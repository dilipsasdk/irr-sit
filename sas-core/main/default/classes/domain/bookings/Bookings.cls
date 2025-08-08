public without sharing class Bookings extends ApplicationDomain {
  public Bookings(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Booking__c>) Records;

    List<Booking> bookingObjects = new List<Booking>();
    for (Booking__c b : this.instanceRecords) {
      bookingObjects.add(new Booking(b));
    }

    this.objects = bookingObjects;
  }

  public List<Booking__c> instanceRecords;
  public List<Booking> objects;

  // fullRecords exist only when an instance has been created from TEDS
  // response data.
  public List<FullBookingData> fullRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Bookings(records);
    }
  }

  public static Bookings newInstance(List<Booking__c> sObjectList) {
    return (Bookings) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  /**
   * Loads Passenger, Flight, Segment data for instance of domain that was not
   * created as part of retrieving data from TEDS.
   * Stores the data in the same FullBookingData format as if domain instance was
   * created from call to TEDS
   *
   * TODO: Move me to the service class, or somewhere.
   */
  public Bookings reloadFullBookingData() {
    Set<Id> bookingIds = new Map<Id, Booking__c>(instanceRecords).keySet();
    Map<Id, Flight__c> idsToFlights = new Map<Id, Flight__c>(
      FlightsSelector.newInstance().selectByBookingIds(bookingIds)
    );
    List<Passenger__c> allPassengers = PassengersSelector.newInstance()
      .selectByBookingId(bookingIds);
    List<Segment__c> allSegments = SegmentsSelector.newInstance()
      .selectByBookingId(bookingIds);

    Map<String, List<Segment__c>> flightIdToSegments = new Map<String, List<Segment__c>>();
    Map<Id, List<Flight__c>> bookingIdToFlights = new Map<Id, List<Flight__c>>();

    //Sort Segments for TEDS Flight Id
    //Sort Flights by Booking
    for (Segment__c segment : allSegments) {
      Flight__c flightForSegment = idsToFlights.get(segment.Flight__c);
      if (bookingIdToFlights.get(segment.Booking__c) == null) {
        bookingIdToFlights.put(segment.Booking__c, new List<Flight__c>());
      }
      if (flightForSegment != null) {
        bookingIdToFlights.get(segment.Booking__c).add(flightForSegment);
      }

      if (flightIdToSegments.get(flightForSegment.TEDS_Identifier__c) == null) {
        flightIdToSegments.put(
          flightForSegment.TEDS_Identifier__c,
          new List<Segment__c>()
        );
      }
      flightIdToSegments.get(flightForSegment.TEDS_Identifier__c).add(segment);
    }
    Map<Id, List<Passenger__c>> bookingIdToPassengers = new Map<Id, List<Passenger__c>>();
    //Sort passenger by booking Id
    for (Passenger__c passenger : allPassengers) {
      if (bookingIdToPassengers.get(passenger.Booking__c) == null) {
        bookingIdToPassengers.put(
          passenger.Booking__c,
          new List<Passenger__c>()
        );
      }
      bookingIdToPassengers.get(passenger.Booking__c).add(passenger);
    }

    if (fullRecords == null) {
      fullRecords = new List<FullBookingData>();
    }
    for (Booking__c booking : instanceRecords) {
      FullBookingData fbd = new FullBookingData(
        booking,
        bookingIdToFlights.get(booking.Id),
        bookingIdToPassengers.get(booking.Id),
        flightIdToSegments
      );
      fullRecords.add(fbd);
    }
    return this;
  }

  /**
   * TODO: Extend with setAirports and more
   */
  public Bookings setSegmentEvents(List<SegmentEvent> segmentEvents) {
    Map<Id, List<SegmentEvent>> segmentIdToSegmentEvents = new Map<Id, List<SegmentEvent>>();
    for (SegmentEvent se : segmentEvents) {
      if (segmentIdToSegmentEvents.get(se.segmentId) == null) {
        segmentIdToSegmentEvents.put(se.segmentId, new List<SegmentEvent>());
      }

      segmentIdToSegmentEvents.get(se.segmentId).add(se);
    }

    for (Booking b : this.objects) {
      for (Segment s : b.segments) {
        List<SegmentEvent> events = segmentIdToSegmentEvents.get(s.Id);
        s.setEvents(events);
      }
    }

    return this;
  }

  /**
   * @param uowUpsert fflib UnitOfWork to handle the upserts of data
   * @param uowDelete fflib UnitOfWork to handle the deletion of data
   * @return The Bookings instance itself
   *
   * Upserts the Booking and Flights if they already exist.
   * Deletes all the detail records (i.e. Segments, Segment Events, Passengers, and Flight Irregularities)
   * The reason for using two units of work is because the commitWork method processes inserts/updates before deletions
   * and we want it to work in the reverse order
   */
  public static Bookings createFromReservationData(
    List<Reservation> reservations,
    fflib_ISObjectUnitOfWork uowUpsert,
    fflib_ISObjectUnitOfWork uowDelete
  ) {
    List<SObject> toDelete = new List<SObject>();
    List<Booking__c> bookingSObjects = new List<Booking__c>();

    Map<String, Booking> newBookings = new Map<String, Booking>();
    Set<String> flightIds = new Set<String>();
    Map<String, Flight__c> newlyCreatedFlights = new Map<String, Flight__c>();

    for (Reservation r : reservations) {
      bookingSObjects.add(r.booking.underlyingSObject);
      newBookings.put(r.booking.tedsIdentifier, r.booking);
      flightIds.addAll(r.flights.keySet());
    }
    List<Booking__c> existingBookings = BookingsSelector.newInstance()
      .selectByTEDSIdFull(newBookings.keySet());
    Map<String, Booking__c> existingBookingIdToRecord = new Map<String, Booking__c>();
    for (Booking__c bRecord : existingBookings) {
      existingBookingIdToRecord.put(bRecord.TEDS_Identifier__c, bRecord);
    }

    List<Flight__c> existingFlights = FlightsSelector.newInstance()
      .selectByTEDSId(flightIds);
    Map<String, Flight__c> existingFlightIdToRecord = new Map<String, Flight__c>();
    for (Flight__c fRecord : existingFlights) {
      existingFlightIdToRecord.put(fRecord.TEDS_Identifier__c, fRecord);
    }

    if (existingFlights.size() > 0) {
      uowDelete.registerDeleted(
        FlightIrregularitiesSelector.newInstance()
          .selectByFlightId(new Map<Id, Flight__c>(existingFlights).keySet())
      );
    }

    for (Reservation r : reservations) {
      Boolean shouldUpsertBooking = existingBookingIdToRecord.containsKey(
        r.booking.tedsIdentifier
      );
      if (shouldUpsertBooking) {
        toDelete.addAll(
          existingBookingIdToRecord.get(r.booking.tedsIdentifier).Passengers__r
        );
        toDelete.addAll(
          existingBookingIdToRecord.get(r.booking.tedsIdentifier).Segments__r
        );
        r.booking.updateSObjectFields();
        r.booking.underlyingSObject.id = existingBookingIdToRecord.get(
            r.booking.tedsIdentifier
          )
          .Id;
        uowUpsert.registerDirty(r.booking.underlyingSObject);
      } else {
        r.booking.updateSObjectFields();
        uowUpsert.registerNew(r.booking.underlyingSObject);
      }

      for (Passenger p : r.booking.passengers) {
        p.updateSObjectFields();
        uowUpsert.registerNew(
          p.underlyingSObject,
          Passenger__c.Booking__c,
          r.booking.underlyingSObject
        );
      }

      for (Flight f : r.booking.flights) {
        f.updateSObjectFields(); 

        Boolean isFlightInDatabase = existingFlightIdToRecord.containsKey(f.tedsIdentifier);
        Boolean isFlightAlreadyCreated = newlyCreatedFlights.containsKey(f.tedsIdentifier);

        if (isFlightInDatabase) {
          f.underlyingSObject.id = existingFlightIdToRecord.get(f.tedsIdentifier).Id;
          uowUpsert.registerDirty(f.underlyingSObject);
        } else if (!isFlightAlreadyCreated) {
          newlyCreatedFlights.put(f.tedsIdentifier, f.underlyingSObject);
          uowUpsert.registerNew(f.underlyingSObject);

          if (f.irregularities != null) {
            for (FlightIrregularity fi : f.irregularities) {
              fi.updateSObjectFields();
              uowUpsert.registerNew(
                fi.underlyingSObject, 
                FlightIrregularities__c.Flight__c, 
                f.underlyingSObject
              );
            }
          }
        }
      }

      for (Segment s : r.booking.segments) {
        s.updateSObjectFields();
        uowUpsert.registerNew(
          s.underlyingSObject,
          Segment__c.Booking__c,
          r.booking.underlyingSObject
        );

        if (r.flights.containsKey(s.name)) {
          uowUpsert.registerRelationship(
            s.underlyingSObject,
            Segment__c.Flight__c,
            existingFlightIdToRecord.get(s.name) == null ? newlyCreatedFlights.get(s.name) : existingFlightIdToRecord.get(s.name)
          );
        }

        if (s.getEvents() != null) {
          for (SegmentEvent se : s.getEvents()) {
            se.updateSObjectFields();
            uowUpsert.registerNew(
              se.underlyingSObject,
              Segment_Event__c.Segment__c,
              s.underlyingSObject
            );
          }
        }
      }
    }
    uowDelete.registerDeleted(toDelete);

    Bookings toReturn = Bookings.newInstance(bookingSObjects);
    toReturn.objects = newBookings.values();

    return toReturn;
  }

  public class FullBookingData {
    public Booking__c booking { get; set; }
    public List<Flight__c> flights { get; set; }
    public List<Passenger__c> passengers { get; set; }
    public Map<String, List<Segment__c>> segments { get; set; } // TEDS FlightId => List of segments

    public FullBookingData(
      Booking__c booking,
      List<Flight__c> flights,
      List<Passenger__c> passengers,
      Map<String, List<Segment__c>> segments
    ) {
      this.booking = booking;
      this.flights = flights;
      this.passengers = passengers;
      this.segments = segments; //Flight Id => List of segments
    }
  }
}
