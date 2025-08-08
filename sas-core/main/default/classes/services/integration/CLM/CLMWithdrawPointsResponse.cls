/**
 * Data structure and parser for CLM /clm/callcenter/withdrawPoints endpoint.
 */

public class CLMWithdrawPointsResponse {
  public String clmTransactionId { get; set; }
  public String ebNumber { get; set; }
  public String emailOnProfile { get; set; }
  public String partnerTransactionUid { get; set; }
  public String pointsWithdrawn { get; set; }
  public String transactionStatus { get; set; }

  public static CLMWithdrawPointsResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      CLMWithdrawPointsResponse.class
    );
    return (CLMWithdrawPointsResponse) jsonDeserializer.deserialize(json);
  }

  public static List<CLMWithdrawPointsResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<CLMWithdrawPointsResponse>.class
    );
    return (List<CLMWithdrawPointsResponse>) jsonDeserializer.deserialize(json);
  }
}
