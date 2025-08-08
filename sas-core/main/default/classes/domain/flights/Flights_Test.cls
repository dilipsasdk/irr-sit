@IsTest
public with sharing class Flights_Test {
  @IsTest
  public static void validFlightNumbersShouldReturnNormalizedTEDSFormat() {
    String validFlightNumber1 = 'SK1';
    String validFlightNumber2 = 'SK01';
    String validFlightNumber3 = 'SK001';
    String validFlightNumber4 = 'SK0001';
    String validFlightNumber5 = 'A3001';
    String validFlightNumber6 = '9W1';

    System.assertEquals(
      'SK0001',
      Flight.normalizeFlightNumber(validFlightNumber1),
      'Should have returned a properly formatted flight number'
    );
    System.assertEquals(
      'SK0001',
      Flight.normalizeFlightNumber(validFlightNumber2),
      'Should have returned a properly formatted flight number'
    );
    System.assertEquals(
      'SK0001',
      Flight.normalizeFlightNumber(validFlightNumber3),
      'Should have returned a properly formatted flight number'
    );
    System.assertEquals(
      'SK0001',
      Flight.normalizeFlightNumber(validFlightNumber4),
      'Should have returned a properly formatted flight number'
    );
    System.assertEquals(
      'A30001',
      Flight.normalizeFlightNumber(validFlightNumber5),
      'Should have returned a properly formatted flight number'
    );
    System.assertEquals(
      '9W0001',
      Flight.normalizeFlightNumber(validFlightNumber6),
      'Should have returned a properly formatted flight number'
    );
  }
  @IsTest
  public static void invalidFlightNumberShouldThrowException() {
    String invalidFlightNumber = 'SAS123';
    Boolean exceptionWasThrown = false;

    try {
      Flight.normalizeFlightNumber(invalidFlightNumber);
    } catch (Exception e) {
      exceptionWasThrown = true;
    }
    System.assert(exceptionWasThrown, 'An Exception should have been thrown');
  }
}
