@IsTest
private class CasesSelector_Test {
  private static CasesSelector casesSel = CasesSelector.newInstance();

  @testSetup
  static void setup() {
    Proactivity__c normalProactivity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Phone_Number__c = '0000000000'
    );
    Proactivity__c directlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 6',
      Type__c = 'Normal'
    );
    Proactivity__c directlyAndIndirectlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 7',
      Type__c = 'Normal',
      Email__c = 'test@test.com'
    );
    Proactivity__c mixedMatchProactivity = new Proactivity__c(
      Note__c = 'Test 8',
      Type__c = 'Normal',
      Email__c = 'test@test.com',
      Phone_Number__c = '0000000000'
    );

    insert new List<Proactivity__c>{
      directlyMatchedProactivity,
      directlyAndIndirectlyMatchedProactivity,
      mixedMatchProactivity
    };

    Case caseWithOneProactivityRegularMatcher = new Case(
      FCS_EBNumber__c = '000000001'
    );
    Case caseWithDirectMatch = new Case(
      Proactivity__c = directlyMatchedProactivity.Id,
      FCS_EBNumber__c = '000000002'
    );
    Case caseWithDirectAndIndirectMatch = new Case(
      Proactivity__c = directlyAndIndirectlyMatchedProactivity.Id,
      FCS_EBNumber__c = '000000003'
    );
    Case caseWithMixedMatch = new Case(
      Proactivity__c = mixedMatchProactivity.Id,
      FCS_EBNumber__c = '000000004'
    );

    insert new List<Case>{
      caseWithOneProactivityRegularMatcher,
      caseWithDirectMatch,
      caseWithDirectAndIndirectMatch,
      caseWithMixedMatch
    };

    LIA_Claim__c claimWithOneProactivityRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityRegularMatcher.Id,
      Phone_Number__c = '0000000000'
    );

    LIA_Claim__c claimWithOneProactivityRegularMatcherDoubleMatch = new LIA_Claim__c(
      Case__c = caseWithDirectAndIndirectMatch.Id,
      Contact_Email__c = 'test@test.com'
    );

    insert new List<SObject>{
      normalProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithOneProactivityRegularMatcherDoubleMatch
    };
  }

  @IsTest
  static void shouldSelectCaseWithNormalProactivityClaimMatch() {
    // Given (setup)
    Proactivity__c normalProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 1'
    ][0];
    Case correctCase = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000001'
    ][0];

    // When
    List<Case> oneCaseNormalMatcher = casesSel.selectByProactivityId(
      normalProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneCaseNormalMatcher.size(),
      'Should select a single case from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctCase.Id,
      oneCaseNormalMatcher[0].Id,
      'Should select a single case from proactivity ID correctly (wrong case)'
    );
  }

  @IsTest
  static void shouldSelectCaseWithDirectMatchNoClaim() {
    // Given (setup)
    Proactivity__c directMatchProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 6'
    ][0];
    Case correctCase = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000002'
    ][0];

    // When
    List<Case> oneCaseDirectMatchNoClaim = casesSel.selectByProactivityId(
      directMatchProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneCaseDirectMatchNoClaim.size(),
      'Should select a single case without claim from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctCase.Id,
      oneCaseDirectMatchNoClaim[0].Id,
      'Should select a single case without claim from proactivity ID correctly (wrong case)'
    );
  }

  @IsTest
  static void shouldSelectCaseWithMixedMatch() {
    // Given (setup)
    Proactivity__c mixedMatchProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 8'
    ][0];
    List<Case> correctCases = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c IN ('000000001', '000000003', '000000004')
    ];

    // When
    List<Case> threeCasesMixMatch = casesSel.selectByProactivityId(
      mixedMatchProactivity.ID
    );

    List<Id> selectedCaseIds = new List<Id>{};
    for (Case c : threeCasesMixMatch) {
      selectedCaseIds.add(c.Id);
    }

    Integer correctlyMatched = 0;
    for (Case c : correctCases) {
      if (selectedCaseIds.contains(c.Id)) {
        correctlyMatched += 1;
      }
    }

    // Then
    System.assertEquals(
      3,
      threeCasesMixMatch.size(),
      'Should select three cases with mixed matching from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      3,
      correctlyMatched,
      'Should select three cases with mixed matching from proactivity ID correctly (wrong case)'
    );
  }

  @IsTest
  public static void similarCasesShouldBeFetchedForNonClaimFirmIban() {
    String bookingReference = 'ABC123';
    String bankAccountNumber = 'SE7280000810340009783242';

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Bank_Account_Number__c => bankAccountNumber,
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Flight_Date__c => Date.valueOf('2022-01-01'),
        LIA_Claim__c.Flight_Number__c => 'SK1234'
      }
    );

    LIA_Claim__c cl = createdCasesClaims.claims[1];
    cl.Liability_PNR__c = 'ABC124';
    cl.PIR__c = 'ARNSK12456';
    cl.Flight_Date__c = Date.valueOf('2022-02-02');
    cl.Flight_Number__c = 'SK1235';
    update cl;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<Case> similarCases = CasesSelector.newInstance()
      .selectSimilarCasesById(createdCasesClaims.cases[0].Id);
    Test.stopTest();
    System.assertEquals(
      2,
      similarCases.size(),
      'Should have found more than one case'
    );
  }

  @IsTest
  public static void similarCasesShouldNotBeFetchedForClaimFirmIban() {
    //Should exclude results where only bank account matches if number is connected to a Claim Firm
    String bookingReference = 'ABC123';
    String bankAccountNumber = 'SE7280000810340009783242';

    Claim_Firm__c cf = new Claim_Firm__c(Name = 'Testfirm');
    insert cf;

    Bank_Account_Info__c bai = new Bank_Account_Info__c(
      Bank_Account_Number__c = bankAccountNumber,
      Claim_Firm__c = cf.Id
    );

    insert bai;

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Bank_Account_Number__c => bankAccountNumber,
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Flight_Date__c => Date.valueOf('2022-01-01'),
        LIA_Claim__c.Flight_Number__c => 'SK1234'
      }
    );

    LIA_Claim__c cl = createdCasesClaims.claims[1];
    cl.Liability_PNR__c = 'ABC124';
    cl.PIR__c = 'ARNSK12456';
    cl.Flight_Date__c = Date.valueOf('2022-02-02');
    cl.Flight_Number__c = 'SK1235';
    update cl;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<Case> similarCases = CasesSelector.newInstance()
      .selectSimilarCasesById(createdCasesClaims.cases[0].Id);
    Test.stopTest();
    System.assertEquals(
      1,
      similarCases.size(),
      'Should not have found more than one case'
    );
  }

  @IsTest
  public static void similarCasesShouldBeFetchedForClaimFirms() {
    //Find similar cases if other info matches for claims with a bank account connected to a Claim Firm
    String bookingReference = 'ABC123';
    String bankAccountNumber = 'SE7280000810340009783242';

    Claim_Firm__c cf = new Claim_Firm__c(Name = 'Testfirm');
    insert cf;

    Bank_Account_Info__c bai = new Bank_Account_Info__c(
      Bank_Account_Number__c = bankAccountNumber,
      Claim_Firm__c = cf.Id
    );

    insert bai;

    TestDataFactories.CasesClaims createdCasesClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => bookingReference,
        LIA_Claim__c.Bank_Account_Number__c => bankAccountNumber,
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Flight_Date__c => Date.valueOf('2022-01-01'),
        LIA_Claim__c.Flight_Number__c => 'SK1234'
      }
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<Case> similarCases = CasesSelector.newInstance()
      .selectSimilarCasesById(createdCasesClaims.cases[0].Id);
    Test.stopTest();
    System.assertEquals(
      2,
      similarCases.size(),
      'Should have found more than one case'
    );
  }

  @IsTest
  public static void shouldSelectReadOnlyCase() {
    //Select cases that are not read only and closed date greater than 90 days
    Case shouldNotMatch1 = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = 'Closed',
      Department__c = 'Customer Claim',
      IsReadOnly__c = true,
      CreatedDate = System.now() - 92,
      ClosedDate = System.now() - 91
    );
    Case shouldNotMatch2 = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = 'Closed',
      Department__c = 'Customer Claim',
      IsReadOnly__c = false,
      CreatedDate = System.now() - 92,
      ClosedDate = System.now() - 50
    );
    Case shouldNotMatch3 = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = 'Closed',
      Department__c = 'Customer Claim',
      IsReadOnly__c = true,
      CreatedDate = System.now() - 92,
      ClosedDate = System.now() - 50
    );
    Case shouldMatch = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Status = 'Closed',
      Department__c = 'Customer Claim',
      IsReadOnly__c = false,
      CreatedDate = System.now() - 92,
      ClosedDate = System.now() - 91
    );

    insert new List<Case>{
      shouldNotMatch1,
      shouldNotMatch2,
      shouldNotMatch3,
      shouldMatch
    };

    List<Case> readOnlyCases = CasesSelector.newInstance()
      .selectInactiveByDepartment('Customer Claim');
    
    System.assertEquals(
      1,
      readOnlyCases.size(),
      'Should not have found more than one case'
    );
    System.assertEquals(
      shouldMatch.Id,
      readOnlyCases[0].Id,
      'Should not have found more than one case (wrong case)'
    );
  }
}
