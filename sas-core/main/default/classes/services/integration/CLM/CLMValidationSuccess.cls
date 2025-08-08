/**
 * Class for parsing a succesful response from the CLM verifyOtp API call.
 */
public with sharing class CLMValidationSuccess {
  public String status { get; set; }
  public String databaseUUID { get; set; }
  public String thirdPartyId { get; set; }
  public Date otpExiration { get; set; }
  public String otpReciever { get; set; }
  public String messageFromSender { get; set; }
  public String idFromSender { get; set; }

  public static CLMValidationSuccess parse(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      CLMValidationSuccess.class
    );
    return (CLMValidationSuccess) jsonDeserializer.deserialize(json);
  }

  public static List<CLMValidationSuccess> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<CLMValidationSuccess>.class
    );
    return (List<CLMValidationSuccess>) jsonDeserializer.deserialize(json);
  }
}
