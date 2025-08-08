/**
 * Utility class which handles Countries
 */
public without sharing class CountryUtils {
  private static final Decimal DEFAULT_AMOUNT_OF_YEARS_YOU_CAN_WAIT_TO_FILE_A_CLAIM = 3.0;

  // Maps the country codes which are associated with another country in a "child to parent"-type relationship, e.g. Åland (AX) to Finland (FI).
  private static final Map<String, String> countryCodeToIBANCountryCode = new Map<String, String>{
    'GF' => 'FR',
    'GP' => 'FR',
    'MQ' => 'FR',
    'RE' => 'FR',
    'PF' => 'FR',
    'TF' => 'FR',
    'YT' => 'FR',
    'NC' => 'FR',
    'BL' => 'FR',
    'MF' => 'FR',
    'PM' => 'FR',
    'WF' => 'FR',
    'IM' => 'GB',
    'GG' => 'GB',
    'JE' => 'GB',
    'AX' => 'FI'
  };

  // TODO: Consider: This could be stored in the settlement country settings
  // Source: https://european-union.europa.eu/principles-countries-history/country-profiles_en
  private static final Set<String> countryCodesInEU = new Set<String>{
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'CZ',
    'DK',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HU',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SK',
    'SL',
    'ES',
    'SE'
  };

  private static final Map<String, String> COUNTRY_NAME_TO_VOUCHER_MARKET = new Map<String, String>{
    'australia' => 'AU',
    'austria' => 'AT',
    'belgium' => 'BE',
    'china' => 'CN',
    'denmark' => 'DK',
    'finland' => 'FI',
    'france' => 'FR',
    'germany' => 'DE',
    'hongkong' => 'HK',
    'iceland' => 'IS',
    'ireland' => 'IE',
    'italy' => 'IT',
    'japan' => 'JP',
    'lithuania' => 'LT',
    'netherlands' => 'NL',
    'norway' => 'NO',
    'poland' => 'PL',
    'russia' => 'RU',
    'singapore' => 'SG',
    'spain' => 'ES',
    'sweden' => 'SE',
    'switzerland' => 'CH',
    'thailand' => 'TH',
    'unitedstates' => 'US',
    'luxembourg' => 'LU',
    'unitedkingdom' => 'GB',
    'canada' => 'CA'
  };

  private static final Set<String> countryCodesNotInEUButEU261Applicable = new Set<String>{
    'NO',
    'CH',
    'IS'
  };

  public static Boolean countryAndCurrencyMatches(
    String country,
    String currencyCode
  ) {
    List<Settlement_Country_Setting__mdt> countrySetting = [
      SELECT Id
      FROM Settlement_Country_Setting__mdt
      WHERE Default_Currency__c = :currencyCode AND Country_Name__c = :country
    ];

    return countrySetting.size() > 0;
  }

  public static String getCountryNameByShortCode(String countryShortCode) {
    String convertedShortCode = countryCodeToIBANCountryCode(countryShortCode);
    String countryName;
    try {
      countryName = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :convertedShortCode
      ]
      .Country_Name__c;
    } catch (Exception e) {
      // Incorrect country short code, return null
    }

    return countryName;
  }

  /**
   * Converts the contry codes which are available for selection in the front end to the country codes which their banking system uses for IBAN, e.g. AX -> FI.
   * Source 1: https://www.iban.com/structure
   * Source 2: https://www.iban.com/iban-mandatory
   *
   * @param formCountryCode A String of the country short code derived from the form.
   * @return A String of the name of the "Parent" country short code
   */
  public static String countryCodeToIBANCountryCode(String formCountryCode) {
    if (countryCodeToIBANCountryCode.keySet().contains(formCountryCode)) {
      return countryCodeToIBANCountryCode.get(formCountryCode);
    }
    return formCountryCode;
  }

  /**
   * Asserts whether the country is within the european union.
   * Source 1: https://european-union.europa.eu/principles-countries-history/country-profiles_en?page=0
   * Source 2: https://www.iban.com/country-codes
   *
   * @param countryOrTerritoryCode A String of a country (or territory) short code.
   * @return A Boolean
   */
  public static Boolean isInEU(String countryOrTerritoryCode) {
    String countryCode = countryCodeToIBANCountryCode(countryOrTerritoryCode);

    if (countryCodesInEU.contains(countryCode)) {
      return true;
    }

    return false;
  }

  /**
   * Asserts whether the country is within the european union, Norway, Switzerland or Iceland (EU261).
   * Source 1: https://european-union.europa.eu/principles-countries-history/country-profiles_en?page=0
   * Source 2: https://www.iban.com/country-codes
   * Source 3: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm
   *
   * @param countryOrTerritoryCode A String of a country (or territory) short code.
   * @return A Boolean
   */
  public static Boolean isInEUOrNorwaySwitzerlandIceland(
    String countryOrTerritoryCode
  ) {
    if (isInEU(countryOrTerritoryCode)) {
      return true;
    } else if (
      countryCodesNotInEUButEU261Applicable.contains(countryOrTerritoryCode)
    ) {
      return true;
    }
    return false;
  }

  public static Map<String, Decimal> getAmountOfYearsYouCanWaitToFileAClaim(
    Set<String> countryNames
  ) {
    Map<String, Decimal> countryToTimeLimit = new Map<String, Decimal>{};

    List<Settlement_Country_Setting__mdt> countrySettings = [
      SELECT Maximum_Time_To_Claim_Compensation__c, Country_Name__c
      FROM Settlement_Country_Setting__mdt
      WHERE Country_Name__c IN :countryNames
    ];

    for (Settlement_Country_Setting__mdt countrySetting : countrySettings) {
      if (countrySetting.Maximum_Time_To_Claim_Compensation__c == null) {
        countryToTimeLimit.put(
          countrySetting.Country_Name__c,
          DEFAULT_AMOUNT_OF_YEARS_YOU_CAN_WAIT_TO_FILE_A_CLAIM
        );
      } else {
        countryToTimeLimit.put(
          countrySetting.Country_Name__c,
          countrySetting.Maximum_Time_To_Claim_Compensation__c
        );
      }
    }

    if (countryToTimeLimit.keySet().size() != countryNames.size()) {
      throw new CountryNotFoundException(
        'Could not find countrysetting for country.'
      );
    }

    return countryToTimeLimit;
  }

  public static String getVoucherMarketByCountryName(String countryName) {
    String toReturn = COUNTRY_NAME_TO_VOUCHER_MARKET.get(
      countryName.replace(' ', '').toLowerCase()
    );
    return toReturn == null ? 'LU' : toReturn;
  }

  private class CountryNotFoundException extends Exception {
  }
}
