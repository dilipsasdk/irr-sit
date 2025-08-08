@IsTest
global class CLMMock implements HttpCalloutMock {
  public static String VALID_CLM_EBNUMBER = '123456789';
  public static Integer VALID_CLM_OTP = 999999;
  public static String ABUSED_CLM_EBNUMBER = '987654321';
  public static Integer INVALID_CLM_OTP = 100000;

  private String endpoint;

  global HttpResponse respond(HttpRequest req) {
    endpoint = req.getEndpoint();
    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);
    res.setHeader('Content-Type', 'application/json');

    if (endpoint.contains(CLMIntegrationService.OTP_ENDPOINT)) {
      if (endpoint.contains('ccRequestOtp')) {
        if (req.getBody().contains(String.valueOf(VALID_CLM_EBNUMBER))) {
          res.setBody(CLMMockResponses.REQUEST_OTP_RESPONSE);
        } else if (
          req.getBody().contains(String.valueOf(ABUSED_CLM_EBNUMBER))
        ) {
          res.setStatusCode(400);
          res.setBody(CLMMockResponses.ABUSED_OTP_RESPONSE);
        } else {
          res.setStatusCode(404);
        }
      } else if (endpoint.contains('verifyOtp')) {
        if (req.getBody().contains(String.valueOf(VALID_CLM_OTP))) {
          res.setBody(CLMMockResponses.VERIFY_OTP_RESPONSE);
        } else if (req.getBody().contains(String.valueOf(INVALID_CLM_OTP))) {
          res.setStatusCode(400);
          res.setBody(CLMMockResponses.INVALID_OTP_RESPONSE);
        } else {
          res.setStatusCode(404);
        }
      }
    } else {
      res.setStatusCode(404);
    }
    return res;
  }
}
