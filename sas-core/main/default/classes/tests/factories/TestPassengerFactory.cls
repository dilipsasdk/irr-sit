@IsTest
public with sharing class TestPassengerFactory {
  public static Passenger create() {
    Booking b = new Booking(new Booking__c());
    return create(b);
  }

  public static Passenger create(Booking b) {
    return create(b, 1)[0];
  }

  public static List<Passenger> create(Booking b, Integer noPassengers) {
    List<Passenger> passengers = new List<Passenger>{};
    for (Integer i = 0; i < noPassengers; i++) {
      Passenger p = new Passenger();
      p.accountId = fflib_IDGenerator.generate(Passenger__c.getSObjectType());
      p.bookingId = b.id;
      p.email = 'test' + String.valueOf(i) + '@example.com';
      p.euroBonusNumber = String.valueOf(i).leftPad(9, '0');
      p.firstName = 'Test' + String.valueOf(i);
      p.lastName = 'Testsson' + String.valueOf(i);
      p.identifier = 'PT' + String.valueOf(i);
      p.phone = String.valueOf(i).leftPad(10, '0');
      passengers.add(p);
    }

    return passengers;
  }

  public static Passenger create(Booking b, ClaimCustomer cc) {
    Passenger p = create(b, 1)[0];
    p.firstName = cc.firstName;
    p.lastName = cc.lastName;
    return p;
  }
}
