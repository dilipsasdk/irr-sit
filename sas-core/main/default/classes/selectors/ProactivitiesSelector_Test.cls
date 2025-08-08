@IsTest
private class ProactivitiesSelector_Test {
  private static ProactivitiesSelector proactivites = ProactivitiesSelector.newInstance();
  private static Date today = Date.today();
  private static String flightIdentifier1 =
    Flight.constructTEDSFlightNumberDate('SK1', today) + '-UME-ARN';
  private static String flightIdentifier2 =
    Flight.constructTEDSFlightNumberDate('SK2', today) + '-ARN-UME';
  private static String flightIdentifier3 =
    Flight.constructTEDSFlightNumberDate('SK3', today) + '-UME-ARN';
  private static String flightIdentifier4 =
    Flight.constructTEDSFlightNumberDate('SK4', today) + '-UME-ARN';
  private static String flightIdentifier5 =
    Flight.constructTEDSFlightNumberDate('SK5', today) + '-LAX-CPH';
  private static String flightIdentifier6 =
    Flight.constructTEDSFlightNumberDate('SK6', today) + '-LAX-CPH';

  @testSetup
  static void setup() {
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
    Proactivity__c strikeCodeProactivity = new Proactivity__c(
      Note__c = 'Test 7',
      Type__c = 'Normal',
      Cancellation_Code__c = 'INDU',
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c flightIdProactivity1 = new Proactivity__c(
      Note__c = 'Test 8',
      Type__c = 'Normal',
      Flight_Id__c = 'SK0005-' + StringUtils.dateToTEDSString(today)
    );
    Proactivity__c flightIdProactivity2 = new Proactivity__c(
      Note__c = 'Test 9',
      Type__c = 'Normal',
      Flight_Id__c = 'SK0006-' + StringUtils.dateToTEDSString(today)
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
    Case caseWithThreeProactivitiesCancellationCodeAndAirportMatcher = new Case(
      FCS_EBNumber__c = '000000005'
    );
    Case caseWithNoRelevantClaimFlight = new Case(
      FCS_EBNumber__c = '000000007'
    );
    Case caseWithNoSpecificFlightId1 = new Case(FCS_EBNumber__c = '000000008');
    Case caseWithNoSpecificFlightId2 = new Case(FCS_EBNumber__c = '000000009');

    insert new List<SObject>{
      caseWithOneProactivityRegularMatcher,
      caseWithTwoProactivitiesRegularMatcher,
      caseWithOneProactivityAirportMatcher,
      caseWithOneProactivityCancellationCodeMatcher,
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher,
      caseWithNoRelevantClaimFlight,
      directlyMatchedProactivity,
      caseWithNoSpecificFlightId1,
      caseWithNoSpecificFlightId2
    };

    Case caseWithDirectMatch = new Case(
      FCS_EBNumber__c = '000000006',
      Proactivity__c = directlyMatchedProactivity.Id
    );

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

    LIA_Claim__c claimWithThreeProactivitesCancellationCodeAndAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK3'),
      Liability_PNR__c = 'ABC123',
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithNoIrrelevantClaimFlight = new LIA_Claim__c(
      Case__c = caseWithNoRelevantClaimFlight.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK8'),
      Liability_PNR__c = 'ABC124',
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithFlightId1 = new LIA_Claim__c(
      Case__c = caseWithNoSpecificFlightId1.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK5'),
      Liability_PNR__c = 'ABC125',
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithFlightId2 = new LIA_Claim__c(
      Case__c = caseWithNoSpecificFlightId2.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK6'),
      Liability_PNR__c = 'ABC126',
      Flight_Date__c = today
    );

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

    Flight__c flight4 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier4
    );

    Flight__c flight5 = new Flight__c(
      Arrival_Airport__c = 'CPH',
      Departure_Airport__c = 'LAX',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier5
    );

    Flight__c flight6 = new Flight__c(
      Arrival_Airport__c = 'CPH',
      Departure_Airport__c = 'LAX',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier6
    );

    Booking__c flight3Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC123',
      Booking_Reference__c = 'ABC123'
    );
    Booking__c flight4Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC124',
      Booking_Reference__c = 'ABC124'
    );

    Booking__c flight5Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC125',
      Booking_Reference__c = 'ABC125'
    );
    Booking__c flight6Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC126',
      Booking_Reference__c = 'ABC126'
    );

    insert new List<SObject>{
      flight1,
      flight2,
      flight3,
      flight4,
      flight5,
      flight6,
      flight3Booking,
      flight4Booking,
      flight5Booking,
      flight6Booking
    };

    CaseToBooking__c ctb1 = new CaseToBooking__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Booking__c = flight3Booking.Id
    );
    CaseToBooking__c ctb2 = new CaseToBooking__c(
      Case__c = caseWithNoRelevantClaimFlight.Id,
      Booking__c = flight4Booking.Id
    );
    CaseToBooking__c ctb3 = new CaseToBooking__c(
      Case__c = caseWithNoSpecificFlightId1.Id,
      Booking__c = flight5Booking.Id
    );
    CaseToBooking__c ctb4 = new CaseToBooking__c(
      Case__c = caseWithNoSpecificFlightId2.Id,
      Booking__c = flight6Booking.Id
    );
    Segment__c seg1 = new Segment__c(
      Booking__c = flight3Booking.Id,
      Flight__c = flight3.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = flight4Booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg3 = new Segment__c(
      Booking__c = flight4Booking.Id,
      Flight__c = flight4.Id
    );
    Segment__c seg4 = new Segment__c(
      Booking__c = flight5Booking.Id,
      Flight__c = flight5.Id
    );
    Segment__c seg5 = new Segment__c(
      Booking__c = flight6Booking.Id,
      Flight__c = flight6.Id
    );

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

    FlightIrregularities__c flightIrregularity4 = new FlightIrregularities__c(
      Flight__c = flight4.Id,
      Code__c = 'INDU'
    );

    insert new List<SObject>{
      ctb1,
      ctb2,
      seg1,
      seg2,
      seg3,
      ctb3,
      ctb4,
      seg4,
      seg5,
      flightIrregularity1,
      flightIrregularity2,
      flightIrregularity3,
      flightIrregularity4,
      normalProactivity,
      majorEventProactivity,
      airportMatcherProactivity,
      cancellationCodeProactivity,
      airportMatcherAndCancellationCodeProactivity,
      strikeCodeProactivity,
      flightIdProactivity1,
      flightIdProactivity2,
      claimWithOneProactivityRegularMatcher,
      claimWithTwoProactivitiesRegularMatcher,
      claimWithOneProactivityAirportMatcher,
      claimWithOneProactivityCancellationCodeMatcher,
      claimWithThreeProactivitesCancellationCodeAndAirportMatcher,
      claimWithNoIrrelevantClaimFlight,
      claimWithFlightId1,
      claimWithFlightId2,
      caseWithDirectMatch
    };
  }

  @IsTest
  static void shouldSelectNormalProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 2'
    ][0];
    Case caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000001'
    ][0];

    // When
    List<Proactivity__c> oneProactivityRegularMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityRegularMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityRegularMatcher.size(),
      'Should select a single proactivity from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityRegularMatcher[0].Id,
      'Should select a single proactivity from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectMultipleNormalProactivityByClaimTest() {
    // Given (setup)
    List<String> notes = new List<String>{ 'Test 1', 'Test 2', 'Test 3' };
    List<Proactivity__c> correctProactivities = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c IN :notes
    ];
    List<Case> caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c IN ('000000001', '000000002', '000000003')
    ];
    Set<Id> caseIds = new Set<Id>();
    for (Case c : caseWithOneProactivityRegularMatcher) {
      caseIds.add(c.Id);
    }

    List<LIA_Claim__c> claimsWithProactivities = ClaimsSelector.newInstance()
      .selectByCaseIdWithCustomers(caseIds);

    // When
    Set<Proactivity__c> multipleProactivitiesRegularMatcher = proactivites.selectProactivitiesByClaimsWithMatchingReasons(
        claimsWithProactivities
      )
      .proactivityToReason.keySet();

    // Then
    System.assertEquals(
      3,
      multipleProactivitiesRegularMatcher.size(),
      'Should select a single proactivity from case ID correctly (too many/few matches)'
    );

    for (Proactivity__c p : multipleProactivitiesRegularMatcher) {
      System.assert(
        notes.contains(p.Note__c),
        'Should select the correct proactivities from case ID correctly (wrong proactivity)'
      );
    }
  }

  @IsTest
  static void shouldSelectAllProactivitiesByClaimTest() {
    // Given (setup)
    List<String> notes = new List<String>{
      'Test 1',
      'Test 2',
      'Test 3',
      'Test 4',
      'Test 5',
      'Test 7'
    };

    List<Proactivity__c> correctProactivities = [
      SELECT Id, Note__c
      FROM Proactivity__c
      WHERE Note__c IN :notes
    ];
    List<Case> caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE
        FCS_EBNumber__c IN (
          '000000001',
          '000000002',
          '000000003',
          '000000004',
          '000000005',
          '000000007'
        )
    ];
    Set<Id> caseIds = new Set<Id>();
    for (Case c : caseWithOneProactivityRegularMatcher) {
      caseIds.add(c.Id);
    }

    List<LIA_Claim__c> claimsWithProactivities = ClaimsSelector.newInstance()
      .selectByCaseIdWithCustomers(caseIds);

    List<String> flight1ProactivityNotes = new List<String>{ 'Test 3' };
    List<String> flight2ProactivityNotes = new List<String>{ 'Test 4' };
    List<String> flight3ProactivityNotes = new List<String>{
      'Test 5',
      'Test 4',
      'Test 3'
    };
    List<String> flight4ProactivityNotes = new List<String>{
      'Test 7',
      'Test 3'
    };

    Map<Id, List<String>> flightIdToCorrectProactivityNotes = new Map<Id, List<String>>{};

    List<Flight__c> flights = [SELECT Id, TEDS_Identifier__c FROM Flight__c];
    for (Flight__c f : flights) {
      List<Proactivity__c> flightProactivities = new List<Proactivity__c>{};
      for (Proactivity__c p : correctProactivities) {
        if (f.TEDS_Identifier__c == flightIdentifier1) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight1ProactivityNotes);
        } else if (f.TEDS_Identifier__c == flightIdentifier2) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight2ProactivityNotes);
        } else if (f.TEDS_Identifier__c == flightIdentifier3) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight3ProactivityNotes);
        } else if (f.TEDS_Identifier__c == flightIdentifier4) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight4ProactivityNotes);
        }
      }
    }

    // When
    ProactivitiesSelector.ProactivityQueryResult result = proactivites.selectProactivitiesByClaimsWithMatchingReasons(
      claimsWithProactivities
    );
    Set<Proactivity__c> multipleProactivitiesRegularMatcher = result.proactivityToReason.keySet();

    // Then
    System.assertEquals(
      6,
      multipleProactivitiesRegularMatcher.size(),
      'Should select a single proactivity from case ID correctly (too many/few matches)'
    );

    for (Proactivity__c p : multipleProactivitiesRegularMatcher) {
      System.assert(
        notes.contains(p.Note__c),
        'Should select the correct proactivities from case ID correctly (wrong proactivity)'
      );
    }

    for (Id flightId : result.flightIdToProactivities.keySet()) {
      Set<Proactivity__c> proactivities = result.flightIdToProactivities.get(
        flightId
      );
      List<String> correctProactivityNotesToCompare = flightIdToCorrectProactivityNotes.get(
        flightId
      );

      System.assertEquals(
        correctProactivityNotesToCompare.size(),
        proactivities.size(),
        'Should select the correct proactivities from case ID correctly (wrong number of proactivities)'
      );

      // Make sure the list of proactivities is the same list as the one we expect
      for (Proactivity__c p : proactivities) {
        System.assert(
          correctProactivityNotesToCompare.contains(p.Note__c),
          'Should select the correct proactivities from case ID correctly (wrong proactivity)'
        );
      }
    }
  }

  @IsTest
  static void shouldSelectMajorEventProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity1 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 1'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 2'
    ][0];
    Case caseWithTwoProactivitiesRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000002'
    ][0];
    // When
    List<Proactivity__c> twoProactivitiesRegularMatcher = proactivites.selectByCaseId(
      caseWithTwoProactivitiesRegularMatcher.Id
    );

    // Then
    Integer correctlyMatched = 0;
    for (Proactivity__c p : twoProactivitiesRegularMatcher) {
      if (p.id == correctProactivity1.Id || p.id == correctProactivity2.Id) {
        correctlyMatched += 1;
      }
    }

    System.assertEquals(
      2,
      twoProactivitiesRegularMatcher.size(),
      'Should select two proactivities from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Should select two proactivities from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectAirportMatcherProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Case caseWithOneProactivityAirportMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000003'
    ][0];
    // When
    List<Proactivity__c> oneProactivityAirportMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityAirportMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityAirportMatcher.size(),
      'Should select a single proactivity with an airport matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityAirportMatcher[0].Id,
      'Should select a single proactivity with an airport matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectCancellationCodeProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 4'
    ][0];
    Case caseWithOneProactivityCancellationCodeMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000004'
    ][0];
    // When
    List<Proactivity__c> oneProactivityCancellationCodeMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityCancellationCodeMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityCancellationCodeMatcher.size(),
      'Should select a single proactivity with a cancellation code matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityCancellationCodeMatcher[0].Id,
      'Should select a single proactivity with a cancellation code matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectCancellationCodeAndAirportProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity1 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 4'
    ][0];
    Proactivity__c correctProactivity3 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 5'
    ][0];
    Case caseWithThreeProactivitiesCancellationCodeAndAirportMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000005'
    ][0];
    // When
    List<Proactivity__c> threeProactivitiesCancellationCodeAndAirportMatcher = proactivites.selectByCaseId(
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id
    );

    Integer correctlyMatched = 0;
    for (
      Proactivity__c p : threeProactivitiesCancellationCodeAndAirportMatcher
    ) {
      if (
        p.id == correctProactivity1.Id ||
        p.id == correctProactivity2.Id ||
        p.id == correctProactivity3.Id
      ) {
        correctlyMatched += 1;
      }
    }
    // Then
    System.assertEquals(
      3,
      correctlyMatched,
      'Should select three proactivities with a cancellation code and airport matcher from case ID correctly (too many/few matches)'
    );
  }

  @IsTest
  static void shouldSelectDirectlyLinkedProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 6'
    ][0];
    Case caseWithDirectMatch = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000006'
    ][0];

    // When
    List<Proactivity__c> directMatchProactivity = proactivites.selectByCaseId(
      caseWithDirectMatch.Id
    );

    // Then
    System.assertEquals(
      1,
      directMatchProactivity.size(),
      'Should select a single proactivity with a direct match from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      directMatchProactivity[0].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectNonClaimFlightProactivites() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 7'
    ][0];
    Case caseWithIrrelevantClaimFlight = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000007'
    ][0];

    // When
    List<Proactivity__c> nonClaimFlightProactiviies = proactivites.selectByCaseId(
      caseWithIrrelevantClaimFlight.Id
    );

    for (Proactivity__c p : nonClaimFlightProactiviies) {
      Proactivity__c pasdf = p;
    }

    // Then
    System.assertEquals(
      2,
      nonClaimFlightProactiviies.size(),
      'Should select a single proactivity with a direct match from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      nonClaimFlightProactiviies[0].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
    System.assertEquals(
      correctProactivity2.Id,
      nonClaimFlightProactiviies[1].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldMatchFlightAndProactivityBasedOnFlightId() {
    // Given (setup)
    List<String> notes = new List<String>{ 'Test 8', 'Test 9' };

    List<Proactivity__c> correctProactivities = [
      SELECT Id, Note__c
      FROM Proactivity__c
      WHERE Note__c IN :notes
    ];
    List<Case> caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c IN ('000000008', '000000009')
    ];
    Set<Id> caseIds = new Set<Id>();
    for (Case c : caseWithOneProactivityRegularMatcher) {
      caseIds.add(c.Id);
    }

    List<LIA_Claim__c> claimsWithProactivities = ClaimsSelector.newInstance()
      .selectByCaseIdWithCustomers(caseIds);

    List<String> flight1ProactivityNotes = new List<String>{ 'Test 8' };
    List<String> flight2ProactivityNotes = new List<String>{ 'Test 9' };

    Map<Id, List<String>> flightIdToCorrectProactivityNotes = new Map<Id, List<String>>{};

    List<Flight__c> flights = [SELECT Id, TEDS_Identifier__c FROM Flight__c];
    for (Flight__c f : flights) {
      List<Proactivity__c> flightProactivities = new List<Proactivity__c>{};
      for (Proactivity__c p : correctProactivities) {
        if (f.TEDS_Identifier__c == flightIdentifier5) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight1ProactivityNotes);
        } else if (f.TEDS_Identifier__c == flightIdentifier6) {
          flightIdToCorrectProactivityNotes.put(f.Id, flight2ProactivityNotes);
        }
      }
    }

    // When
    ProactivitiesSelector.ProactivityQueryResult result = proactivites.selectProactivitiesByClaimsWithMatchingReasons(
      claimsWithProactivities
    );
    Set<Proactivity__c> multipleProactivitiesRegularMatcher = result.proactivityToReason.keySet();

    // Then
    System.assertEquals(
      2,
      multipleProactivitiesRegularMatcher.size(),
      'Should select two proactivities from claim correctly (too many/few matches)'
    );

    for (Proactivity__c p : multipleProactivitiesRegularMatcher) {
      System.assert(
        notes.contains(p.Note__c),
        'Should select the correct proactivities from case ID correctly (wrong proactivity)'
      );
    }

    for (Id flightId : result.flightIdToProactivities.keySet()) {
      Set<Proactivity__c> proactivities = result.flightIdToProactivities.get(
        flightId
      );
      List<String> correctProactivityNotesToCompare = flightIdToCorrectProactivityNotes.get(
        flightId
      );

      System.assertEquals(
        correctProactivityNotesToCompare.size(),
        proactivities.size(),
        'Should select the correct proactivities from case ID correctly (wrong number of proactivities)'
      );

      // Make sure the list of proactivities is the same list as the one we expect
      for (Proactivity__c p : proactivities) {
        System.assert(
          correctProactivityNotesToCompare.contains(p.Note__c),
          'Should select the correct proactivities from case ID correctly (wrong proactivity)'
        );
      }
    }
  }
}
