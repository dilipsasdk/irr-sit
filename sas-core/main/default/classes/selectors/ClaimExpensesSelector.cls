public inherited sharing class ClaimExpensesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Claim_Expense__c.Id,
      Claim_Expense__c.Name,
      Claim_Expense__c.CreatedDate,
      Claim_Expense__c.LastModifiedDate,
      Claim_Expense__c.Amount__c,
      Claim_Expense__c.Claim__c,
      Claim_Expense__c.Claim_Expense_Amount_In_SEK__c,
      Claim_Expense__c.Currency__c,
      Claim_Expense__c.Date_of_Exchange_Calculation__c,
      Claim_Expense__c.Type__c,
      Claim_Expense__c.Under_Expense_Limit__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Claim_Expense__c.SObjectType;
  }

  public static ClaimExpensesSelector newInstance() {
    return (ClaimExpensesSelector) SAS_Service_Application.Selector.newInstance(
      Claim_Expense__c.SObjectType
    );
  }

  public List<Claim_Expense__c> selectById(Set<Id> ids) {
    return (List<Claim_Expense__c>) selectSObjectsById(ids);
  }

  public List<Claim_Expense__c> selectByClaimId(Set<Id> claimIds) {
    return (List<Claim_Expense__c>) Database.query(
      newQueryFactory().setCondition('Claim__c IN :claimIds').toSOQL()
    );
  }
}
