public inherited sharing class CaseToBookingsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      CaseToBooking__c.Id,
      CaseToBooking__c.Booking__c,
      CaseToBooking__c.Case__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return CaseToBooking__c.SObjectType;
  }

  public static CaseToBookingsSelector newInstance() {
    return (CaseToBookingsSelector) SAS_Service_Application.Selector.newInstance(
      CaseToBooking__c.SObjectType
    );
  }

  public List<CaseToBooking__c> selectById(Set<Id> ids) {
    return (List<CaseToBooking__c>) selectSObjectsById(ids);
  }

  public List<CaseToBooking__c> selectByCaseId(Set<Id> caseIds) {
    if (caseIds.contains(null)) {
      return new List<CaseToBooking__c>();
    }
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory().setCondition('Case__c in :caseIds').toSOQL()
    );
  }

  public List<CaseToBooking__c> selectByBookingReference(
    Set<String> bookingReferences
  ) {
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory()
        .setCondition('Booking__r.Booking_Reference__c in :bookingReferences')
        .toSOQL()
    );
  }

  public List<CaseToBooking__c> selectByCaseIdAndBookingReference(
    Id caseId,
    String bookingReference
  ) {
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Case__c =:caseId AND Booking__r.Booking_Reference__c =:bookingReference'
        )
        .toSOQL()
    );
  }

  public List<CaseToBooking__c> selectByCaseIdAndBookingIds(
    Id caseId,
    Set<Id> bookingIds
  ) {
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory()
        .setCondition('Case__c =:caseId AND Booking__c IN :bookingIds')
        .toSOQL()
    );
  }

  public List<CaseToBooking__c> selectByCaseIdAndBookingIdentifier(
    Id caseId,
    String bookingIdentifier
  ) {
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Case__c =:caseId AND Booking__r.TEDS_Identifier__c =:bookingIdentifier'
        )
        .toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
