@IsTest
public with sharing class CLMMockResponses {
  public static final String REQUEST_OTP_RESPONSE = '{ "status": "SENT", "databaseUUID": "F2572C8C-97C8-4F51-9F0E-A597C9D8E5DA", "otpReciever": "+467******56", "messageFromSender": "Queued", "idFromSender": "RRcjVXLAT48QnqstLpAuuW" }';
  public static final String VERIFY_OTP_RESPONSE = '{ "status": "VERIFIED", "thirdPartyId": null, "databaseUUID": "F2572C8C-97C8-4F51-9F0E-A597C9D8E5DA" }';
  public static final String INVALID_OTP_RESPONSE = '{ "otpExpiry": "2023-10-13T15:06:07.454Z", "otpRetryCount": 2, "error": "Status is not verified", "errorCode": 8, "status": "RETRY", "thirdPartyId": null, "databaseUUID": "F2572C8C-97C8-4F51-9F0E-A597C9D8E5DA" }';
  public static final String ABUSED_OTP_RESPONSE = '{ "error": "OTP code abused", "errorCode": 8, "status": "ABUSED", "databaseUUID": "F2572C8C-97C8-4F51-9F0E-A597C9D8E5DA" }';
}
