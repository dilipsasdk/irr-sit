public inherited sharing class ExchangeRatesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Exchange_Rate__c.Id,
      Exchange_Rate__c.Name,
      Exchange_Rate__c.CreatedDate,
      Exchange_Rate__c.LastModifiedDate,
      Exchange_Rate__c.From_Currency__c,
      Exchange_Rate__c.To_Currency__c,
      Exchange_Rate__c.Rate__c,
      Exchange_Rate__c.Date__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Exchange_Rate__c.SObjectType;
  }

  public static ExchangeRatesSelector newInstance() {
    return (ExchangeRatesSelector) SAS_Service_Application.Selector.newInstance(
      Exchange_Rate__c.SObjectType
    );
  }

  public List<Exchange_Rate__c> selectById(Set<Id> ids) {
    return (List<Exchange_Rate__c>) selectSObjectsById(ids);
  }

  public List<Exchange_Rate__c> selectAll() {
    return (List<Exchange_Rate__c>) Database.query(newQueryFactory().toSOQL());
  }

  public List<Exchange_Rate__c> selectByFromCurrency(String fromCurrency) {
    return (List<Exchange_Rate__c>) Database.query(
      newQueryFactory()
        .setCondition('From_Currency__c = :fromCurrency')
        .toSOQL()
    );
  }

  public List<ExchangeRate> selectByFromCurrency(
    Money.CurrencyCode fromCurrency
  ) {
    String fromCurrencyString = fromCurrency.name();
    List<Exchange_Rate__c> sObjects = (List<Exchange_Rate__c>) Database.query(
      newQueryFactory()
        .setCondition('From_Currency__c = :fromCurrencyString')
        .toSOQL()
    );

    List<ExchangeRate> toReturn = new List<ExchangeRate>();

    if (sObjects == null) {
      return toReturn;
    }

    for (Exchange_Rate__c er : sObjects) {
      toReturn.add(new ExchangeRate(er));
    }

    return toReturn;
  }

  public List<Exchange_Rate__c> selectByCurrencies(
    String fromCurrency,
    String toCurrency
  ) {
    return (List<Exchange_Rate__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'From_Currency__c = :fromCurrency AND To_Currency__c = :toCurrency'
        )
        .toSOQL()
    );
  }

  public List<Exchange_Rate__c> selectByToCurrency(String toCurrency) {
    return (List<Exchange_Rate__c>) Database.query(
      newQueryFactory().setCondition('To_Currency__c = :toCurrency').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
