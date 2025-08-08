@IsTest
private class FlightDelayCertificateRequests_Test {
  @IsTest
  public static void updatingBookingReferenceShouldUpdateBookingOnCase() {
    String newBookingReference = 'TEST21';
    Case c = new Case(
      Department__c = 'Customer Claim',
      Team__c = 'Flight Delay Certificate',
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim)
    );
    insert c;

    Flight_Delay_Certificate_Request__c fdcr = new Flight_Delay_Certificate_Request__c(
      Booking_Reference__c = '123457',
      Case__c = c.Id,
      Contact_First_Name__c = 'Test',
      Contact_Last_Name__c = 'Testsson'
    );
    insert fdcr;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fdcr.Booking_Reference__c = newBookingReference;
    update fdcr;
    Test.stopTest();
    List<CaseToBooking__c> ctb = CaseToBookingsSelector.newInstance()
      .selectByCaseId(new Set<Id>{ c.Id });
    List<Booking__c> bookings = BookingsSelector.newInstance()
      .selectByBookingReference(newBookingReference);
    System.assert(
      ctb.size() > 0,
      'There should have been a case to booking created for this case'
    );
    System.assertEquals(
      bookings[0].Id,
      ctb[0].Booking__c,
      'Booking should be linked to the case related to the Flight Delay Certificate Request'
    );
  }
}
