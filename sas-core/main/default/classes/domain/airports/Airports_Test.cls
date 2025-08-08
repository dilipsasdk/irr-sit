// Todo: Move to Airports
@IsTest
private class Airports_Test {
  public static Set<String> airportIdsFromTEDS = new Set<String>{
    'ARN',
    'HEL',
    'ITM',
    'RUN',
    'SYD'
  };

  @isTest
  static void shouldCalculateDistanceBetweenAirports() {
    // Given
    Test.setMock(HttpCalloutMock.class, new APIMMock()); // Needed for TEDSbooking-fetches caused by trigger

    // When
    Test.startTest();
    AirportService.newInstance()
      .fetchAirportsByReference(airportIdsFromTEDS, true);
    Test.stopTest();

    // Then
    List<Airport__c> airportsFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(airportIdsFromTEDS);

      Airport ARN;
    for (Airport__c a : airportsFromDB) {
      if (a.TEDS_Identifier__c == 'ARN') {
        ARN = new Airport(a);
        break;
      }
    }

    for (Airport__c a : airportsFromDB) {
      switch on a.TEDS_Identifier__c {
        when 'HEL' {
          System.assertEquals(
            398569,
            Airport.distanceBetweenAirportsInMeters(ARN, new Airport(a)),
            'Should calculate the distance between ARN and HEL correctly.'
          );
        }
        when 'ITM' {
          System.assertEquals(
            8062362,
            Airport.distanceBetweenAirportsInMeters(ARN, new Airport(a)),
            'Should calculate the distance between ARN and ITM correctly.'
          );
        }
        when 'RUN' {
          System.assertEquals(
            9584413,
            Airport.distanceBetweenAirportsInMeters(ARN, new Airport(a)),
            'Should calculate the distance between RUN and ARN correctly.'
          );
        }
        when 'SYD' {
          System.assertEquals(
            15597941,
            Airport.distanceBetweenAirportsInMeters(ARN, new Airport(a)),
            'Should calculate the distance between SYD and ARN correctly.'
          );
        }
      }
    }
  }
}
