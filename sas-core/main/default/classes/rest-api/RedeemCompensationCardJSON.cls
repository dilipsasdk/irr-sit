global class RedeemCompensationCardJSON {
  global FormData formData;
  global MetaData metaData;

  global class Contact {
    global String firstName;
    global String lastName;
    global String email;
    global String phone;
    global String address;
    global String postalCode;
    global String city;
    global String country;
    global String euroBonusNumber;
  }

  global class CompensationDetails {
    global String bankAccountHolderName;
    global String bankAccountNumber;
    global String bankCountry;
    global String bankName;
    global String bankBic;
    global String bankRoutingNumber;

    global String preferredCurrency;
    global String preferredCompensationMethod;
    global String preferredReimbursementMethod;

    global String referenceNumber;
  }

  global class FormData {
    global String type;

    global String compensationCardNumber;
    global String bookingReference;

    global Contact contact;

    global CompensationDetails compensationDetails;
  }

  global class MetaData {
    global String market;
  }

  public static RedeemCompensationCardJSON parse(String json) {
    return (RedeemCompensationCardJSON) System.JSON.deserialize(
      json,
      RedeemCompensationCardJSON.class
    );
  }
}
