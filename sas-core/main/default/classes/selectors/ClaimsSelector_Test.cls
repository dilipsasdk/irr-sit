/**
 * To run tests manually:
 * 1. Run the code within "setup()"
 * 2. To connect a proactivity with a claim you need a Segment and a CaseToBooking, these can be created like this:
 * ----------------------------
 * List<Booking__c> bookings = [SELECT Id, TEDS_Identifier__c FROM Booking__c WHERE TEDS_Identifier = ?];
 * List<Flight__c> lf = [SELECT Id, TEDS_Identifier__c FROM Flight__c WHERE TEDS_Identifier__c = ?];
 * List<Case> lc = [SELECT Id FROM Case WHERE CaseNumber = ?];
 * Id fid = lf[0].Id;
 * Id cid = lc[0].Id;
 * Id bid = bookings[0];
 * Segment__c s = new Segment__c(Booking__c = bid, Flight__c = fid);
 * CaseToBooking__c c = new CaseToBooking__c(Booking__c = bid, Case__c = cid);
 * insert new List<sObject>{s, c};
 * ----------------------------
 * Replace "?" with the identifiers for the Bookings, Flights and Cases you wish to connect.
 */
@IsTest
private class ClaimsSelector_Test {
  private static ClaimsSelector claims = ClaimsSelector.newInstance();

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
    ); // TODO: Change to real cancellation codes
    Proactivity__c airportMatcherAndCancellationCodeProactivity = new Proactivity__c(
      Note__c = 'Test 5',
      Type__c = 'Normal',
      Cancellation_Code__c = 'AIRS',
      Airport__c = 'ARN',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c directlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 6',
      Type__c = 'Normal'
    );

    insert directlyMatchedProactivity;

    Case caseWithOneProactivityRegularMatcher = new Case();
    Case caseWithTwoProactivitiesRegularMatcher = new Case();
    Case caseWithOneProactivityAirportMatcher = new Case();
    Case caseWithOneProactivityCancellationCodeMatcher = new Case();
    Case caseWithThreeProactivitiesCancellationCodeAndAirportMatcher = new Case();
    Case caseWithDirectMatch = new Case(
      Proactivity__c = directlyMatchedProactivity.Id
    );

    insert new List<Case>{
      caseWithOneProactivityRegularMatcher,
      caseWithTwoProactivitiesRegularMatcher,
      caseWithOneProactivityAirportMatcher,
      caseWithOneProactivityCancellationCodeMatcher,
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher,
      caseWithDirectMatch
    };

    LIA_Claim__c claimWithOneProactivityRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityRegularMatcher.Id,
      Phone_Number__c = '0000000000'
    );
    LIA_Claim__c claimWithTwoProactivitiesRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithTwoProactivitiesRegularMatcher.Id,
      Contact_Email__c = 'test@test.com',
      Phone_Number__c = '0000000000'
    );
    LIA_Claim__c claimWithOneProactivityAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityAirportMatcher.Id,
      Flight_Number__c = 'SK1',
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithOneProactivityCancellationCodeMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityCancellationCodeMatcher.Id,
      Flight_Number__c = 'SK2',
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithThreeProactivitesCancellationCodeAndAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Flight_Number__c = 'SK3',
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithDirectMatch = new LIA_Claim__c(
      Case__c = caseWithDirectMatch.Id,
      Phone_Number__c = '0000000001'
    );

    String flightIdentifier1 =
      Flight.constructTEDSFlightNumberDate('SK1', today) + '-UME-ARN';
    String flightIdentifier2 =
      Flight.constructTEDSFlightNumberDate('SK2', today) + '-ARN-UME';
    String flightIdentifier3 =
      Flight.constructTEDSFlightNumberDate('SK3', today) + '-UME-ARN';

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

    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier3
    );

    insert new List<Flight__c>{ flight1, flight2, flight3 };

    FlightIrregularities__c flightIrregularity1 = new FlightIrregularities__c(
      Flight__c = flight1.Id,
      Code__c = 'AUTH'
    );

    FlightIrregularities__c flightIrregularity2 = new FlightIrregularities__c(
      Flight__c = flight2.Id,
      Code__c = 'AIRS'
    );

    FlightIrregularities__c flightIrregularity3 = new FlightIrregularities__c(
      Flight__c = flight3.Id,
      Code__c = 'AIRS'
    );

    Booking__c bookingAirportMatcher = new Booking__c(
      TEDS_Identifier__c = 'ABC123'
    );
    Booking__c booking2CancellationCodeMatcher = new Booking__c(
      TEDS_Identifier__c = 'ABC321'
    );
    Booking__c booking2CancellationCodeAndAirportMatcher = new Booking__c(
      TEDS_Identifier__c = 'ABC000'
    );

    insert new List<Booking__c>{
      bookingAirportMatcher,
      booking2CancellationCodeMatcher,
      booking2CancellationCodeAndAirportMatcher
    };

    Segment__c segmentAirportMatcher = new Segment__c(
      Booking__c = bookingAirportMatcher.Id,
      Flight__c = flight1.Id
    );
    Segment__c segmentCancellationCodeMatcher = new Segment__c(
      Booking__c = booking2CancellationCodeMatcher.Id,
      Flight__c = flight2.Id
    );
    Segment__c segmentCancellationCodeAndAirportMatcher = new Segment__c(
      Booking__c = booking2CancellationCodeAndAirportMatcher.Id,
      Flight__c = flight3.Id
    );

    CaseToBooking__c ctbAirportMatcher = new CaseToBooking__c(
      Booking__c = bookingAirportMatcher.Id,
      Case__c = caseWithOneProactivityAirportMatcher.Id
    );

    CaseToBooking__c ctbCancellationCodeMatcher = new CaseToBooking__c(
      Booking__c = booking2CancellationCodeMatcher.Id,
      Case__c = caseWithOneProactivityCancellationCodeMatcher.Id
    );

    CaseToBooking__c ctbCancellationCodeAndAirportMatcher = new CaseToBooking__c(
      Booking__c = booking2CancellationCodeAndAirportMatcher.Id,
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id
    );

    insert new List<SObject>{
      segmentAirportMatcher,
      segmentCancellationCodeMatcher,
      segmentCancellationCodeAndAirportMatcher,
      ctbAirportMatcher,
      ctbCancellationCodeMatcher,
      ctbCancellationCodeAndAirportMatcher,
      normalProactivity,
      majorEventProactivity,
      airportMatcherProactivity,
      cancellationCodeProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithTwoProactivitiesRegularMatcher,
      claimWithOneProactivityAirportMatcher,
      claimWithOneProactivityCancellationCodeMatcher,
      claimWithThreeProactivitesCancellationCodeAndAirportMatcher,
      claimWithDirectMatch,
      airportMatcherAndCancellationCodeProactivity,
      flightIrregularity1,
      flightIrregularity2,
      flightIrregularity3
    };
  }

  @IsTest
  static void shouldSelectClaimWithNormalProactivity() {
    // Given (setup)
    Proactivity__c normalProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 1'
    ][0];
    LIA_Claim__c correctClaim = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Contact_Email__c = 'test@test.com'
    ][0];

    // When
    List<LIA_Claim__c> oneClaimNormalMatcher = claims.selectByProactivityId(
      normalProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneClaimNormalMatcher.size(),
      'Should select a single claim from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctClaim.Id,
      oneClaimNormalMatcher[0].Id,
      'Should select a single claim from proactivity ID correctly (wrong claim)'
    );
  }
  @IsTest
  static void shouldSelectClaimWithMajorEventProactivity() {
    // Given (setup)
    Proactivity__c majorEventProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 2'
    ][0];
    List<LIA_Claim__c> claimList = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Phone_Number__c = '0000000000'
    ];

    LIA_Claim__c correctClaim1 = claimList[0];
    LIA_Claim__c correctClaim2 = claimList[1];

    // When
    List<LIA_Claim__c> twoClaimsMajorEventMatcher = claims.selectByProactivityId(
      majorEventProactivity.ID
    );

    // Then
    Integer correctlyMatched = 0;
    for (LIA_Claim__c c : twoClaimsMajorEventMatcher) {
      if (c.id == correctClaim1.Id || c.id == correctClaim2.Id) {
        correctlyMatched += 1;
      }
    }

    System.assertEquals(
      2,
      twoClaimsMajorEventMatcher.size(),
      'Should select two proactivities from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Should select two proactivities from case ID correctly (wrong proactivity)'
    );
  }
  @IsTest
  static void shouldSelectClaimWithAirportMatcherProactivity() {
    // Given (setup)
    Proactivity__c airportProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    LIA_Claim__c correctClaim1 = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Flight_Number__c = 'SK0001'
    ][0];
    LIA_Claim__c correctClaim2 = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Flight_Number__c = 'SK0003'
    ][0];

    // When
    List<LIA_Claim__c> twoClaimsAirportMatcher = claims.selectByProactivityId(
      airportProactivity.ID
    );

    // Then
    Integer correctlyMatched = 0;
    for (LIA_Claim__c c : twoClaimsAirportMatcher) {
      if (c.id == correctClaim1.Id || c.id == correctClaim2.Id) {
        correctlyMatched += 1;
      }
    }

    System.assertEquals(
      2,
      twoClaimsAirportMatcher.size(),
      'Should select two proactivities with airport matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Should select two proactivities with airport matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectClaimWithCancellationCodeProactivity() {
    // Given (setup)
    Proactivity__c cancellationCodeProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 4'
    ][0];
    LIA_Claim__c correctClaim1 = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Flight_Number__c = 'SK0002'
    ][0];
    LIA_Claim__c correctClaim2 = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Flight_Number__c = 'SK0003'
    ][0];

    // When
    List<LIA_Claim__c> twoClaimsCancellationCodeMatcher = claims.selectByProactivityId(
      cancellationCodeProactivity.ID
    );

    // Then
    Integer correctlyMatched = 0;
    for (LIA_Claim__c c : twoClaimsCancellationCodeMatcher) {
      if (c.id == correctClaim1.Id || c.id == correctClaim2.Id) {
        correctlyMatched += 1;
      }
    }

    System.assertEquals(
      2,
      twoClaimsCancellationCodeMatcher.size(),
      'Should select two proactivities with cancellation code matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Should select two proactivities with cancellation code matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectClaimWithCancellationCodeAndAirportProactivity() {
    // Given (setup)
    Proactivity__c cancellationCodeAndAirportProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 5'
    ][0];
    LIA_Claim__c correctClaim = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Flight_Number__c = 'SK0003'
    ][0];

    // When
    List<LIA_Claim__c> oneClaimCancellationCodeAndAirportMatcher = claims.selectByProactivityId(
      cancellationCodeAndAirportProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneClaimCancellationCodeAndAirportMatcher.size(),
      'Should select a single claim from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctClaim.Id,
      oneClaimCancellationCodeAndAirportMatcher[0].Id,
      'Should select a single claim from proactivity ID correctly (wrong claim)'
    );
  }

  @IsTest
  static void shouldSelectClaimWithDirectMatch() {
    // Given (setup)
    Proactivity__c directMatchProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 6'
    ][0];
    LIA_Claim__c correctClaim = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Phone_Number__c = '0000000001'
    ][0];

    // When
    List<LIA_Claim__c> oneClaimDirectMatch = claims.selectByProactivityId(
      directMatchProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneClaimDirectMatch.size(),
      'Should select a single claim from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctClaim.Id,
      oneClaimDirectMatch[0].Id,
      'Should select a single claim from proactivity ID correctly (wrong claim)'
    );
  }
}
