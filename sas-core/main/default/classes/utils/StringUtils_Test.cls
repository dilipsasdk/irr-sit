@IsTest
private class StringUtils_Test {
  @IsTest
  static void isEmailAddressShouldReturnFalseForEmptyString() {
    Boolean res = StringUtils.isEmailAddress('');
    System.assertEquals(false, res, 'Empty input should return false');
  }

  @IsTest
  static void isEmailAddressShouldReturnFalseForNull() {
    Boolean res = StringUtils.isEmailAddress(null);
    System.assertEquals(false, res, 'Null input should return false');
  }

  @IsTest
  static void isEmailAddressShouldReturnTrueForValidEmail() {
    // Just sanity checking a simple example.
    Boolean res = StringUtils.isEmailAddress('test@example.com');
    System.assertEquals(
      true,
      res,
      'test@example.com should be a valid email address.'
    );
  }

  @IsTest
  static void itShouldBePossibleToRemoveWhiteSpace() {
    String nullString = null;
    String emptyString = '';
    String withDifferentTypesOfSpaces = 'a  b\u00A0c';
    String withZeroWidthSpace = 'a\u200Bb\uFEFFc';

    System.assertEquals(
      null,
      StringUtils.removeWhitespace(nullString),
      'Null string should return null.'
    );
    System.assertEquals(
      '',
      StringUtils.removeWhitespace(emptyString),
      'Empty string should return itself'
    );
    System.assertEquals(
      'abc',
      StringUtils.removeWhitespace(withDifferentTypesOfSpaces),
      'Visible spaces should be removed'
    );
    System.assertEquals(
      'abc',
      StringUtils.removeWhitespace(withZeroWidthSpace),
      'Zero-width spaces should be removed'
    );
  }

  @IsTest
  static void itShouldBePossibleToSanitizeString() {
    String testString1 = 'TLAST';
    String testString2 = 'T LAST';
    String testString3 = 'T LÄST';
    String testString4 = 'T LÁST';
    String testString5 = '';

    System.assertEquals(
      'TLAST',
      StringUtils.sanitize(testString1),
      'Should not replace anything'
    );
    System.assertEquals(
      'TLAST',
      StringUtils.sanitize(testString2),
      'Should have removed empty space'
    );
    System.assertEquals(
      'TLAST',
      StringUtils.sanitize(testString3),
      'Should have removed empty space and special character'
    );
    System.assertEquals(
      'TLAST',
      StringUtils.sanitize(testString4),
      'Should have removed empty space and special character'
    );
    System.assertEquals(
      '',
      StringUtils.sanitize(testString5),
      'Should not replace anything'
    );
  }

  @IsTest
  static void mergeFieldsShouldBeReplacedCorrectly() {
    String body = 'abc abc abc {{{Sender.FirstName}}}, abc abc abc {{{Case.Department__c}}}';
    User sender = new User(FirstName = 'Testname');
    Case c = new Case(Department__c = 'Testdepartment');

    String actual = StringUtils.populateMergeFields(body, c, sender);

    String expected = 'abc abc abc Testname, abc abc abc Testdepartment';
    System.assertEquals(
      expected,
      actual,
      'Result should be "' + expected + '"'
    );
  }

  @IsTest
  public static void ticketNumbersCanBeFomatted() {
    String validTicketNumber = '1171234567890';
    String invalidTicketNumber = '117123456789';
    String invalidTicketNumber2 = '117TESTTEST12';

    String formattedTicketNumber = StringUtils.formatTicketNumberForTEDS(
      validTicketNumber
    );
    Assert.areEqual(
      '117-1234567890',
      formattedTicketNumber,
      'Ticket number should be formatted correctly'
    );

    try {
      StringUtils.formatTicketNumberForTEDS(invalidTicketNumber);
      Assert.fail('Should throw IllegalArgumentException');
    } catch (Exception e) {
      Assert.isInstanceOfType(
        e,
        IllegalArgumentException.class,
        'Should throw IllegalArgumentException'
      );
    }
    try {
      StringUtils.formatTicketNumberForTEDS(invalidTicketNumber2);
      Assert.fail('Should throw IllegalArgumentException');
    } catch (Exception e) {
      Assert.isInstanceOfType(
        e,
        IllegalArgumentException.class,
        'Should throw IllegalArgumentException'
      );
    }
  }
}
