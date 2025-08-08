/**
 * @author Anton Norell
 * @date 2019-12-05
 * @description Test class for controller FCS_IdentifyCustomerController
 */
@IsTest
private class FCS_IdentifyCustomerController_Test {
  /**
   * Setting up setup objects in setup method
   */
  @TestSetup
  static void createTestData() {
    insert new MessagingChannel(
      DeveloperName = 'FacebookChannel4',
      MasterLabel = 'Facebook4',
      MessagingPlatformKey = '456',
      MessageType = 'Facebook'
    );
    C_Settings.SETTINGS_OVERRIDE = new List<C_GeneralSetting__mdt>{
      new C_GeneralSetting__mdt(
        MasterLabel = 'APIM_Subscription_Key',
        Value__c = 'TESTKEY',
        Group__c = 'APIM'
      )
    };
  }

  /**
   * Asserts that the correct case and fields are retrieved from method in controller.
   */
  @IsTest
  static void shouldReturnRecordDataBasedOnCaseId() {
    Account acc = new Account(
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      LastName = 'Last Name'
    );
    insert acc;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Case originalCase = new Case(
      AccountId = acc.Id,
      FCS_EBNumber__c = '123456789',
      FCS_EBLevel__c = 'S',
      FCS_TPAccountNumber__c = '321'
    );
    insert originalCase;
    Test.stopTest();

    FCS_IdentifyCustomerController.ComponentRecordData retrievedData = FCS_IdentifyCustomerController.getRecordData(
      originalCase.Id
    );

    System.assertNotEquals(null, retrievedData);
    System.assertEquals(
      originalCase.FCS_EBNumber__c,
      retrievedData.euroBonusNumber
    );
    System.assertEquals(acc.Id, retrievedData.accountId);
    System.assertEquals(null, retrievedData.lastRetrievedFromSource);
  }

  /**
   * Asserts that the correct LiveChatTranscript and fields are retrieved from method in controller
   */
  @IsTest
  static void shouldReturnRecordDataBasedOnLiveChatTranscriptId() {
    Account acc = new Account(
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      LastName = 'Last Name'
    );
    insert acc;
    acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc.Id];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Case originalCase = new Case(
      AccountId = acc.Id,
      FCS_EBNumber__c = '123456789',
      FCS_TPAccountNumber__c = '321'
    );
    insert originalCase;
    Test.stopTest();
    LiveChatVisitor visitor = new LiveChatVisitor();
    insert visitor;
    LiveChatTranscript transcript = new LiveChatTranscript(
      LiveChatVisitorId = visitor.Id,
      CaseId = originalCase.Id,
      AccountId = acc.Id,
      ContactId = acc.PersonContactId,
      FCS_EBNumber__c = '123',
      FCS_CODSId__c = '321'
    );
    insert transcript;

    FCS_IdentifyCustomerController.ComponentRecordData retrievedData = FCS_IdentifyCustomerController.getRecordData(
      transcript.Id
    );

    System.assertNotEquals(null, retrievedData);
    System.assertEquals(
      transcript.FCS_EBNumber__c,
      retrievedData.euroBonusNumber
    );
    System.assertEquals(acc.Id, retrievedData.accountId);
    System.assertEquals(transcript.FCS_CODSId__c, retrievedData.codsId);
    System.assertEquals(acc.PersonContactId, retrievedData.personContactId);
    System.assertEquals(null, retrievedData.lastRetrievedFromSource);
  }

  /**
   * Asserts that the correct MessagingSession and fields are retrieved from method in controller
   */
  @IsTest
  static void shouldReturnRecordDataBasedOnMessagingSession() {
    Account acc = new Account(
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      LastName = 'Last Name'
    );
    insert acc;
    acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc.Id];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Case originalCase = new Case(
      AccountId = acc.Id,
      FCS_EBNumber__c = '123456789',
      FCS_TPAccountNumber__c = '321'
    );
    Test.stopTest();
    insert originalCase;
    List<MessagingChannel> messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel4'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123',
      AccountId = acc.Id,
      ContactId = acc.PersonContactId
    );
    insert messagingEndUser1;
    MessagingSession session = new MessagingSession(
      Origin = 'InboundInitiated',
      MessagingEndUserId = messagingEndUser1.Id,
      Status = 'New',
      MessagingChannelId = messagingChannel[0].Id,
      CaseId = originalCase.Id
    );
    insert session;

    FCS_IdentifyCustomerController.ComponentRecordData retrievedData = FCS_IdentifyCustomerController.getRecordData(
      session.Id
    );

    System.assertNotEquals(null, retrievedData);
    System.assertEquals(acc.Id, retrievedData.accountId);
    System.assertEquals(acc.PersonContactId, retrievedData.personContactId);
    System.assertEquals(null, retrievedData.lastRetrievedFromSource);
  }

  /**
   * Asserts that the controller can update a chat transcript record based on a supplied JSON string with record id and data
   */
  @IsTest
  static void shouldUpdateLiveChatTranscriptBasedOnSuppliedJSONData() {
    LiveChatVisitor visitor = new LiveChatVisitor();
    insert visitor;
    LiveChatTranscript transcript = new LiveChatTranscript(
      LiveChatVisitorId = visitor.Id
    );
    insert transcript;

    String jsonData =
      '{"recordId": "' +
      transcript.Id +
      '", "euroBonusNumber": "123"}';
    FCS_IdentifyCustomerController.updateRecordDataWithApex(jsonData);

    System.assertEquals(
      '123',
      [
        SELECT Id, FCS_EBNumber__c
        FROM LiveChatTranscript
        WHERE Id = :transcript.Id
      ]
      .FCS_EBNumber__c,
      'The method did not update the underlying transcript correctly. Expected FCS_EBNumber__ to be updated.'
    );
  }

  /**
   * Asserts that the controller can update a chat transcript record based on a supplied JSON string with,
   * record id and data as well as updating a related case record
   */
  @IsTest
  static void shouldUpdateLiveChatTranscriptAndRelatedRecordsBasedOnSuppliedJSONData() {
    Case originalCase = new Case();
    insert originalCase;
    LiveChatVisitor visitor = new LiveChatVisitor();
    insert visitor;
    LiveChatTranscript transcript = new LiveChatTranscript(
      LiveChatVisitorId = visitor.Id,
      CaseId = originalCase.Id
    );
    insert transcript;

    String jsonData =
      '{"recordId": "' +
      transcript.Id +
      '", "euroBonusNumber": "123", "caseId": "' +
      originalCase.Id +
      '"  }';
    FCS_IdentifyCustomerController.updateRecordDataWithApex(jsonData);

    System.assertEquals(
      '123',
      [
        SELECT Id, FCS_EBNumber__c
        FROM LiveChatTranscript
        WHERE Id = :transcript.Id
      ]
      .FCS_EBNumber__c,
      'The method did not update the underlying transcript correctly. Expected FCS_EBNumber__ to be updated.'
    );
    System.assertEquals(
      '123',
      [SELECT Id, FCS_EBNumber__c FROM Case WHERE Id = :originalCase.Id]
      .FCS_EBNumber__c,
      'The method did not update the related case correctly. Expected FCS_EBNumber__ to be updated.'
    );
  }

  /**
   * Asserts that the controller can update a case record based on a supplied JSON string with record id and data
   */
  @IsTest
  static void shouldUpdateCaseAndRelatedRecordsBasedOnSuppliedJSONData() {
    Case originalCase = new Case();
    insert originalCase;
    LiveChatVisitor visitor = new LiveChatVisitor();
    insert visitor;
    LiveChatTranscript transcript = new LiveChatTranscript(
      LiveChatVisitorId = visitor.Id,
      CaseId = originalCase.Id
    );
    insert transcript;

    String jsonData =
      '{"recordId": "' +
      originalCase.Id +
      '", "euroBonusNumber": "123"}';
    FCS_IdentifyCustomerController.updateRecordDataWithApex(jsonData);

    System.assertEquals(
      '123',
      [SELECT Id, FCS_EBNumber__c FROM Case WHERE Id = :originalCase.Id]
      .FCS_EBNumber__c,
      'The method did not update the underlying case correctly. Expected FCS_EBNumber__ to be updated.'
    );
    System.assertEquals(
      '123',
      [
        SELECT Id, FCS_EBNumber__c
        FROM LiveChatTranscript
        WHERE Id = :transcript.Id
      ]
      .FCS_EBNumber__c,
      'The method did not update the related chat transcript correctly. Expected FCS_EBNumber__ to be updated.'
    );
  }

  /**
   * Asserts that the controller can update a MassagingSession record based on a supplied JSON string with record id and data
   */
  @IsTest
  static void shouldUpdateMessagingSessionAndRelatedRecordsBasedOnSuppliedJSONData() {
    Case originalCase = new Case();
    insert originalCase;
    List<MessagingChannel> messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel4'
    ];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    MessagingSession session = new MessagingSession(
      Origin = 'InboundInitiated',
      MessagingEndUserId = messagingEndUser1.Id,
      Status = 'New',
      MessagingChannelId = messagingChannel[0].Id,
      CaseId = originalCase.Id
    );
    insert session;

    Account account = new Account(
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      LastName = 'Name'
    );
    insert account;

    String jsonData =
      '{"recordId": "' +
      session.Id +
      '", "euroBonusNumber": "123", "caseId": "' +
      originalCase.Id +
      '", "accountId": "' +
      account.Id +
      '"}';
    FCS_IdentifyCustomerController.updateRecordDataWithApex(jsonData);

    System.assertEquals(
      '123',
      [
        SELECT Id, AccountId, FCS_EBNumber__c
        FROM Case
        WHERE Id = :originalCase.Id
      ]
      .FCS_EBNumber__c,
      'The method did not update the related case correctly. Expected EBNumber__ to be updated.'
    );
    System.assertEquals(
      account.Id,
      [
        SELECT Id, EndUserAccountId, MessagingEndUser.AccountId
        FROM MessagingSession
        WHERE Id = :session.Id
      ]
      .MessagingEndUser.AccountId,
      'The method did not update the related End User Account correctly. Expected AccountId to be updated.'
    );
  }

  /**
   * Asserts that the controller maps information from a frequent flyer record to an account record correctly.
   * Checks both valid values and null values.
   */
  @IsTest
  static void shouldReturnAccountBasedOnFrequentFlyer() {
    FCS_FrequentFlyer__x ff = new FCS_FrequentFlyer__x(
      ExternalId = '123',
      AddressLine1__c = 'AddressLine1',
      City__c = 'City',
      ZipCode__c = 'ZipCode',
      CountryCode__c = 'Country',
      CountyState__c = 'State',
      BirthDate__c = String.valueOf(Date.today().addYears(-2)),
      ConsentEmail__c = true,
      ConsentEB__c = false,
      ConsentSMS__c = true,
      ConsentEB0__c = false,
      ConsentTelemarketing__c = true,
      EmailPersonal__c = 'email@email.com',
      EBLevel__c = null,
      EBNumber__c = '321',
      FirstName__c = 'First Name',
      Gender__c = 'F',
      LastName__c = 'Last Name',
      EBMemberSinceDate__c = null,
      Mobile__c = '0701234567',
      Phone__c = null,
      SubscriptionId__c = null,
      TPAccountNumber__c = '678',
      CompanyName__c = 'Company Name',
      CMP__c = '123',
      MiddleName__c = 'Middle',
      Salutation__c = 'Salutation',
      Title__c = 'Title'
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Account account = FCS_IdentifyCustomerController.createAccountRecordBasedOnFrequentFlyers(
      new List<FCS_FrequentFlyer__x>{ ff }
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      account,
      'Method did not return expected account'
    );
    System.assertEquals(
      C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      account.RecordTypeId
    );
    System.assertEquals(ff.ExternalId, account.FCS_FrequentFlyer__c);
    System.assertEquals(ff.AddressLine1__c, account.PersonMailingStreet);
    System.assertEquals(ff.City__c, account.PersonMailingCity);
    System.assertEquals(ff.ZipCode__c, account.PersonMailingPostalCode);
    System.assertEquals(ff.CountryCode__c, account.PersonMailingCountry);
    System.assertEquals(ff.CountyState__c, account.PersonMailingState);
    System.assertEquals(Date.valueOf(ff.BirthDate__c), account.PersonBirthdate);
    System.assertEquals(ff.ConsentEmail__c, account.FCS_ConsentEmail__c);
    System.assertEquals(ff.ConsentEB__c, account.FCS_ConsentEuroBonus__c);
    System.assertEquals(ff.ConsentEB0__c, account.FCS_ConsentSiteProfile__c);
    System.assertEquals(ff.ConsentSMS__c, account.FCS_ConsentSMS__c);
    System.assertEquals(
      ff.ConsentTelemarketing__c,
      account.FCS_ConsentTelemarketing__c
    );
    System.assertEquals(ff.EmailPersonal__c, account.PersonEmail);
    System.assertEquals(ff.EBLevel__c, account.FCS_EBLevel__c);
    System.assertEquals(ff.EBNumber__c, account.FCS_EBNumber__c);
    System.assertEquals(ff.FirstName__c, account.FirstName);
    System.assertEquals(ff.Gender__c, account.FCS_Gender__c);
    System.assertEquals(ff.LastName__c, account.LastName);
    System.assertEquals(null, account.FCS_EBMemberSinceDate__c);
    System.assertEquals(ff.SubscriptionId__c, account.FCS_SubscriptionId__c);
    System.assertEquals(ff.TPAccountNumber__c, account.FCS_TPAccountNumber__c);
    System.assertEquals(ff.CompanyName__c, account.FCS_CompanyName__c);
    System.assertEquals(ff.CMP__c, account.FCS_CMP__c);
    System.assertEquals(ff.Title__c, account.PersonTitle);
    System.assertEquals(ff.Salutation__c, account.Salutation);
    System.assertEquals(ff.MiddleName__c, account.MiddleName);
    System.assert(
      account.FCS_LastRetrievedFromSource__c > DateTime.now().addMinutes(-5) &&
        account.FCS_LastRetrievedFromSource__c < DateTime.now().addMinutes(5)
    );
  }
  @IsTest
  static void shouldReturnAccountBasedOnFrequentFlyerForSASInternalUser() {
    FCS_FrequentFlyer__x ff = new FCS_FrequentFlyer__x(
      ExternalId = '123',
      AddressLine1__c = 'AddressLine1',
      City__c = 'City',
      ZipCode__c = 'ZipCode',
      CountryCode__c = 'Country',
      CountyState__c = 'State',
      BirthDate__c = String.valueOf(Date.today().addYears(-2)),
      ConsentEmail__c = true,
      ConsentEB__c = false,
      ConsentSMS__c = true,
      ConsentEB0__c = false,
      ConsentTelemarketing__c = true,
      EmailPersonal__c = 'email@sas.se',
      EBLevel__c = null,
      EBNumber__c = '321',
      FirstName__c = 'First Name',
      Gender__c = 'F',
      LastName__c = 'Last Name',
      EBMemberSinceDate__c = null,
      Mobile__c = '0701234567',
      Phone__c = null,
      SubscriptionId__c = null,
      TPAccountNumber__c = '678',
      CompanyName__c = 'Company Name',
      CMP__c = '123',
      MiddleName__c = 'Middle',
      Salutation__c = 'Salutation',
      Title__c = 'Title'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    Account account = FCS_IdentifyCustomerController.createAccountRecordBasedOnFrequentFlyers(
      new List<FCS_FrequentFlyer__x>{ ff }
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      account,
      'Method did not return expected account'
    );
    System.assertEquals(
      C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      account.RecordTypeId
    );
    System.assertEquals(ff.ExternalId, account.FCS_FrequentFlyer__c);
    System.assertEquals(ff.AddressLine1__c, account.PersonMailingStreet);
    System.assertEquals(ff.City__c, account.PersonMailingCity);
    System.assertEquals(ff.ZipCode__c, account.PersonMailingPostalCode);
    System.assertEquals(ff.CountryCode__c, account.PersonMailingCountry);
    System.assertEquals(ff.CountyState__c, account.PersonMailingState);
    System.assertEquals(Date.valueOf(ff.BirthDate__c), account.PersonBirthdate);
    System.assertEquals(ff.ConsentEmail__c, account.FCS_ConsentEmail__c);
    System.assertEquals(ff.ConsentEB__c, account.FCS_ConsentEuroBonus__c);
    System.assertEquals(ff.ConsentEB0__c, account.FCS_ConsentSiteProfile__c);
    System.assertEquals(ff.ConsentSMS__c, account.FCS_ConsentSMS__c);
    System.assertEquals(
      ff.ConsentTelemarketing__c,
      account.FCS_ConsentTelemarketing__c
    );
    System.assertEquals(null, account.PersonEmail);
    System.assertEquals(ff.EBLevel__c, account.FCS_EBLevel__c);
    System.assertEquals(ff.EBNumber__c, account.FCS_EBNumber__c);
    System.assertEquals(ff.FirstName__c, account.FirstName);
    System.assertEquals(ff.Gender__c, account.FCS_Gender__c);
    System.assertEquals(ff.LastName__c, account.LastName);
    System.assertEquals(null, account.FCS_EBMemberSinceDate__c);
    System.assertEquals(ff.SubscriptionId__c, account.FCS_SubscriptionId__c);
    System.assertEquals(ff.TPAccountNumber__c, account.FCS_TPAccountNumber__c);
    System.assertEquals(ff.CompanyName__c, account.FCS_CompanyName__c);
    System.assertEquals(ff.CMP__c, account.FCS_CMP__c);
    System.assertEquals(ff.Title__c, account.PersonTitle);
    System.assertEquals(ff.Salutation__c, account.Salutation);
    System.assertEquals(ff.MiddleName__c, account.MiddleName);
    System.assert(
      account.FCS_LastRetrievedFromSource__c > DateTime.now().addMinutes(-5) &&
        account.FCS_LastRetrievedFromSource__c < DateTime.now().addMinutes(5)
    );
  }

  /**
   * Asserts that an account record is inserted based on a provided Frequent Flyer record provided to controller
   */
  @IsTest
  static void shouldInsertBasedOnFrequentFlyer() {
    FCS_FrequentFlyer__x ff = new FCS_FrequentFlyer__x(
      ExternalId = '123',
      AddressLine1__c = 'AddressLine1',
      City__c = 'City',
      ZipCode__c = 'ZipCode',
      CountryCode__c = 'Country',
      CountyState__c = 'State',
      BirthDate__c = String.valueOf(Date.today().addYears(-2)),
      ConsentEmail__c = true,
      ConsentEB__c = false,
      ConsentSMS__c = true,
      ConsentEB0__c = false,
      ConsentTelemarketing__c = true,
      EmailPersonal__c = 'email@email.com',
      EBLevel__c = null,
      EBNumber__c = '321',
      FirstName__c = 'First Name',
      Gender__c = 'F',
      LastName__c = 'Last Name',
      EBMemberSinceDate__c = null,
      Mobile__c = '0701234567',
      Phone__c = null,
      SubscriptionId__c = null,
      TPAccountNumber__c = '678',
      CompanyName__c = 'Company Name',
      CMP__c = '123',
      MiddleName__c = 'Middle',
      Salutation__c = 'Salutation',
      Title__c = 'Title'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    FCS_IdentifyCustomerController.createAccountRecordBasedOnFrequentFlyers(
      new List<FCS_FrequentFlyer__x>{ ff }
    );
    Test.stopTest();

    System.assertEquals(
      1,
      [SELECT Id FROM Account].size(),
      'Expected 1 account to be inserted based on Frequent Flyer'
    );
  }

  /**
   * Asserts that the controller can handle an empty return when querying for Frequent Flyer
   */
  @IsTest
  static void shouldReturnNullIfFrequentFlyerListIfEmpty() {
    Account account = FCS_IdentifyCustomerController.createAccountRecordBasedOnFrequentFlyers(
      new List<FCS_FrequentFlyer__x>()
    );

    System.assertEquals(null, account);
  }

  /**
   * Asserts that en exception is thrown if component is placed on an unsupported object
   */
  @IsTest
  static void shouldThrowExceptionIfNotSupportedObject() {
    Opportunity opp = new Opportunity(
      Name = 'Name',
      StageName = 'New',
      CloseDate = Date.today()
    );
    insert opp;

    FCS_IdentifyCustomerController.IdentifyCustomerComponentException catchedException;
    try {
      FCS_IdentifyCustomerController.getRecordData(opp.Id);
    } catch (FCS_IdentifyCustomerController.IdentifyCustomerComponentException e) {
      catchedException = e;
    }

    System.assertNotEquals(
      null,
      catchedException,
      'Expected exception for unsupported object. Check that object is still unsupported.'
    );
  }

  @IsTest
  static void findCustomerShouldNotFetchAccountForSASEmails() {
    Account account = FCS_IdentifyCustomerController.findCustomer(
      'EmailPersonal__c',
      'test@sas.se'
    );
    System.assertEquals(
      null,
      account,
      'SAS emails should not cause a fetch for an account.'
    );
  }

  /*
    @IsTest
    static void shouldThrowExceptionDueToUnsupportedExternalObjectQuery(){
        Exception returnedException;
        try{
            Account account = FCS_IdentifyCustomerController.findCustomer('FCS_EBNumber__c', '700001423');

        } catch (QueryException e){
            returnedException = e;
        }
        System.assertNotEquals(null, returnedException, 'Expected a QueryException to be thrown');
        System.assertEquals('entity type FCS_FrequentFlyer__x does not support query',
                returnedException.getMessage(),
                'Expected the exception to contain another message. Check that used query is not malformed. '
        );
    }*/

  /**
   * Asserts that the query for the external object Frequent Flyer can run correctly. As external object queries
   * are not supported in test context, the test should return a null result.
   */
  /*
    @IsTest
    static void shouldReturnNullResultDueToNoSupportForQuery(){
        Account account = FCS_IdentifyCustomerController.findCustomer('FCS_EBNumber__c', '700001423');

        System.assertEquals(null, account);
    }
*/
  /**
   * Asserts that the query for the external object Frequent Flyer can run correctly. As external object queries
   * are not supported in test context, the test catches the expected exception and verifies the message.
   */
}
