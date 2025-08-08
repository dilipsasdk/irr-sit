/**
 * Data structure and parser for CLM /clm/callcenter/addPoints endpoint.
 */

public class CLMAddPointsResponse {
  public String clmTransactionId { get; set; }
  public String ebNumber { get; set; }
  public String partnerTrnUid { get; set; }
  public String pointsAdded { get; set; }
  public String transactionStatus { get; set; }

  public static CLMAddPointsResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      CLMAddPointsResponse.class
    );
    return (CLMAddPointsResponse) jsonDeserializer.deserialize(json);
  }

  public static List<CLMAddPointsResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<CLMAddPointsResponse>.class
    );
    return (List<CLMAddPointsResponse>) jsonDeserializer.deserialize(json);
  }
}
