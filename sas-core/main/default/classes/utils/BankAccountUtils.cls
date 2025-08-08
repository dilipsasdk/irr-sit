/**
 * Utility class which handles bank accounts
 */
public without sharing class BankAccountUtils {
  // Numbers at the left hand side are the character codes
  private static Map<Integer, String> ASCIIToIntIBAN = new Map<Integer, String>{
    65 => '10',
    66 => '11',
    67 => '12',
    68 => '13',
    69 => '14',
    70 => '15',
    71 => '16',
    72 => '17',
    73 => '18',
    74 => '19',
    75 => '20',
    76 => '21',
    77 => '22',
    78 => '23',
    79 => '24',
    80 => '25',
    81 => '26',
    82 => '27',
    83 => '28',
    84 => '29',
    85 => '30',
    86 => '31',
    87 => '32',
    88 => '33',
    89 => '34',
    90 => '35'
  };

  /**
   * Checks if the bank account number conforms to the IBAN (International Bank Account Number) or the ABA (American Bank Association routing number) format.
   * If the bank country DOES NOT require IBAN (or ABA) the number is treated as valid and the function returns true.
   * If the bank country DOES require IBAN or ABA the function validates it and returns true if it is valid and false if it is invalid.
   * @param accountNumber A String containing the bank account number
   * @param bankCountry A String containing the bank country name
   * @param bicNumber The Bank Identification Code
   * @return true or false depending on if the number is valid. If the bank country does not use IBAN true is returned
   */
  public static Boolean validateIBAN(
    String accountNumber,
    String bankCountry,
    String bicNumber
  ) {
    if (accountNumber.length() == 0) {
      // If the bank account field is blank
      return false;
    }

    if (bankCountry == 'United States') {
      // Should have the format: "{Bankaccount}ABA{BankRoutingNumber}" (according to ClaimService.cls)
      if (isValidUSAccountNumber(accountNumber, bicNumber)) {
        return true;
      } else {
        return false;
      }
    }

    List<Settlement_Country_Setting__mdt> countryCodeQuery = [
      SELECT Country_Short_Code__c
      FROM Settlement_Country_Setting__mdt
      WHERE Country_Name__c = :bankCountry AND Uses_IBAN__c = TRUE
    ];

    if (countryCodeQuery.size() == 1) {
      // If the country uses IBAN
      if (
        isValidIBAN(
          accountNumber,
          bankCountry,
          countryCodeQuery[0].Country_Short_Code__c
        )
      ) {
        return true;
      } else {
        return false;
      }
    }

    return true;
  }

  public class BankCountryAndIBANCodeDoNotMatchException extends Exception {
  }

  // Source: https://www.ecbs.org/Download/EBS204_V3.2.pdf
  private static Boolean isValidIBAN(
    String accountNumber,
    String bankCountry,
    String countryCodeForBankCountry
  ) {
    if (accountNumber.length() < 15 || accountNumber.length() > 32) {
      return false;
    }

    String countryCodeFromAccountNumber = accountNumber.substring(0, 2);
    if (countryCodeFromAccountNumber != countryCodeForBankCountry) {
      throw new BankCountryAndIBANCodeDoNotMatchException(
        'The bank country has to match the country represented by the first two letters of the Bank Account Number.'
      );
    }

    // Rearrange the IBAN
    String validationStr =
      accountNumber.substring(4, accountNumber.length()) +
      accountNumber.substring(0, 4);

    // Convert letters to numbers
    String numberIBAN = '';
    List<Integer> characters = validationStr.getChars();
    for (Integer character : characters) {
      if (character > 64 && character < 91) {
        // If A-Z
        numberIBAN = numberIBAN + ASCIIToIntIBAN.get(character);
      } else if (character > 47 && character < 58) {
        // If 0-9
        numberIBAN = numberIBAN + (character - 48).format();
      } else {
        // Safeguard: This should not happen, if the number contains special characters or characters like ÅÄÖ they are caught here.
        return false;
      }
    }

    // Perform validation check
    if (calculateMod(numberIBAN) != 1) {
      return false;
    }

    return true; // Default case
  }

  private static Boolean isValidUSAccountNumber(
    String fullAccountNumber,
    String bicNr
  ) {
    if (!fullAccountNumber.contains('ABA')) {
      return false;
    }

    List<String> separate = fullAccountNumber.split('ABA');
    if (separate.size() != 2) {
      return false;
    }

    String routingNumber = separate[1];
    String accountNumber = separate[0];
    if (
      routingNumber.length() == 9 &
      routingNumber.isNumeric() &
      routingNumber != accountNumber
    ) {
      if (
        accountNumber.length() > 5 &
        accountNumber.length() < 18 &
        accountNumber.isAlphanumeric()
      ) {
        if (bicNr != accountNumber) {
          return true;
        }
      }
    }
    return false;
  }

  /*
   * A Long can only hold 2^63 ~= 9*10^18
   * An IBAN can be much longer, at shortest 15 characters (which becomes a minimum of 17 after parse) but can be more than double.
   * We therefore divide the number into smaller pieces and perform modolo incrementally
   */
  private static Integer calculateMod(String overflowNumber) {
    Integer residual = 0;
    List<Integer> numbers = overflowNumber.getChars();
    for (Integer num : numbers) {
      residual = Math.mod(residual * 10 + num - 48, 97); // ASCII 0 = 48, 9 = 57
    }

    return residual;
  }

  public static Boolean validateBIC(String bicNumber) {
    Pattern p = Pattern.compile('^[A-Z]{6}[0-9A-Z]{2}([0-9A-Z]{3})?$');

    if (p.matcher(bicNumber).matches()) {
      return true;
    }

    return false;
  }
  public static Boolean validateAddress(String addr1, String addr2) {
    String address = addr1 + ' ' + addr2;
    List<String> invalidChar = new List<String>{ '´', '`', '?', '!', '+' };
    for (String str : InvalidChar) {
      if (address.containsAny(str)) {
        return false;
      }
    }
    return true;
  }
}
