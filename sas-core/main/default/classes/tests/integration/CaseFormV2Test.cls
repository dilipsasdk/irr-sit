@isTest
private class CaseFormV2Test {
  @IsTest
  public static void shouldCreateClaimCasesWithAllFields() {
    // Add exchange rate for claim expense calculations
    Decimal rate = 10.3;
    Exchange_Rate__c newRate = new Exchange_Rate__c(
      From_Currency__c = 'USD',
      To_Currency__c = 'SEK',
      Rate__c = rate,
      Date__c = Date.valueOf('2022-08-02'),
      Name = 'USD-SEK'
    );

    // Create attachments
    ContentVersion powerOfAttorneyFile = new ContentVersion(
      Title = 'Power of attorney',
      PathOnClient = 'Power of attorney.txt',
      VersionData = Blob.valueOf('Test Content 1'),
      IsMajorVersion = true
    );
    ContentVersion receiptFile1 = new ContentVersion(
      Title = 'Receipt',
      PathOnClient = 'Receipt 1.txt',
      VersionData = Blob.valueOf('Test Content 2'),
      IsMajorVersion = true
    );
    ContentVersion receiptFile2 = new ContentVersion(
      Title = 'Receipt',
      PathOnClient = 'Receipt 2.txt',
      VersionData = Blob.valueOf('Test Content 3'),
      IsMajorVersion = true
    );
    ContentVersion boardingPassFile1 = new ContentVersion(
      Title = 'Boarding pass',
      PathOnClient = 'Boarding pass 1.txt',
      VersionData = Blob.valueOf('Test Content 4'),
      IsMajorVersion = true
    );
    ContentVersion boardingPassFile2 = new ContentVersion(
      Title = 'Boarding pass',
      PathOnClient = 'Boarding pass 2.txt',
      VersionData = Blob.valueOf('Test Content 5'),
      IsMajorVersion = true
    );
    insert new List<SObject>{
      powerOfAttorneyFile,
      receiptFile1,
      receiptFile2,
      boardingPassFile1,
      boardingPassFile2,
      newRate
    };

    // Construct request JSON manually.
    String contactJson =
      '{' +
      '  "type": "private",' +
      '  "companyName": "Test Aktiebolag",' +
      '  "companyCode": "ABC",' +
      '  "firstName": "Test",' +
      '  "lastName": "Testsson",' +
      '  "email": "test@example.com",' +
      '  "phone": "000000000",' +
      '  "address": "Frösundaviks allé 1",' +
      '  "postalCode": "16970",' +
      '  "city": "Solna",' +
      '  "country": "FR",' +
      '  "euroBonusNumber": "000000000"' +
      '}';

    String compensationDetailsJson =
      '{' +
      '  "bankAccountHolderName": "Test Testsson",' +
      '  "bankAccountNumber": "FI0000000000000000",' +
      '  "bankCountry": "FI",' +
      '  "bankName": "S-Pankki",' +
      '  "bankBic": "SBANFIHH",' +
      '  "preferredCurrency": "EUR",' +
      '  "preferredCompensationMethod": "eurobonus",' +
      '  "preferredReimbursementMethod": "monetary",' +
      '  "referenceNumber": "1234567890"' +
      '}';

    String travelersJson =
      '[' +
      '  { "firstName": "Test", "lastName": "Testsson"},' +
      '  { "firstName": "Test", "lastName": "Testsdottir"}' +
      ']';

    String expensesJson =
      '[' +
      '  {' +
      '    "expenseType": "food",' +
      '    "expenseCurrency": "NOK",' +
      '    "amount": 250.55,' +
      '    "contentVersionIds": ["' +
      receiptFile1.Id +
      '"]' +
      '  },' +
      '  {' +
      '    "expenseType": "transportation",' +
      '    "expenseCurrency": "USD",' +
      '    "amount": 399,' +
      '    "contentVersionIds": ["' +
      receiptFile2.Id +
      '"]' +
      '  }' +
      ']';

    String rebookedFlightsJson =
      '[' +
      '  {' +
      '    "departureDate": "2022-02-20",' +
      '    "flightNumber": "SK1",' +
      '    "contentVersionIds": ["' +
      boardingPassFile1.Id +
      '"]' +
      '  },' +
      '  {' +
      '    "departureDate": "2022-02-22",' +
      '    "flightNumber": "SK1000",' +
      '    "contentVersionIds": ["' +
      boardingPassFile2.Id +
      '"]' +
      '  }' +
      ']';

    String claimJson =
      '{' +
      '  "category": "flight-disruptions",' +
      '  "type": "flight-delay-compensation",' +
      '  "delayLength": "2-3",' +
      '  "unaccompaniedMinor": true,' +
      '  "personWithReducedMobility": true,' +
      '  "bookingReference": "TEST12",' +
      '  "departureDate": "2022-03-02",' +
      '  "flightNumber": "SK1234",' +
      '  "passengerIrregularityReportNumber": "TEST13",' +
      '  "comment": "An angry comment.",' +
      '  "travelers": ' +
      travelersJson +
      ',' +
      '  "expenses": ' +
      expensesJson +
      ',' +
      '  "rebookedFlights": ' +
      rebookedFlightsJson +
      '}';

    String input =
      '{' +
      '  "formData": {' +
      '    "type": "claim",' +
      '    "contact": ' +
      contactJson +
      ',' +
      '    "claim": ' +
      claimJson +
      ',' +
      '    "compensationDetails": ' +
      compensationDetailsJson +
      ',' +
      '    "contentVersionIds": ["' +
      powerOfAttorneyFile.Id +
      '"]' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}';

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormJSONV2 requestBody = CaseFormJSONV2.parse(input);
    CaseFormResponse response = CaseFormV2.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin, Department__c
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];

    LIA_Claim__c cl = [
      SELECT
        Id,
        Address_line_1__c,
        Bank_Country__c,
        Country__c,
        Concerns_a_person_with_reduced_mobility__c,
        Concerns_an_unaccompanied_minor__c,
        Currency__c,
        Liability_PNR__c,
        Preferred_Compensation_Method__c,
        Preferred_Reimbursement_Method__c,
        Flight_Date__c,
        Flight_Number__c,
        EU261_Handling_Status__c,
        External_Data_Status__c,
        External_Data_Retrieve_Count__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];

    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertEquals(
      'Customer Claim',
      c.Department__c,
      'Department should be set correctly for Denmark.'
    );
    System.assertEquals(
      'Unhandled',
      cl.EU261_Handling_Status__c,
      'EU261_Handling_Status__c Status should be updated'
    );
    System.assertEquals(
      'Not Started',
      cl.External_Data_Status__c,
      'External_Data_Status__c Should be updated'
    );
    System.assertEquals(
      0,
      cl.External_Data_Retrieve_Count__c,
      'External_Data_Retrieve_Count__c Should be updated to 0'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
    System.assertEquals(
      'Finland',
      cl.Bank_Country__c,
      'Should have set bank country correctly.'
    );
    System.assertEquals(
      'Frösundaviks allé 1',
      cl.Address_line_1__c,
      'Should have set contact address correctly.'
    );
    System.assertEquals(
      'France',
      cl.Country__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      true,
      cl.Concerns_a_person_with_reduced_mobility__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      true,
      cl.Concerns_an_unaccompanied_minor__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'EUR',
      cl.Currency__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'TEST12',
      cl.Liability_PNR__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'EuroBonus Points',
      cl.Preferred_Compensation_Method__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'Monetary',
      cl.Preferred_Reimbursement_Method__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      Date.parse('2022-03-02'),
      cl.Flight_Date__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'SK1234',
      cl.Flight_Number__c,
      'Should have set contact country correctly.'
    );

    List<Claim_Expense__c> expenses = [
      SELECT Amount__c, Currency__c, Type__c, Claim_Expense_Amount_In_SEK__c
      FROM Claim_Expense__c
      WHERE Claim__c = :cl.Id
    ];

    System.assertEquals(
      2,
      expenses.size(),
      'There should be 2 expenses linked to the claim.'
    );

    for (Claim_Expense__c e : expenses) {
      if (e.Type__c == 'transportation') {
        System.assertEquals('USD', e.Currency__c);
        System.assertEquals(399, e.Amount__c);
        System.assertEquals(399 * rate, e.Claim_Expense_Amount_In_SEK__c);
      } else {
        System.assertEquals('NOK', e.Currency__c);
        System.assertEquals(250.55, e.Amount__c);
      }
    }

    List<Customer__c> travellers = [
      SELECT First_Name__c, Last_Name__c
      FROM Customer__c
      WHERE Claim__c = :cl.Id
    ];

    System.assertEquals(
      2,
      travellers.size(),
      'There should be 2 travellers linked to the claim.'
    );

    for (Customer__c cust : travellers) {
      System.assertEquals('Test', cust.First_Name__c);
    }

    List<Claim_Rebooked_Flight__c> rebookedFlights = [
      SELECT Departure_Date__c, Flight_Number__c
      FROM Claim_Rebooked_Flight__c
      WHERE Claim__c = :cl.Id
    ];

    for (Claim_Rebooked_Flight__c f : rebookedFlights) {
      if (f.Flight_Number__c == 'SK0001') {
        System.assertEquals(f.Departure_Date__c, Date.parse('2022-02-20'));
      } else {
        System.assertEquals(f.Departure_Date__c, Date.parse('2022-02-22'));
      }
    }

    System.assertEquals(
      2,
      travellers.size(),
      'There should be 2 rebooked flights linked to the claim.'
    );

    List<ContentDocumentLink> linksToClaim = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :cl.Id
    ];
    System.assertEquals(
      5,
      linksToClaim.size(),
      'There should be 5 files linked to the claim.'
    );

    List<ContentDocumentLink> linksToExpense = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :expenses[0].Id
    ];
    System.assertEquals(
      1,
      linksToExpense.size(),
      'There should be 1 file linked to each expense.'
    );

    List<ContentDocumentLink> linksToRebookedFlight = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :rebookedFlights[0].Id
    ];
    System.assertEquals(
      1,
      linksToRebookedFlight.size(),
      'There should be 1 file linked to each rebooked flight.'
    );

    List<ContentVersion> expenseFileFromQuery = [
      SELECT Title
      FROM ContentVersion
      WHERE ContentDocumentId = :linksToExpense[0].ContentDocumentId
    ];
    System.assertEquals(
      'Receipt',
      expenseFileFromQuery[0].Title,
      'Title for linked file to expense should match receipt file.'
    );

    List<ContentVersion> boardingPassFileFromQuery = [
      SELECT Title
      FROM ContentVersion
      WHERE ContentDocumentId = :linksToRebookedFlight[0].ContentDocumentId
    ];
    System.assertEquals(
      'Boarding pass',
      boardingPassFileFromQuery[0].Title,
      'Title for linked file to rebooked flight should match boarding pass file.'
    );
  }

  @IsTest
  public static void shouldCreateClaimCasesWithMinimalFields() {
    // Construct request JSON manually.
    String contactJson =
      '{' +
      '  "type": "private",' +
      '  "firstName": "Test",' +
      '  "lastName": "Testsson",' +
      '  "email": "test@example.com",' +
      '  "phone": "000000000",' +
      '  "address": "Frösundaviks allé 1",' +
      '  "postalCode": "16970",' +
      '  "city": "Solna",' +
      '  "country": "SE"' +
      '}';

    String compensationDetailsJson =
      '{' +
      '  "preferredCompensationMethod": "voucher"' +
      '}';

    String claimJson =
      '{' +
      '  "category": "accident-and-injury",' +
      '  "type": "other",' +
      '  "delayLength": "2-3",' +
      '  "bookingReference": "TEST12",' +
      '  "departureDate": "2022-03-02",' +
      '  "flightNumber": "SK1234"' +
      '}';

    String input =
      '{' +
      '  "formData": {' +
      '    "type": "claim",' +
      '    "contact": ' +
      contactJson +
      ',' +
      '    "claim": ' +
      claimJson +
      ',' +
      '    "compensationDetails": ' +
      compensationDetailsJson +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}';

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormJSONV2 requestBody = CaseFormJSONV2.parse(input);
    CaseFormResponse response = CaseFormV2.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    // TODO: Check all fields correctly when it's possible.
    LIA_Claim__c cl = [SELECT Id FROM LIA_Claim__c WHERE Case__c = :c.Id];
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
  }

  @IsTest
  public static void shouldCreateBaggageClaimCases() {
    // Construct request JSON manually.
    String contactJson =
      '{' +
      '  "type": "private",' +
      '  "firstName": "Test",' +
      '  "lastName": "Testsson",' +
      '  "email": "test@example.com",' +
      '  "phone": "000000000",' +
      '  "address": "Frösundaviks allé 1",' +
      '  "postalCode": "16970",' +
      '  "city": "Solna",' +
      '  "country": "SE"' +
      '}';

    String compensationDetailsJson =
      '{' +
      '  "preferredCompensationMethod": "voucher"' +
      '}';

    String claimJson =
      '{' +
      '  "category": "baggage",' +
      '  "type": "baggage-delayed",' +
      '  "baggageDelayTime": "less-than-21-days",' +
      '  "bookingReference": "TEST12",' +
      '  "passengerIrregularityReportNumber": "ARNSK12345",' +
      '  "baggagePurchasePrice": 500,' +
      '  "baggagePurchaseYear": 2021,' +
      '  "departureDate": "2022-03-02",' +
      '  "flightNumber": "SK1234"' +
      '}';

    String input =
      '{' +
      '  "formData": {' +
      '    "type": "claim",' +
      '    "contact": ' +
      contactJson +
      ',' +
      '    "claim": ' +
      claimJson +
      ',' +
      '    "compensationDetails": ' +
      compensationDetailsJson +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}';

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormJSONV2 requestBody = CaseFormJSONV2.parse(input);
    CaseFormResponse response = CaseFormV2.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    LIA_Claim__c cl = [
      SELECT
        Id,
        Customer_Claim_Type__c,
        Delay_Length__c,
        Purchase_Price__c,
        Purchase_Year__c,
        EU261_Handling_Status__c,
        External_Data_Status__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
    System.assertEquals(
      'Baggage delayed/lost',
      cl.Customer_Claim_Type__c,
      'Should have set claim type correctly.'
    );
    System.assertEquals(
      'Less than 21 days',
      cl.Delay_Length__c,
      'Should have set delay length correctly.'
    );
    System.assertEquals(
      500,
      cl.Purchase_Price__c,
      'Should have set purchase price correctly.'
    );
    System.assertEquals(
      2021,
      cl.Purchase_Year__c,
      'Should have set purchase year correctly.'
    );
    System.assertEquals(
      null,
      cl.External_Data_Status__c,
      'External Data Status should be null'
    );
    System.assertEquals(
      null,
      cl.EU261_Handling_Status__c,
      'EU261 Handling Status should be null'
    );
  }

  @IsTest
  public static void shouldCreateCompensationCardClaims() {
    // Given
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    // Construct request JSON manually.
    String contactJson =
      '{' +
      '  "type": "private",' +
      '  "firstName": "Test",' +
      '  "lastName": "Testsson",' +
      '  "email": "test@example.com",' +
      '  "phone": "000000000",' +
      '  "address": "Frösundaviks allé 1",' +
      '  "postalCode": "16970",' +
      '  "city": "Solna",' +
      '  "country": "SE"' +
      '}';

    String claimData =
      '{' +
      '  "bookingReference": "TEST12",' +
      '  "compensationCardNumber": "0012345678"' +
      '}';

    String compensationDetailsJson =
      '{' +
      '  "preferredCompensationMethod": "voucher"' +
      '}';

    String input =
      '{' +
      '  "formData": {' +
      '    "type": "denied-boarding", ' +
      '    "claim": ' +
      claimData +
      ',' +
      '    "contact": ' +
      contactJson +
      ',' +
      '    "compensationDetails": ' +
      compensationDetailsJson +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}';

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormJSONV2 requestBody = CaseFormJSONV2.parse(input);
    CaseFormResponse response = CaseFormV2.createCase(requestBody);
    Test.StopTest();

    Case c = [
      SELECT Id, Status
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    LIA_Claim__c cl = [
      SELECT Id, RecordTypeId, Compensation_Card_Number__c, Liability_PNR__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];

    System.assertEquals(
      Claim.getRecordTypeIdByEnum(Claim.RecordType.CompensationCard),
      cl.RecordTypeId,
      'Record type should be set to compensation card.'
    );

    System.assertEquals(
      '0012345678',
      cl.Compensation_Card_Number__c,
      'Compensation Card Number should be set.'
    );

    System.assertEquals(
      'TEST12',
      cl.Liability_PNR__c,
      'Compensation Card Number should be set.'
    );

    System.assertEquals(
      Cases.STATUS_CLOSED,
      c.Status,
      'Case should have been set to closed.'
    );
  }
}
