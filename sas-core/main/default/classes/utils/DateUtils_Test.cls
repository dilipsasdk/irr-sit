@IsTest
private class DateUtils_Test {
  @isTest
  static void shouldEvaluateIfInTime() {
    // Given
    Datetime today = DateTime.newInstance(2022, 1, 1);
    Datetime inTime = DateTime.newInstance(2020, 1, 1);
    Datetime justInTime = DateTime.newInstance(2019, 1, 1);
    Datetime aheadInTime = DateTime.newInstance(2024, 1, 1);
    Datetime aheadJustInTime = DateTime.newInstance(2025, 1, 1);
    Datetime justOutOfTime = DateTime.newInstance(2018, 12, 30); // 3 years and 2 extra days (depending on gap year).
    Datetime outOfTime = DateTime.newInstance(2015, 1, 1);
    Datetime aheadJustOutOfTime = DateTime.newInstance(2025, 1, 3);
    Datetime aheadOutOfTime = DateTime.newInstance(2027, 1, 3);
    List<DateTime> dates = new List<DateTime>{
      inTime,
      justInTime,
      aheadInTime,
      aheadJustInTime,
      justOutOfTime,
      outOfTime,
      aheadJustOutOfTime,
      aheadOutOfTime
    };

    // When
    List<Boolean> resultsPos = new List<Boolean>{};
    List<Boolean> resultsNeg = new List<Boolean>{};
    for (Datetime dat : dates) {
      resultsPos.add(DateUtils.areWithinTimeLimit(today, dat, 3.0));
      resultsNeg.add(DateUtils.areWithinTimeLimit(dat, today, 3.0));
    }

    // Then
    List<Boolean> correct = new List<Boolean>{
      true,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    };

    Integer count = 0;
    for (Integer i = 0; i < correct.size(); i++) {
      count += 1;
      System.assertEquals(
        correct[i],
        resultsPos[i],
        'Should assign eligability correctly (Pos). Date number: ' +
        String.valueOf(count)
      );
      System.assertEquals(
        correct[i],
        resultsNeg[i],
        'Should assign eligability correctly (Neg). Date number: ' +
        String.valueOf(count)
      );
    }
  }

  @IsTest
  public static void validDatestringShouldReturnTrue() {
    String validDatestring = '2022-01-01T12:34:56Z';
    Boolean validFormat = DateUtils.isValidIsoDatetime(validDatestring);
    System.assert(validFormat, 'Datetime validation should have succeeded');
  }
  @IsTest
  public static void invalidDatestringShouldReturnFalse() {
    String invalidDatestring = 'test bla bla';
    Boolean invalidFormat = DateUtils.isValidIsoDatetime(invalidDatestring);
    System.assert(!invalidFormat, 'Datetime validation should have failed');
  }

  @IsTest
  public static void validDatesShouldBeReturned() {
    Datetime validDatetime = Datetime.newInstance(1);
    Datetime referenceDatetime = Datetime.newInstance(0);

    Long validTimestamp = 1L;
    Long referenceTimestamp = 0L;

    System.assertEquals(
      validDatetime,
      DateUtils.verifyDatetime(validDatetime, referenceDatetime),
      'validDatetime should have been returned'
    );
    System.assertEquals(
      Datetime.newInstance(validTimestamp),
      DateUtils.convertTimestampToDatetime(validTimestamp, referenceTimestamp),
      'validTimestamp should have been returned'
    );
  }
  @IsTest
  public static void invalidDatesShouldReturnNull() {
    Datetime invalidDatetime = Datetime.newInstance(0);
    Datetime referenceDatetime = Datetime.newInstance(1);

    Long invalidTimestamp = 0L;
    Long referenceTimestamp = 1L;

    System.assertEquals(
      null,
      DateUtils.verifyDatetime(invalidDatetime, referenceDatetime),
      'null should have been returned'
    );
    System.assertEquals(
      null,
      DateUtils.convertTimestampToDatetime(
        invalidTimestamp,
        referenceTimestamp
      ),
      'null should have been returned'
    );
    System.assertEquals(
      null,
      DateUtils.verifyDatetime(referenceDatetime, referenceDatetime),
      'null should have been returned'
    );
    System.assertEquals(
      null,
      DateUtils.convertTimestampToDatetime(
        referenceTimestamp,
        referenceTimestamp
      ),
      'null should have been returned'
    );
  }
  @IsTest
  public static void nullArgementThrowsException() {
    Boolean caughtDatetime = false;
    Boolean caughtTimestamp = false;
    try {
      DateUtils.verifyDatetime(null);
    } catch (U.InvalidArgumentException e) {
      caughtDatetime = true;
    }
    try {
      DateUtils.convertTimestampToDatetime(null);
    } catch (U.InvalidArgumentException e) {
      caughtTimestamp = true;
    }
    System.assert(caughtDatetime, 'null Datetime should have thrown exception');
    System.assert(
      caughtTimestamp,
      'null Timestamp should have thrown exception'
    );
  }
}
