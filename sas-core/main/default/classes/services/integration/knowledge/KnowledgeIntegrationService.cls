public without sharing class KnowledgeIntegrationService {
  private static final String API_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('Contentful_API_Key');

  private static String ENDPOINT = Test.isRunningTest() 
  ? 'SSIAdapter'
  : 'callout:SAS_SSI';

  public static KnowledgeIntegrationService newInstance() {
    return (KnowledgeIntegrationService) SAS_Service_Application.Service.newInstance(
      KnowledgeIntegrationService.class
    );
  }

  public class IntegrationException extends Exception {
  }

  public static KnowledgeJsonToApex fetchContentfulContent() {
    HttpResponse response = makeRequest(HttpUtils.HTTP_METHOD.GET);

    if (response.getStatusCode() == 404) {
      return null;
    }
    return KnowledgeJsonToApex.parse(response.getBody());
  }

  public static HttpResponse makeRequest(HttpUtils.HTTP_METHOD method) {
    HttpRequest request = new HttpRequest();

    request.setEndpoint(ENDPOINT);
    request.setHeader('authorization', API_KEY);
    request.setMethod(String.valueOf(method));
    request.setTimeout(120000);

    Http http = new Http();
    HttpResponse response = http.send(request);

    return response;
  }
}
