public inherited sharing class TravelPassProductsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Travel_Pass_Product__c.Id,
      Travel_Pass_Product__c.Account__c,
      Travel_Pass_Product__c.Category_Code__c,
      Travel_Pass_Product__c.Category_Name__c,
      Travel_Pass_Product__c.External_Name__c,
      Travel_Pass_Product__c.Internal_Name__c,
      Travel_Pass_Product__c.LastModifiedDate,
      Travel_Pass_Product__c.Type_Code__c,
      Travel_Pass_Product__c.Type_Name__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Travel_Pass_Product__c.SObjectType;
  }

  public static TravelPassProductsSelector newInstance() {
    return (TravelPassProductsSelector) SAS_Service_Application.Selector.newInstance(
      Travel_Pass_Product__c.SObjectType
    );
  }

  public List<Travel_Pass_Product__c> selectById(Set<Id> ids) {
    return (List<Travel_Pass_Product__c>) selectSObjectsById(ids);
  }

  public List<Travel_Pass_Product__c> selectByAccountId(Set<Id> accountIds) {
    return (List<Travel_Pass_Product__c>) Database.query(
      newQueryFactory().setCondition('Account__c in :accountIds').toSOQL()
    );
  }
}
