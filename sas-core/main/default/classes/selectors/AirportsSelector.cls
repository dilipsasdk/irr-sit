public inherited sharing class AirportsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Airport__c.Id,
      Airport__c.Name,
      Airport__c.CreatedDate,
      Airport__c.LastModifiedDate,
      Airport__c.City__c,
      Airport__c.Country_Code__c,
      Airport__c.Country_Name__c,
      Airport__c.Latitude__c,
      Airport__c.Longitude__c,
      Airport__c.Is_EU261_Applicable__c,
      Airport__c.TEDS_Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Airport__c.SObjectType;
  }

  public static AirportsSelector newInstance() {
    return (AirportsSelector) SAS_Service_Application.Selector.newInstance(
      Airport__c.SObjectType
    );
  }

  public List<Airport__c> selectById(Set<Id> ids) {
    return (List<Airport__c>) selectSObjectsById(ids);
  }

  public List<Airport__c> selectByTEDSId(Set<String> airportIds) {
    return (List<Airport__c>) Database.query(
      newQueryFactory()
        .setCondition('TEDS_Identifier__c IN :airportIds')
        .toSOQL()
    );
  }

  public List<Airport__c> selectByIATACode(Set<String> airportIds) {
    return (List<Airport__c>) selectByTEDSId(airportIds);
  }

  public override String getOrderBy() {
    return 'TEDS_Identifier__c';
  }
}
