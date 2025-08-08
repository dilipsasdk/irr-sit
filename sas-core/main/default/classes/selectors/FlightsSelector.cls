public inherited sharing class FlightsSelector extends fflib_SObjectSelector {
  // TODO: Make the airports lookups
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Flight__c.Id,
      Flight__c.Name,
      Flight__c.CreatedDate,
      Flight__c.LastModifiedDate,
      Flight__c.Aircraft_Registration__c,
      Flight__c.Actual_Arrival_Time__c,
      Flight__c.Actual_Arrival_Time_Local__c,
      Flight__c.Actual_Departure_Time__c,
      Flight__c.Actual_Departure_Time_Local__c,
      Flight__c.Arrival_Airport__c,
      Flight__c.Arrival_Delayed_Minutes__c,
      Flight__c.Arrival_Gate__c,
      Flight__c.Arrival_Status__c,
      Flight__c.Arrival_Terminal__c,
      Flight__c.Departure_Airport__c,
      Flight__c.Departure_Delayed_Minutes__c,
      Flight__c.Departure_Gate__c,
      Flight__c.Departure_Status__c,
      Flight__c.Departure_Terminal__c,
      Flight__c.Estimated_Arrival_Time__c,
      Flight__c.Estimated_Arrival_Time_Local__c,
      Flight__c.Estimated_Departure_Time__c,
      Flight__c.Estimated_Departure_Time_Local__c,
      Flight__c.Operating_Carrier__c,
      Flight__c.Operational_Control_Center__c,
      Flight__c.Scheduled_Arrival_Time__c,
      Flight__c.Scheduled_Arrival_Time_Local__c,
      Flight__c.Scheduled_Departure_Time__c,
      Flight__c.Scheduled_Departure_Time_Local__c,
      Flight__c.TEDS_Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Flight__c.SObjectType;
  }

  public static FlightsSelector newInstance() {
    return (FlightsSelector) SAS_Service_Application.Selector.newInstance(
      Flight__c.SObjectType
    );
  }

  public List<Flight__c> selectById(Set<Id> ids) {
    return (List<Flight__c>) selectSObjectsById(ids);
  }

  public List<Flight__c> selectByTEDSId(Set<String> flightIds) {
    return (List<Flight__c>) Database.query(
      newQueryFactory()
        .setCondition('TEDS_Identifier__c IN :flightIds')
        .toSOQL()
    );
  }

  public List<Flight__c> selectByFlightNumberAndDate(
    String flightNumber,
    Date departureDate
  ) {
    String flightLikeId =
      Flight.constructTEDSFlightNumberDate(flightNumber, departureDate) +
      '-___-___';

    return (List<Flight__c>) Database.query(
      newQueryFactory()
        .setCondition('TEDS_Identifier__c LIKE :flightLikeId')
        .toSOQL()
    );
  }

  /**
   * Selects all flights linked to the given bookings through segments.
   */
  public List<Flight__c> selectByBookingIds(Set<Id> bookingIds) {
    List<Booking__c> bookings = BookingsSelector.newInstance()
      .selectByIdFull(bookingIds);

    if (bookings == null || bookings.size() == 0) {
      return new List<Flight__c>();
    }

    Set<Id> flightIds = new Set<Id>();

    for (Booking__c booking : bookings) {
      for (Segment__c segment : booking.Segments__r) {
        flightIds.add(segment.Flight__c);
      }
    }

    return selectById(flightIds);
  }

  public List<Flight__c> selectBybookingReference(
    Set<String> bookingReference
  ) {
    List<Booking__c> bookings = BookingsSelector.newInstance()
      .selectByBookingReference(bookingReference);
    List<Flight__c> toReturn = new List<Flight__c>{};
    for (Booking__c b : bookings) {
      for (Segment__c s : b.Segments__r) {
        toReturn.add(s.Flight__r);
      }
    }

    return toReturn;
  }

  public List<Flight__c> selectFlightsWhichShouldHaveLandedTheLast24Hours() {
    return (List<Flight__c>) Database.query(
      newQueryFactory()
        .setCondition('Scheduled_Arrival_Time__c = LAST_N_DAYS:1')
        .toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'TEDS_Identifier__c';
  }
}
