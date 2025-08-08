public without sharing class SettlementsController {
  private static SettlementsSelector settlements = SettlementsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRates = ExchangeRatesSelector.newInstance();

  @AuraEnabled
  public static void addSettlementsItemsToSettlement(
    Id settlementId,
    List<Settlement_Item__c> settlementItems
  ) {
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlementId => settlementItems }
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<Settlement__c> getSettlement(String settlementId) {
    return settlements.selectByIdWithSettlementItems(
      new Set<Id>{ settlementId }
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<Exchange_Rate__c> getExchangeRates(
    String fromCurrency,
    String toCurrency
  ) {
    if (fromCurrency == null) {
      return new List<Exchange_Rate__c>();
    }
    if (toCurrency == null) {
      return exchangeRates.selectByFromCurrency(fromCurrency);
    }
    return exchangeRates.selectByCurrencies(fromCurrency, toCurrency);
  }

  @AuraEnabled(cacheable=true)
  public static List<Exchange_Rate__c> getAllExchangeRates() {
    return exchangeRates.selectAll();
  }

  @AuraEnabled(cacheable=true)
  public static List<Customer__c> getPassengers(String settlementId) {
    // TODO: Create proper selector for me.
    Settlement__c s = settlements.selectById(new Set<Id>{ settlementId })[0];
    return CustomersSelector.newInstance()
      .selectByClaimId(new Set<Id>{ s.Claim__c });
  }
}
