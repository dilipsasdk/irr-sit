@IsTest
public with sharing class TestBookingFactory {
  public static Booking createValidForClaim(Claim c) {
    Booking b = create();

    b.bookingReference = c.bookingReference;
    b.tedsIdentifier =
      c.bookingReference +
      '-' +
      c.departureDate.year() +
      c.departureDate.month() +
      c.departureDate.day();

    if (c.customers != null) {
      for (ClaimCustomer cc : c.customers) {
        b.passengers.add(TestPassengerFactory.create(b, cc));
      }
    }

    return b;
  }

  public static Booking create() {
    Booking b = new Booking();

    b.id = fflib_IDGenerator.generate(Booking__c.getSObjectType());
    b.bookingReference = '000000';
    b.createdAtTravelOfficeId = 'STOSK08RV';
    b.isCancelled = false;
    b.isStaffBooking = false;
    b.tedsIdentifier = '000000-20220101';
    b.passengers = new List<Passenger>{};

    return b;
  }
}
