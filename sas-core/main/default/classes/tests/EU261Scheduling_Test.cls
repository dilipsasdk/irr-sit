@IsTest
public with sharing class EU261Scheduling_Test {
  private static ClaimsSelector claimsSel = ClaimsSelector.newInstance();
  private static GroupsSelector groupsSel = GroupsSelector.newInstance();
  @IsTest
  static void itIsPossibleToUpdateExternalDataStatus() {
    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => 'ABC123',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.EU261_Handling_Status__c => 'Unhandled',
        LIA_Claim__c.External_Data_Status__c => 'Not Started',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        )
      }
    );
    casesWithClaims.claims[1].Customer_Claim_Type__c = 'Flight cancellation';
    update casesWithClaims.claims[1];

    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Claims claimsDomain = Claims.newInstance(
      claimsSel.selectUnhandledEU261ClaimsByDataStatus('Not Started')
    );
    claimsDomain.updateExternalDataStatus(
      Claim.ExternalDataStatus.InProgress,
      uow
    );
    uow.commitWork();
    Test.stopTest();

    LIA_Claim__c claim1AfterUpdate = [
      SELECT Id, External_Data_Status__c
      FROM LIA_Claim__c
      WHERE Id = :casesWithClaims.claims[0].Id
    ];
    LIA_Claim__c claim2AfterUpdate = [
      SELECT Id, External_Data_Status__c
      FROM LIA_Claim__c
      WHERE Id = :casesWithClaims.claims[1].Id
    ];
    System.assertEquals(
      'In Progress',
      claim1AfterUpdate.External_Data_Status__c,
      'External Data Status should have been updated'
    );
    System.assertEquals(
      'Not Started',
      claim2AfterUpdate.External_Data_Status__c,
      'External Data Status should not have been updated'
    );
  }

  @IsTest
  static void fetchingBookingThatExistsInEDWShouldUpdateDataStatus() {
    Group automationGroup = groupsSel.selectGroupsByName(
      new Set<String>{ 'SAS Automation Queue' }
    )[0];
    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      2,
      new Map<Schema.SObjectField, Object>{
        Case.OwnerId => automationGroup.Id
      },
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => APIMMock.EDW_SINGLE_PNR,
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        ),
        LIA_Claim__c.External_Data_Status__c => 'In Progress',
        LIA_Claim__c.EU261_Handling_Status__c => 'Unhandled'
      }
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Database.executeBatch(new FetchEDWBookingsForEU261ClaimsBatch(), 2);
    Test.stopTest();
    LIA_Claim__c cl = claimsSel.selectById(
      new Set<Id>{ casesWithClaims.claims[0].Id }
    )[0];
    Case caseAfterUpdate = [
      SELECT Id, OwnerId
      FROM Case
      WHERE Id = :casesWithClaims.cases[0].Id
    ];
    System.assertEquals(
      1,
      cl.External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'Completed',
      cl.External_Data_Status__c,
      'External Data Status should have been updated'
    );
    System.assertEquals(
      automationGroup.Id,
      caseAfterUpdate.OwnerId,
      'Case should still be assigned to automation queue'
    );
  }

  @IsTest
  static void fetchingBookingThatDoesNotExistsInEDWShouldFailGracefully() {
    List<Group> allGroups = groupsSel.selectGroupsByName(
      new Set<String>{ 'Claims - EU261', 'SAS Automation Queue' }
    );
    Group eu261Group;
    Group automationGroup;
    for (Group g : allGroups) {
      if (g.Name == 'Claims - EU261') {
        eu261Group = g;
      } else if (g.Name == 'SAS Automation Queue') {
        automationGroup = g;
      }
    }

    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      2,
      new Map<Schema.SObjectField, Object>{
        Case.OwnerId => automationGroup.Id
      },
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => 'ABC123',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        ),
        LIA_Claim__c.External_Data_Status__c => 'In Progress',
        LIA_Claim__c.EU261_Handling_Status__c => 'Unhandled'
      }
    );

    LIA_Claim__c claimWithHighExternalDataCount = casesWithClaims.claims[0];
    claimWithHighExternalDataCount.Liability_PNR__c = 'ABC111';
    claimWithHighExternalDataCount.External_Data_Retrieve_Count__c = 3;
    update claimWithHighExternalDataCount;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Database.executeBatch(new FetchEDWBookingsForEU261ClaimsBatch(), 2);
    Test.stopTest();
    Set<Id> claimIds = new Map<Id, LIA_Claim__c>(casesWithClaims.claims)
      .keySet();
    List<LIA_Claim__c> claimsAfterUpdate = claimsSel.selectById(claimIds);

    LIA_Claim__c claimWithLowExternalDataCount;
    for (LIA_Claim__c c : claimsAfterUpdate) {
      if (c.Liability_PNR__c == 'ABC111') {
        claimWithHighExternalDataCount = c;
      } else {
        claimWithLowExternalDataCount = c;
      }
    }

    Case caseAfterUpdate = [
      SELECT Id, OwnerId
      FROM Case
      WHERE Id = :claimWithHighExternalDataCount.Case__c
    ];

    System.assertEquals(
      1,
      claimWithLowExternalDataCount.External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'In Progress',
      claimWithLowExternalDataCount.External_Data_Status__c,
      'External Data Status should still be In Progress'
    );
    System.assertEquals(
      4,
      claimWithHighExternalDataCount.External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'Unavailable',
      claimWithHighExternalDataCount.External_Data_Status__c,
      'External Data Status should set to Unavailable'
    );
    System.assertEquals(
      'Unable to handle',
      claimWithHighExternalDataCount.EU261_Handling_Status__c,
      'EU261 Handling Status should set to Unable to handle'
    );
    System.assertEquals(
      eu261Group.Id,
      caseAfterUpdate.OwnerId,
      'Case should have been routed to manual handling queue'
    );
  }
}
