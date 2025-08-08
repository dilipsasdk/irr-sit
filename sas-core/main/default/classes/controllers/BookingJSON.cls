global class BookingJSON implements Comparable {
  @AuraEnabled
  public String bookingReference { get; set; }
  @AuraEnabled
  public String createdAtTravelOfficeId { get; set; }
  @AuraEnabled
  public String bookingIdentifier { get; set; }
  @AuraEnabled
  public Boolean isCancelled { get; set; }
  @AuraEnabled
  public Datetime lastUpdated { get; set; }
  @AuraEnabled
  public String type { get; set; }

  @AuraEnabled
  public List<Flight> flights { get; set; }
  @AuraEnabled
  public List<Passenger> passengers { get; set; }
  @AuraEnabled
  public List<Case> relatedCases { get; set; }
  @AuraEnabled
  public List<CommunicationLog> relatedCommunicationLogs { get; set; }

  global class CommunicationLog {
    @AuraEnabled
    public String bookingReference { get; set; }
    @AuraEnabled
    public String channel { get; set; }
    @AuraEnabled
    public Datetime createdDate { get; set; }
    @AuraEnabled
    public String flightId { get; set; }
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String messageContent { get; set; }

    public CommunicationLog(IRR_CommunicationLog__c l) {
      bookingReference = l.IRR_BookingReference__c;
      channel = l.IRR_Channel__c;
      createdDate = l.CreatedDate;
      flightId = l.IRR_FlightId__c;
      id = l.Id;
      messageContent = l.IRR_MessageContent__c;
    }
  }

  global class Flight implements Comparable {
    @AuraEnabled
    public Datetime actualArrivalTime { get; set; }
    @AuraEnabled
    public String actualArrivalTimeLocal { get; set; }
    @AuraEnabled
    public Datetime actualDepartureTime { get; set; }
    @AuraEnabled
    public String actualDepartureTimeLocal { get; set; }
    @AuraEnabled
    public String arrivalAirport { get; set; }
    @AuraEnabled
    public Decimal arrivalDelayedMinutes { get; set; }
    @AuraEnabled
    public String arrivalGate { get; set; }
    @AuraEnabled
    public String arrivalStatus { get; set; }
    @AuraEnabled
    public String arrivalTerminal { get; set; }
    @AuraEnabled
    public String bookingClass { get; set; }
    @AuraEnabled
    public String departureAirport { get; set; }
    @AuraEnabled
    public Decimal departureDelayedMinutes { get; set; }
    @AuraEnabled
    public String departureGate { get; set; }
    @AuraEnabled
    public String departureStatus { get; set; }
    @AuraEnabled
    public String departureTerminal { get; set; }
    @AuraEnabled
    public Datetime estimatedArrivalTime { get; set; }
    @AuraEnabled
    public String estimatedArrivalTimeLocal { get; set; }
    @AuraEnabled
    public Datetime estimatedDepartureTime { get; set; }
    @AuraEnabled
    public String estimatedDepartureTimeLocal { get; set; }
    @AuraEnabled
    public String fareBasis { get; set; }
    @AuraEnabled
    public String flightNumber { get; set; }
    @AuraEnabled
    public Datetime scheduledArrivalTime { get; set; }
    @AuraEnabled
    public String scheduledArrivalTimeLocal { get; set; }
    @AuraEnabled
    public Datetime scheduledDepartureTime { get; set; }
    @AuraEnabled
    public String scheduledDepartureTimeLocal { get; set; }
    @AuraEnabled
    public String segmentStatusCode { get; set; }
    @AuraEnabled
    public String serviceClass { get; set; }
    @AuraEnabled
    public String tripType { get; set; }

    public Flight(Segment__c s) {
      actualArrivalTime = s.Flight__r.Actual_Arrival_Time__c;
      actualArrivalTimeLocal = s.Flight__r.Actual_Arrival_Time_Local__c;
      actualDepartureTime = s.Flight__r.Actual_Departure_Time__c;
      actualDepartureTimeLocal = s.Flight__r.Actual_Departure_Time_Local__c;
      arrivalAirport = s.Flight__r.Arrival_Airport__c;
      arrivalDelayedMinutes = s.Flight__r.Arrival_Delayed_Minutes__c;
      arrivalGate = s.Flight__r.Arrival_Gate__c;
      arrivalStatus = s.Flight__r.Arrival_Status__c;
      arrivalTerminal = s.Flight__r.Arrival_Terminal__c;
      bookingClass = s.Booking_Class__c;
      departureAirport = s.Flight__r.Departure_Airport__c;
      departureDelayedMinutes = s.Flight__r.Departure_Delayed_Minutes__c;
      departureGate = s.Flight__r.Departure_Gate__c;
      departureStatus = s.Flight__r.Departure_Status__c;
      departureTerminal = s.Flight__r.Departure_Terminal__c;
      estimatedArrivalTime = s.Flight__r.Estimated_Arrival_Time__c;
      estimatedArrivalTimeLocal = s.Flight__r.Estimated_Arrival_Time_Local__c;
      estimatedDepartureTime = s.Flight__r.Estimated_Departure_Time__c;
      estimatedDepartureTimeLocal = s.Flight__r.Estimated_Departure_Time_Local__c;
      fareBasis = s.Fare_Basis__c;
      flightNumber = s.Flight__r.TEDS_Identifier__c.substringBefore('-');
      scheduledArrivalTime = s.Flight__r.Scheduled_Arrival_Time__c;
      scheduledArrivalTimeLocal = s.Flight__r.Scheduled_Arrival_Time_Local__c;
      scheduledDepartureTime = s.Flight__r.Scheduled_Departure_Time__c;
      scheduledDepartureTimeLocal = s.Flight__r.Scheduled_Departure_Time_Local__c;
      segmentStatusCode = s.Segment_Status_Code__c;
      serviceClass = s.Service_Class__c;
      tripType = s.Trip_Type__c;
    }

    global Integer compareTo(Object other) {
      BookingJSON.Flight otherFlight = (BookingJSON.Flight) other;

      Integer toReturn = 0;
      if (scheduledDepartureTime > otherFlight.scheduledDepartureTime) {
        toReturn = 1;
      } else if (scheduledDepartureTime < otherFlight.scheduledDepartureTime) {
        toReturn = -1;
      }

      return toReturn;
    }
  }

  global class Passenger implements Comparable {
    @AuraEnabled
    public List<String> bags { get; set; }
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public String euroBonusNumber { get; set; }
    @AuraEnabled
    public String firstName { get; set; }
    @AuraEnabled
    public String identifier { get; set; }
    @AuraEnabled
    public String lastName { get; set; }
    @AuraEnabled
    public String phone { get; set; }
    @AuraEnabled
    public List<String> specialServiceRequests { get; set; }
    @AuraEnabled
    public List<String> seats { get; set; }
    @AuraEnabled
    public Set<String> ticketNumbers { get; set; }

    public Passenger(
      Passenger__c p,
      List<String> bagsList,
      List<String> seatsList,
      List<String> SSRs,
      Set<String> ticketNumbersSet
    ) {
      bags = bagsList;
      email = p.Email__c;
      euroBonusNumber = p.EuroBonus_Number__c;
      firstName = p.First_Name__c;
      identifier = p.Identifier__c;
      lastName = p.Last_Name__c;
      phone = p.Phone__c;
      seats = seatsList;
      specialServiceRequests = SSRs;
      ticketNumbers = ticketNumbersSet;
    }

    global Integer compareTo(Object other) {
      BookingJSON.Passenger otherPassenger = (BookingJSON.Passenger) other;

      Integer toReturn = 0;
      if (identifier > otherPassenger.identifier) {
        toReturn = 1;
      } else if (otherPassenger.identifier < identifier) {
        toReturn = -1;
      }

      return toReturn;
    }
  }

  public BookingJSON(
    Booking__c booking,
    List<Case> relatedCasesArg,
    List<IRR_CommunicationLog__c> relatedCommunicationLogsArg
  ) {
    bookingReference = booking.Booking_Reference__c;
    createdAtTravelOfficeId = booking.Created_at_Travel_Office_Id__c;
    bookingIdentifier = booking.TEDS_Identifier__c;
    isCancelled = booking.Is_Cancelled__c;
    lastUpdated = booking.LastModifiedDate;
    relatedCases = relatedCasesArg;
    type = booking.Type__c;
    List<BookingJSON.Flight> tempFlights = new List<BookingJSON.Flight>();
    List<BookingJSON.CommunicationLog> tempLogs = new List<BookingJSON.CommunicationLog>();
    List<BookingJSON.Passenger> tempPassengers = new List<BookingJSON.Passenger>();

    Map<String, List<String>> bags = new Map<String, List<String>>();
    Map<String, List<String>> specialServiceRequests = new Map<String, List<String>>();
    Map<String, List<String>> seats = new Map<String, List<String>>();
    Map<String, Set<String>> ticketNumbers = new Map<String, Set<String>>();

    String firstPassengerIdHandled;

    // Constructing the flights of this booking from segments.
    // Each passenger has the same flights, so we'll collect flights from only one.
    for (Segment__c s : booking.Segments__r) {
      String segmentId = s.Identifier__c.substringBetween('ST', 'PT');
      String passengerId = s.Identifier__c.substringAfter('PT');

      List<String> existingSSRs = specialServiceRequests.get(passengerId);
      if (existingSSRs == null) {
        specialServiceRequests.put(
          passengerId,
          new List<String>{ s.Special_Service_Requests__c }
        );
      } else {
        existingSSRs.add(s.Special_Service_Requests__c);
        specialServiceRequests.put(passengerId, existingSSRs);
      }

      List<String> existingBags = bags.get(passengerId);
      String bag =
        (s.Baggage_Quantity__c == null
          ? '-'
          : s.Baggage_Quantity__c.format() + ' x 23kg') +
        ' (' +
        s.Flight__r.Departure_Airport__c +
        '-' +
        s.Flight__r.Arrival_Airport__c +
        ')';
      if (existingBags == null) {
        bags.put(passengerId, new List<String>{ bag });
      } else {
        existingBags.add(bag);
        bags.put(passengerId, existingBags);
      }

      List<String> existingSeats = seats.get(passengerId);
      String seat =
        (String.isBlank(s.Seat__c) ? '-' : s.Seat__c) +
        ' (' +
        s.Flight__r.Departure_Airport__c +
        '-' +
        s.Flight__r.Arrival_Airport__c +
        ')';
      if (existingSeats == null) {
        seats.put(passengerId, new List<String>{ seat });
      } else {
        existingSeats.add(seat);
        seats.put(passengerId, existingSeats);
      }

      Set<String> existingTicketNumbers = ticketNumbers.get(passengerId);
      if (existingTicketNumbers == null) {
        ticketNumbers.put(passengerId, new Set<String>{ s.Ticket_Number__c });
      } else {
        existingTicketNumbers.add(s.Ticket_Number__c);
        ticketNumbers.put(passengerId, existingTicketNumbers);
      }

      if (firstPassengerIdHandled == null) {
        firstPassengerIdHandled = passengerId;
        tempFlights.add(new BookingJSON.Flight(s));
      } else if (firstPassengerIdHandled == passengerId) {
        tempFlights.add(new BookingJSON.Flight(s));
      }
    }

    for (Passenger__c p : booking.Passengers__r) {
      tempPassengers.add(
        new BookingJSON.Passenger(
          p,
          bags.get(p.Identifier__c.substringAfter('PT')),
          seats.get(p.Identifier__c.substringAfter('PT')),
          specialServiceRequests.get(p.Identifier__c.substringAfter('PT')),
          ticketNumbers.get(p.Identifier__c.substringAfter('PT'))
        )
      );
    }

    if (relatedCommunicationLogsArg != null) {
      for (IRR_CommunicationLog__c l : relatedCommunicationLogsArg) {
        tempLogs.add(new BookingJSON.CommunicationLog(l));
      }
    }

    tempFlights.sort();
    tempPassengers.sort();

    flights = tempFlights;
    relatedCommunicationLogs = tempLogs;
    passengers = tempPassengers;
  }

  global Integer compareTo(Object other) {
    BookingJSON otherBooking = (BookingJSON) other;

    Integer toReturn = 0;
    if (
      flights == null ||
      otherBooking.flights == null ||
      flights.size() == 0 ||
      otherBooking.flights.size() == 0
    ) {
      return toReturn;
    }
    if (
      flights[0].scheduledDepartureTime >
      otherBooking.flights[0].scheduledDepartureTime
    ) {
      toReturn = 1;
    } else if (
      flights[0].scheduledDepartureTime <
      otherBooking.flights[0].scheduledDepartureTime
    ) {
      toReturn = -1;
    }

    return toReturn;
  }
}
