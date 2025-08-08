@IsTest
public with sharing class Settlements_IntegrationTest {
  @IsTest
  public static void accountingFilesShouldBeCreatedCorrectly() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'SEK',
      Payment_Run_Id__c = 1000
    );
    Settlement__c settlement1 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c settlement2 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1B1B',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c settlement3 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 120,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{ counter, settlement1, settlement2, settlement3 };

    Settlement_Item__c settlementItemToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude2 = new Settlement_Item__c(
      Amount__c = 60,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude3 = new Settlement_Item__c(
      Amount__c = 70,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude4 = new Settlement_Item__c(
      Amount__c = 120,
      Net_Amount_After_Deductible__c = 50,
      Cost_Center__c = '90801',
      Is_Insured__c = true,
      Cost_Account__c = '6741',
      Currency__c = 'SEK',
      Settlement__c = settlement3.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemNotToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Pending L1 confirmation',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemNotToInclude2 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'NOK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude5 = new Settlement_Item__c(
      Amount__c = 70,
      Cost_Center__c = '71470',
      Cost_Account__c = '6740',
      Currency__c = 'SEK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.Emergency
      )
    );
    insert new List<SObject>{
      settlementItemToInclude1,
      settlementItemToInclude2,
      settlementItemToInclude3,
      settlementItemToInclude4,
      settlementItemToInclude5,
      settlementItemNotToInclude1,
      settlementItemNotToInclude2
    };

    // When
    Test.startTest();
    SettlementService.createAccountingFile(
      AccountingFileBuilder.PaymentCurrency.SEK
    );
    Test.stopTest();

    //Then
    Settlement_Item__c settlementItemToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude1.Id
    ];
    Settlement_Item__c settlementItemToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude2.Id
    ];
    Settlement_Item__c settlementItemToInclude3Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude3.Id
    ];
    Settlement_Item__c settlementItemToInclude4Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude4.Id
    ];
    Settlement_Item__c settlementItemToInclude5Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude5.Id
    ];
    Settlement_Item__c settlementItemNotToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude1.Id
    ];
    Settlement_Item__c settlementItemNotToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude2.Id
    ];

    String expectedFileTitle =
      'a501' +
      String.valueOf(Date.today().dayOfYear()).leftPad(3, '0') +
      '0' +
      Datetime.now().format('yyyyMMdd') +
      counter.Accounting_Verification_Number__c +
      '.sfsek';

    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude5Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude1Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude2Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude3Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );

    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude1Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );
    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude2Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );
    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude3Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );

    System.assertEquals(
      'Pending L1 confirmation',
      settlementItemNotToInclude1Afterwards.Status__c,
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude1Afterwards.Accounting_File_Name__c
      ),
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assertEquals(
      'Waiting for transfer',
      settlementItemNotToInclude2Afterwards.Status__c,
      'Settlement item in different currency should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude2Afterwards.Accounting_File_Name__c
      ),
      'Settlement item in different currency should not be modified.'
    );

    ContentVersion createdFile = [
      SELECT Id, Title, VersionData
      FROM ContentVersion
      WHERE Title = :expectedFileTitle
    ];

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerAccountingFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{PR}', Datetime.now().format('yyMM'))
      .replace('{-S1NAME---}', settlementItemToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', settlementItemToInclude2Afterwards.Name)
      .replace('{-S3NAME---}', settlementItemToInclude3Afterwards.Name)
      .replace('{-S4NAME---}', settlementItemToInclude4Afterwards.Name)
      .replace('{-S5NAME---}', settlementItemToInclude5Afterwards.Name);

    // TODO: Fix reconciliation reference date.
    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlement Items are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     *
     * This is also why the example file template has wrong spacing for the
     * debit lines.
     */

    System.assertEquals(
      comparisonText,
      createdFile.VersionData.toString(),
      'Created payment file contents should match example file.'
    );

    Racer_Integration_Counter__c counterAfterwards = [
      SELECT Id, Accounting_Verification_Number__c, Payment_Run_Id__c
      FROM Racer_Integration_Counter__c
      WHERE Id = :counter.Id
    ];

    System.assertEquals(
      10001,
      counterAfterwards.Accounting_Verification_Number__c,
      'Accounting verification number should be incremented afterwards.'
    );
    System.assertEquals(
      1000,
      counterAfterwards.Payment_Run_Id__c,
      'Run Id should not be incremented after file creation.'
    );
  }

  @IsTest
  public static void othAccountingFilesShouldBeCreatedCorrectly() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'OTH',
      Payment_Run_Id__c = 1000
    );
    Settlement__c settlement1 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'JAPAN',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Country__c = 'JAPAN',
      Currency__c = 'JPY',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'JP0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c settlement2 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Germany',
      BIC_Swift__c = 'AAAAAAB1B1B',
      City__c = 'Stockholm',
      Country__c = 'Germany',
      Currency__c = 'EUR',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'DE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c settlement3 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 120,
      Bank_Country__c = 'Switzerland',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'CHF',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'CH0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{ counter, settlement1, settlement2, settlement3 };

    Settlement_Item__c settlementItemToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'JPY',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude2 = new Settlement_Item__c(
      Amount__c = 60,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'JPY',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude3 = new Settlement_Item__c(
      Amount__c = 70,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'EUR',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude4 = new Settlement_Item__c(
      Amount__c = 120,
      Net_Amount_After_Deductible__c = 50,
      Cost_Center__c = '90801',
      Is_Insured__c = true,
      Cost_Account__c = '6741',
      Currency__c = 'CHF',
      Settlement__c = settlement3.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemNotToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'JPY',
      Settlement__c = settlement1.Id,
      Status__c = 'Pending L1 confirmation',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemNotToInclude2 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Center__c = '90801',
      Cost_Account__c = '6727',
      Currency__c = 'NOK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.DefaultRecordType
      )
    );
    Settlement_Item__c settlementItemToInclude5 = new Settlement_Item__c(
      Amount__c = 70,
      Cost_Center__c = '71470',
      Cost_Account__c = '6740',
      Currency__c = 'EUR',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer',
      RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
        SettlementItem.RecordType.Emergency
      )
    );
    insert new List<SObject>{
      settlementItemToInclude1,
      settlementItemToInclude2,
      settlementItemToInclude3,
      settlementItemToInclude4,
      settlementItemToInclude5,
      settlementItemNotToInclude1,
      settlementItemNotToInclude2
    };

    // When
    Test.startTest();
    SettlementService.createAccountingFile(
      AccountingFileBuilder.PaymentCurrency.OTH
    );
    Test.stopTest();

    //Then
    Settlement_Item__c settlementItemToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude1.Id
    ];
    Settlement_Item__c settlementItemToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude2.Id
    ];
    Settlement_Item__c settlementItemToInclude3Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude3.Id
    ];
    Settlement_Item__c settlementItemToInclude4Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude4.Id
    ];
    Settlement_Item__c settlementItemToInclude5Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude5.Id
    ];
    Settlement_Item__c settlementItemNotToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude1.Id
    ];
    Settlement_Item__c settlementItemNotToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude2.Id
    ];

    String expectedFileTitle =
      'a501' +
      String.valueOf(Date.today().dayOfYear()).leftPad(3, '0') +
      '0' +
      Datetime.now().format('yyyyMMdd') +
      counter.Accounting_Verification_Number__c +
      '.sfoth';

    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude5Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude1Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude2Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude3Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );

    System.assertEquals(
      'Pending L1 confirmation',
      settlementItemNotToInclude1Afterwards.Status__c,
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude1Afterwards.Accounting_File_Name__c
      ),
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assertEquals(
      'Waiting for transfer',
      settlementItemNotToInclude2Afterwards.Status__c,
      'Settlement item in different currency should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude2Afterwards.Accounting_File_Name__c
      ),
      'Settlement item in different currency should not be modified.'
    );

    ContentVersion createdFile = [
      SELECT Id, Title, VersionData
      FROM ContentVersion
      WHERE Title = :expectedFileTitle
    ];

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerAccountingOTHFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{PR}', Datetime.now().format('yyMM'))
      .replace('{-S1NAME---}', settlementItemToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', settlementItemToInclude2Afterwards.Name)
      .replace('{-S3NAME---}', settlementItemToInclude3Afterwards.Name)
      .replace('{-S4NAME---}', settlementItemToInclude4Afterwards.Name)
      .replace('{-S5NAME---}', settlementItemToInclude5Afterwards.Name);

    // TODO: Fix reconciliation reference date.
    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlement Items are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     *
     * This is also why the example file template has wrong spacing for the
     * debit lines.
     */

    System.assertEquals(
      comparisonText,
      createdFile.VersionData.toString(),
      'Created payment file contents should match example file.'
    );
  }

  @IsTest
  public static void paymentFilesShouldBeCreatedCorrectly() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'SEK',
      Payment_Run_Id__c = 1000
    );
    Settlement__c sekToInclude1 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 400,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c sekToInclude2 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 500,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c sekNotToInclude = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 500,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );
    Settlement__c nokSettlement = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Norway',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{
      counter,
      sekToInclude1,
      sekToInclude2,
      sekNotToInclude,
      nokSettlement
    };

    // When
    Test.startTest();
    SettlementService.createPaymentFile(PaymentFileBuilder.PaymentCurrency.SEK);
    Test.stopTest();

    // Then
    Settlement__c sekToInclude1Afterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude1.Id
    ];
    Settlement__c sekToInclude2Afterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude2.Id
    ];
    Settlement__c sekNotToIncludeAfterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c
      FROM Settlement__c
      WHERE Id = :sekNotToInclude.Id
    ];
    Settlement__c nokSettlementAfterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c
      FROM Settlement__c
      WHERE Id = :nokSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_WAITING_FOR_TRANSFER,
      nokSettlementAfterwards.Settlement_Status__c,
      'A settlement in different currency should not have been modified.'
    );
    System.assert(
      String.isEmpty(nokSettlementAfterwards.Payment_File_Name__c),
      'A settlement in different currency should not have been modified.'
    );
    System.assertEquals(
      Settlements.STATUS_IN_PROGRESS,
      sekNotToIncludeAfterwards.Settlement_Status__c,
      'A settlement in same currency but not waiting for transfer should not have been modified.'
    );
    System.assert(
      String.isEmpty(sekNotToIncludeAfterwards.Payment_File_Name__c),
      'A settlement in same currency but not waiting for transfer should not have been modified.'
    );

    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude1Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude2Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );

    String expectedFileTitle =
      'SF_SEB_SEK_' +
      Datetime.now().format('yyyyMMdd') +
      counter.Payment_Run_Id__c +
      '.txt';

    System.assertEquals(
      expectedFileTitle,
      sekToInclude1Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );
    System.assertEquals(
      expectedFileTitle,
      sekToInclude2Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );

    ContentVersion createdFile = [
      SELECT Id, Title, VersionData
      FROM ContentVersion
      WHERE PathOnClient = :expectedFileTitle
    ];

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerPaymentFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{-S1NAME---}', sekToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', sekToInclude2Afterwards.Name);

    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlements are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     */

    String tail = '';
    for (Integer i = 0; i < comparisonText.length(); i++) {
      String expected = comparisonText.substring(i, i + 1);
      String actual = createdFile.VersionData.toString().substring(i, i + 1);
      tail += actual;
      System.assertEquals(
        expected,
        actual,
        'Created payment file contents should match example file. ' +
          'Character ' +
          i +
          ' (' +
          expected +
          ' actual: ' +
          actual +
          ') does not match. (' +
          tail +
          ')'
      );
    }

    System.assertEquals(
      comparisonText,
      createdFile.VersionData.toString(),
      'Created payment file contents should match example file.'
    );

    Racer_Integration_Counter__c counterAfterwards = [
      SELECT Id, Accounting_Verification_Number__c, Payment_Run_Id__c
      FROM Racer_Integration_Counter__c
      WHERE Id = :counter.Id
    ];

    System.assertEquals(
      10000,
      counterAfterwards.Accounting_Verification_Number__c,
      'Accounting verification number should not be incremented afterwards.'
    );
    System.assertEquals(
      1001,
      counterAfterwards.Payment_Run_Id__c,
      'Run Id should be incremented after file creation.'
    );
  }

  @IsTest
  public static void ebSettlementsShouldBeProcessedImmediatelyWhenWaitingForTransfer() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = '000000000',
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.EBPoints
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Settlement_Item__c settlementItem = new Settlement_Item__c(
      Status__c = 'Draft',
      Settlement__c = settlement.Id
    );

    insert settlementItem;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    SettlementService.processPayableSettlement(settlement.Id);
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    List<Settlement_Item__c> settlementItemsAfterProcessing = [
      SELECT Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as done after successfully adding points.'
    );
    System.assertEquals(
      APIMMock.CLM_TRANSACTION_ID,
      settlementAfterProcessing.External_Reference__c,
      'Settlement should external reference set based on response.'
    );

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementItemsAfterProcessing[0].Status__c,
      'Settlement Item should be marked as done after successfully creating a voucher.'
    );

    System.assertEquals(
      Datetime.now().date(),
      settlementItemsAfterProcessing[0].Date_Of_Accounting__c.date(),
      'Settlement Item should have today marked as date of accounting.'
    );
  }

  @IsTest
  public static void paymentFilesShouldTakeStateCorrectlyForChequePayments() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'USD',
      Payment_Run_Id__c = 5000
    );
    Settlement__c sekToInclude1 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 400,
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'United States',
      Currency__c = 'USD',
      Date_of_Exchange_Calculation__c = Date.today(),
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '98001',
      State__c = UsStateUtils.getStateFromPostalCode('98001'),
      RecordTypeId = Settlements.getRecordTypeId(Settlements.RecordType.Cheque),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    Settlement__c sekToInclude2 = new Settlement__c(
      Address_line_1__c = 'Froesundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 500,
      Bank_Country__c = 'United States',
      BIC_Swift__c = 'AAAAAAB1',
      City__c = 'Stockholm',
      Control_verified__c = true,
      Country__c = 'United States',
      Currency__c = 'USD',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'ASD34223ABA123954389',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{ counter, sekToInclude1, sekToInclude2 };

    // When
    Test.startTest();
    SettlementService.createPaymentFile(PaymentFileBuilder.PaymentCurrency.USD);
    Test.stopTest();

    // Then
    Settlement__c sekToInclude1Afterwards = [
      SELECT Id, Settlement_Status__c, State__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude1.Id
    ];
    Settlement__c sekToInclude2Afterwards = [
      SELECT Id, Settlement_Status__c, State__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude2.Id
    ];

    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude1Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude2Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );

    String expectedFileTitle =
      'SF_NORDEA_USD_' +
      Datetime.now().format('yyyyMMdd') +
      counter.Payment_Run_Id__c +
      '.txt';

    System.assertEquals(
      expectedFileTitle,
      sekToInclude1Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );
    System.assertEquals(
      expectedFileTitle,
      sekToInclude2Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );

    ContentVersion createdFile = [
      SELECT Id, Title, VersionData
      FROM ContentVersion
      WHERE PathOnClient = :expectedFileTitle
    ];

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerPaymentUSDFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{-S1NAME---}', sekToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', sekToInclude2Afterwards.Name);

    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlements are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     */

    // Loop through each character one by one:
    String tail = '';
    for (Integer i = 0; i < comparisonText.length(); i++) {
      String expected = comparisonText.substring(i, i + 1);
      String actual = createdFile.VersionData.toString().substring(i, i + 1);
      tail += actual;
      System.assertEquals(
        expected,
        actual,
        'Created payment file contents should match example file. ' +
          'Character ' +
          i +
          ' (' +
          expected +
          ' actual: ' +
          actual +
          ') does not match. (' +
          tail +
          ')'
      );
    }

    System.assertEquals(
      comparisonText,
      createdFile.VersionData.toString(),
      'Created payment file contents should match example file.'
    );

    Racer_Integration_Counter__c counterAfterwards = [
      SELECT Id, Accounting_Verification_Number__c, Payment_Run_Id__c
      FROM Racer_Integration_Counter__c
      WHERE Id = :counter.Id
    ];

    System.assertEquals(
      10000,
      counterAfterwards.Accounting_Verification_Number__c,
      'Accounting verification number should not be incremented afterwards.'
    );
    System.assertEquals(
      5001,
      counterAfterwards.Payment_Run_Id__c,
      'Run Id should be incremented after file creation.'
    );
  }

  @IsTest
  public static void ebSettlementProcessingShouldHandleDomainFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = APIMMock.EB_NUMBER_NOT_IN_CLM,
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.EBPoints
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    SettlementService.processPayableSettlement(settlement.Id);
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as denied after failing to add points.'
    );
    System.assertEquals(
      'Customer does not exist.',
      settlementAfterProcessing.Error_Message__c,
      'Settlement should have error detail set to response error.'
    );
  }

  @IsTest
  public static void ebSettlementProcessingShouldHandleServiceFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = APIMMock.EB_NUMBER_RETURN_500,
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.EBPoints
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    SettlementService.processPayableSettlement(settlement.Id);
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as failed after failing to add points.'
    );
    System.assert(
      settlementAfterProcessing.Error_Message__c.contains('500'),
      'Settlement should have error detail set to contain 500 error code.'
    );
  }

  @IsTest
  public static void voucherSettlementsShouldBeProcessedImmediatelyWhenWaitingForTransfer() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    Case c = new Case();
    insert c;

    LIA_Claim__c claim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Case__c = c.Id
    );
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Amount__c = 1,
      Address_line_1__c = 'TestAddress',
      Claim__c = claim.Id,
      City__c = 'Test City',
      Country__c = 'Sweden',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Voucher
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER,
      Submitter__c = settlementSubmitter.Id,
      Voucher_Email__c = 'test@example.com'
    );

    insert settlement;

    Settlement_Item__c settlementItem = new Settlement_Item__c(
      Status__c = 'Draft',
      Settlement__c = settlement.Id
    );

    insert settlementItem;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    SettlementService.processPayableSettlement(settlement.Id);
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    List<Settlement_Item__c> settlementItemsAfterProcessing = [
      SELECT Status__c, Date_Of_Accounting__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as done after successfully creating a voucher.'
    );

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementItemsAfterProcessing[0].Status__c,
      'Settlement Item should be marked as done after successfully creating a voucher.'
    );

    System.assertEquals(
      Datetime.now().date(),
      settlementItemsAfterProcessing[0].Date_Of_Accounting__c.date(),
      'Settlement Item should have today marked as date of accounting.'
    );
  }

  @IsTest
  public static void voucherSettlementProcessingShouldHandleServiceFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    Case c = new Case();
    insert c;

    LIA_Claim__c claim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Case__c = c.Id
    );
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Amount__c = 1,
      Address_line_1__c = 'TestAddress',
      Claim__c = claim.Id,
      City__c = 'Test City',
      Country__c = 'Sweden',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Voucher
      ),
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER,
      Submitter__c = settlementSubmitter.Id,
      Voucher_Email__c = APIMMock.VOUCHER_INVALID_EMAIL
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    SettlementService.processPayableSettlement(settlement.Id);
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as failed after failing to create a voucher.'
    );
    System.assert(
      settlementAfterProcessing.Error_Message__c.contains('400'),
      'Settlement should have error detail set to contain 400 error code as returned from API.'
    );
  }

  @IsTest
  static void updateItemsForSettlementsCreatesItems() {
    // Given
    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert claim;

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      Currency__c = 'SEK',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    // When
    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1'
    );
    Settlement_Item__c si2 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 2'
    );

    List<Settlement_Item__c> items = new List<Settlement_Item__c>{ si1, si2 };

    Test.startTest();
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlement.Id => items }
    );
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Amount__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    List<Settlement_Item__c> itemsAfterInsert = [
      SELECT Id, Amount__c, Comments__c, Cost_Account__c, Customer_Name__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    Settlement_Item__c si1AfterProcessing;
    Settlement_Item__c si2AfterProcessing;

    System.assertEquals(
      2,
      itemsAfterInsert.size(),
      'There should be two settlement items for the given settlement.'
    );

    for (Settlement_Item__c si : itemsAfterInsert) {
      if (si.Comments__c == si1.Comments__c) {
        si1AfterProcessing = si;
      } else {
        si2AfterProcessing = si;
      }
    }

    System.assertEquals(
      si1.Amount__c + si2.Amount__c,
      settlementAfterProcessing.Amount__c,
      'Updating settlement items should set the amount of the settlement equal to sum of its settlement items.'
    );
    System.assertEquals(
      si1.Comments__c,
      si1AfterProcessing.Comments__c,
      'Comments should be stored in the created settlement items correctly.'
    );
    System.assertEquals(
      si1.Cost_Account__c,
      si1AfterProcessing.Cost_Account__c,
      'Cost account should be stored in the created settlement items correctly.'
    );
    System.assertEquals(
      si2.Customer_Name__c,
      si2AfterProcessing.Customer_Name__c,
      'Customer name should be stored in the created settlement items correctly.'
    );
  }

  @IsTest
  static void updateAmountInSekForSettlementsItem() {
    // Given
    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert claim;

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      Currency__c = 'SEK',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    // When
    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1',
      Exchange_Rate__c = 1
    );
    Settlement_Item__c si2 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 2',
      Exchange_Rate__c = 1
    );

    List<Settlement_Item__c> items = new List<Settlement_Item__c>{ si1, si2 };

    Test.startTest();
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlement.Id => items }
    );
    Test.stopTest();

    Settlement_Item__c si1AfterProcessing;
    Settlement_Item__c si2AfterProcessing;

    List<Settlement_Item__c> settlementItemAfterProcessing = [
      SELECT
        Id,
        Amount__c,
        Amount_In_SEK__c,
        Comments__c,
        Date_of_Exchange_Calculation__c,
        Exchange_Rate__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    for (Settlement_Item__c si : settlementItemAfterProcessing) {
      if (si.Comments__c == si1.Comments__c) {
        si1AfterProcessing = si;
      } else {
        si2AfterProcessing = si;
      }
    }

    System.assertEquals(
      si1AfterProcessing.Exchange_Rate__c * si1AfterProcessing.Amount__c,
      si1AfterProcessing.Amount_In_SEK__c,
      'Amount in SEK should be updated.'
    );
    System.assertEquals(
      Date.today(),
      si1AfterProcessing.Date_of_Exchange_Calculation__c,
      'Date of Exchange Calculation should be updated.'
    );
    System.assertEquals(
      si1.Exchange_Rate__c,
      si1AfterProcessing.Exchange_Rate__c,
      'Exchange Rate should be updated.'
    );
  }

  @IsTest
  static void updateAmountInSekFromUsdForSettlementsItem() {
    // Given
    Exchange_Rate__c rate = new Exchange_Rate__c(
      Name = 'USD-SEK',
      From_Currency__c = 'USD',
      To_Currency__c = 'SEK',
      Date__c = Date.Today(),
      Rate__c = 9
    );

    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert new List<SObject>{ rate, claim };

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      Currency__c = 'USD',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    // When
    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1'
    );
    Settlement_Item__c si2 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 2'
    );

    List<Settlement_Item__c> items = new List<Settlement_Item__c>{ si1, si2 };

    Test.startTest();
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlement.Id => items }
    );
    Test.stopTest();

    Settlement_Item__c si1AfterProcessing;
    Settlement_Item__c si2AfterProcessing;

    List<Settlement_Item__c> settlementItemAfterProcessing = [
      SELECT
        Id,
        Amount__c,
        Amount_In_SEK__c,
        Comments__c,
        Date_of_Exchange_Calculation__c,
        Exchange_Rate__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    for (Settlement_Item__c si : settlementItemAfterProcessing) {
      if (si.Comments__c == si1.Comments__c) {
        si1AfterProcessing = si;
      } else {
        si2AfterProcessing = si;
      }
    }

    System.assertEquals(
      rate.Rate__c * si2.Amount__c,
      si2AfterProcessing.Amount_In_SEK__c,
      'Exchange Calculation should be done coreect.'
    );
    System.assertEquals(
      rate.Date__c,
      si1AfterProcessing.Date_of_Exchange_Calculation__c,
      'Date of Exchange Calculation should be done.'
    );

    System.assertEquals(
      rate.Rate__c,
      si1AfterProcessing.Exchange_Rate__c,
      'Exchange Rate should be updated.'
    );
  }

  @IsTest
  static void updateItemsForSettlementsUpdatesExistingItems() {
    // Given
    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert claim;

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      Currency__c = 'SEK',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1',
      Settlement__c = settlement.Id
    );
    Settlement_Item__c si2 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 2',
      Settlement__c = settlement.Id
    );
    List<Settlement_Item__c> existingItems = new List<Settlement_Item__c>{
      si1,
      si2
    };

    insert existingItems;

    Settlement_Item__c si1Update = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1',
      Settlement__c = settlement.Id,
      Id = si1.Id
    );

    Settlement_Item__c si2Update = new Settlement_Item__c(
      Amount__c = 300,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 2¨',
      Settlement__c = settlement.Id,
      Id = si2.Id
    );

    List<Settlement_Item__c> updatedItems = new List<Settlement_Item__c>{
      si1Update,
      si2Update
    };

    // When
    Test.startTest();
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlement.Id => updatedItems }
    );
    Test.stopTest();

    List<Settlement_Item__c> itemsAfterInsert = [
      SELECT Id, Amount__c, Comments__c, Cost_Account__c, Customer_Name__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    System.assertEquals(
      2,
      itemsAfterInsert.size(),
      'There should be two settlement items for the given settlement.'
    );

    Settlement_Item__c si1AfterProcessing;
    Settlement_Item__c si2AfterProcessing;

    for (Settlement_Item__c si : itemsAfterInsert) {
      if (si.Comments__c == si1.Comments__c) {
        si1AfterProcessing = si;
      } else {
        si2AfterProcessing = si;
      }
    }

    System.assertEquals(
      si1.Id,
      si1AfterProcessing.Id,
      'The existing settlement item should have been updated instead of creating a new one.'
    );

    System.assertEquals(
      si2.Id,
      si2AfterProcessing.Id,
      'The existing settlement item should have been updated instead of creating a new one.'
    );
  }
  @IsTest
  static void updateItemsForSettlementsHandlesInsuranceCalculations() {
    // Given
    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert claim;

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      Currency__c = 'USD',
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    // When
    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 1200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1'
    );
    Settlement_Item__c si2 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 2',
      Customer_Name__c = 'Test Testsson 1'
    );
    Settlement_Item__c si3 = new Settlement_Item__c(
      Amount__c = 400,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 3',
      Customer_Name__c = 'Test Testsson 2'
    );

    List<Settlement_Item__c> items = new List<Settlement_Item__c>{
      si1,
      si2,
      si3
    };

    Test.startTest();
    SettlementService.updateItemsForSettlements(
      new Map<Id, List<Settlement_Item__c>>{ settlement.Id => items }
    );
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Amount__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    List<Settlement_Item__c> itemsAfterInsert = [
      SELECT
        Id,
        Amount__c,
        Comments__c,
        Cost_Account__c,
        Customer_Name__c,
        Is_Insured__c,
        Net_Amount_After_Deductible__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :settlement.Id
    ];

    Settlement_Item__c si1AfterProcessing;
    Settlement_Item__c si2AfterProcessing;
    Settlement_Item__c si3AfterProcessing;

    System.assertEquals(
      3,
      itemsAfterInsert.size(),
      'There should be three settlement items for the given settlement.'
    );

    for (Settlement_Item__c si : itemsAfterInsert) {
      if (si.Comments__c == si1.Comments__c) {
        si1AfterProcessing = si;
      } else if (si.Comments__c == si2.Comments__c) {
        si2AfterProcessing = si;
      } else {
        si3AfterProcessing = si;
      }
    }

    System.assertEquals(
      si1.Amount__c + si2.Amount__c + si3.Amount__c,
      settlementAfterProcessing.Amount__c,
      'Settlement amount should not be affected by insurance calculations.'
    );
    System.assertEquals(
      si1.Amount__c,
      si1AfterProcessing.Amount__c,
      'Settlement item amounts should not be affected by insurance calculations.'
    );
    System.assertEquals(
      si2.Amount__c,
      si2AfterProcessing.Amount__c,
      'Settlement item amounts should not be affected by insurance calculations.'
    );
    System.assertEquals(
      si3.Amount__c,
      si3AfterProcessing.Amount__c,
      'Settlement item amounts should not be affected by insurance calculations.'
    );
    System.assertEquals(
      true,
      si1.Is_Insured__c,
      'Settlement items should be set as insured.'
    );
    System.assertEquals(
      true,
      si2.Is_Insured__c,
      'Settlement items should be set as insured.'
    );
    System.assertEquals(
      true,
      si3.Is_Insured__c,
      'Settlement items should be set as insured.'
    );
    System.assertEquals(
      0, // Assuming deductible of 1250.
      si1AfterProcessing.Net_Amount_After_Deductible__c,
      'First settlement for first customer should have all of payment fall under deductible.'
    );
    System.assertEquals(
      350, // Assuming deductible of 1250.
      si2AfterProcessing.Net_Amount_After_Deductible__c,
      'Second settlement for first customer should have net amount left after deductible.'
    );

    System.assertEquals(
      0, // Assuming deductible of 1250.
      si3AfterProcessing.Net_Amount_After_Deductible__c,
      'Different customer should have all of payment fall under deductible.'
    );
  }
  @IsTest
  static void updateItemsForSettlementsFailsIfSettlementHasNoCurrency() {
    // Given
    LIA_Claim__c claim = new LIA_Claim__c(
      Customer_Claim_Category__c = 'Baggage',
      Customer_Claim_Type__c = 'Baggage damaged',
      PIR__c = 'ARNSK12345'
    );

    insert claim;

    Settlement__c settlement = new Settlement__c(
      BIC_Swift__c = 'AAAAAAB1',
      Claim__c = claim.Id,
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );

    insert settlement;

    Settlement_Item__c si1 = new Settlement_Item__c(
      Amount__c = 200,
      Cost_Account__c = '6741',
      Comments__c = 'Test comment 1',
      Customer_Name__c = 'Test Testsson 1'
    );

    List<Settlement_Item__c> items = new List<Settlement_Item__c>{ si1 };

    Exception caughtException;

    // When
    Test.startTest();
    try {
      SettlementService.updateItemsForSettlements(
        new Map<Id, List<Settlement_Item__c>>{ settlement.Id => items }
      );
    } catch (Exception e) {
      caughtException = e;
    }
    Test.stopTest();

    // Then
    System.assertEquals(
      'Settlements.UpdateException',
      caughtException.getTypeName(),
      'Missing currency from settlement should have caused an UpdateException.'
    );
  }
}
