public inherited sharing class PassengersSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Passenger__c.Id,
      Passenger__c.Name,
      Passenger__c.CreatedDate,
      Passenger__c.LastModifiedDate,
      Passenger__c.Account__c,
      Passenger__c.Booking__c,
      Passenger__c.Email__c,
      Passenger__c.EuroBonus_Number__c,
      Passenger__c.First_Name__c,
      Passenger__c.Identifier__c,
      Passenger__c.Last_Name__c,
      Passenger__c.Phone__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Passenger__c.SObjectType;
  }

  public static PassengersSelector newInstance() {
    return (PassengersSelector) SAS_Service_Application.Selector.newInstance(
      Passenger__c.SObjectType
    );
  }

  public List<Passenger__c> selectByAccountId(Set<Id> accountIds) {
    return (List<Passenger__c>) Database.query(
      newQueryFactory().setCondition('Account__c in :accountIds').toSOQL()
    );
  }

  public List<Passenger__c> selectById(Set<Id> ids) {
    return (List<Passenger__c>) selectSObjectsById(ids);
  }

  public List<Passenger__c> selectByEuroBonusNumber(
    Set<String> euroBonusNumbers
  ) {
    return (List<Passenger__c>) Database.query(
      newQueryFactory()
        .setCondition('EuroBonus_Number__c in :euroBonusNumbers')
        .toSOQL()
    );
  }
  public List<Passenger__c> selectByLastName(String lastName) {
    return (List<Passenger__c>) Database.query(
      newQueryFactory().setCondition('Last_Name__c = :lastName').toSOQL()
    );
  }
  public List<Passenger__c> selectByBookingId(Set<Id> bookingIds) {
    return (List<Passenger__c>) Database.query(
      newQueryFactory().setCondition('Booking__c IN :bookingIds').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Last_Name__c';
  }
}