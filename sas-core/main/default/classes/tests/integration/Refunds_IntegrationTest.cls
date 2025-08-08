@IsTest
public with sharing class Refunds_IntegrationTest {
  public static String bookingReferenceOnlyInTEDS = 'TEDS12';
  public static String invalidBookingReference = 'AAAAAA';
  public static String ebNumberWithBookings = 'TEST123456';
  public static String ebNumberWithoutBookings = 'TEST654321';

  public static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );

  public static Refund_RequestsSelector refundRequests = (Refund_RequestsSelector) SAS_Service_Application.Selector.newInstance(
    Refund_Request__c.SObjectType
  );

  @IsTest
  public static void insertingCaseWithRefundFetchesRelatedBooking() {
    // Given

    Refund_Request__c refund = new Refund_Request__c(
      PNR__c = bookingReferenceOnlyInTEDS
    );

    insert refund;

    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    testCase.Refund_Request__c = refund.Id;
    testCase.Initially_Provided_PNR__c = bookingReferenceOnlyInTEDS;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When
    insert testCase;
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookings.selectByCaseId(
      new Set<Id>{ testCase.Id }
    )[0];

    System.assertEquals(
      bookingReferenceOnlyInTEDS,
      bookingFromDB.Booking_Reference__c,
      'Booking should be found by case Id of the refund case and have the same reference'
    );
  }

  @IsTest
  public static void pnrShouldAlwaysBeUppercase() {
    Refund_Request__c refund = new Refund_Request__c(PNR__c = 'abc123');

    Test.startTest();

    insert refund;
    Refund_Request__c refundRequestAfterInsert = refundRequests.selectById(
      new Set<Id>{ refund.Id }
    )[0];
    System.assertEquals(
      'ABC123',
      refundRequestAfterInsert.PNR__c,
      'Refund request PNR should be uppercase after insert.'
    );

    refund.PNR__c = 'def456';
    update refund;
    Refund_Request__c refundRequestAfterUpdate = refundRequests.selectById(
      new Set<Id>{ refund.Id }
    )[0];
    System.assertEquals(
      'DEF456',
      refundRequestAfterUpdate.PNR__c,
      'Refund request PNR should be uppercase after update.'
    );

    Test.stopTest();
  }
}
