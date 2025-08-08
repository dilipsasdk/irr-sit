@IsTest
private class UnlockRecords_Test {
  @IsTest
  static void shouldUnlockASingleRecord() {
    // Given
    Case c = new Case(Subject = 'C');
    insert c;
    LockRecords.LockRecord(new List<String>{ c.Id });

    // When
    UnlockRecords.UnlockRecord(new List<String>{ c.Id });

    // Then
    System.assertEquals(
      false,
      Approval.isLocked(c),
      'It should successfully unlock a single record.'
    );
  }

  @IsTest
  static void shouldUnlockAListOfRecords() {
    // Given
    Case c1 = new Case(Subject = 'C1');
    Case c2 = new Case(Subject = 'C2');
    List<Case> casesToUnlock = new List<Case>{ c1, c2 };
    insert casesToUnlock;
    LockRecords.LockRecord(new List<String>{ c1.Id, c2.Id });

    // When
    UnlockRecords.UnlockRecord(new List<String>{ c1.Id, c2.Id });

    // Then
    System.assertEquals(
      false,
      Approval.isLocked(c1),
      'It should successfully unlock the first record.'
    );
    System.assertEquals(
      false,
      Approval.isLocked(c2),
      'It should successfully unlock the second record.'
    );
  }

  @IsTest
  static void shouldIgnoreUnlockedRecords() {
    // Given
    Case c1 = new Case(Subject = 'C1');
    Case c2 = new Case(Subject = 'C2');
    List<Case> casesToUnlock = new List<Case>{ c1, c2 };
    insert casesToUnlock;
    LockRecords.LockRecord(new List<String>{ c1.Id, c2.Id });
    UnlockRecords.UnlockRecord(new List<String>{ c1.Id });

    // When
    UnlockRecords.UnlockRecord(new List<String>{ c1.Id, c2.Id });

    // Then
    System.assertEquals(
      false,
      Approval.isLocked(c1),
      'Unlocking the first record twice should succeed and leave the first record as unlocked'
    );
    System.assertEquals(
      false,
      Approval.isLocked(c2),
      'Second record should be unlocked'
    );
  }

  @IsTest
  static void shouldUnlockAListOfSettlementsAndOtherRecords() {
    // Given
    Case c = new Case(Subject = 'C1');
    Settlement__c s = new Settlement__c();
    List<SObject> recordsToLock = new List<SObject>{ c, s };
    insert recordsToLock;
    LockRecords.LockRecord(new List<String>{ c.Id, s.Id });

    // When
    UnlockRecords.UnlockRecord(new List<String>{ c.Id, s.Id });

    // Then
    System.assertEquals(
      false,
      Approval.isLocked(c),
      'It should successfully unlock the case record.'
    );
    System.assertEquals(
      false,
      Approval.isLocked(s),
      'It should successfully unlock the settlement record.'
    );
  }
}
