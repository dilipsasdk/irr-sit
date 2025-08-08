public without sharing class RedeemCompensationCardRequest {
  public Contact contact { get; private set; }
  public CompensationDetails compensationDetails { get; private set; }
  public String compensationCardNumber { get; private set; }

  public String origin { get; private set; }

  public String bookingReference { get; private set; }

  public class InvalidDataException extends Exception {
  }

  private static final Map<String, String> MARKET_TO_ORIGIN = new Map<String, String>{
    'dk-da' => 'Form - Compensation Card DK',
    'no-no' => 'Form - Compensation Card NO',
    'se-sv' => 'Form - Compensation Card SE',
    'default' => 'Form - Compensation Card International'
  };

  private static final Map<String, Claim.CompensationType> JSON_TO_COMPENSATION_TYPE = new Map<String, Claim.CompensationType>{
    'eurobonus' => Claim.CompensationType.EBPoints,
    'monetary' => Claim.CompensationType.Monetary,
    'voucher' => Claim.CompensationType.Voucher
  };

  public class Contact {
    public String firstName { get; private set; }
    public String lastName { get; private set; }
    public String email { get; private set; }
    public String phone { get; private set; }
    public String addressLine1 { get; private set; }
    public String addressLine2 { get; private set; }
    public String postalCode { get; private set; }
    public String city { get; private set; }
    public String country { get; private set; }
    public String euroBonusNumber { get; private set; }

    public Contact(RedeemCompensationCardJSON.Contact jsonData) {
      if (jsonData.address != null && jsonData.address.length() > 35) {
        // Racer supports maximum length of 35 characters for address lines.
        // We have two address lines so we'll just split the given address
        // across those. Can't handle more than 70 because of the Racer limit.
        if (jsonData.address.length() > 70) {
          throw new InvalidDataException(
            'Address too long. Length: ' + jsonData.address.length()
          );
        }
        addressLine1 = jsonData.address.substring(0, 35);
        addressLine2 = jsonData.address.substring(35);
      } else {
        addressLine1 = jsonData.address;
      }
      addressLine1 = jsonData.address;
      city = jsonData.city;
      firstName = jsonData.firstName;
      lastName = jsonData.lastName;
      postalCode = jsonData.postalCode;
      email = jsonData.email;
      phone = jsonData.phone;

      if (!String.isBlank(jsonData.country)) {
        country = CountryUtils.getCountryNameByShortCode(jsonData.country);
      }
      try {
        euroBonusNumber = Accounts.parseIntoEuroBonusNumber(
          jsonData.euroBonusNumber
        );
      } catch (Exception e) {
        euroBonusNumber = '';
      }
    }
  }

  public class CompensationDetails {
    public String bankAccountHolderName;
    public String bankAccountNumber;
    public String bankCountry;
    public String bankName;
    public String bankBic;

    public Money.CurrencyCode preferredCurrency;
    public Claim.CompensationType preferredCompensationMethod;
    public Claim.CompensationType preferredReimbursementMethod;

    public String referenceNumber;

    public CompensationDetails(
      RedeemCompensationCardJSON.CompensationDetails jsonData
    ) {
      this.bankAccountHolderName = jsonData.bankAccountHolderName;
      this.bankName = jsonData.bankName;
      this.bankBic = jsonData.bankBic;
      this.preferredCurrency = String.isBlank(jsonData.preferredCurrency)
        ? null
        : Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
            jsonData.preferredCurrency.toUpperCase()
          );
      this.preferredCompensationMethod = JSON_TO_COMPENSATION_TYPE.get(
        jsonData.preferredCompensationMethod
      );
      this.preferredReimbursementMethod = JSON_TO_COMPENSATION_TYPE.get(
        jsonData.preferredReimbursementMethod
      );

      if (!String.isBlank(jsonData.bankCountry)) {
        this.bankCountry = CountryUtils.getCountryNameByShortCode(
          jsonData.bankCountry
        );
      }

      if (!String.isBlank(jsonData.bankAccountNumber)) {
        if (!String.isBlank(jsonData.bankRoutingNumber)) {
          // US bank account numbers should be sent to Racer as {accountNumber}ABA{routingNumber}
          // Other countries have only an account number.
          this.bankAccountNumber =
            StringUtils.removeWhitespace(jsonData.bankAccountNumber) +
            'ABA' +
            StringUtils.removeWhitespace(jsonData.bankRoutingNumber);
        } else {
          this.bankAccountNumber = jsonData.bankAccountNumber.replace(' ', '');
        }
      }
    }
  }

  public RedeemCompensationCardRequest(RedeemCompensationCardJSON jsonData) {
    String origin = MARKET_TO_ORIGIN.get(jsonData.metaData.market);
    this.origin = origin != null ? origin : MARKET_TO_ORIGIN.get('default');

    contact = new Contact(jsonData.formData.contact);
    compensationDetails = new CompensationDetails(
      jsonData.formData.compensationDetails
    );

    if (!Booking.isValidBookingReference(jsonData.formData.bookingReference)) {
      throw new InvalidDataException(
        'Invalid booking reference: ' + jsonData.formData.bookingReference
      );
    }

    bookingReference = jsonData.formData.bookingReference;
    compensationCardNumber = jsonData.formData.compensationCardNumber;
  }
}
