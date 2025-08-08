@IsTest
private class Trip_Test {
  private static String oneWayBookingReference = 'ONTIME';
  private static String roundTripBookingReference = 'ROUNDT';
  private static String dayReturnBookingReference = 'DAYRET';
  private static String multiCityBookingReference = 'MULTIC';
  private static String unknownBookingReference = 'UNKNOW';

  @TestSetup
  static void makeBookings() {
    Booking__c oneWayBooking = new Booking__c(
      Booking_Reference__c = oneWayBookingReference,
      TEDS_Identifier__c = 'uniqueBooking1',
      Type__c = 'OneWay'
    );
    Booking__c dayReturnBooking = new Booking__c(
      Booking_Reference__c = dayReturnBookingReference,
      TEDS_Identifier__c = 'uniqueBooking2',
      Type__c = 'DayReturn'
    );
    Booking__c multiCityBooking = new Booking__c(
      Booking_Reference__c = multiCityBookingReference,
      TEDS_Identifier__c = 'uniqueBooking3',
      Type__c = 'MultiCity'
    );
    Booking__c roundTripBooking = new Booking__c(
      Booking_Reference__c = roundTripBookingReference,
      TEDS_Identifier__c = 'uniqueBooking4',
      Type__c = 'RoundTrip'
    );
    Booking__c unknownBooking = new Booking__c(
      Booking_Reference__c = unknownBookingReference,
      TEDS_Identifier__c = 'uniqueBooking5',
      Type__c = 'Unknown'
    );
    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'HEL',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0001-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 11, 0)
    );
    Flight__c flight2 = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'ARN',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0002-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 10, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 12, 1, 0)
    );
    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0003-20220818',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c flight4 = new Flight__c(
      Arrival_Airport__c = 'CPH',
      Departure_Airport__c = 'ARN',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0004-20220818',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 4, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c flight5 = new Flight__c(
      Arrival_Airport__c = 'CDG',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0005-20220818',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 19, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 19, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c flightRoundtripReturn = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'ARN',
      TEDS_Identifier__c = 'SK0004-20220819',
      Operating_Carrier__c = 'SK',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 19, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 19, 2, 1, 0)
    );
    Airport__c airportHEL = new Airport__c(
      City__c = 'Helsinki',
      Country_Code__c = 'FI',
      Country_Name__c = 'Finland',
      TEDS_Identifier__c = 'HEL',
      Is_EU261_Applicable__c = true,
      Latitude__c = 60.317199707031,
      Longitude__c = 24.963300704956
    );
    Airport__c airportARN = new Airport__c(
      City__c = 'Stockholm',
      Country_Code__c = 'SE',
      Country_Name__c = 'Sweden',
      TEDS_Identifier__c = 'ARN',
      Is_EU261_Applicable__c = true,
      Latitude__c = 59.651901245117,
      Longitude__c = 17.918600082397
    );
    Airport__c airportCPH = new Airport__c(
      City__c = 'Copenhagen',
      Country_Code__c = 'DK',
      Country_Name__c = 'Denmark',
      TEDS_Identifier__c = 'CPH',
      Is_EU261_Applicable__c = true,
      Latitude__c = 55.617900848389,
      Longitude__c = 12.656000137329
    );
    Airport__c airportCDG = new Airport__c(
      City__c = 'Paris',
      Country_Code__c = 'FR',
      Country_Name__c = 'France',
      TEDS_Identifier__c = 'CDG',
      Is_EU261_Applicable__c = true,
      Latitude__c = 49.012798,
      Longitude__c = 2.55
    );
    Airport__c airportJFK = new Airport__c(
      City__c = 'New York',
      Country_Code__c = 'US',
      Country_Name__c = 'United States',
      TEDS_Identifier__c = 'JFK',
      Is_EU261_Applicable__c = false,
      Latitude__c = 40.639801,
      Longitude__c = -73.7789
    );

    insert new List<SObject>{
      oneWayBooking,
      dayReturnBooking,
      multiCityBooking,
      roundTripBooking,
      unknownBooking,
      flight1,
      flight2,
      flight3,
      flight4,
      flight5,
      flightRoundtripReturn,
      airportHEL,
      airportARN,
      airportCPH,
      airportCDG,
      airportJFK
    };

    Segment__c oneWaySegment = new Segment__c(
      Booking__c = oneWayBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c dayReturnSegment1 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c dayReturnSegment2 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Inbound'
    );
    Segment__c roundTripSegment1 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c roundTripSegment2 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flightRoundtripReturn.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Inbound'
    );
    Segment__c multiCitySegment1 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c multiCitySegment2 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight4.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c multiCitySegment3 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight5.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c unknownSegment = new Segment__c(
      Booking__c = unknownBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Unknown'
    );

    insert new List<SObject>{
      oneWaySegment,
      dayReturnSegment1,
      dayReturnSegment2,
      roundTripSegment1,
      roundTripSegment2,
      multiCitySegment1,
      multiCitySegment2,
      multiCitySegment3,
      unknownSegment
    };
  }

  @IsTest
  static void oneWayShouldBeDividedIntoOneTrip() {
    Booking__c bc = BookingsSelector.newInstance()
      .selectByBookingReference(oneWayBookingReference)[0];
    Booking b = new Booking(bc);
    b.setAirports(getAirports());
    List<Trip> trips = Trip.divideSegmentsIntoTrips(b.segments);

    System.assertEquals(
      1,
      trips.size(),
      'Should divide booking into a single trip'
    );

    System.assertEquals(
      trips[0].originAirport.tedsIdentifier,
      'HEL',
      'Origin airport should be HEL'
    );

    System.assertEquals(
      trips[0].destinationAirport.tedsIdentifier,
      'ARN',
      'Destination airport should be ARN'
    );
  }

  @IsTest
  static void roundTripShouldBeDividedIntoTwoTrips() {
    Booking__c bc = BookingsSelector.newInstance()
      .selectByBookingReference(roundTripBookingReference)[0];
    Booking b = new Booking(bc);
    b.setAirports(getAirports());
    List<Trip> trips = Trip.divideSegmentsIntoTrips(b.segments);

    System.assertEquals(
      2,
      trips.size(),
      'Should divide booking into two trips'
    );

    System.assertEquals(
      trips[0].originAirport.tedsIdentifier,
      'HEL',
      'Origin airport of the first trip should be HEL'
    );

    System.assertEquals(
      trips[0].destinationAirport.tedsIdentifier,
      'ARN',
      'Destination airport of the first trip should be ARN'
    );

    System.assertEquals(
      trips[1].originAirport.tedsIdentifier,
      'ARN',
      'Origin airport of the second trip should be ARN'
    );

    System.assertEquals(
      trips[1].destinationAirport.tedsIdentifier,
      'HEL',
      'Destination airport of the second trip should be HEL'
    );
  }

  @IsTest
  static void dayReturnShouldBeDividedIntoTwoTrips() {
    Booking__c bc = BookingsSelector.newInstance()
      .selectByBookingReference(dayReturnBookingReference)[0];
    Booking b = new Booking(bc);
    b.setAirports(getAirports());

    Boolean isSupported = true;
    List<Trip> trips;
    try {
      trips = Trip.divideSegmentsIntoTrips(b.segments);
    } catch (Trip.BookingTypeNotSupportedException e) {
      isSupported = false;
    }

    System.assert(isSupported, 'Dayreturn bookings should not be supported');

    System.assertEquals(
      2,
      trips.size(),
      'Should divide booking into two trips'
    );

    System.assertEquals(
      trips[0].originAirport.tedsIdentifier,
      'HEL',
      'Origin airport of the first trip should be HEL'
    );

    System.assertEquals(
      trips[0].destinationAirport.tedsIdentifier,
      'ARN',
      'Destination airport of the first trip should be ARN'
    );

    System.assertEquals(
      trips[1].originAirport.tedsIdentifier,
      'ARN',
      'Origin airport of the second trip should be ARN'
    );

    System.assertEquals(
      trips[1].destinationAirport.tedsIdentifier,
      'HEL',
      'Destination airport of the second trip should be HEL'
    );
  }

  @IsTest
  static void multiCityTwoCitiesShouldBeDividedIntoTwoTrips() {
    Booking__c bc = BookingsSelector.newInstance()
      .selectByBookingReference(multiCityBookingReference)[0];
    Booking b = new Booking(bc);
    b.setAirports(getAirports());

    List<Trip> trips = Trip.divideSegmentsIntoTrips(b.segments);

    System.assertEquals(
      2,
      trips.size(),
      'Should divide booking into two trips'
    );

    System.assertEquals(
      trips[0].originAirport.tedsIdentifier,
      'HEL',
      'Origin airport of the first trip should be HEL'
    );

    System.assertEquals(
      trips[0].destinationAirport.tedsIdentifier,
      'CPH',
      'Destination airport of the first trip should be CPH'
    );

    System.assertEquals(
      trips[1].originAirport.tedsIdentifier,
      'CPH',
      'Origin airport of the second trip should be CPH'
    );

    System.assertEquals(
      trips[1].destinationAirport.tedsIdentifier,
      'CDG',
      'Destination airport of the second trip should be CDG'
    );
  }

  private static Map<String, Airport> getAirports() {
    List<Airport__c> allAirports = AirportsSelector.newInstance()
      .selectByIATACode(new Set<String>{ 'HEL', 'ARN', 'CPH', 'JFK', 'CDG' });
    Map<String, Airport> airportCodeToAirport = new Map<String, Airport>{};
    for (Airport__c a : allAirports) {
      airportCodeToAirport.put(a.TEDS_Identifier__c, new Airport(a));
    }

    return airportCodeToAirport;
  }
}
