@IsTest
public with sharing class ExchangeRates_IntegrationTest {
  @IsTest
  public static void insertingExchangeRateFileShouldUpdateRates() {
    // Given
    String exchangeRatesFileName = 'PRD_BSR_20220119';
    String exchangeRatesFileContents =
      'SEK,EUR,0.09709,2022-05-03\n' +
      'DKK,USD,0.153329,2022-05-03\n' +
      'EUR,USD,1.05406,2022-05-03\n' +
      'GBP,USD,1.256953,2022-05-03\n' +
      'CNY,USD,0.151271,2022-05-03\n' +
      'JPY,USD,0.0077,2022-05-03\n' +
      'USD,AED,3.672595,2022-05-03\n' +
      'USD,AUD,1.415336,2022-05-03\n' +
      'USD,CHF,0.973054,2022-05-03\n' +
      'USD,CAD,1.285425,2022-05-03\n' +
      'USD,CNY,6.606373,2022-05-03\n' +
      'USD,CZK,23.32688,2022-05-03\n' +
      'USD,DKK,7.051192,2022-05-03\n' +
      'USD,EUR,0.94788,2022-05-03\n' +
      'USD,GBP,0.794683,2022-05-03\n' +
      'USD,HKD,7.846337,2022-05-03\n' +
      'USD,JPY,129.785853,2022-05-03\n' +
      'USD,NOK,9.371983,2022-05-03\n' +
      'USD,NZD,1.548134,2022-05-03\n' +
      'USD,PLN,4.425386,2022-05-03\n' +
      'USD,SEK,9.814698,2022-05-03\n' +
      'USD,SGD,1.382824,2022-05-03\n' +
      'USD,THB,34.221964,2022-05-03';

    Exchange_Rate__c existingDkkUsd = new Exchange_Rate__c(
      From_Currency__c = 'DKK',
      To_Currency__c = 'USD',
      Rate__c = 1.24,
      Date__c = Date.valueOf('2022-01-18'),
      Name = 'DKK-USD'
    );
    insert existingDkkUsd;
    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = exchangeRatesFileName + '.csv',
      Title = exchangeRatesFileName,
      VersionData = Blob.valueOf(exchangeRatesFileContents)
    );

    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    List<Exchange_Rate__c> ratesAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
    ];

    Exchange_Rate__c sekEurAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
      WHERE Name = 'SEK-EUR'
    ][0];
    Exchange_Rate__c dkkUsdAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
      WHERE Name = 'DKK-USD'
    ][0];

    Exchange_Rate__c xdrUsdAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
      WHERE Name = 'XDR-USD'
    ][0];

    System.assertEquals(
      41,
      ratesAfterInsert.size(),
      'Only relevant rates should have been inserted.'
    );
    System.assertEquals(
      0.09709,
      sekEurAfterInsert.Rate__c,
      'New rate should have been inserted correctly.'
    );
    System.assertEquals(
      0.153329,
      dkkUsdAfterInsert.Rate__c,
      'Existing rate should have been updated.'
    );
    System.assertEquals(
      1.343699,
      xdrUsdAfterInsert.Rate__c,
      'Existing rate should have been updated.'
    );
  }
}
