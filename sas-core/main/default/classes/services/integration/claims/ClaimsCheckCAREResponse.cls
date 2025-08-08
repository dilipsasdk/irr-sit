/**
 * Data structure and parser for Voucher API POST /vouchers endpoint.
 */

public class ClaimsCheckCAREResponse {
  public Boolean claimsfound { get; set; }

  public static ClaimsCheckCAREResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      ClaimsCheckCAREResponse.class
    );
    return (ClaimsCheckCAREResponse) jsonDeserializer.deserialize(json);
  }

  public static List<ClaimsCheckCAREResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<ClaimsCheckCAREResponse>.class
    );
    return (List<ClaimsCheckCAREResponse>) jsonDeserializer.deserialize(json);
  }
}
