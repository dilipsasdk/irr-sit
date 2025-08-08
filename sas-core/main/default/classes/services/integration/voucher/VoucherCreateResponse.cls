/**
 * Data structure and parser for Voucher API POST /vouchers endpoint.
 */

public class VoucherCreateResponse {
  public String link { get; set; }
  public String caseId { get; set; }

  public static VoucherCreateResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      VoucherCreateResponse.class
    );
    return (VoucherCreateResponse) jsonDeserializer.deserialize(json);
  }

  public static List<VoucherCreateResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<VoucherCreateResponse>.class
    );
    return (List<VoucherCreateResponse>) jsonDeserializer.deserialize(json);
  }
}
