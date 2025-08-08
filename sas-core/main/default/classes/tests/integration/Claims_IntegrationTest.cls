@IsTest
public with sharing class Claims_IntegrationTest {
  @IsTest
  public static void baggageClaimsWithNonStarAllianceOperatingCarriersShouldBeProrated() {
    // Given
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    Case c = new Case(
      InApproval__c = true,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = Cases.STATUS_IN_PROGRESS
    );

    insert new List<SObject>{ c, booking, flight1, flight2 };

    CaseToBooking__c ctb = new CaseToBooking__c(
      Booking__c = booking.Id,
      Case__c = c.Id
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Case__c = c.Id,
      Customer_Claim_Category__c = 'Baggage',
      Liability_PNR__c = 'ABC123',
      PIR__c = 'ARNSK12345'
    );

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ claim, ctb, seg1, seg2 };

    c.LIA_Claim__c = claim.Id;

    Settlement__c settlement = new Settlement__c(Claim__c = claim.Id);

    upsert new List<SObject>{ c, settlement };

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When claim case is closed
    Test.startTest();
    c.Status = CASES.STATUS_CLOSED;
    update c;
    Test.stopTest();

    // Then
    List<Case> supportCase = [SELECT Id FROM Case WHERE ParentId = :c.Id];
    System.assertEquals(
      1,
      supportCase.size(),
      'A support case should have been created for the closed claim case.'
    );
  }

  @IsTest
  public static void baggageClaimsForStarAllianceBookingsShouldNotBeProrated() {
    // Given
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'LH',
      TEDS_Identifier__c = 'LH1'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    Case c = new Case(
      InApproval__c = true,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = Cases.STATUS_IN_PROGRESS
    );

    insert new List<SObject>{ c, booking, flight1, flight2 };

    CaseToBooking__c ctb = new CaseToBooking__c(
      Booking__c = booking.Id,
      Case__c = c.Id
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Case__c = c.Id,
      Customer_Claim_Category__c = 'Baggage',
      Liability_PNR__c = 'ABC123',
      PIR__c = 'ARNSK12345'
    );

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ claim, ctb, seg1, seg2 };

    c.LIA_Claim__c = claim.Id;

    Settlement__c settlement = new Settlement__c(Claim__c = claim.Id);

    upsert new List<SObject>{ c, settlement };

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When claim case is closed
    Test.startTest();
    c.Status = CASES.STATUS_CLOSED;
    update c;
    Test.stopTest();

    // Then
    List<Case> supportCase = [SELECT Id FROM Case WHERE ParentId = :c.Id];
    System.assertEquals(
      0,
      supportCase.size(),
      'A support case should not have been created for the closed claim case.'
    );
  }

  @IsTest
  public static void nonBaggageClaimsShouldNotBeProrated() {
    // Given
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    Case c = new Case(
      InApproval__c = true,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = Cases.STATUS_IN_PROGRESS
    );

    insert new List<SObject>{ c, booking, flight1, flight2 };

    CaseToBooking__c ctb = new CaseToBooking__c(
      Booking__c = booking.Id,
      Case__c = c.Id
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Case__c = c.Id,
      Customer_Claim_Category__c = 'Flight disruptions',
      Liability_PNR__c = 'ABC123',
      Flight_Date__c = Date.today(),
      Flight_Number__c = 'SK1'
    );

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ claim, ctb, seg1, seg2 };

    c.LIA_Claim__c = claim.Id;

    Settlement__c settlement = new Settlement__c(Claim__c = claim.Id);

    upsert new List<SObject>{ c, settlement };

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When claim case is closed
    Test.startTest();
    c.Status = CASES.STATUS_CLOSED;
    update c;
    Test.stopTest();

    // Then
    List<Case> supportCase = [SELECT Id FROM Case WHERE ParentId = :c.Id];
    System.assertEquals(
      0,
      supportCase.size(),
      'A support case should not have been created for the closed claim case.'
    );
  }

  @IsTest
  public static void shouldNotCreateDuplicateProrationCases() {
    // Given
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    Case c = new Case(
      InApproval__c = true,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = Cases.STATUS_IN_PROGRESS
    );

    insert new List<SObject>{ c, booking, flight1, flight2 };

    CaseToBooking__c ctb = new CaseToBooking__c(
      Booking__c = booking.Id,
      Case__c = c.Id
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Case__c = c.Id,
      Customer_Claim_Category__c = 'Baggage',
      Liability_PNR__c = 'ABC123',
      PIR__c = 'ARNSK12345'
    );

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ claim, ctb, seg1, seg2 };

    c.LIA_Claim__c = claim.Id;

    Settlement__c settlement = new Settlement__c(Claim__c = claim.Id);

    upsert new List<SObject>{ c, settlement };

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When claim case is closed
    Test.startTest();
    c.Status = CASES.STATUS_CLOSED;
    update c;
    c.Status = CASES.STATUS_IN_PROGRESS;
    update c;
    c.Status = CASES.STATUS_CLOSED;
    update c;
    Test.stopTest();

    // Then
    List<Case> supportCase = [SELECT Id FROM Case WHERE ParentId = :c.Id];
    System.assertEquals(
      1,
      supportCase.size(),
      'Only one support case should have been created for the closed claim case even though it was closed twice.'
    );
  }

  @IsTest
  public static void baggageClaimsClosedWithoutSettlementShouldNotBeProrated() {
    // Given
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    Case c = new Case(
      InApproval__c = true,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = Cases.STATUS_IN_PROGRESS
    );

    insert new List<SObject>{ c, booking, flight1, flight2 };

    CaseToBooking__c ctb = new CaseToBooking__c(
      Booking__c = booking.Id,
      Case__c = c.Id
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Case__c = c.Id,
      Customer_Claim_Category__c = 'Baggage',
      Liability_PNR__c = 'ABC123',
      PIR__c = 'ARNSK12345'
    );

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );
    insert new List<SObject>{ claim, ctb, seg1, seg2 };

    c.LIA_Claim__c = claim.Id;

    update c;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When claim case is closed
    Test.startTest();
    c.Status = CASES.STATUS_CLOSED;
    update c;
    Test.stopTest();

    // Then
    List<Case> supportCase = [SELECT Id FROM Case WHERE ParentId = :c.Id];
    System.assertEquals(
      0,
      supportCase.size(),
      'Support cases should not be created for claims without settlements'
    );
  }

  @IsTest
  public static void attemptingToRedeemUsedCompensationCardShouldFail() {
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    String bookingReference = APIMMock.VALID_VO_VOUCHER_ACCESS_CODE;
    String cardNumber = APIMMock.VALID_VO_VOUCHER_NUMBER;

    Group compensationCardQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(
        new Set<String>{ ClaimService.COMPENSATION_CARD_OMNI_QUEUE_NAME }
      )[0];

    Redeemed_Compensation_Card__c redeemedCard = new Redeemed_Compensation_Card__c(
      Booking_Reference__c = bookingReference,
      Compensation_Card_Number__c = cardNumber
    );

    insert redeemedCard;

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      1,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Compensation_Card_Number__c => cardNumber,
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Customer_Claim_Category__c => 'Compensation Card',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CompensationCard
        )
      }
    );

    Case c = createdCasesClaims.cases[0];
    LIA_Claim__c claim = createdCasesClaims.claims[0];

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.attemptToRedeemCompensationCardClaim(claim.Id);
    Test.stopTest();

    List<Settlement__c> settlementsForClaim = [
      SELECT Id
      FROM Settlement__c
      WHERE Claim__c = :claim.Id
    ];
    System.assertEquals(
      0,
      settlementsForClaim.size(),
      'No settlements should have been created'
    );
    Case caseAfterAttempt = [
      SELECT Id, Status, OwnerId
      FROM Case
      WHERE Id = :c.Id
    ];
    System.assertEquals(
      Cases.STATUS_CLOSED,
      caseAfterAttempt.Status,
      'Case should have been closed.'
    );
    System.assertEquals(
      compensationCardQueue.Id,
      caseAfterAttempt.OwnerId,
      'Case should have been assigned to the Compensation Card queue.'
    );
  }

  @IsTest
  public static void attemptingToRedeemAnInvalidCompensationCardShouldFail() {
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    String bookingReference = 'nnnnnn';
    String cardNumber = '0000000';

    Group compensationCardQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(
        new Set<String>{ ClaimService.COMPENSATION_CARD_OMNI_QUEUE_NAME }
      )[0];

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      1,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.BIC_Swift__c => 'XXXXXXXX',
        LIA_Claim__c.Compensation_Card_Number__c => cardNumber,
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Customer_Claim_Category__c => 'Compensation Card',
        LIA_Claim__c.Preferred_Compensation_Method__c => 'Monetary',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CompensationCard
        )
      }
    );

    Case c = createdCasesClaims.cases[0];
    LIA_Claim__c claim = createdCasesClaims.claims[0];

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.attemptToRedeemCompensationCardClaim(claim.Id);
    Test.stopTest();

    List<Settlement__c> settlementsForClaim = [
      SELECT Id, Amount__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Claim__c = :claim.Id
    ];
    System.assertEquals(
      0,
      settlementsForClaim.size(),
      'No settlements should have been created.'
    );

    List<Redeemed_Compensation_Card__c> compensationCards = [
      SELECT Id
      FROM Redeemed_Compensation_Card__c
      WHERE Claim__c = :claim.Id
    ];
    System.assertEquals(
      0,
      compensationCards.size(),
      'No redeemed compensation cards should have been created.'
    );

    Case caseAfterAttempt = [
      SELECT Id, Status, OwnerId
      FROM Case
      WHERE Id = :c.Id
    ];
    System.assertEquals(
      Cases.STATUS_CLOSED,
      caseAfterAttempt.Status,
      'Case should have been closed.'
    );
    System.assertEquals(
      compensationCardQueue.Id,
      caseAfterAttempt.OwnerId,
      'Case should have been assigned to the Compensation Card queue.'
    );
  }

  @IsTest
  public static void attemptingToRedeemAValidUnusedCompensationCardShouldSucceed() {
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    String bookingReference = C_Util.isSandbox()
      ? APIMMock.VALID_VO_VOUCHER_ACCESS_CODE
      : APIMMock.VOUCHER_VALID_PNR;
    String cardNumber = C_Util.isSandbox()
      ? APIMMock.VALID_VO_VOUCHER_NUMBER
      : APIMMock.VOUCHER_VALID_CARD_ID;
    Group compensationCardQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(
        new Set<String>{ ClaimService.COMPENSATION_CARD_OMNI_QUEUE_NAME }
      )[0];

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      1,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Bank_Account_Number__c => 'SE7280000810340009783242',
        LIA_Claim__c.Bank_Country__c => 'Sweden',
        LIA_Claim__c.Bank_Account_Holder_Name__c => 'Teemu Teekkari',
        LIA_Claim__c.BIC_Swift__c => 'AAAABBCC',
        LIA_Claim__c.Compensation_Card_Number__c => cardNumber,
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Customer_Claim_Category__c => 'Compensation Card',
        LIA_Claim__c.Preferred_Compensation_Method__c => 'Monetary',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CompensationCard
        )
      }
    );
    Exchange_Rate__c rate = new Exchange_Rate__c(
      Name = 'EUR-SEK',
      From_Currency__c = 'EUR',
      To_Currency__c = 'SEK',
      Date__c = Date.Today(),
      Rate__c = 2
    );
    insert rate;

    Case c = createdCasesClaims.cases[0];
    LIA_Claim__c claim = createdCasesClaims.claims[0];

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.attemptToRedeemCompensationCardClaim(claim.Id);
    Test.stopTest();

    List<Settlement__c> settlementsForClaim = [
      SELECT Id, Amount__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Claim__c = :claim.Id
    ];
    System.assertEquals(
      1,
      settlementsForClaim.size(),
      'A settlements should have been created.'
    );
    System.assertEquals(
      Settlements.STATUS_WAITING_FOR_TRANSFER,
      settlementsForClaim[0].Settlement_Status__c,
      'Settlement should be waiting for transfer.'
    );
    System.assertEquals(
      800,
      settlementsForClaim[0].Amount__c,
      'Settlement amount should match compensation card value.'
    );
    List<Redeemed_Compensation_Card__c> compensationCards = [
      SELECT Id
      FROM Redeemed_Compensation_Card__c
      WHERE Claim__c = :claim.Id
    ];
    System.assertEquals(
      1,
      compensationCards.size(),
      'The compensation card should be marked as redeemed.'
    );
    Case caseAfterAttempt = [
      SELECT Id, Status, OwnerId
      FROM Case
      WHERE Id = :c.Id
    ];

    System.assertEquals(
      Cases.STATUS_CLOSED,
      caseAfterAttempt.Status,
      'Case should have been closed.'
    );
    System.assertEquals(
      compensationCardQueue.Id,
      caseAfterAttempt.OwnerId,
      'Case should have been assigned to the Compensation Card queue.'
    );
  }
  @IsTest
  public static void fetchingByCAREClaimsByPNRShouldCreateRecords() {
    String bookingReference = APIMMock.PNR_FOR_WHICH_CLAIMS_EXIST;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.fetchCAREClaimsFromEDW(bookingReference, null, null);
    Test.stopTest();

    CARE_Claim__c createdCAREClaim = [
      SELECT Id, Booking_Reference__c
      FROM CARE_Claim__c
      WHERE Booking_Reference__c = :bookingReference
    ];

    System.assertEquals(
      bookingReference,
      createdCAREClaim.Booking_Reference__c,
      'A CARE claim should have been inserted into the DB.'
    );
  }

  @IsTest
  public static void fetchingByCAREClaimsByPIRShouldCreateRecords() {
    String pir = APIMMock.PIR_FOR_WHICH_CLAIMS_EXIST;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.fetchCAREClaimsFromEDW(null, pir, null);
    Test.stopTest();

    CARE_Claim__c createdCAREClaim = [
      SELECT Id, PIR__c
      FROM CARE_Claim__c
      WHERE PIR__c = :pir
    ];

    System.assertEquals(
      pir,
      createdCAREClaim.PIR__c,
      'A CARE claim should have been inserted into the DB.'
    );
  }

  @IsTest
  public static void fetchingInvalidCAREClaimsShouldNotCreateAnything() {
    String bookingReference = APIMMock.PNR_FOR_WHICH_CLAIMS_DO_NOT_EXIST;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    ClaimService.fetchCAREClaimsFromEDW(bookingReference, null, null);
    Test.stopTest();

    List<CARE_Claim__c> createdCAREClaims = [SELECT Id FROM CARE_Claim__c];

    System.assertEquals(
      0,
      createdCAREClaims.size(),
      'No claim should have been created.'
    );
  }
}
