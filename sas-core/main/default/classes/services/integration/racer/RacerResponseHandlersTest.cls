@IsTest
public class RacerResponseHandlersTest {
  @IsTest
  public static void successfullL1ResponseShouldMarkSettlementsAsDelivered() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String L1FileContents =
      '01/28/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L1|46|ACCEPTED||ID0000\n' +
      '01/28/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L1|105|ACCEPTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAINL1_TEST.txt',
      Title = 'SF_PAINL1_TEST',
      VersionData = Blob.valueOf(L1FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c, Date_of_Payment__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c, Date_of_Payment__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c, Date_of_Payment__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as accepted by Bank because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_DONE,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as accepted by Bank because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be marked as accepted by Bank as it has not been processed.'
    );
    System.assertEquals(
      '2022-01-28 01:00:00',
      String.valueOfGMT(relevantSettlement1Afterwards.Date_of_Payment__c),
      'Date Of Payment should be in proper format for Settlement 1 because file has been processed successfully.'
    );
    System.assertEquals(
      null,
      irrelevantSettlementAfterwards.Date_of_Payment__c,
      'Date Of Payment should be null for Settlement 3 as it has not been processed .'
    );
  }

  @IsTest
  public static void failedL1ResponseShouldMarkSettlementsAsFailed() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String L1FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L1|46|REJECTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L1|105|REJECTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAINL1_TEST.txt',
      Title = 'SF_PAINL1_TEST',
      VersionData = Blob.valueOf(L1FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_BANK,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as rejected by bank.'
    );
    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_BANK,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as rejected by bank.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified as the file has not been processed.'
    );
  }

  @IsTest
  public static void itShouldBeAbleToHandleL2FilesWithSeveralErrors() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );
    Settlement__c irrelevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = paymentFileName1
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement1,
      irrelevantSettlement2
    };

    Settlement_Item__c itemPending = new Settlement_Item__c(
      Settlement__c = relevantSettlement1.Id,
      Status__c = SettlementItems.STATUS_PENDING_L1_CONFIRMATION
    );

    Settlement_Item__c itemAlreadySentToRacer = new Settlement_Item__c(
      Settlement__c = relevantSettlement1.Id,
      Status__c = SettlementItems.STATUS_SENT_TO_RACER
    );

    insert new List<SObject>{ itemPending, itemAlreadySentToRacer };

    String s1Name = [
      SELECT NAME
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ]
    .Name;
    String s2Name = [
      SELECT NAME
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ]
    .Name;

    String error1 = 'ERR1';
    String error2 = 'ERR2';
    String L2FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L2|ID000/OTH' +
      s1Name +
      '|1114|000000000000|SAS SF OTH|DK BANK TRANSFER|RJCT|NARR|ErrorOnAllCounterParties|5968|DKK|22-JAN-01|Name Name|RJCT|AC03|' +
      error1 +
      '\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L2|ID000/SE' +
      s2Name +
      '|1114|000000000000|SAS SF OTH|DK BANK TRANSFER|RJCT|NARR|ErrorOnAllCounterParties|5968|DKK|22-JAN-01|Name Name|RJCT|AC03|' +
      error2;

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAINL2_TEST.txt',
      Title = 'SF_PAINL2_TEST',
      VersionData = Blob.valueOf(L2FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlement1Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement1.Id
    ];
    Settlement__c irrelevantSettlement2Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement2.Id
    ];
    Settlement_Item__c pendingItemAfterwards = [
      SELECT Id, Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Id = :itemPending.Id
    ];
    Settlement_Item__c sentToRacerItemAfterwards = [
      SELECT Id, Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Id = :itemAlreadySentToRacer.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as having errors.'
    );
    System.assertEquals(
      Settlements.STATUS_FAILED,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as having errors.'
    );
    System.assertEquals(
      Settlements.STATUS_DONE,
      irrelevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement within a different payment should not be modified'
    );
    System.assertEquals(
      Settlements.STATUS_DONE,
      irrelevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement within same payment file, but without errors, should not be modified'
    );
    System.assertEquals(
      error1,
      relevantSettlement1Afterwards.Error_Message__c,
      'Settlement 1 should have correct error message.'
    );
    System.assertEquals(
      error2,
      relevantSettlement2Afterwards.Error_Message__c,
      'Settlement 2 should have correct error message.'
    );
    System.assertEquals(
      null,
      irrelevantSettlement1Afterwards.Error_Message__c,
      'Settlement 3 should have no error message.'
    );
    System.assertEquals(
      null,
      irrelevantSettlement2Afterwards.Error_Message__c,
      'Settlement 4 should have no error message.'
    );
    System.assertEquals(
      SettlementItems.STATUS_SETTLEMENT_FAILED,
      pendingItemAfterwards.Status__c,
      'Draft item status should be updated to Settlement failed.'
    );
    System.assertEquals(
      null,
      pendingItemAfterwards.Date_Of_Accounting__c,
      'Draft item status should be updated to Settlement failed.'
    );
    System.assertEquals(
      SettlementItems.STATUS_SENT_TO_RACER,
      sentToRacerItemAfterwards.Status__c,
      'Draft item status should be updated to Settlement failed.'
    );
    System.assertEquals(
      null,
      sentToRacerItemAfterwards.Date_Of_Accounting__c,
      'Draft item status should be updated to Settlement failed.'
    );
  }

  @IsTest
  public static void paymulResponseShouldMarkSettlementsAsDelivered() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String PaymulFileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|PAYMUL|368|PROCESSED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|PAYMUL|368|PROCESSED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAYMUL_TEST.txt',
      Title = 'SF_PAYMUL_TEST',
      VersionData = Blob.valueOf(PaymulFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as accepted by Racer because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as accepted by Racer because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be marked as accepted by Racer as it has not been processed.'
    );
  }

  @IsTest
  public static void paymulResponseShouldHandleFailures() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String PaymulFileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|PAYMUL|368|REJECTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|PAYMUL|368|REJECTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAYMUL_TEST.txt',
      Title = 'SF_PAYMUL_TEST',
      VersionData = Blob.valueOf(PaymulFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_RACER,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_RACER,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified as it has not been processed.'
    );
  }

  @IsTest
  public static void receivingGLSuccessFileShouldMarkSettlementItemsAsDone() {
    // Given
    String accountingFileName = 'TestAccountingFile.caresek';
    String irrelevantAccountingFileName = 'IrrelevantAccountingFile.txt';
    String GLFileContents =
      '12/23/2021 05:23:21|' +
      accountingFileName +
      '|RACERGL|63|PROCESSED|Successfull Completion.Data File moved to archive folder.|';

    Settlement__c settlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK
    );

    insert new List<SObject>{ settlement };

    Settlement_Item__c item1 = new Settlement_Item__c(
      Accounting_File_Name__c = accountingFileName,
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = settlement.Id,
      Status__c = SettlementItems.STATUS_SENT_TO_RACER,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    Settlement_Item__c item2 = new Settlement_Item__c(
      Accounting_File_Name__c = accountingFileName,
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = settlement.Id,
      Status__c = SettlementItems.STATUS_SENT_TO_RACER,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    Settlement_Item__c item3 = new Settlement_Item__c(
      Accounting_File_Name__c = irrelevantAccountingFileName,
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = settlement.Id,
      Status__c = SettlementItems.STATUS_SENT_TO_RACER,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    insert new List<SObject>{ item1, item2, item3 };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_RACERGL_TEST.txt',
      Title = 'SF_RACERGL_TEST',
      VersionData = Blob.valueOf(GLFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement_Item__c item1Afterwards = [
      SELECT Id, Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Id = :item1.Id
    ];
    Settlement_Item__c item2Afterwards = [
      SELECT Id, Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Id = :item2.Id
    ];
    Settlement_Item__c item3Afterwards = [
      SELECT Id, Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Id = :item3.Id
    ];

    System.assertEquals(
      SettlementItems.STATUS_DONE,
      item1Afterwards.Status__c,
      'Settlement item 1 should be marked as waiting for transfer.'
    );
    System.assertEquals(
      SettlementItems.STATUS_DONE,
      item2Afterwards.Status__c,
      'Settlement item 2 should be marked as waiting for transfer.'
    );
    System.assertEquals(
      SettlementItems.STATUS_SENT_TO_RACER,
      item3Afterwards.Status__c,
      'Settlement item 3 should not be modified as it was sent in a different file.'
    );

    Datetime parsedDatetime = DateUtils.convertRACERDateToDatetime(
      '12/23/2021 05:23:21'
    );

    System.assertEquals(
      parsedDatetime,
      item1Afterwards.Date_Of_Accounting__c,
      'Settlement item 1 should have the date if processing as date of accounting.'
    );
    System.assertEquals(
      parsedDatetime,
      item2Afterwards.Date_Of_Accounting__c,
      'Settlement item 2 should have the date if processing as date of accounting.'
    );
    System.assertEquals(
      null,
      item3Afterwards.Date_Of_Accounting__c,
      'Settlement item 3 should not have a date of accounting.'
    );
  }

  @IsTest
  public static void receivingL1SuccessShouldMoveSettlementsItemsToWaitingForTransfer() {
    // Given
    String accountingFileName1 = 'TestAccountingFile1.caresek';
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';

    String L1FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L1|46|ACCEPTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L1|105|ACCEPTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    Settlement_Item__c item1 = new Settlement_Item__c(
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = relevantSettlement1.Id,
      Status__c = SettlementItems.STATUS_PENDING_L1_CONFIRMATION,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    Settlement_Item__c item2 = new Settlement_Item__c(
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = relevantSettlement2.Id,
      Status__c = SettlementItems.STATUS_PENDING_L1_CONFIRMATION,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    Settlement_Item__c item3 = new Settlement_Item__c(
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = relevantSettlement2.Id,
      Status__c = SettlementItems.STATUS_PENDING_L1_CONFIRMATION,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    Settlement_Item__c item4 = new Settlement_Item__c(
      Amount__c = 100,
      Currency__c = 'SEK',
      Cost_Account__c = '6738',
      Cost_Center__c = '90801',
      Customer_Name__c = 'Test Testsson',
      Settlement__c = irrelevantSettlement.Id,
      Status__c = SettlementItems.STATUS_PENDING_L1_CONFIRMATION,
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );

    insert new List<SObject>{ item1, item2, item3, item4 };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'SF_PAINL1_TEST.txt',
      Title = 'SF_PAINL1_TEST',
      VersionData = Blob.valueOf(L1FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement_Item__c item1Afterwards = [
      SELECT Id, Status__c
      FROM Settlement_Item__c
      WHERE Id = :item1.Id
    ];
    Settlement_Item__c item2Afterwards = [
      SELECT Id, Status__c
      FROM Settlement_Item__c
      WHERE Id = :item2.Id
    ];
    Settlement_Item__c item3Afterwards = [
      SELECT Id, Status__c
      FROM Settlement_Item__c
      WHERE Id = :item3.Id
    ];
    Settlement_Item__c item4Afterwards = [
      SELECT Id, Status__c
      FROM Settlement_Item__c
      WHERE Id = :item4.Id
    ];

    System.assertEquals(
      SettlementItems.STATUS_WAITING_FOR_TRANSFER,
      item1Afterwards.Status__c,
      'Settlement item 1 should be marked as waiting for transfer.'
    );
    System.assertEquals(
      SettlementItems.STATUS_WAITING_FOR_TRANSFER,
      item2Afterwards.Status__c,
      'Settlement item 2 should be marked as waiting for transfer.'
    );
    System.assertEquals(
      SettlementItems.STATUS_WAITING_FOR_TRANSFER,
      item3Afterwards.Status__c,
      'Settlement item 3 should be marked as waiting for transfer.'
    );
    System.assertEquals(
      SettlementItems.STATUS_PENDING_L1_CONFIRMATION,
      item4Afterwards.Status__c,
      'Settlement item 4 should not be modified as its settlement has not been processed.'
    );
  }
}
