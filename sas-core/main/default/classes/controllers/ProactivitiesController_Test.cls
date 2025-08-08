@IsTest
private class ProactivitiesController_Test {
  private static ProactivitiesSelector proactivites = ProactivitiesSelector.newInstance();

  @testSetup
  static void setup() {
    Date today = Date.today();

    Proactivity__c normalProactivity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Email__c = 'test@test.com'
    );
    Proactivity__c majorEventProactivity = new Proactivity__c(
      Note__c = 'Test 2',
      Type__c = 'Major Event',
      Email__c = 'test@test.com',
      Phone_Number__c = '0000000000'
    );
    Proactivity__c airportMatcherProactivity = new Proactivity__c(
      Note__c = 'Test 3',
      Type__c = 'Normal',
      Airport__c = 'ARN',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c cancellationCodeProactivity = new Proactivity__c(
      Note__c = 'Test 4',
      Type__c = 'Normal',
      Cancellation_Code__c = 'AIRS',
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c airportMatcherAndCancellationCodeProactivity = new Proactivity__c(
      Note__c = 'Test 4',
      Type__c = 'Normal',
      Cancellation_Code__c = 'AIRS',
      Airport__c = 'ARN',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today
    );

    Case caseWithOneProactivityRegularMatcher = new Case(
      FCS_EBNumber__c = '000000001'
    );
    Case caseWithTwoProactivitiesRegularMatcher = new Case(
      FCS_EBNumber__c = '000000002'
    );
    Case caseWithOneProactivityAirportMatcher = new Case(
      FCS_EBNumber__c = '000000003'
    );
    Case caseWithOneProactivityCancellationCodeMatcher = new Case(
      FCS_EBNumber__c = '000000004'
    );

    insert new List<Case>{
      caseWithOneProactivityRegularMatcher,
      caseWithTwoProactivitiesRegularMatcher,
      caseWithOneProactivityAirportMatcher,
      caseWithOneProactivityCancellationCodeMatcher
    };

    LIA_Claim__c claimWithOneProactivityRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityRegularMatcher.Id,
      Phone_Number__c = '0000000000'
    );
    LIA_Claim__c claimWithTwoProactivitiesRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithTwoProactivitiesRegularMatcher.Id,
      Contact_Email__c = 'test@test.com'
    );
    LIA_Claim__c claimWithOneProactivityAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityAirportMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK1'),
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithOneProactivityCancellationCodeMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityCancellationCodeMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK2'),
      Flight_Date__c = today
    );

    String flightIdentifier1 =
      Flight.constructTEDSFlightNumberDate('SK1', today) + '-ARN-UME';
    String flightIdentifier2 =
      Flight.constructTEDSFlightNumberDate('SK2', today) + '-UME-ARN';

    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier1
    );

    Flight__c flight2 = new Flight__c(
      Arrival_Airport__c = 'UME',
      Departure_Airport__c = 'ARN',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier2
    );

    insert new List<Flight__c>{ flight1, flight2 };

    FlightIrregularities__c flightIrregularity = new FlightIrregularities__c(
      Flight__c = flight2.Id,
      Code__c = 'AIRS'
    );

    insert new List<SObject>{
      flightIrregularity,
      normalProactivity,
      majorEventProactivity,
      airportMatcherProactivity,
      cancellationCodeProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithTwoProactivitiesRegularMatcher,
      claimWithOneProactivityAirportMatcher,
      claimWithOneProactivityCancellationCodeMatcher,
      airportMatcherAndCancellationCodeProactivity
    };
  }

  @IsTest
  static void shouldSelectNormalProactivityByCaseIdTest() {
    // Given (setup)
    Case caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000001'
    ][0];

    // When
    List<ProactivitiesController.Proactivity> proactivitiesWithMatchingReason = ProactivitiesController.getProactivitiesForRecord(
      String.valueOf(caseWithOneProactivityRegularMatcher.Id),
      String.valueOf('Case')
    );

    // Then
    System.assertEquals(
      1,
      proactivitiesWithMatchingReason.size(),
      'Incorrect amount of matches for proactivity/case match'
    );
    System.assertEquals(
      'Phone',
      proactivitiesWithMatchingReason[0].matchingReasons,
      'Incorrect matching reason(s) for proactivity/case match'
    );
  }

  @IsTest
  static void shouldSelectMajorEventProactivityByCaseIdTest() {
    // Given (setup)
    Case caseWithTwoProactivitiesRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000002'
    ][0];
    // When
    List<ProactivitiesController.Proactivity> proactivitiesWithMatchingReason = ProactivitiesController.getProactivitiesForRecord(
      String.valueOf(caseWithTwoProactivitiesRegularMatcher.Id),
      String.valueOf('Case')
    );

    // Then
    System.assertEquals(
      2,
      proactivitiesWithMatchingReason.size(),
      'Incorrect amount of matches for proactivity/case match'
    );
    System.assertEquals(
      'Email',
      proactivitiesWithMatchingReason[0].matchingReasons,
      'Incorrect matching reason(s) for proactivity/case match'
    );
  }

  @IsTest
  static void shouldSelectAirportMatcherProactivityByCaseIdTest() {
    // Given (setup)
    Case caseWithOneProactivityAirportMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000003'
    ][0];
    // When
    List<ProactivitiesController.Proactivity> proactivitiesWithMatchingReason = ProactivitiesController.getProactivitiesForRecord(
      String.valueOf(caseWithOneProactivityAirportMatcher.Id),
      String.valueOf('Case')
    );

    // Then
    System.assertEquals(
      1,
      proactivitiesWithMatchingReason.size(),
      'Incorrect amount of matches for proactivity/case match'
    );
    System.assertEquals(
      'SK0001: (Arrival airport)',
      proactivitiesWithMatchingReason[0].matchingReasons,
      'Incorrect matching reason(s) for proactivity/case match'
    );
  }

  @IsTest
  static void shouldSelectCancellationCodeProactivityByCaseIdTest() {
    // Given (setup)
    Case caseWithOneProactivityCancellationCodeMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000004'
    ][0];
    // When
    List<ProactivitiesController.Proactivity> proactivitiesWithMatchingReason = ProactivitiesController.getProactivitiesForRecord(
      String.valueOf(caseWithOneProactivityCancellationCodeMatcher.Id),
      String.valueOf('Case')
    );

    // Then
    System.assertEquals(
      1,
      proactivitiesWithMatchingReason.size(),
      'Incorrect amount of matches for proactivity/case match'
    );
    System.assertEquals(
      'SK0002: (Code "AIRS")',
      proactivitiesWithMatchingReason[0].matchingReasons,
      'Incorrect matching reason(s) for proactivity/case match'
    );
  }
}
