public without sharing class ClaimExpense extends AbstractSObjectWrapper {
  public Claim_Expense__c underlyingSObject { get; private set; }

  public Decimal amount;
  public Id parentClaimId;
  public Decimal amountInSEK;
  public Money.CurrencyCode currencyOfAmount;
  public Type type;
  public Date dateOfExchangeCalculation;

  public override void updateSObjectFields() {
    this.underlyingSObject.Amount__c = this.amount;
    this.underlyingSObject.Claim__c = this.parentClaimId;
    this.underlyingSObject.Claim_Expense_Amount_In_SEK__c = this.amountInSEK;
    this.underlyingSObject.Currency__c = Money.CURRENCY_ENUM_TO_PICKLIST_VALUE.get(
      this.currencyOfAmount
    );
    this.underlyingSObject.Type__c = TYPE_ENUM_TO_PICKLIST_VALUE.get(this.type);
    this.underlyingSObject.Date_of_Exchange_Calculation__c = this.dateOfExchangeCalculation; // TODO: Fixme. Should this be set automatically?
  }
  @TestVisible
  private ClaimExpense() {
    this.underlyingSObject = new Claim_Expense__c();
  }

  public ClaimExpense(Claim parentClaim) {
    this();
    this.parentClaimId = parentClaim.id;
  }

  public ClaimExpense(Claim_Expense__c expense) {
    super(expense);
    this.underlyingSObject = expense;

    this.amount = expense.Amount__c;
    this.parentClaimId = expense.Claim__c;
    this.amountInSEK = expense.Claim_Expense_Amount_In_SEK__c;
    this.currencyOfAmount = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
      expense.Currency__c
    );
    this.type = TYPE_PICKLIST_VALUE_TO_ENUM.get(expense.Type__c);
    this.dateOfExchangeCalculation = expense.Date_of_Exchange_Calculation__c;
  }

  public enum Type {
    Accommodation,
    Food,
    Other,
    PhoneCalls,
    Transportation
  }

  private static final Map<String, Type> TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, Type>{
    'Accommodation' => Type.Accommodation,
    'Food' => Type.Food,
    'Other' => Type.Other,
    'Phone calls' => Type.PhoneCalls,
    'Transportation' => Type.Transportation
  };

  // TODO: Make private
  public static final Map<Type, String> TYPE_ENUM_TO_PICKLIST_VALUE = new Map<Type, String>{
    Type.Accommodation => 'Accommodation',
    Type.Food => 'Food',
    Type.Other => 'Other',
    Type.PhoneCalls => 'Phone calls',
    Type.Transportation => 'Transportation'
  };
}
