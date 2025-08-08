@IsTest
public with sharing class SimilarCasesControllerTest {
  @IsTest
  public static void gettingSimilarCasesShouldFetchSFCasesAndCARECases() {
    // Given
    String sharedBookingReference = 'ABC123';

    TestDataFactories.CasesClaims similar = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => sharedBookingReference,
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        )
      }
    );
    TestDataFactories.CasesClaims different = TestDataFactories.createCasesWithClaims(
      1,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => '123ABC',
        LIA_Claim__c.Flight_Number__c => 'LH2',
        LIA_Claim__c.Flight_Date__c => Date.today().addDays(1),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        )
      }
    );

    Case thisCase = similar.cases[0];
    Case similarCase = similar.cases[1];
    Case differentCase = different.cases[0];

    LIA_Claim__c cl = similar.claims[1];
    cl.PIR__c = 'ARNSK12456';
    cl.Liability_PNR__c = '12345D';
    cl.Flight_Number__c = 'SK2';
    cl.Flight_Date__c = Date.today().addDays(2);
    update cl;

    CARE_Claim__c similarCAREClaim = new CARE_Claim__c(
      Booking_Reference__c = sharedBookingReference
    );
    insert similarCAREClaim;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    // When
    List<SimilarCasesController.SimilarCasesJSON> foundCases = SimilarCasesController.getSimilarCasesForCase(
      thisCase.Id
    );
    Test.stopTest();

    // Then
    System.assertEquals(
      3, // CARE claim + Similar case + the case itself
      foundCases.size(),
      'Similar SF case and CARE case should have been found.'
    );

    Case foundSFCase;
    CARE_Claim__c foundCARECase;

    for (SimilarCasesController.SimilarCasesJSON c : foundCases) {
      if (c.type == 'Case' && c.caseData.Id != thisCase.Id) {
        foundSFCase = c.caseData;
      } else {
        foundCARECase = c.claimData;
      }
    }

    System.assertNotEquals(null, foundSFCase, 'Should have found a SF case.');
    System.assertNotEquals(
      null,
      foundCARECase,
      'Should have found a CARE case.'
    );
  }
}
