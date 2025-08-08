public inherited sharing class Refund_RequestsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Refund_Request__c.Id,
      Refund_Request__c.Country_of_Purchase__c,
      Refund_Request__c.Note__c,
      Refund_Request__c.PNR__c,
      Refund_Request__c.Refund_Macro__c,
      Refund_Request__c.Ticket_Numbers__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Refund_Request__c.SObjectType;
  }

  public static Refund_RequestsSelector newInstance() {
    return (Refund_RequestsSelector) SAS_Service_Application.Selector.newInstance(
      Refund_Request__c.SObjectType
    );
  }

  public List<Refund_Request__c> selectById(Set<Id> ids) {
    return (List<Refund_Request__c>) selectSObjectsById(ids);
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
