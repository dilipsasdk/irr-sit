@IsTest
public with sharing class Bookings_Test {
  private static BookingsSelector bookingsSel = BookingsSelector.newInstance();
  @IsTest
  public static void bookingWithDelayedFlightsShouldReturnTrue() {
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1',
      Arrival_Status__c = 'delayed',
      Departure_Status__c = 'ontime'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'delayed'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    insert new List<SObject>{ booking, flight1, flight2 };

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ seg1, seg2 };
    Booking__c bookingToTest = bookingsSel.selectByIdFull(
      new Set<Id>{ booking.Id }
    )[0];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Bookings b = Bookings.newInstance(new List<Booking__c>{ bookingToTest })
      .reloadFullBookingData();
    Boolean result = b.objects[0].hasDelayedOrCancelledFlights();
    Test.stopTest();
    System.assert(
      result,
      'Booking should be marked as containing delayed flights'
    );
  }
  @IsTest
  public static void bookingWithCancelledFlightsShouldReturnTrue() {
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1',
      Arrival_Status__c = 'cancelled',
      Departure_Status__c = 'cancelled'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'ontime'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    insert new List<SObject>{ booking, flight1, flight2 };

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ seg1, seg2 };

    Booking__c bookingToTest = bookingsSel.selectByIdFull(
      new Set<Id>{ booking.Id }
    )[0];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Bookings b = Bookings.newInstance(new List<Booking__c>{ bookingToTest })
      .reloadFullBookingData();
      Boolean result = b.objects[0].hasDelayedOrCancelledFlights();
    Test.stopTest();
    System.assert(
      result,
      'Booking should be marked as containing cancelled flights'
    );
  }
  @IsTest
  public static void bookingWithoutIrregularitiesShouldReturnFalse() {
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'ontime'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'ontime'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    insert new List<SObject>{ booking, flight1, flight2 };

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ seg1, seg2 };
    Booking__c bookingToTest = bookingsSel.selectByIdFull(
      new Set<Id>{ booking.Id }
    )[0];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Bookings b = Bookings.newInstance(new List<Booking__c>{ bookingToTest })
      .reloadFullBookingData();
      Boolean result = b.objects[0].hasDelayedOrCancelledFlights();
    Test.stopTest();
    System.assert(
      !result,
      'Booking should not be marked as containing delayed flights'
    );
  }

  @IsTest
  public static void invalidPnrsShouldBeIdentifiedCorrectly() {
    List<String> pnrs = new List<String>{
      'ABCD',
      '',
      null,
      '"abcde',
      'ÖABCDE'
    };

    for (String pnr : pnrs) {
      System.assert(
        !Booking.isValidBookingReference(pnr),
        'PNR: ' +
        pnr +
        ' should be invalid.'
      );
    }
  }

  @IsTest
  public static void validPnrsShouldBeIdentifiedCorrectly() {
    List<String> pnrs = new List<String>{
      'ABCDE',
      'ABCDEF',
      '234DER',
      'A2B4C8',
      '12345'
    };

    for (String pnr : pnrs) {
      System.assert(
        Booking.isValidBookingReference(pnr),
        'PNR: ' +
        pnr +
        ' should be valid.'
      );
    }
  }

  @IsTest
  public static void bookingShouldContainPassengerFlight() {
    Case c = TestDataFactories.createCasesWithClaims(
        1,
        null,
        new Map<Schema.SObjectField, Object>{
          LIA_Claim__c.Liability_PNR__c => APIMMock.DEFAULT_VALID_TEDS_PNR,
          LIA_Claim__c.Flight_Number__c => 'SK0402',
          LIA_Claim__c.Flight_Date__c => Date.valueOf('2021-04-20')
        }
      )
      .cases[0];

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    BookingService.addBookingToCase(c.Id, APIMMock.DEFAULT_VALID_TEDS_PNR);
    Bookings b = Bookings.newInstance(
        BookingsSelector.newInstance()
          .selectByBookingReference(APIMMock.DEFAULT_VALID_TEDS_PNR)
      )
      .reloadFullBookingData();
    Test.stopTest();
    Booking currentBooking = b.objects[0];
    System.assert(
      currentBooking.containsFlight('SK0402-20210420'),
      'Flight should have been found in the booking'
    );
    System.assert(
      currentBooking.containsPassenger('TESTSSON'),
      'Passenger should have been found in the booking'
    );
    System.assert(
      !currentBooking.containsFlight('SK9999-20190620'),
      'Flight should not have been found in the booking'
    );
    System.assert(
      !currentBooking.containsPassenger('OtherTestsson'),
      'Passenger should not have been found in the booking'
    );
  }

  @IsTest
  public static void shouldReloadDataProperly() {
    Case c = TestDataFactories.createCasesWithClaims(
        1,
        null,
        new Map<Schema.SObjectField, Object>{
          LIA_Claim__c.Liability_PNR__c => APIMMock.DEFAULT_VALID_TEDS_PNR,
          LIA_Claim__c.Flight_Number__c => 'SK0402',
          LIA_Claim__c.Flight_Date__c => Date.valueOf('2021-04-20')
        }
      )
      .cases[0];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    BookingService.addBookingToCase(c.Id, APIMMock.DEFAULT_VALID_TEDS_PNR);
    Bookings b = Bookings.newInstance(
        BookingsSelector.newInstance()
          .selectByBookingReference(APIMMock.DEFAULT_VALID_TEDS_PNR)
      )
      .reloadFullBookingData();
    Test.stopTest();
    System.assertNotEquals(b.fullRecords, null);
  }
}
