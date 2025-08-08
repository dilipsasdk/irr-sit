@IsTest
private class LockRecords_Test {
  @IsTest
  static void shouldLockASingleRecord() {
    Case c = new Case(Subject = 'C');
    insert c;

    LockRecords.LockRecord(new List<String> {c.Id});

    System.assertEquals(
      true,
      Approval.isLocked(c),
      'It should successfully lock a single record.'
    );
  }

  @IsTest
  static void shouldLockAListOfRecords() {
    Case c1 = new Case(Subject = 'C1');
    Case c2 = new Case(Subject = 'C2');
    List<Case> casesToLock = new List<Case> {c1,c2}; 
    insert casesToLock;

    LockRecords.LockRecord(new List<String> {c1.Id,c2.Id});
    
    System.assertEquals(
      true,
      Approval.isLocked(c1),
      'It should successfully lock the first record.'
      );
    System.assertEquals(
      true,
      Approval.isLocked(c2),
      'It should successfully lock the second record.'
      );  
  }

  @IsTest
  static void shouldIgnoreLockedRecords() {
    // Given 
    Case c1 = new Case(Subject = 'C1');
    Case c2 = new Case(Subject = 'C2');
    List<Case> casesToLock = new List<Case> {c1,c2}; 
    insert casesToLock;
    LockRecords.LockRecord(new List<String> {c1.Id});

    // When
    LockRecords.LockRecord(new List<String> {c1.Id,c2.Id});

    // Then
    System.assertEquals(
      true,
      Approval.isLocked(c1),
      'Locking the first record twice should succeed and leave the first record as locked'
    );
    System.assertEquals(
      true,
      Approval.isLocked(c2),
      'Second record should be locked'
    );
  }

  @IsTest
  static void shouldLockAListOfSettlementsAndOtherRecords() {
    Case c = new Case(Subject = 'C1');
    Settlement__c s = new Settlement__c();
    List<SObject> recordsToLock = new List<SObject> {c,s}; 
    insert recordsToLock;

    LockRecords.LockRecord(new List<String> {c.Id,s.Id});
    
    System.assertEquals(
      true,
      Approval.isLocked(c),
      'It should successfully lock the case record.'
      );
    System.assertEquals(
      true,
      Approval.isLocked(s),
      'It should successfully lock the settlement record.'
      );  
  }

}
