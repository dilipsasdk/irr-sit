// Todo: move to test folder
@IsTest
public with sharing class AirportService_IntegrationTest {
  public static String airportIdFromTEDS = 'ARN';
  public static String specialTerriroryAirportIdFromTEDS = 'RUN';
  public static Set<String> airportIdsFromTEDS = new Set<String>{
    'ARN',
    'HEL'
  };
  public static String cityInDetailedAirportInfo = 'Stockholm';

  @IsTest
  public static void shouldFetchAirportsByAirportId() {
    // Given
    Set<String> airportIds = new Set<String>();
    airportIds.add(airportIdFromTEDS);
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    AirportService.newInstance().fetchAirportsByReference(airportIds, true);
    Test.stopTest();

    // Then
    Airport__c airportFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(new Set<String>{ airportIdFromTEDS })[0];

    System.assertEquals(
      'Stockholm-Arlanda Airport',
      airportFromDB.Name,
      'Airport should exist and have the correct name.'
    );
    System.assertEquals(
      cityInDetailedAirportInfo,
      airportFromDB.City__c,
      'Airport should exist and have the correct city.'
    );

    System.assertEquals(
      'SE',
      airportFromDB.Country_Code__c,
      'Airport should exist and have the correct country code.'
    );
    System.assertEquals(
      'Sweden',
      airportFromDB.Country_Name__c,
      'Airport should exist and have the correct country name.'
    );
    System.assertEquals(
      59.651901245117,
      airportFromDB.Latitude__c,
      'Airport should exist and have the correct latitude.'
    );
    System.assertEquals(
      17.918600082397,
      airportFromDB.Longitude__c,
      'Airport should exist and have the correct longitude.'
    );
    System.assertEquals(
      'ARN',
      airportFromDB.TEDS_Identifier__c,
      'Airport should exist and have the correct TEDS Identifier.'
    );
  }

  @IsTest
  public static void shouldBatchFetchAirportsByAirportId() {
    // Given
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    AirportService.newInstance()
      .fetchAirportsByReference(airportIdsFromTEDS, true);
    Test.stopTest();

    // Then
    List<Airport__c> airportsFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(airportIdsFromTEDS);

    List<String> correctAirportIdentifiers = new List<String>{ 'ARN', 'HEL' };
    List<String> airportIdentifiers = new List<String>{};
    for (Airport__c a : airportsFromDB) {
      airportIdentifiers.add(a.TEDS_Identifier__c);
    }

    airportIdentifiers.sort();
    for (Integer i = 0; i < airportsFromDB.size(); i++) {
      System.assertEquals(
        airportIdentifiers[i],
        correctAirportIdentifiers[i],
        'Should fetch and insert all airports.'
      );
    }

    System.assertEquals(
      2,
      airportsFromDB.size(),
      'Should fetch and insert the correct amount of airports.'
    );
  }

  @IsTest
  public static void shouldFetchSpecialTerritoryAirportsByAirportId() {
    // Given
    Set<String> airportIds = new Set<String>();
    airportIds.add(specialTerriroryAirportIdFromTEDS);
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    AirportService.newInstance().fetchAirportsByReference(airportIds, true);
    Test.stopTest();

    // Then
    Airport__c airportFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(new Set<String>{ specialTerriroryAirportIdFromTEDS })[0];

    System.assertEquals(
      'Roland Garros Airport',
      airportFromDB.Name,
      'Special territory airport should exist and have the right name.'
    );
  }
}
