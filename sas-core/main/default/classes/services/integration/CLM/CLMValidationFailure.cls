/**
 * Class for parsing a failure response from the CLM verifyOtp API call.
 */
public with sharing class CLMValidationFailure {
  public String error { get; set; }
  public Integer errorCode { get; set; }
  public String status { get; set; }
  public String databaseUUID { get; set; }
  public String thirdPartyId { get; set; }
  public Date otpExiration { get; set; }
  public String otpReciever { get; set; }
  public Integer otpRetryCount { get; set; }
  public Integer otpMaxRetryCount { get; set; }
  public Integer otpSendCount { get; set; }
  public Integer otpMaxSendCount { get; set; }

  public static CLMValidationFailure parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      CLMValidationFailure.class
    );
    return (CLMValidationFailure) jsonDeserializer.deserialize(json);
  }

  public static List<CLMValidationFailure> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<CLMValidationFailure>.class
    );
    return (List<CLMValidationFailure>) jsonDeserializer.deserialize(json);
  }
}
