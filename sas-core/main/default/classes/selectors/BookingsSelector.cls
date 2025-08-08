public inherited sharing class BookingsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Booking__c.Id,
      Booking__c.Name,
      Booking__c.CreatedDate,
      Booking__c.LastModifiedDate,
      Booking__c.Booking_Reference__c,
      Booking__c.Created_at_Travel_Office_Id__c,
      Booking__c.Is_Cancelled__c,
      Booking__c.Is_Staff_Booking__c,
      Booking__c.TEDS_Identifier__c,
      Booking__c.Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Booking__c.SObjectType;
  }

  public static BookingsSelector newInstance() {
    return (BookingsSelector) SAS_Service_Application.Selector.newInstance(
      Booking__c.SObjectType
    );
  }

  public List<Booking__c> selectById(Set<Id> ids) {
    return (List<Booking__c>) selectSObjectsById(ids);
  }

  public List<Booking__c> selectByIdFull(Set<Id> bookingIds) {
    fflib_QueryFactory bookingsQF = newQueryFactory()
      .setCondition('Id in :bookingIds');
    fflib_QueryFactory passengers = new PassengersSelector()
      .addQueryFactorySubselect(bookingsQF);
    fflib_QueryFactory segments = new SegmentsSelector()
      .addQueryFactorySubselect(bookingsQF);

    new FlightsSelector()
      .configureQueryFactoryFields(
        segments,
        Segment__c.Flight__c.getDescribe().getRelationshipName()
      );

    return (List<Booking__c>) Database.query(bookingsQF.toSOQL());
  }

  // Todo: Rename to selectByBookingReferenceFull
  public List<Booking__c> selectByBookingReference(String bookingReference) {
    return selectByBookingReference(new Set<String>{ bookingReference });
  }

  public List<Booking__c> selectByBookingReference(
    Set<String> bookingReferences
  ) {
    fflib_QueryFactory bookingsQF = newQueryFactory()
      .setCondition('Booking_Reference__c IN :bookingReferences');
    fflib_QueryFactory passengers = new PassengersSelector()
      .addQueryFactorySubselect(bookingsQF);
    fflib_QueryFactory segments = new SegmentsSelector()
      .addQueryFactorySubselect(bookingsQF);

    new FlightsSelector()
      .configureQueryFactoryFields(
        segments,
        Segment__c.Flight__c.getDescribe().getRelationshipName()
      );

    return (List<Booking__c>) Database.query(bookingsQF.toSOQL());
  }

  public List<Booking__c> selectByCaseId(Set<Id> caseIds) {
    CaseToBookingsSelector caseToBookings = (CaseToBookingsSelector) SAS_Service_Application.Selector.newInstance(
      CaseToBooking__c.SObjectType
    );

    Set<Id> bookingIds = new Set<Id>();
    for (CaseToBooking__c c : caseToBookings.selectByCaseId(caseIds)) {
      bookingIds.add(c.Booking__c);
    }

    return this.selectByIdFull(bookingIds);
  }

  public List<Booking__c> selectByAccountId(Set<Id> accountIds) {
    PassengersSelector passengers = (PassengersSelector) SAS_Service_Application.Selector.newInstance(
      Passenger__c.SObjectType
    );

    Set<Id> bookingIds = new Set<Id>();
    for (Passenger__c c : passengers.selectByAccountId(accountIds)) {
      bookingIds.add(c.Booking__c);
    }

    return this.selectByIdFull(bookingIds);
  }

  public List<Booking__c> selectByTEDSIdFull(Set<String> tedsIds) {
    fflib_QueryFactory bookingsQF = newQueryFactory()
      .setCondition('TEDS_Identifier__c in :tedsIds');
    fflib_QueryFactory passengers = new PassengersSelector()
      .addQueryFactorySubselect(bookingsQF);
    fflib_QueryFactory segments = new SegmentsSelector()
      .addQueryFactorySubselect(bookingsQF);

    new FlightsSelector()
      .configureQueryFactoryFields(
        segments,
        Segment__c.Flight__c.getDescribe().getRelationshipName()
      );

    return (List<Booking__c>) Database.query(bookingsQF.toSOQL());
  }

  public List<Booking__c> selectByLastNameAndBookingReference(
    String lastName,
    String bookingReference
  ) {
    Set<Id> bookingIds = new Set<Id>();
    List<Passenger__c> allPassengers = PassengersSelector.newInstance()
      .selectByLastName(lastName);

    for (Passenger__c p : allPassengers) {
      bookingIds.add(p.Booking__c);
    }
    fflib_QueryFactory bookingsQF = newQueryFactory()
      .setCondition(
        'Booking_Reference__c = :bookingReference AND Id in :bookingIds'
      );
    fflib_QueryFactory segments = new SegmentsSelector()
      .addQueryFactorySubselect(bookingsQF);

    new FlightsSelector()
      .configureQueryFactoryFields(
        segments,
        Segment__c.Flight__c.getDescribe().getRelationshipName()
      );

    return (List<Booking__c>) Database.query(bookingsQF.toSOQL());
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
