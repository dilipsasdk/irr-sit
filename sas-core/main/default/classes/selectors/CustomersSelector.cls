public inherited sharing class CustomersSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Customer__c.Id,
      Customer__c.Name,
      Customer__c.CreatedDate,
      Customer__c.LastModifiedDate,
      Customer__c.Claim__c,
      Customer__c.First_Name__c,
      Customer__c.Last_Name__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Customer__c.SObjectType;
  }

  public static CustomersSelector newInstance() {
    return (CustomersSelector) SAS_Service_Application.Selector.newInstance(
      Customer__c.SObjectType
    );
  }

  public List<Customer__c> selectById(Set<Id> ids) {
    return (List<Customer__c>) selectSObjectsById(ids);
  }

  public List<Customer__c> selectByName(Set<String> names) {
    return (List<Customer__c>) Database.query(
      newQueryFactory().setCondition('Name IN :names').toSOQL()
    );
  }

  public List<Customer__c> selectByClaimId(Set<Id> claimIds) {
    return (List<Customer__c>) Database.query(
      newQueryFactory().setCondition('Claim__c IN :claimIds').toSOQL()
    );
  }
}
