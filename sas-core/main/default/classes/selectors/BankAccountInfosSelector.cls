public inherited sharing class BankAccountInfosSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Bank_Account_Info__c.Id,
      Bank_Account_Info__c.Active__c,
      Bank_Account_Info__c.Name,
      Bank_Account_Info__c.Bank_Account_Number__c,
      Bank_Account_Info__c.Bank_Name__c,
      Bank_Account_Info__c.BIC_Swift__c,
      Bank_Account_Info__c.Claim_Firm__c,
      Bank_Account_Info__c.Country__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Bank_Account_Info__c.SObjectType;
  }

  public static BankAccountInfosSelector newInstance() {
    return (BankAccountInfosSelector) SAS_Service_Application.Selector.newInstance(
      Bank_Account_Info__c.SObjectType
    );
  }

  public List<Bank_Account_Info__c> selectById(Set<Id> ids) {
    return (List<Bank_Account_Info__c>) selectSObjectsById(ids);
  }

  public List<Bank_Account_Info__c> selectByBankAccountNumber(
    Set<String> accountNumbers
  ) {
    return (List<Bank_Account_Info__c>) Database.query(
      newQueryFactory()
        .setCondition('Bank_Account_Number__c in :accountNumbers')
        .toSOQL()
    );
  }
}
