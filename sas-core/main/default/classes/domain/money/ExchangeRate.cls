public without sharing class ExchangeRate extends AbstractSObjectWrapper {
  public Exchange_Rate__c underlyingSObject { get; private set; }

  public Date dateOfExchangeCalculation;
  public Money.CurrencyCode fromCurrency;
  public Money.CurrencyCode toCurrency;
  public Decimal rate;

  public override void updateSObjectFields() {
    this.underlyingSObject.Date__c = this.dateOfExchangeCalculation;
    this.underlyingSObject.From_Currency__c = Money.CURRENCY_ENUM_TO_PICKLIST_VALUE.get(
      this.fromCurrency
    );
    this.underlyingSObject.Rate__c = this.rate;
    this.underlyingSObject.To_Currency__c = Money.CURRENCY_ENUM_TO_PICKLIST_VALUE.get(
      this.toCurrency
    );
  }

  private ExchangeRate() {
    this.underlyingSObject = new Exchange_Rate__c();
  }

  public ExchangeRate(Exchange_Rate__c er) {
    super(er);
    this.underlyingSObject = er;

    this.dateOfExchangeCalculation = er.Date__c;
    this.fromCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
      er.From_Currency__c
    );
    this.rate = er.Rate__c;
    this.toCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
      er.To_Currency__c
    );
  }

  public override String toString() {
    return '' +
      this.fromCurrency +
      '-' +
      this.toCurrency +
      ': ' +
      this.rate +
      ' (' +
      this.dateOfExchangeCalculation +
      ')';
  }
}
