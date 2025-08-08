public with sharing class VoucherValidateResponseV2 {
  public String id;
  public String type;
  public Integer balance;
  public String voucherCurrency;
  public CustomerDetails customerDetails;
  public FlightDetails flightDetails;

  private static final Map<String, String> replacementMap = new Map<String, String>{
    'currency' => 'voucherCurrency'
  };

  public class CustomerDetails {
    public String firstName;
    public String lastName;
    public String phoneNumber;
    public String email;

    public CustomerDetails(
      String firstName,
      String lastName,
      String phoneNumber,
      String email
    ) {
      this.firstName = firstName;
      this.lastName = lastName;
      this.phoneNumber = phoneNumber;
      this.email = email;
    }
  }

  public class FlightDetails {
    public String flightNumber;
    public String flightDate;
    public String pnr;

    public FlightDetails(String flightNumber, String flightDate, String pnr) {
      this.flightNumber = flightNumber;
      this.flightDate = flightDate;
      this.pnr = pnr;
    }
  }

  public static VoucherValidateResponseV2 parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      VoucherValidateResponseV2.class,
      replacementMap
    );
    return (VoucherValidateResponseV2) jsonDeserializer.deserialize(json);
  }

  public static List<VoucherValidateResponseV2> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<VoucherValidateResponseV2>.class,
      replacementMap
    );
    return (List<VoucherValidateResponseV2>) jsonDeserializer.deserialize(json);
  }
}
