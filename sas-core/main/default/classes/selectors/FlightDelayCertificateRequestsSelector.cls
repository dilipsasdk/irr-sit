public with sharing class FlightDelayCertificateRequestsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Flight_Delay_Certificate_Request__c.Id,
      Flight_Delay_Certificate_Request__c.Booking_Reference__c,
      Flight_Delay_Certificate_Request__c.Case__c,
      Flight_Delay_Certificate_Request__c.Contact_First_Name__c,
      Flight_Delay_Certificate_Request__c.Contact_Last_Name__c,
      Flight_Delay_Certificate_Request__c.Contact_Full_Name__c,
      Flight_Delay_Certificate_Request__c.Flight_Number__c,
      Flight_Delay_Certificate_Request__c.Flight_Date__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Flight_Delay_Certificate_Request__c.SObjectType;
  }

  public static FlightDelayCertificateRequestsSelector newInstance() {
    return (FlightDelayCertificateRequestsSelector) SAS_Service_Application.Selector.newInstance(
      Flight_Delay_Certificate_Request__c.SObjectType
    );
  }

  public List<Flight_Delay_Certificate_Request__c> selectById(Set<Id> ids) {
    return (List<Flight_Delay_Certificate_Request__c>) selectSObjectsById(ids);
  }
  public List<Flight_Delay_Certificate_Request__c> selectByIdFull(Set<Id> ids) {
    fflib_QueryFactory fdcrQF = newQueryFactory().setCondition('Id in :ids');
    CasesSelector.newInstance().configureQueryFactoryFields(fdcrQF, 'Case__r');
    return (List<Flight_Delay_Certificate_Request__c>) Database.query(
      fdcrQF.toSOQL()
    );
  }
}
