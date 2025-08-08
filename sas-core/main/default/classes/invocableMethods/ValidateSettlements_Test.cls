@IsTest
private class ValidateSettlements_Test {
  @IsTest
  static void invalidSettlementValidationTest() {
    // Given
    LIA_Claim__c privateClaim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Type_of_Customer__c = 'Private Customer'
    );
    LIA_Claim__c otherClaim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Type_of_Customer__c = 'Claim firm'
    );

    insert new List<LIA_Claim__c>{ privateClaim, otherClaim };

    Settlement__c validSettlement = new Settlement__c(
      Claim__c = privateClaim.Id,
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE7280000810340009783242',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Bank_Country__c = 'Sweden'
    );

    Settlement__c invalidSettlement1 = validSettlement.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c invalidSettlement2 = validSettlement.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c invalidSettlement3 = validSettlement.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c invalidSettlement4 = validSettlement.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c invalidSettlement5 = validSettlement.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c invalidSettlement6 = validSettlement.clone(
      false,
      true,
      false,
      false
    );

    invalidSettlement1.Amount__c = 0;
    invalidSettlement2.City__c = null;
    invalidSettlement3.Bank_Account_Number__c = 'SE738000081034000978324';
    invalidSettlement4.Claim__c = otherClaim.Id;
    invalidSettlement5.Address_line_1__c = null;

    invalidSettlement6.RecordTypeId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );
    invalidSettlement6.EuroBonus_Number__c = '1234';
    invalidSettlement6.EuroBonus_Points__c = 1000;

    insert new List<Settlement__c>{
      invalidSettlement1,
      invalidSettlement2,
      invalidSettlement3,
      invalidSettlement4,
      invalidSettlement5
    };

    // When
    Boolean singleError = false;
    Boolean largeError = false;

    ValidateSettlements.ValidationStatus statusSingle = ValidateSettlements.validate(
      new List<List<Settlement__c>>{
        new List<Settlement__c>{ invalidSettlement1 }
      }
    )[0];
    if (!statusSingle.isValid) {
      singleError = true;
    }

    ValidateSettlements.ValidationStatus statusMulti = ValidateSettlements.validate(
      new List<List<Settlement__c>>{
        new List<Settlement__c>{
          invalidSettlement1,
          invalidSettlement2,
          invalidSettlement3,
          invalidSettlement4,
          invalidSettlement5
        }
      }
    )[0];
    if (!statusMulti.isValid) {
      largeError = true;
    }

    // Then
    System.assert(singleError, 'A settlement with one error was validated.');
    System.assert(
      largeError,
      'A settlement with multiple errors was validated.'
    );
  }
  @IsTest
  static void validSettlementValidationTest() {
    // Given
    LIA_Claim__c privateClaim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Type_of_Customer__c = 'Private Customer'
    );

    insert new List<LIA_Claim__c>{ privateClaim };

    Settlement__c validSettlement1 = new Settlement__c(
      Claim__c = privateClaim.Id,
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE7280000810340009783242',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      RecordTypeId = Settlements.getRecordTypeId(
        Settlements.RecordType.Monetary
      ),
      Bank_Country__c = 'Sweden'
    );

    Settlement__c validSettlement2 = validSettlement1.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c validSettlement3 = validSettlement1.clone(
      false,
      true,
      false,
      false
    );
    Settlement__c validSettlement4 = validSettlement1.clone(
      false,
      true,
      false,
      false
    );

    validSettlement2.RecordTypeId = Settlements.getRecordTypeId(
      Settlements.RecordType.Voucher
    );
    validSettlement2.Voucher_Email__c = 'Test@example.com';
    validSettlement2.Payee_First_Name__c = 'Test';
    validSettlement2.Payee_Last_Name__c = 'Testsson';
    validSettlement2.Bank_Account_Number__c = null;
    validSettlement2.Bank_Country__c = null;
    validSettlement2.Country__c = null;

    validSettlement3.RecordTypeId = Settlements.getRecordTypeId(
      Settlements.RecordType.Cheque
    );
    validSettlement3.Country__c = 'United States';
    validSettlement3.Bank_Country__c = 'United States';
    validSettlement3.Currency__c = 'USD';
    validSettlement3.Postal_Code__c = '90801';
    validSettlement3.State__c = UsStateUtils.getStateFromPostalCode('90801');

    validSettlement4.RecordTypeId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );
    validSettlement4.Address_line_1__c = null;
    validSettlement4.EuroBonus_Number__c = '000000000';
    validSettlement4.EuroBonus_Points__c = 1;
    validSettlement4.Bank_Country__c = null;
    validSettlement4.Country__c = null;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    insert new List<Settlement__c>{
      validSettlement1,
      validSettlement2,
      validSettlement3,
      validSettlement4
    };

    // When
    Boolean noError = false;

    Test.startTest();
    ValidateSettlements.ValidationStatus status;
    try {
      status = ValidateSettlements.validate(
        new List<List<Settlement__c>>{
          new List<Settlement__c>{
            validSettlement1,
            validSettlement2,
            validSettlement3,
            validSettlement4
          }
        }
      )[0];
    } catch (Exception e) {
      status = new ValidateSettlements.ValidationStatus('Error');
    }

    if (status.isValid) {
      noError = true;
    }

    Test.stopTest();

    // Then
    System.assertEquals(status.errorMessage, '');
    System.assert(noError, 'A valid settlement was invalidated');
  }
}
