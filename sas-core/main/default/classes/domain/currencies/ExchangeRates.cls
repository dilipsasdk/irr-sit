public without sharing class ExchangeRates extends ApplicationDomain {
  public ExchangeRates(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new ExchangeRates(records);
    }
  }

  public static ExchangeRates newInstance(List<Exchange_Rate__c> sObjectList) {
    return (ExchangeRates) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  private static ContentVersionsSelector contentVersionsSel = ContentVersionsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRatesSel = ExchangeRatesSelector.newInstance();

  public static final String CURRENCY_FILE_NAME = 'PRD_BSR_';
  public static final List<String> ACTIVE_CURRENCIES = new List<String>{
    'AUD',
    'AED',
    'CAD',
    'CHF',
    'CNY',
    'CZK',
    'DKK',
    'EUR',
    'GBP',
    'HKD',
    'JPY',
    'NOK',
    'NZD',
    'PLN',
    'SEK',
    'SGD',
    'THB',
    'USD'
  };

  //Units of USD in final XDR => USD calculation.
  public static final Decimal SPECIAL_DRAWING_RIGHTS_USD_UNITS = 0.58252;
  // Units of currency in each respective currency in the currency basket used for calculating the exchange rate of XDR => USD.
  // The number of units is set by the IMF according to the weight of each currency in the basket.
  public static final Map<String, Decimal> currencyToUnitsOfCurrency = new Map<String, Decimal>{
    'EUR' => 0.38671,
    'CNY' => 1.0174,
    'JPY' => 11.900,
    'GBP' => 0.085946
  };

  public static void handleCurrencyFiles(List<Id> contentVersionIds) {
    if (contentVersionIds.size() == 0) {
      return;
    }
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Map<String, Exchange_Rate__c> newRates = generateExchangeRatesFromFile(
      contentVersionIds,
      uow
    );
    generateXdrExchangeRates(newRates, uow);
    uow.commitWork();
  }

  private static Map<String, Exchange_Rate__c> generateExchangeRatesFromFile(
    List<Id> contentVersionIds,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<ContentVersion> cvs = contentVersionsSel.selectById(
      new Set<Id>(contentVersionIds),
      true
    );

    Map<String, Exchange_Rate__c> existingRatesByName = new Map<String, Exchange_Rate__c>();

    List<Exchange_Rate__c> allRates = exchangeRatesSel.selectAll();
    for (Exchange_Rate__c rate : allRates) {
      existingRatesByName.put(rate.Name, rate);
    }

    for (ContentVersion cv : cvs) {
      String fileContents = cv.VersionData.toString();
      List<String> lines = fileContents.split('\n');

      for (String line : lines) {
        // Line format: SEK,EUR,0.09709,2022-01-19
        List<String> dataFields = line.split(',');
        if (
          ACTIVE_CURRENCIES.contains(dataFields[0]) &&
          ACTIVE_CURRENCIES.contains(dataFields[1])
        ) {
          Exchange_Rate__c e = existingRatesByName.get(
            dataFields[0] +
            '-' +
            dataFields[1]
          );
          if (e == null) {
            Exchange_Rate__c newRate = new Exchange_Rate__c(
              From_Currency__c = dataFields[0],
              To_Currency__c = dataFields[1],
              Rate__c = Decimal.valueOf(dataFields[2]),
              Date__c = Date.valueOf(dataFields[3]),
              Name = dataFields[0] + '-' + dataFields[1]
            );
            existingRatesByName.put(newRate.Name, newRate);
            uow.registerNew(newRate);
          } else {
            e.Rate__c = Decimal.valueOf(dataFields[2]);
            e.Date__c = Date.valueOf(dataFields[3]);
            uow.registerDirty(e);
          }
        }
      }
    }
    return existingRatesByName;
  }

  /*
   * Calculate exchange rate for XDR => Other currency
   * Rate equals 1 XDR in USD expressed in other currency
   */
  private static void generateXdrExchangeRates(
    Map<String, Exchange_Rate__c> allRatesByName,
    fflib_ISObjectUnitOfWork uow
  ) {
    Decimal newRate = 0;
    Decimal oneXdrInUsd = calculateOneXdrInUsd(allRatesByName);
    Date dateOfGeneration = allRatesByName.size() > 0
      ? allRatesByName.values()[0].Date__c
      : Date.today();

    //Update XDR => Currency rate
    //No need to convert the SDR amount if currency is USD
    //Convert SDR amount to active currency for non-USD currencies
    for (String activeCurrency : ACTIVE_CURRENCIES) {
      if (activeCurrency == 'USD') {
        newRate = oneXdrInUsd;
      } else {
        Exchange_Rate__c usdToActiveCurrencyRate = allRatesByName.get(
          'USD-' + activeCurrency
        );
        if (usdToActiveCurrencyRate != null) {
          newRate = oneXdrInUsd * usdToActiveCurrencyRate.Rate__c;
        }
      }

      Exchange_Rate__c existingXdrRate = allRatesByName.get(
        'XDR-' + activeCurrency
      );
      if (existingXdrRate == null) {
        Exchange_Rate__c newXdrRate = new Exchange_Rate__c(
          From_Currency__c = 'XDR',
          To_Currency__c = activeCurrency,
          Rate__c = newRate,
          Date__c = dateOfGeneration,
          Name = 'XDR-' + activeCurrency
        );
        uow.registerNew(newXdrRate);
      } else {
        existingXdrRate.Rate__c = newRate;
        existingXdrRate.Date__c = dateOfGeneration;
        uow.registerDirty(existingXdrRate);
      }
    }
  }

  private static Decimal calculateOneXdrInUsd(
    Map<String, Exchange_Rate__c> allRatesByName
  ) {
    // The exchange rate for XDR => USD  is set as the sum of the units of currency for each currency in the XDR basket expressed in USD.
    // 1 XDR = [calculated sum] USD
    Decimal oneXdrInUsd = SPECIAL_DRAWING_RIGHTS_USD_UNITS;

    for (String basketCurrency : currencyToUnitsOfCurrency.keySet()) {
      Exchange_Rate__c basketCurrencyToUsd = allRatesByName.get(
        basketCurrency + '-USD'
      );
      if (basketCurrencyToUsd != null) {
        oneXdrInUsd +=
          currencyToUnitsOfCurrency.get(basketCurrency) *
          basketCurrencyToUsd.Rate__c;
      }
    }
    //Round to six decimal places
    return oneXdrInUsd.setScale(6);
  }
}
