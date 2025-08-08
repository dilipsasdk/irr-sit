public inherited sharing class SettlementItemsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Settlement_Item__c.Id,
      Settlement_Item__c.Name,
      Settlement_Item__c.CreatedDate,
      Settlement_Item__c.LastModifiedDate,
      Settlement_Item__c.Accounting_File_Name__c,
      Settlement_Item__c.Amount__c,
      Settlement_Item__c.Comments__c,
      Settlement_Item__c.Cost_Account__c,
      Settlement_Item__c.Cost_Center__c,
      Settlement_Item__c.Currency__c,
      Settlement_Item__c.Customer_Name__c,
      Settlement_Item__c.Is_Insured__c,
      Settlement_Item__c.Net_Amount_After_Deductible__c,
      Settlement_Item__c.Settlement__c,
      Settlement_Item__c.Status__c,
      Settlement_Item__c.Date_Of_Accounting__c,
      Settlement_Item__c.RecordTypeId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Settlement_Item__c.SObjectType;
  }

  public static SettlementItemsSelector newInstance() {
    return (SettlementItemsSelector) SAS_Service_Application.Selector.newInstance(
      Settlement_Item__c.SObjectType
    );
  }

  public List<Settlement_Item__c> selectById(Set<Id> ids) {
    return (List<Settlement_Item__c>) selectSObjectsById(ids);
  }

  public List<Settlement_Item__c> selectByAccountingFileName(
    String accountingFileName
  ) {
    return (List<Settlement_Item__c>) Database.query(
      newQueryFactory()
        .setCondition('Accounting_File_Name__c = :accountingFileName')
        .toSOQL()
    );
  }

  public List<Settlement_Item__c> selectBySettlementIds(Set<Id> settlementIds) {
    return (List<Settlement_Item__c>) Database.query(
      newQueryFactory().setCondition('Settlement__c IN :settlementIds').toSOQL()
    );
  }

  public List<Settlement_Item__c> selectWaitingForTransferByCurrency(
    List<String> currencies
  ) {
    String statusToTake = 'Waiting for transfer';

    return (List<Settlement_Item__c>) Database.query(
      newQueryFactory()
        .selectField('Settlement__r.Date_of_Exchange_Calculation__c')
        .setCondition(
          'Status__c = :statusToTake AND Currency__c IN :currencies'
        )
        .toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
