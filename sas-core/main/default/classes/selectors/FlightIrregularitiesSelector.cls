public inherited sharing class FlightIrregularitiesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      FlightIrregularities__c.Id,
      FlightIrregularities__c.Name,
      FlightIrregularities__c.CreatedDate,
      FlightIrregularities__c.LastModifiedDate,
      FlightIrregularities__c.Cancellation_Time__c,
      FlightIrregularities__c.Code__c,
      FlightIrregularities__c.Description__c,
      FlightIrregularities__c.Duration_minutes__c,
      FlightIrregularities__c.Eligible_For_EU261__c,
      FlightIrregularities__c.Flight__c,
      FlightIrregularities__c.Name__c,
      FlightIrregularities__c.Reason__c,
      FlightIrregularities__c.Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return FlightIrregularities__c.SObjectType;
  }

  public static FlightIrregularitiesSelector newInstance() {
    return (FlightIrregularitiesSelector) SAS_Service_Application.Selector.newInstance(
      FlightIrregularities__c.SObjectType
    );
  }

  public List<FlightIrregularities__c> selectById(Set<Id> ids) {
    return (List<FlightIrregularities__c>) selectSObjectsById(ids);
  }

  public List<FlightIrregularities__c> selectByFlightId(Set<Id> flightIds) {
    return (List<FlightIrregularities__c>) Database.query(
      newQueryFactory().setCondition('Flight__c IN :flightIds').toSOQL()
    );
  }

  public List<FlightIrregularities__c> selectByTEDSFlightId(
    Set<String> flightIds
  ) {
    return (List<FlightIrregularities__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Flight__c IN (SELECT Id FROM Flight__c WHERE TEDS_Identifier__c IN :flightIds)'
        )
        .toSOQL()
    );
  }

  public List<FlightIrregularities__c> selectByFlightNumberDateAndAirports(
    String flightNumber,
    Date departureDate,
    String fromAirport,
    String toAirport
  ) {
    String flightId =
      Flight.constructTEDSFlightNumberDate(flightNumber, departureDate) +
      '-' +
      fromAirport +
      '-' +
      toAirport;

    return (List<FlightIrregularities__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Flight__c IN (SELECT Id FROM Flight__c WHERE TEDS_Identifier__c = :flightId)'
        )
        .toSOQL()
    );
  }
}
