@IsTest
public with sharing class Accounts_Test {
  @IsTest
  public static void invalidEBNumberShouldThrow() {
    String tooLong = '12345678900987';
    String empty = '';
    String tooShort = '1';
    String onlyLetters = 'abcdefghk';

    Exception caughtException;

    try {
      Accounts.parseIntoEuroBonusNumber(tooLong);
    } catch (Exception e) {
      caughtException = e;
    }

    System.assertEquals(
      'Accounts.IncorrectEBNumberException',
      caughtException.getTypeName(),
      'Should have caused an IncorrectEBNumberException.'
    );

    try {
      Accounts.parseIntoEuroBonusNumber(empty);
    } catch (Exception e) {
      caughtException = e;
    }

    System.assertEquals(
      'Accounts.IncorrectEBNumberException',
      caughtException.getTypeName(),
      'Should have caused an IncorrectEBNumberException.'
    );

    try {
      Accounts.parseIntoEuroBonusNumber(tooShort);
    } catch (Exception e) {
      caughtException = e;
    }

    System.assertEquals(
      'Accounts.IncorrectEBNumberException',
      caughtException.getTypeName(),
      'Should have caused an IncorrectEBNumberException.'
    );

    try {
      Accounts.parseIntoEuroBonusNumber(onlyLetters);
    } catch (Exception e) {
      caughtException = e;
    }

    System.assertEquals(
      'Accounts.IncorrectEBNumberException',
      caughtException.getTypeName(),
      'Should have caused an IncorrectEBNumberException.'
    );
  }

  @IsTest
  public static void lettersAndWhitespaceShouldBeDropped() {
    String testString1 = 'EBS  123456789';
    String parsed1 = Accounts.parseIntoEuroBonusNumber(testString1);

    String testString2 = '123456789EE';
    String parsed2 = Accounts.parseIntoEuroBonusNumber(testString2);

    System.assertEquals('123456789', parsed1, 'It should drop all non-digits.');
    System.assertEquals('123456789', parsed2, 'It should drop all non-digits.');
  }
}
