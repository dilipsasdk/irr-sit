@IsTest
public with sharing class TestAirportFixture {
  public static final Map<String, Airport> codeToAirport = new Map<String, Airport>{
    'HEL' => new Airport(
      new Airport__c(
        City__c = 'Helsinki',
        Country_Code__c = 'FI',
        Country_Name__c = 'Finland',
        TEDS_Identifier__c = 'HEL',
        Is_EU261_Applicable__c = true,
        Latitude__c = 60.317199707031,
        Longitude__c = 24.963300704956
      )
    ),
    'ARN' => new Airport(
      new Airport__c(
        City__c = 'Stockholm',
        Country_Code__c = 'SE',
        Country_Name__c = 'Sweden',
        TEDS_Identifier__c = 'ARN',
        Is_EU261_Applicable__c = true,
        Latitude__c = 59.651901245117,
        Longitude__c = 17.918600082397
      )
    ),
    'CPH' => new Airport(
      new Airport__c(
        City__c = 'Copenhagen',
        Country_Code__c = 'DK',
        Country_Name__c = 'Denmark',
        TEDS_Identifier__c = 'CPH',
        Is_EU261_Applicable__c = true,
        Latitude__c = 55.617900848389,
        Longitude__c = 12.656000137329
      )
    ),
    'JFK' => new Airport(
      new Airport__c(
        City__c = 'New York',
        Country_Code__c = 'US',
        Country_Name__c = 'United States',
        TEDS_Identifier__c = 'JFK',
        Is_EU261_Applicable__c = false,
        Latitude__c = 40.639801,
        Longitude__c = -73.7789
      )
    ),
    'LAX' => new Airport(
      new Airport__c(
        City__c = 'Los Angeles',
        Country_Code__c = 'US',
        Country_Name__c = 'United States',
        TEDS_Identifier__c = 'LAX',
        Is_EU261_Applicable__c = false,
        Latitude__c = 33.942501,
        Longitude__c = -118.407997
      )
    )
  };
}
