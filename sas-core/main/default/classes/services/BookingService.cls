public without sharing class BookingService {
  public static BookingService newInstance() {
    return (BookingService) SAS_Service_Application.Service.newInstance(
      BookingService.class
    );
  }

  public class IllegalArgumentsException extends Exception {
  }

  public class BatchException extends Exception {
  }
  public static Boolean bookingIsHuge = false;

  /**
   * Adds one or more booking(s) to the case. If necessary booking or flight objects do not exist
   * in Salesforce, attempts to fetch them from TEDS and commit to SF DB.
   *
   * Also fetches detailed flight information from the TEDS Flights API for the
   * flights in the booking.
   *
   * @param caseId The case to which the booking should be added.
   * @param bookingReference The 6 character code of the booking.
   * @return The bookings object representing the booking, or null if none could be found.
   *
   */
  public static Bookings addBookingToCase(ID caseId, String bookingReference) {
    if (caseId == null) {
      throw new IllegalArgumentsException('caseId cannot be null.');
    }

    TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
    query.reference = bookingReference;

    return addBookingToCaseByQuery(caseId, query);
  }

  /**
   * Removes a booking from a case. I.e. removes the CaseToBooking
   * junction object linking the referenced case and a booking.
   *
   * @param caseId The case from which a booking should be removed.
   * @param bookingId The id of the booking.
   *
   */
  public static void removeBookingFromCaseIdentifier(
    Id caseId,
    String bookingIdentifier
  ) {
    List<CaseToBooking__c> caseToBooking = CaseToBookingsSelector.newInstance()
      .selectByCaseIdAndBookingIdentifier(caseId, bookingIdentifier);

    if (!caseToBooking.isEmpty()) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      uow.registerDeleted(caseToBooking);
      uow.commitWork();
    }
  }

  /**
   * Removes a booking from a case. I.e. removes the CaseToBooking
   * junction object linking the referenced case and a booking.
   *
   * @param caseId The case from which a booking should be removed.
   * @param bookingReference The 6 character code of the booking.
   *
   */
  public static void removeBookingFromCase(ID caseId, String bookingReference) {
    List<CaseToBooking__c> caseToBooking = CaseToBookingsSelector.newInstance()
      .selectByCaseIdAndBookingReference(caseId, bookingReference);

    if (!caseToBooking.isEmpty()) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      uow.registerDeleted(caseToBooking);
      uow.commitWork();
    }
  }

  /**
   * Attempts to fetch the given booking from TEDS, and create necessary DB objects.
   * Does nothing if one isn't found.
   *
   * @param bookingIdentifier The booking to find. {PNR}-{creationDate}
   *
   * @throws IntegrationError If there is a problem with the integration.
   */
  public static Bookings fetchBookingByBookingIdentifier(
    String bookingIdentifier
  ) {
    IRR_MOD_TedsBooking tBooking = TEDSIntegrationService.newInstance()
      .fetchBookingByBookingIdentifier(bookingIdentifier);

    if (tBooking == null) {
      // Not found in TEDS. Booking reference doesn't exist in recent flight data (6 months or so).
      return Bookings.newInstance(new List<Booking__c>());
    }
    List<Reservation> reservations = new List<Reservation>();
    reservations.add(new TEDSReservation(tBooking));

    Set<String> flightIds = new Set<String>();
    for (Reservation r : reservations) {
      flightIds.addAll(r.flights.keySet());
    }
    Flights newFlights;
    if (flightIds.size() > 0) {
      newFlights = FlightService.newInstance()
        .fetchFlightsByReference(flightIds, false);
    }
    Bookings newBookings = commitReservationsToDb(reservations);
    if (newFlights != null) {
      newFlights.upsertToDB();
    }

    return newBookings;
  }

  public class FetchBookingByBookingIdentifierAsync implements Queueable, Database.AllowsCallouts {
    private String bookingIdentifier;
    public fetchBookingByBookingIdentifierAsync(String bookingIdentifier) {
      this.bookingIdentifier = bookingIdentifier;
    }
    public void execute(QueueableContext ctx) {
      fetchBookingByBookingIdentifier(this.bookingIdentifier);
    }
  }

  /**
   * Fetches all bookings related to an EB customer from TEDS and inserts them into SF DB.
   *
   * Updates existing bookings, creates new ones and removes bookings from SF that don't
   * exist in SF any more.
   *
   * @param euroBonusNumber The EB number to find bookings for.
   */
  public static Bookings fetchBookingsByEBNumber(String euroBonusNumber) {
    TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
    query.euroBonusNumber = euroBonusNumber;
    return fetchBookingsByQuery(query); // !
  }

  public static Bookings fetchEDWBookingsByBookingReferences(
    Set<String> bookingReferences
  ) {
    List<Reservation> newReservations = new List<Reservation>();

    for (String bookingReference : bookingReferences) {
      EDWIntegrationService.FetchEDWBookingsQuery query = new EDWIntegrationService.FetchEDWBookingsQuery();
      query.pnr = bookingReference;
      FetchEDWBookingResponse data = EDWIntegrationService.fetchEDWBookingsByQuery(
        query
      );
      if (data == null || data.reservationList.reservation.size() == 0) {
        continue;
      }
      newReservations.add(
        new EDWReservation(data.reservationList.reservation[0])
      );
    }

    if (newReservations.size() == 0) {
      return Bookings.newInstance(new List<Booking__c>());
    }
    return commitReservationsToDb(newReservations);
  }

  /**
   *
   */
  public class AddBookingToCaseAsync implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    private String bookingReference;
    public AddBookingToCaseAsync(Id caseId, String bookingReference) {
      this.caseId = caseId;
      this.bookingReference = bookingReference;
    }
    public void execute(QueueableContext ctx) {
      try {
        addBookingToCase(this.caseId, this.bookingReference);
      } catch (IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      } catch (APIMIntegrationService.IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      }
    }
  }

  public class FetchBookingsByEBNumberAsync implements Queueable, Database.AllowsCallouts {
    private String euroBonusNumber;
    public FetchBookingsByEBNumberAsync(String euroBonusNumber) {
      this.euroBonusNumber = euroBonusNumber;
    }
    public void execute(QueueableContext ctx) {
      fetchBookingsByEBNumber(this.euroBonusNumber);
    }
  }

  public class AddBookingToCaseByTicketNumber implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    private String ticketNumber;
    public AddBookingToCaseByTicketNumber(Id caseId, String ticketNumber) {
      this.caseId = caseId;
      this.ticketNumber = ticketNumber;
    }
    public void execute(QueueableContext ctx) {
      try {
        TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
        query.ticketNumber = this.ticketNumber;
        addBookingToCaseByQuery(this.caseId, query);
      } catch (IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      } catch (APIMIntegrationService.IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      }
    }
  }

  public class AddBookingToCaseByPhoneNumber implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    private String phoneNumber;
    public AddBookingToCaseByPhoneNumber(Id caseId, String phoneNumber) {
      this.caseId = caseId;
      this.phoneNumber = EncodingUtil.urlEncode(phoneNumber, 'UTF-8');
    }
    public void execute(QueueableContext ctx) {
      try {
        TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
        query.phoneNumber = this.phoneNumber;
        addBookingToCaseByQuery(this.caseId, query);
      } catch (IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      } catch (APIMIntegrationService.IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      }
    }
  }

  public static Bookings addBookingToCaseByQuery(
    Id caseId,
    TEDSIntegrationService.BookingsQuery bookingQuery
  ) {
    Bookings newBookings = fetchBookingsByQuery(bookingQuery); // !

    if (newBookings.instanceRecords.size() == 0) {
      return newBookings;
    }
    List<Booking__c> foundBookings = newBookings.instanceRecords;
    Set<Id> bookingsToAdd = new Map<Id, Booking__c>(foundBookings).keySet();

    List<CaseToBooking__c> caseToBookings = CaseToBookingsSelector.newInstance()
      .selectByCaseIdAndBookingIds(caseId, bookingsToAdd);

    if (!caseToBookings.isEmpty()) {
      Set<Id> toExlude = new Set<Id>();
      for (CaseToBooking__c ctb : caseToBookings) {
        if (!bookingsToAdd.contains(ctb.Booking__c)) {
          continue;
        }
        toExlude.add(ctb.Booking__c);
      }
      bookingsToAdd.removeAll(toExlude);
    }

    if (bookingsToAdd.isEmpty()) {
      return newBookings;
    }

    // Add case to booking only if the lookup doesn't exist yet.
    List<CaseToBooking__c> newJoins = new List<CaseToBooking__c>();
    for (Id bookingId : bookingsToAdd) {
      newJoins.add(
        new CaseToBooking__c(Booking__c = bookingId, Case__c = caseId)
      );
    }
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    uow.registerNew(newJoins);
    try {
      uow.commitWork();
    } catch (System.DmlException e) {
      if (e.getDmlType(0) == StatusCode.ENTITY_IS_DELETED) {
        // A parallel thread may have deleted the entities. Let's just ignore.
      } else {
        throw e;
      }
    }
    return newBookings;
  }

  /**
   * Removes reservations from a list if they have associated claims currently in the automation queue.
   * This method takes a list of new reservations, checks if any of these reservations have associated claims
   * in the automation queue, and excludes those reservations from the return list.
   *
   * This is done to avoid overwriting more detailed data fetched previously from EDW.
   *
   * @param newReservations A List of Reservation objects to be filtered.
   * @return List<Reservation> A list of Reservation objects after excluding those with associated claims in the automation queue.
   */
  private static List<Reservation> removeReservationsWithCasesInAutomationQueue(
    List<Reservation> newReservations
  ) {
    Set<String> bookingReferences = new Set<String>();
    for (Reservation r : newReservations) {
      bookingReferences.add(r.booking.bookingReference);
    }

    List<LIA_Claim__c> claimsWithBookings = ClaimsSelector.newInstance()
      .selectClaimsInAutomationQueueByBookingReferences(bookingReferences);

    Set<String> bookingReferencesInAutomationQueue = new Set<String>();
    for (LIA_Claim__c c : claimsWithBookings) {
      bookingReferencesInAutomationQueue.add(c.Liability_PNR__c);
    }

    List<Reservation> reservationsToUpsert = new List<Reservation>();
    for (Reservation r : newReservations) {
      if (
        !bookingReferencesInAutomationQueue.contains(r.booking.bookingReference)
      ) {
        reservationsToUpsert.add(r);
      }
    }

    return reservationsToUpsert;
  }

  public static Bookings fetchBookingsByQuery(
    TEDSIntegrationService.BookingsQuery query
  ) {
    List<IRR_MOD_TedsBooking> tBookings = TEDSIntegrationService.newInstance()
      .fetchBookingsByQuery(query);

    if (tBookings == null || tBookings.size() == 0) {
      // Not found in TEDS. Booking reference doesn't exist in recent flight data (6 months or so).
      return Bookings.newInstance(new List<Booking__c>());
    }
    List<Reservation> reservations = new List<Reservation>();
    for (IRR_MOD_TedsBooking tBooking : tBookings) {
      reservations.add(new TEDSReservation(tBooking));
    }

    reservations = removeReservationsWithCasesInAutomationQueue(reservations);

    Set<String> flightIds = new Set<String>();
    for (Reservation r : reservations) {
      flightIds.addAll(r.flights.keySet());
    }

    if (flightIds.size() == 0) {
      return commitReservationsToDb(reservations);
    }
    List<Flights> newFlights = new List<Flights>();
    if (flightIds.size() <= 10) {
      Flights f = FlightService.newInstance()
        .fetchFlightsByReference(flightIds, false);
      newFlights.add(f);
    } else {
      // We can only search 10 flights at a time so let's bunch these up.
      final Integer ITEMS_IN_BUCKET = 10;
      List<Set<String>> bucketedFlights = new List<Set<String>>();

      for (Integer i = 0; i < flightIds.size(); i = i + ITEMS_IN_BUCKET) {
        bucketedFlights.add(new Set<String>());
      }
      Integer count = 0;

      for (String flightIdentifier : flightIds) {
        Integer bucket = count / ITEMS_IN_BUCKET;
        bucketedFlights[bucket].add(flightIdentifier);

        count++;
      }

      for (Set<String> bucket : bucketedFlights) {
        Flights f = FlightService.newInstance()
          .fetchFlightsByReference(bucket, false);
        newFlights.add(f);
      }
    }
    Bookings newBookings = commitReservationsToDb(reservations);
    for (Flights f : newFlights) {
      if (f == null) {
        continue;
      }
      f.upsertToDB();
    }
    return newBookings;
  }

  public static void batchViewAmadeusHistory(Set<String> bookingReferences) {
    if (bookingReferences.size() > 20) {
      // Too many bookings cuts of the debug log
      throw new BatchException('Too many bookings (max = 20).');
    }

    List<Booking__c> bookingsToInpsect = BookingsSelector.newInstance()
      .selectByBookingReference(bookingReferences);

    // Fetch segment events
    Set<Id> segmentIds = new Set<Id>();
    for (Booking__c b : bookingsToInpsect) {
      for (Segment__c s : b.Segments__r) {
        segmentIds.add(s.Id);
      }
    }

    List<Segment_Event__c> segmentEvents = SegmentEventsSelector.newInstance()
      .selectBySegmentId(segmentIds);

    List<SegmentEvent> segmentEventObjects = new List<SegmentEvent>();
    for (Segment_Event__c s : segmentEvents) {
      segmentEventObjects.add(new SegmentEvent(s));
    }

    // Create objects
    Bookings allBookings = Bookings.newInstance(bookingsToInpsect);
    allBookings.setSegmentEvents(segmentEventObjects);

    for (Booking b : allBookings.objects) {
      String history = '';
      try {
        history = b.getReadableAmadeusHistory();
      } catch (Exception e) {
        history = 'Error: ' + e.getMessage();
      }

      System.debug(history);
      System.debug('-----------------------------------');
    }
  }

  private static Bookings commitReservationsToDb(
    List<Reservation> reservations
  ) {
    fflib_ISObjectUnitOfWork uowUpsert = SAS_Service_Application.UnitOfWork.newInstance();
    fflib_ISObjectUnitOfWork uowDelete = SAS_Service_Application.UnitOfWork.newInstance();
    Bookings toReturn = Bookings.createFromReservationData(
      reservations,
      uowUpsert,
      uowDelete
    );
    try {
      uowDelete.commitWork();
    } catch (System.DmlException e) {
      if (e.getDmlType(0) == StatusCode.ENTITY_IS_DELETED) {
        // A parallel thread may have deleted the entities. Let's just ignore.
      } else {
        throw e;
      }
    }
    uowUpsert.commitWork();
    return toReturn;
  }
}
