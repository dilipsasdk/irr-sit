public inherited sharing class RacerIntegrationCountersSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Racer_Integration_Counter__c.Id,
      Racer_Integration_Counter__c.Accounting_Verification_Number__c,
      Racer_Integration_Counter__c.Currency__c,
      Racer_Integration_Counter__c.Payment_Run_Id__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Racer_Integration_Counter__c.SObjectType;
  }

  public static RacerIntegrationCountersSelector newInstance() {
    return (RacerIntegrationCountersSelector) SAS_Service_Application.Selector.newInstance(
      Racer_Integration_Counter__c.SObjectType
    );
  }

  public List<Racer_Integration_Counter__c> selectById(Set<Id> ids) {
    return (List<Racer_Integration_Counter__c>) selectSObjectsById(ids);
  }

  public List<Racer_Integration_Counter__c> selectByCurrency(String c) {
    return (List<Racer_Integration_Counter__c>) Database.query(
      newQueryFactory().setCondition('Currency__c =:c').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
