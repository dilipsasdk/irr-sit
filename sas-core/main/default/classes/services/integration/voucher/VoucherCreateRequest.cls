/**
 * Data structure and parser for Voucher API POST /vouchers endpoint.
 */

public class VoucherCreateRequest {
  public String type; // See VoucherService.VoucherType enum. Internal representation as string to make JSON serialization straightforward.
  public String subType; // See VoucherService.VoucherSubType enum Internal representation as string to make JSON serialization straightforward.
  public String voucherCurrency; // See VoucherService.VoucherCurrency enum Internal representation as string to make JSON serialization straightforward.
  // real field name is currency, but that is reserved in Salesforce so we're replacing it when building the final JSON.
  public String caseId;
  public String pnr;
  public PersonalDetails personalDetails;
  public VoucherCustomizations voucherCustomizations;

  public class PersonalDetails {
    public String firstName;
    public String lastName;
    public String email;
    public String accessCode;
    public String addressLine;
    public String postalCode;
    public String cityName;
    public String countryName;

    public PersonalDetails(
      String firstName,
      String lastName,
      String email,
      String accessCode,
      String addressLine,
      String postalCode,
      String cityName,
      String countryName
    ) {
      this.firstName = sanitizeStringForVoucherAPI(firstName);
      this.lastName = sanitizeStringForVoucherAPI(lastName);
      this.email = email;
      this.accessCode = accessCode;
      this.addressLine = addressLine;
      this.postalCode = postalCode;
      this.cityName = cityName;
      this.countryName = countryName;
    }
  }

  public class VoucherCustomizations {
    public Integer value;

    public VoucherCustomizations(Integer value) {
      this.value = value;
    }
  }

  public VoucherCreateRequest(
    VoucherIntegrationService.VoucherType type,
    VoucherIntegrationService.VoucherSubType subType,
    String voucherCurrency,
    Integer value,
    String firstName,
    String lastName,
    String email,
    String accessCode,
    String addressLine,
    String postalCode,
    String cityName,
    String countryName,
    String pnr
  ) {
    this.type = String.valueOf(type);
    this.subType = String.valueOf(subType);
    this.voucherCurrency = voucherCurrency;
    this.caseId = accessCode;

    if (pnr != null) {
      this.pnr = pnr;
    }

    personalDetails = new PersonalDetails(
      firstName,
      lastName,
      email,
      accessCode,
      addressLine,
      postalCode,
      cityName,
      countryName
    );
    voucherCustomizations = new voucherCustomizations(value);
  }

  /**
   * Sanitizes a given string to a form acceptable by the Voucher API (and
   * Amadeus). The function converts scandics to two-letter forms and drops
   * other non-latin characters.
   *
   * The voucher API accepts only latin alphabet characters.
   *
   * @param s String to sanitize
   */
  private static String sanitizeStringForVoucherAPI(String s) {
    if (s == null) {
      return '';
    }
    String toReturn = s.replaceAll('ä', 'ae')
      .replaceAll('Ä', 'AE')
      .replaceAll('ö', 'oe')
      .replaceAll('Ö', 'OE')
      .replaceAll('ø', 'oe')
      .replaceAll('Ø', 'OE')
      .replaceAll('æ', 'ae')
      .replaceAll('Æ', 'AE')
      .replaceAll('å', 'o')
      .replaceAll('Å', 'o');

    Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
    Matcher matcher = nonAlphanumeric.matcher(toReturn);

    return matcher.replaceAll('');
  }
}
