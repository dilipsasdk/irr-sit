public without sharing class ClaimExpenses extends ApplicationDomain {
  public ClaimExpenses(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Claim_Expense__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new ClaimExpenses(records);
    }
  }

  public static ClaimExpenses newInstance(List<Claim_Expense__c> sObjectList) {
    return (ClaimExpenses) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public override void onBeforeInsert() {
    updateAmountInSEK();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    updateAmountInSEK();
  }

  public List<Claim_Expense__c> instanceRecords;

  /**
   * Handles currency conversion calculation to SEK for the Claim_Expense_amount_in_SEK__c field.
   */
  public void updateAmountInSEK() {
    ExchangeRatesSelector exchangeRateSel = ExchangeRatesSelector.newInstance();
    Map<String, Exchange_Rate__c> exchangeRatesToSEK = new Map<String, Exchange_Rate__c>();

    for (Exchange_Rate__c er : exchangeRateSel.selectByToCurrency('SEK')) {
      exchangeRatesToSEK.put(er.From_Currency__c, er);
    }

    for (Claim_Expense__c claimExpense : instanceRecords) {
      if (claimExpense.Currency__c == 'SEK') {
        claimExpense.Claim_Expense_Amount_In_SEK__c = claimExpense.Amount__c;
        claimExpense.Date_of_Exchange_Calculation__c = Date.today();
      } else {
        Exchange_Rate__c exchangeRateToSEK = exchangeRatesToSEK.get(
          claimExpense.Currency__c
        );

        if (exchangeRateToSEK != null) {
          claimExpense.Claim_Expense_Amount_In_SEK__c =
            claimExpense.Amount__c * exchangeRateToSEK.Rate__c;
          claimExpense.Date_of_Exchange_Calculation__c = exchangeRateToSEK.Date__c;
        }
      }
    }
  }
}
