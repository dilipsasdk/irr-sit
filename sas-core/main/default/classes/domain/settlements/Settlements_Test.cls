@IsTest
private class Settlements_Test {
  @IsTest
  static void itShouldNotBePossibleToUpdateFailedSettlementToDone() {
    Settlement__c s = new Settlement__c(
      Settlement_Status__c = Settlements.STATUS_FAILED
    );
    insert s;
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance(); // needs to be passed in but tests works without committing.
    Settlements.newInstance(new List<Settlement__c>{ s })
      .markAsDone('done', uow);

    System.assertEquals(
      Settlements.STATUS_FAILED,
      s.Settlement_Status__c,
      'Settlement status should not have been updated.'
    );
  }

  @IsTest
  static void settlementsWithSpecialCharactersShouldBeSanititzed() {
    Settlement__c s = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = null,
      Amount__c = 600,
      BIC_Swift__c = 'AAAAAABB123',
      City__c = 'Örebro',
      Country__c = 'Curaçao',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'åäöéü',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK
    );

    insert s;

    s = SettlementsSelector.newInstance().selectById(new Set<Id>{ s.Id })[0];

    System.assertEquals(
      'Frosundaviks alle 1',
      s.Address_line_1__c,
      'Address line 1 should have been sanitized.'
    );
    System.assertEquals(
      null,
      s.Address_line_2__c,
      'Address line 2 should have been sanitized.'
    );
    System.assertEquals(
      'Orebro',
      s.City__c,
      'City should have been sanitized.'
    );
    System.assertEquals(
      'oaoeu',
      s.Payee_Name__c,
      'Payee name should have been sanitized.'
    );

    s.Payee_Name__c = 'åäöéü';

    update s;

    s = SettlementsSelector.newInstance().selectById(new Set<Id>{ s.Id })[0];

    System.assertEquals(
      'oaoeu',
      s.Payee_Name__c,
      'Payee name should have been sanitized.'
    );
  }
}
