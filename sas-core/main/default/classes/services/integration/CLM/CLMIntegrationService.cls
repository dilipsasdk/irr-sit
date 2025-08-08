/**
 * Service for making requests to Comarch Loyalty Management (CLM) through the Loyalty APIM.
 */
public without sharing class CLMIntegrationService {
  private static final String PARTNER_ID = 'SKSFSC'; // Salesforce Service Cloud
  private static final String CLM_CREDENTIAL_OLD = 'callout:CLM_APIM';
  private static final String CLM_CREDENTIAL_NEW = 'callout:CLM_APIM_V2';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('CLM').get('CLM_APIM_Subscription_Key');

  private static final String CLM_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('CLM').get('CLM_Key');

  public enum POINTS_TYPE {
    BASIC,
    EXTRA
  }

  public enum OTPOperation {
    REQUEST,
    VERIFY
  }

  private static final Map<OTPOperation, String> OTP_OPERATION_TO_ENDPOINT = new Map<OTPOperation, String>{
    OTPOperation.REQUEST => 'ccRequestOtp',
    OTPOperation.VERIFY => 'verifyOtp'
  };

  public static final String OTP_ENDPOINT =
    CLM_CREDENTIAL_NEW + '/api/profile-notification-and-security-service/';

  public static CLMIntegrationService newInstance() {
    return (CLMIntegrationService) SAS_Service_Application.Service.newInstance(
      CLMIntegrationService.class
    );
  }

  public class AddPointsResponse {
    public Boolean isSuccess;
    public CLMAddPointsResponse successResponse;
    public CLMFailureResponse failureResponse;

    AddPointsResponse(CLMAddPointsResponse rawSuccessResponse) {
      this.isSuccess = true;
      this.successResponse = rawSuccessResponse;
    }

    AddPointsResponse(CLMFailureResponse rawFailureResponse) {
      this.isSuccess = false;
      this.failureResponse = rawFailureResponse;
    }
  }

  public class IntegrationException extends Exception {
  }

  /** Attempts to add a number of Extra points to a EuroBonus customer using CLM APIs.
   *
   * @param euroBonusNumber EuroBonus number of the customer for whom points should be added.
   * @param pointsToAdd Number of points to add to the customer.
   * @param ADUserEmail Email address of the user performing the action. Stored in CLM for reference.
   * @param transactionId Unique transaction ID of this points transaction.  Stored in CLM for reference.
   * @param claimId ID of the claim this is related to. Optional.  Stored in CLM for reference.
   * @param reasonForPoints Free text reason for this points transaction. Optional.
   * @param bookingReference A booking reference this points transaction is related to. Optional.
   * @param ticketNumber A ticket number this points transaction is related to. Optional.
   *
   * @throws IntegrationError on failures.
   *
   * @return CLMAddPointsResponse The parsed CLM response on status codes less than 400.
   */
  public AddPointsResponse addPointsToCustomer(
    String euroBonusNumber,
    Integer pointsToAdd,
    String ADUserEmail,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    if (String.isBlank(ADUserEmail)) {
      C_Log.log(
        C_Log.Severity.Error,
        'Attempted to query CLM without AD User',
        null,
        'CLMIntegration',
        null
      );
      throw new IntegrationException('AD User email cannot be empty.');
    }
    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'AD-User' => ADUserEmail,
      'CLMbase64' => CLM_KEY
    };

    String requestBody = constructUpdatePointsBody(
      euroBonusNumber,
      pointsToAdd,
      reasonForPoints,
      transactionId,
      bookingReference,
      ticketNumber,
      claimId
    );

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      CLM_CREDENTIAL_OLD + '/clm/callcenter/addPoints',
      requestBody,
      extraRequestHeaders
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    if (response.getStatusCode() >= 400) {
      // Transaction failure
      return new AddPointsResponse(
        CLMFailureResponse.parse(response.getBody())
      );
    }

    return new AddPointsResponse(
      CLMAddPointsResponse.parse(response.getBody())
    );
  }

  /** Attempts to withdraw a number of Extra points from a EuroBonus customer using CLM APIs.
   *
   * @param euroBonusNumber EuroBonus number of the customer from whom points should be withdrawn.
   * @param pointsToWithdraw Number of points to withdraw from the customer.
   * @param ADUserEmail Email address of the user performing the action. Stored in CLM for reference.
   * @param transactionId Unique transaction ID of this points transaction.  Stored in CLM for reference.
   * @param claimId ID of the claim this is related to. Optional.  Stored in CLM for reference.
   * @param reasonForPoints Free text reason for this points transaction. Optional.
   * @param bookingReference A booking reference this points transaction is related to. Optional.
   * @param ticketNumber A ticket number this points transaction is related to. Optional.
   *
   * @throws IntegrationError on failures.
   *
   * @return CLMWithdrawPointsResponse The parsed CLM response on status codes less than 400.
   */
  public CLMWithdrawPointsResponse withdrawPointsFromCustomer(
    String euroBonusNumber,
    Integer pointsToWithdraw,
    String ADUserEmail,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    if (String.isBlank(ADUserEmail)) {
      C_Log.log(
        C_Log.Severity.Error,
        'Attempted to query CLM without AD User',
        null,
        'CLMIntegration',
        null
      );
      throw new IntegrationException('AD User email cannot be empty.');
    }
    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'AD-User' => ADUserEmail,
      'CLMbase64' => CLM_KEY
    };

    String requestBody = constructUpdatePointsBody(
      euroBonusNumber,
      pointsToWithdraw,
      reasonForPoints,
      transactionId,
      bookingReference,
      ticketNumber,
      claimId
    );

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      CLM_CREDENTIAL_OLD + '/clm/callcenter/withdrawPoints',
      requestBody,
      null
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return CLMWithdrawPointsResponse.parse(response.getBody());
  }

  private String constructUpdatePointsBody(
    String euroBonusNumber,
    Integer pointsToAdd,
    String reasonForPoints,
    String transactionId,
    String bookingReference,
    String ticketNumber,
    String claimId
  ) {
    // throws on invalid number
    Accounts.parseIntoEuroBonusNumber(euroBonusNumber);

    Map<String, Object> bodyMap = new Map<String, Object>{
      'ebNumber' => euroBonusNumber,
      'pointType' => String.valueOf(POINTS_TYPE.EXTRA),
      'partnerTrnUid' => transactionId,
      'partnerid' => PARTNER_ID,
      'numPoints' => pointsToAdd
    };

    if (reasonForPoints != null) {
      bodyMap.put('reason', reasonForPoints);
    }
    if (claimId != null) {
      bodyMap.put('claimId', claimId);
    }
    if (ticketNumber != null) {
      bodyMap.put('ticketno', ticketNumber);
    }
    if (bookingReference != null) {
      bodyMap.put('pnr', bookingReference);
    }

    return JSON.Serialize(bodyMap);
  }

  public OTPVerification verifyCustomer(
    String euroBonusNumber,
    Integer enteredOtp,
    String userEmail,
    OTPOperation otpOp
  ) {
    String fullPath = OTP_ENDPOINT + OTP_OPERATION_TO_ENDPOINT.get(otpOp);

    Map<String, Object> bodyObject = new Map<String, Object>{
      'euroBonusNumber' => euroBonusNumber
    };

    if (otpOp == OTPOperation.VERIFY && enteredOtp != null) {
      bodyObject.put('otpCode', enteredOtp);
    }
    String requestBody = JSON.serialize(bodyObject);

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'requesterid' => userEmail
    };

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      fullPath,
      requestBody,
      extraRequestHeaders
    );

    if (response.getStatusCode() == 400) {
      return new OTPVerification(
        CLMValidationFailure.parse(response.getBody()),
        euroBonusNumber
      );
    }

    return new OTPVerification(
      CLMValidationSuccess.parse(response.getBody()),
      euroBonusNumber
    );
  }

  /**
   * Constructs and fires a request to the CLM APIM.
   *
   * Fills in authentication headers.
   *
   * Any extra headers passed will overwrite existing headers with the same name.
   *
   * @param method HTTP method to use. See HttpRequest.setMethod for more info.
   * @param path The endpoint with queryparams to which make the query to, without the base url included in callout.
   * @param body Request body which will be passed directly to HttpRequest.setBody().
   * @param extraHeaders Any additional headers which should be sent along the request as a map from name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body, // Caller is responsible for creating correct object type.
    Map<String, String> extraHeaders
  ) {
    HttpRequest request = new HttpRequest();

    request.setEndpoint(path);
    request.setMethod(String.valueOf(method));

    request.setHeader('Ocp-Apim-Subscription-Key', SUBSCRIPTION_KEY);
    request.setHeader('Content-Type', 'application/json');

    request.setTimeout(120000); // In milliseconds. CLM is sometimes slow.

    if (extraHeaders != null) {
      for (String header : extraHeaders.keySet()) {
        request.setHeader(header, extraHeaders.get(header));
      }
    }

    if (body != null) {
      request.setBody(body);
    }

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 500) {
      // Log and throw again. Typically can't be resolved.
      String message =
        'CLMIntegration query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus();

      C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
      C_Log.log(
        C_Log.Severity.Error,
        message,
        null,
        'CLMIntegration',
        httpDataLog
      );

      throw new IntegrationException(
        'CLMIntegration query failed with: ' +
          response.getStatusCode() +
          ': ' +
          response.getStatus()
      );
    }

    return response;
  }
}
