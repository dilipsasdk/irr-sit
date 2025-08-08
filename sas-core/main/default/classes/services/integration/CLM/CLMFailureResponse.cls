/**
 * Data structure and parser for CLM /clm/callcenter/addPoints endpoint.
 */

public class CLMFailureResponse {
  public String error { get; set; }
  public String message { get; set; }
  public String path { get; set; }
  public String requestToken { get; set; }
  public String status { get; set; }
  public String timestamp { get; set; }

  public static CLMFailureResponse parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      CLMFailureResponse.class
    );
    return (CLMFailureResponse) jsonDeserializer.deserialize(json);
  }

  public static List<CLMFailureResponse> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<CLMFailureResponse>.class
    );
    return (List<CLMFailureResponse>) jsonDeserializer.deserialize(json);
  }
}
