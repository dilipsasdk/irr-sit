@IsTest
private class Cases_Test {
  private static final String CASE_STATUS_NEW = 'New';
  /**
       Test method for generation of test data used in more than one method
   */
  @TestSetup
  static void createTestUserSetup() {
    PermissionSet socialMediaPermission = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'SocialMediaUser'
    ];

    Profile vendorProfile = [SELECT Id FROM Profile WHERE Name = 'Vendor'];
    List<User> users = FCS_TestDataFactory.createUsers(4);
    insert users;

    PermissionSetAssignment[] assignments = new List<PermissionSetAssignment>{};
    Integer i = 0;
    for (User u : users) {
      u.ProfileId = vendorProfile.Id;
      u.FederationIdentifier = 'SoMe' + i;
      i++;
      assignments.add(
        new PermissionSetAssignment(
          AssigneeId = u.Id,
          PermissionSetId = socialMediaPermission.Id
        )
      );
    }
    insert assignments;
    update users;
  }

  static void createTestData() {
    Integer maxRetriesInDML = 3;
    Integer count = 0;
    boolean retry;
    List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(4);
    insert socialPosts;
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    newCases[0].Subject = 'TestCase 2';
    do {
      retry = false;
      try {
        insert newCases;
      } catch (Exception lockerror) {
        count++;
        String lockingissue = String.valueOf(lockerror);
        if (
          lockingissue.contains('UNABLE_TO_LOCK_ROW') &&
          count <= maxRetriesInDML
        ) {
          retry = true;
        } else if (
          (!lockingissue.contains('UNABLE_TO_LOCK_ROW')) ||
          count > maxRetriesInDML
        ) {
          throw lockerror;
        }
      }
    } while (retry);
  }

  /**
        Tests that cases (used to save tagging of cases where case is created with status closed) created from social posts is assigned to the owner of the source post if owner is a user
    */
  @isTest
  static void addSocialMediaTag() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier LIKE 'SoMe%'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = users[i].Id;
    }
    update socialPosts;

    Case infoTag = new Case(
      Status = 'Closed',
      Origin = 'Facebook',
      SourceId = socialPosts[0].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
      Department__c = 'SoMe Support',
      FCS_CaseType__c = 'Baggage',
      FCS_Case_Reason__c = 'Allowance',
      FCS_CaseResolution__c = 'Referred to webpage'
    );

    Case supportTag = new Case(
      Status = 'Closed',
      Origin = 'Twitter',
      SourceId = socialPosts[1].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
      Department__c = 'SoMe Support',
      FCS_CaseType__c = 'Changes',
      FCS_Case_Reason__c = 'Name change/correction',
      FCS_CaseResolution__c = 'Completed'
    );
    Case feedbackTag = new Case(
      Status = 'Closed',
      Origin = 'Twitter',
      SourceId = socialPosts[2].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
      Department__c = 'SoMe Support',
      FCS_CaseType__c = 'Changes',
      FCS_Case_Reason__c = 'Name change/correction',
      FCS_CaseResolution__c = 'Completed'
    );
    List<Case> soMeCases = new List<Case>();
    soMeCases.add(infoTag);
    soMeCases.add(supportTag);
    soMeCases.add(feedbackTag);
    insert soMeCases;
    Set<Id> caseIds = new Set<Id>();
    caseIds.add(infoTag.Id);
    caseIds.add(supportTag.Id);
    caseIds.add(feedbackTag.Id);
    List<Case> caseList = [SELECT OwnerId FROM Case WHERE Id = :caseIds];
    System.assertEquals(socialPosts[0].OwnerId, caseList[0].OwnerId);
    System.assertEquals(socialPosts[1].OwnerId, caseList[1].OwnerId);
    System.assertEquals(socialPosts[2].OwnerId, caseList[2].OwnerId);
  }

  /**
      Tests that it is not possible to create a case (as tag eg. in status closed) assigned to the owner of the source post if owner is a user
   */
  @isTest
  static void errorAddSocialMediaTag() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost LIMIT 1];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier = 'SoMe0'
    ];
    List<Group> groupList = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = groupList[i].Id;
    }
    update socialPosts;
    Case infoTag = new Case(
      Status = 'Closed',
      Origin = 'Facebook',
      SourceId = socialPosts[0].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL
    );
    List<Case> soMeCases = new List<Case>();
    soMeCases.add(infoTag);
    Database.SaveResult result = Database.insert(soMeCases[0], false);
    System.assert(result.isSuccess() == false);
    System.assert(result.getErrors().size() == 1);
  }

  /**
        Test Method to see if social posts are updated correctly if new case is created from there (not closed).
    */
  @isTest
  static void testUpdateSocialPosts() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier LIKE 'SoMe%'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = users[i].Id;
    }
    List<Case> newCase = FCS_TestDataFactory.createCases(1, null, null, null);
    newCase[0].FCS_CaseType__c = 'Changes';
    newCase[0].FCS_Case_Reason__c = 'Name change/correction';
    newCase[0].Subject = 'TestCase12';
    newCase[0].Status = CASE_STATUS_NEW;
    newCase[0].SourceId = socialPosts[0].Id;
    newCase[0].Department__c = 'SoMe Support';
    newCase[0].RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    insert newCase;
    System.AssertEquals(
      true,
      [
        SELECT Id, FCS_CaseCreated__c
        FROM SocialPost
        WHERE Id = :newCase[0].SourceId
      ][0]
      .FCS_CaseCreated__c
    );
  }

  @IsTest
  static void shouldDeleteRelatedSurveyInvitationsOnDelete() {
    Case[] cases = FCS_TestDataFactory.createCases(2, null, null, null);
    insert cases;

    delete cases;
  }

  @IsTest
  static void enrichCaseDataBasedOnOriginConfigMatchingOriginShouldFillCorrectData() {
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];
    testCase.Origin = 'Email - Group Sales AT';
    testCase.SuppliedFirstname__c = 'Test';
    testCase.SuppliedLastname__c = 'Testsson';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT Department__c, Team__c, Type
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(testCaseAfterTrigger.Type, 'Channel');
    System.assertEquals(testCaseAfterTrigger.Department__c, 'Group Sales');
    System.assertEquals(testCaseAfterTrigger.Team__c, 'AT');
  }
  @IsTest
  static void enrichMissingPointsCaseDataIfNrOfFltsNaNIgnore() {
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];
    testCase.Subject = 'flight retro';
    testCase.SuppliedEmail = 'noreply@flysas.com';
    testCase.Description = 'number-of-flights: notanumber\n';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT
        Flight_Info_Missing_Points_X1__c,
        Flight_Info_Missing_Points_X2__c,
        Flight_Info_Missing_Points_X3__c,
        Flight_Info_Missing_Points_X4__c
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X1__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X2__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X3__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X4__c,
      null
    );
  }

  @IsTest
  static void enrichMissingPointsCaseDataPopulateNrOfFieldsAccordingToNrOfFlights() {
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];
    testCase.Subject = 'flight retro';
    testCase.SuppliedEmail = 'noreply@flysas.com';
    testCase.Description =
      'number-of-flights: 1\nmember-first-name: John\nmember-last-name: Doe\nmember-email: test@exampl.com\n' +
      +'eurobonus-number: 123456789\neurobonus-level: pandion\nflight-1\nflight-1-airline: OO\nflight-1-description: This is a test by Eurobonus Digital Team.\n' +
      +'flight-1-flight-no: 1235\nflight-1-ticket-no: 6675234252525\nflight-1-departure-date: 2021-11-11\nflight-1-departure: ARN\nflight-1-arrival: CPH\n' +
      +'flight-1-ticket-first-name: Gochujang\nflight-1-ticket-last-name: Prinsesstårta\nflight-1-booking-class: A\nflight-1-boarding-number: 15\nflight-1-seat-number: \n';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT
        Flight_Info_Missing_Points_X1__c,
        Flight_Info_Missing_Points_X2__c,
        Flight_Info_Missing_Points_X3__c,
        Flight_Info_Missing_Points_X4__c
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X1__c,
      '<b>Airline</b> :  OO<br>' +
        '<b>Description</b> :  This is a test by Eurobonus Digital Team.<br>' +
        '<b>Flight Nr</b> :  1235<br>' +
        '<b>Ticket Nr</b> :  6675234252525<br>' +
        '<b>Departure Date</b> :  2021-11-11<br>' +
        '<b>Departure</b> :  ARN<br>' +
        '<b>Arrival</b> :  CPH<br>' +
        '<b>First Name</b> :  Gochujang<br>' +
        '<b>Last Name</b> :  Prinsesstårta<br>' +
        '<b>Booking Class</b> :  A<br>' +
        '<b>Boarding Number</b> :  15<br>' +
        '<b>Seat Number</b> : null<br>'
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X2__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X3__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X4__c,
      null
    );
  }

  @IsTest
  static void mergingACaseShouldLockRelatedClaim() {
    Case c = new Case(Status = 'New');
    LIA_Claim__c cl = new LIA_Claim__c();
    insert new List<SObject>{ c, cl };
    c.LIA_Claim__c = cl.Id;
    cl.Case__c = c.Id;
    update new List<SObject>{ c, cl };

    Test.startTest();
    c.Status = 'Merged';
    update c;
    Test.stopTest();

    Case caseAfterUpdate = [SELECT Status FROM Case WHERE Id = :c.Id];

    System.assertEquals(
      'Merged',
      caseAfterUpdate.Status,
      'The case should have been merged.'
    );

    System.assert(Approval.isLocked(cl), 'The related claim should be locked.');
  }

  @IsTest
  static void mergingACaseWithSettlementsShouldThrowAnError() {
    Case c = new Case(Status = 'New');
    LIA_Claim__c cl = new LIA_Claim__c();
    insert new List<SObject>{ c, cl };
    c.LIA_Claim__c = cl.Id;
    cl.Case__c = c.Id;
    Settlement__c s = new Settlement__c(Claim__c = cl.Id);
    upsert new List<SObject>{ c, cl, s };

    DmlException exceptionThrown;

    try {
      c.Status = 'Merged';
      update c;
    } catch (DmlException dmx) {
      exceptionThrown = dmx;
    }

    System.assertNotEquals(
      null,
      exceptionThrown,
      'Should have thrown an exception.'
    );
  }
  @IsTest
  static void claimCaseShouldBeClosedAfterEmailWasSent() {
    Case c = new Case(
      Status = Cases.STATUS_WAITING_FOR_CONTROL,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      InApproval__c = true
    );
    LIA_Claim__c cl = new LIA_Claim__c();
    insert new List<SObject>{ c, cl };
    c.LIA_Claim__c = cl.Id;
    cl.Case__c = c.Id;
    Settlement__c s = new Settlement__c(
      Claim__c = cl.Id,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    EmailMessage e = new EmailMessage(
      Subject = 'Test',
      TextBody = 'This is a test email',
      ToAddress = 'testtest@sas.se',
      FromAddress = 'fromtesttest@sas.se',
      Status = EmailMessages.STATUS_DRAFT,
      ParentId = c.Id
    );
    upsert new List<SObject>{ c, cl, s, e };
    Test.startTest();
    c.Status = Cases.STATUS_WAITING_FOR_TRANSFER;
    update c;
    Test.stopTest();
    Case caseAfterUpdate = [SELECT Status FROM Case WHERE Id = :c.Id];
    System.assertEquals(Cases.STATUS_CLOSED, caseAfterUpdate.Status);
  }
  @IsTest
  static void caseThreadIdShouldBeCorrect() {
    String caseId = '5007T00000K1YJMQA3';
    String threadId = Cases.getThreadId(caseId);

    System.assertEquals(
      'ref:!TESTI0D123.!5007T0K1YJM:ref',
      threadId,
      'Ref Id should match'
    );
  }
  
  @IsTest
  static void caseShouldBeAssignedToAccount() {
    Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EBCustomer').getRecordTypeId();

    List<Account> accountsToCreate = new List<Account>{
      new Account(
        FirstName = 'Test Account ',
        LastName = '1',
        IATA_Number__c = '1',
        recordTypeId = personAccountRTId
      ),
      new Account(
        FirstName = 'Test Account ',
        LastName = '2',
        FCS_EBNumber__c = '1',
        recordTypeId = personAccountRTId
      ),
      new Account(
        FirstName = 'Test Account ',
        LastName = '3',
        PersonMobilePhone = '1',
        recordTypeId = personAccountRTId
      ),
      new Account(
        FirstName = 'Test Account ',
        LastName = '4',
        PersonMobilePhone = '1',
        recordTypeId = personAccountRTId
      ),
      new Account(
        FirstName = 'Test Account ',
        LastName = '5',
        PersonEmail = 'test@email.com',
        recordTypeId = personAccountRTId
      )
    };

    insert accountsToCreate;

    List<Case> casesToCreate = new List<Case>{
      new Case(
        Subject = 'Test Case 1',
        Status = 'New',
        FCS_EBNumber__c = '1'
      ),
      new Case(
        Subject = 'Test Case 2',
        Status = 'New',
        SuppliedPhone = '1'
      ),
      new Case(
        Subject = 'Test Case 3',
        Status = 'New',
        SuppliedEmail = 'test@email.com'
      )
    };

    Test.startTest();
    insert casesToCreate;
    Test.stopTest();

    List<Case> cases = [
      SELECT AccountId
      FROM Case
      WHERE Id IN :casesToCreate
    ];

    for (Case caseRecord : cases) {
      System.assertNotEquals(null, caseRecord.AccountId, 'Case should be assigned to an Account');
    }
  }

  @IsTest
  static void caseShouldBeAssignedToContact() {
    List<Contact> contactsToCreate = new List<Contact>{
      new Contact(
        FirstName = 'Test Contact ',
        LastName = '1',
        MobilePhone = '1'
      ),
      new Contact(
        FirstName = 'Test Contact ',
        LastName = '2',
        Email = 'test@email.com'
      ),
      new Contact(
        FirstName = 'Test Contact ',
        LastName = '3',
        MobilePhone = '3'
      ),
      new Contact(
        FirstName = 'Test Contact ',
        LastName = '4',
        Email = 'test@email.com'
      ),
      new Contact(
        FirstName = 'Test Contact ',
        LastName = '5',
        MobilePhone = '5'
      )
    };

    insert contactsToCreate;

    List<Case> casesToCreate = new List<Case>{
      new Case(
        Subject = 'Test Case 1',
        Status = 'New',
        Origin = 'Phone',
        SuppliedPhone = '1'
      ),
      new Case(
        Subject = 'Test Case 2',
        Status = 'New',
        Origin = 'Email',
        SuppliedEmail = 'test@email.com'
      ),
      new Case(
        Subject = 'Test Case 3',
        Status = 'New',
        Origin = 'Form',
        SuppliedPhone = '3',
        SuppliedFirstName__c = 'Test Contact ',
        SuppliedLastName__c = '3'
      ),
      new Case(
        Subject = 'Test Case 4',
        Status = 'New',
        Origin = 'Form',
        SuppliedEmail = 'test@email.com',
        SuppliedFirstName__c = 'Test Contact ',
        SuppliedLastName__c = '4'
      ),
      new Case(
        Subject = 'Test Case 5',
        Status = 'New',
        Origin = 'Form',
        SuppliedPhone = '5'
      ),
      new Case(
        Subject = 'Test Case 6',
        Status = 'New',
        Origin = 'Form',
        SuppliedEmail = 'test@email.com'
      ),
      // for these cases, the contact should not be found, and it should be created from case data
      new Case(
        Subject = 'Test Case 7',
        Status = 'New',
        Origin = 'Phone',
        SuppliedPhone = '7'
      ),
      new Case(
        Subject = 'Test Case 8',
        Status = 'New',
        Origin = 'Email',
        SuppliedEmail = 'test@emailnotfound.com'
      ),
      new Case(
        Subject = 'Test Case 9',
        Status = 'New',
        Origin = 'Form',
        SuppliedFirstname__c = 'Contact Name ',
        SuppliedLastname__c = 'Not Found'
      )
    };

    Test.startTest();
    insert casesToCreate;
    Test.stopTest();

    List<Case> cases = [
      SELECT ContactId
      FROM Case
      WHERE Id IN :casesToCreate
    ];

    for (Case caseRecord : cases) {
      System.assertNotEquals(null, caseRecord.ContactId, 'Case should be assigned to a Contact');
    }
  }
}
