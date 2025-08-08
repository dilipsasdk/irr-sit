/**
 * Data structure and parser for Voucher API GET /vouchers/validate/vouchers/{voucherID}/{PNR} endpoint.
 */

public class VoucherValidateResponse {
  public String departureTime { get; set; }
  public String lastName { get; set; }
  public String ticketNumber { get; set; }
  public Decimal amount { get; set; }
  public String flightDate { get; set; }
  public String serviceClass { get; set; }
  public String type { get; set; }
  public String flightNumber { get; set; }
  public String firstName { get; set; }
  public String phone { get; set; }
  public String pnr { get; set; }
  public String subType { get; set; }
  public String voucherCurrency { get; set; }
  public String email { get; set; }

  private static final Map<String, String> replacementMap = new Map<String, String>{
    'currency' => 'voucherCurrency'
  };

  public static VoucherValidateResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      VoucherValidateResponse.class,
      replacementMap
    );
    return (VoucherValidateResponse) jsonDeserializer.deserialize(json);
  }

  public static List<VoucherValidateResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<VoucherValidateResponse>.class,
      replacementMap
    );
    return (List<VoucherValidateResponse>) jsonDeserializer.deserialize(json);
  }
}
