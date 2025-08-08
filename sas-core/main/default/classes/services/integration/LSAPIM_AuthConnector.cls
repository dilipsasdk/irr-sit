global with sharing class LSAPIM_AuthConnector extends C_LocalAuthConnector {
  private static final String AUTH_URL = Test.isRunningTest()
    ? 'TESTPATH'
    : C_Settings.getSettings('LSAPIM').get('LSAPIM_TokenURL') +
      '/api/security/oauth/token';

  /**
   * Authenticates against the service
   * @param username The username to use when authenticating
   * @param password he password used when authenticating
   * @param param1 Subscription key
   * @param param2 Resource for call
   * @return The oauth access token
   */
  global override String authenticate(
    String username,
    String password,
    String param1,
    String param2
  ) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(AUTH_URL);
    request.setMethod('POST');
    Map<String, String> requestBody = new Map<String, String>{
      'client_id' => username,
      'client_secret' => password,
      'audience' => param2,
      'grant_type' => 'client_credentials'
    };
    request.setBody(JSON.serialize(requestBody));
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Ocp-Apim-Subscription-Key', param1);

    HttpResponse res = http.send(request);
    AuthResult ar = (AuthResult) JSON.deserialize(
      res.getBody(),
      AuthResult.class
    );
    if (res.getStatusCode() != 200) {
      throw new LSAPIMException(
        'Error authenticating to LSAPIM: ' +
          res.getStatusCode() +
          ': ' +
          ar.error
      );
    }
    return ar.access_token;
  }

  /**
        JSON structure for the authentication result
    */
  private class AuthResult {
    String access_token;
    String error;
    String error_description;
  }

  /**
   * Custom exception class for LSAPIM auth exceptions
   */
  public class LSAPIMException extends Exception {
  }
}
