@IsTest
private class ProactivityService_Test {
  @IsTest
  public static void automationProactivitiesShouldBeCreated() {
    Flight__c f = new Flight__c(TEDS_Identifier__c = 'SK0001-20220817-ARN-UME');
    insert f;

    FlightIrregularities__c fi = new FlightIrregularities__c(
      Flight__c = f.Id,
      Code__c = 'DAMA',
      Reason__c = 'BIRDSTRIKE ON TAKEOFF FROM ARN'
    );
    insert fi;

    // Call the method being tested
    Test.startTest();
    ProactivityService.createAutomationProactivitiesFromFlightIds(
      new Set<Id>{ f.Id }
    );
    Test.stopTest();

    // Retrieve and verify the result
    List<Proactivity__c> proactiveRecords = [
      SELECT
        Id,
        Flight_Id__c,
        Note__c,
        Type__c,
        Automate_Matching_Claims__c,
        Eligibility_Explanation__c,
        EU261_Eligibility__c
      FROM Proactivity__c
    ];
    System.assertEquals(
      1,
      proactiveRecords.size(),
      'An incorrect number of Proactivity records were created'
    );
    Proactivity__c p = proactiveRecords[0];

    String flightId = Flight.TEDSIdToSimpleFlightIds(f.TEDS_Identifier__c)[0];

    System.assertEquals(flightId, p.Flight_Id__c, 'Incorrect flight id');
    System.assertEquals(
      'a bird strike on the aircraft assigned to your flight',
      p.Note__c,
      'Note should be "a bird strike on the aircraft assigned to your flight"'
    );
    System.assertEquals(
      'Automatically Created',
      p.Type__c,
      'Type should be "Automatically Created"'
    );
    System.assertEquals(
      false,
      p.Automate_Matching_Claims__c,
      'Automate Matching Claims should be true'
    );
    System.assertEquals(
      'a bird strike on the aircraft assigned to your flight',
      p.Eligibility_Explanation__c,
      'Eligibility explanation should be "a bird strike on the aircraft assigned to your flight"'
    );
    System.assertEquals(
      'No',
      p.EU261_Eligibility__c,
      'Should not be EU261 eligible'
    );
  }

  @IsTest
  public static void multiMatchIrregularityShouldNotGenerateAProactivity() {
    Flight__c f = new Flight__c(TEDS_Identifier__c = 'SK0001-20220817-ARN-UME');
    insert f;

    FlightIrregularities__c fi = new FlightIrregularities__c(
      Flight__c = f.Id,
      Code__c = 'DAMA',
      Reason__c = 'BIRDSTRIKE ON TAKEOFF DURING THUNDERSTORM'
    );
    insert fi;

    // Call the method being tested
    Test.startTest();
    ProactivityService.createAutomationProactivitiesFromFlightIds(
      new Set<Id>{ f.Id }
    );
    Test.stopTest();

    // Retrieve and verify the result
    List<Proactivity__c> proactiveRecords = [SELECT Id FROM Proactivity__c];
    System.assertEquals(
      0,
      proactiveRecords.size(),
      'No proactivity should have been created'
    );
  }
}
