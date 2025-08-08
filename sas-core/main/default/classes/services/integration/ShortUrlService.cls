/**
 * Service for making requests to Short URL
 */
public without sharing class ShortUrlService {
  private static final String CONTENT_TYPE = 'Content-Type';
  private static final String SHORTENED_URL = 'shortenedURL';
  private static final String SHORT_URL = 'SHORT_URL';
  private static final String ACCEPT = 'Accept';
  private static final String APPLICATION_JSON = 'application/json';
  private static final String USER_AGENT = 'User-Agent';
  private static final String USER_AGENT_VALUE = 'SALESFORCE-SERVICE-CLOUD-CS-SOLUTIONS';
  private static final String API_PATH = 'callout:TravelURLShortenerAPI';
  private static final String API_METHOD = 'POST';
  private static final String URL = 'url';
  private static final String NUMBER_OF_CHARS = 'numberOfCharacters';
  private static final String TTL = 'ttl';

  public class IntegrationException extends Exception {
  }
    
    @future(callout=true)
    public static void makeRequest(String surveyLink, String surveyInvitationId) {
        HttpResponse response = new HttpResponse();
        String requestBody;
        try{
            Integer expireShortLinkAfterSecond = Integer.valueOf(System.Label.ExpireShortLinkAfterSecond);
            Map<String, Object> requestMap = new Map<String, Object>{ URL => surveyLink, NUMBER_OF_CHARS =>5, TTL =>expireShortLinkAfterSecond };
            requestBody = JSON.serialize(requestMap);
            response = makeRequest(API_METHOD, API_PATH, requestBody);
            String tinyUrl = '';
            
            List<SurveyInvitation> surveyInvitationList = getSurveyInvitation(surveyInvitationId);
    
            tinyUrl = getTinyURL(response.getBody());
            if(!surveyInvitationList.isEmpty()){
                surveyInvitationList[0].Short_URL__c = tinyUrl;
                update surveyInvitationList[0];
            }
       }catch(Exception ex){
            system.debug(ex.getMessage());
       }
    }
    
  public static string getTinyURL(string jsonString){
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        String shortenedURL = (String) jsonMap.get(SHORTENED_URL);
        return shortenedURL;
    }
    
   public static List<SurveyInvitation> getSurveyInvitation(string surveyInvitationId){
        return [SELECT Id FROM SurveyInvitation WHERE Id = :surveyInvitationId 
                                                LIMIT 1];
    }

  public static HttpResponse makeRequest(String method,
                                         String path,
                                         String body) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(path);
    request.setMethod(method);
    request.setHeader(USER_AGENT, USER_AGENT_VALUE);
    request.setHeader(ACCEPT, APPLICATION_JSON);
    request.setHeader(CONTENT_TYPE, APPLICATION_JSON);

    if (body != null) {
      request.setBody(body);
    }
    request.setTimeout(120000);
    Http http = new Http();
    try {
      HttpResponse response = http.send(request);
      if (response.getStatusCode() == 200 || 
          response.getStatusCode() == 201) {
          return response;
      }
      else {
        String message = response.getStatusCode() + ': ' + response.getStatus();
        C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
        C_Log.log(C_Log.Severity.Error, message, null, SHORT_URL, httpDataLog);
        throw new IntegrationException(SHORT_URL+'-'+response.getStatusCode() + ': ' + response.getStatus());
      }
    }
     catch (CalloutException e) {
      C_Log.log(C_Log.Severity.Error, e.getMessage(), null, SHORT_URL, C_Log.generateLogHttpData(request));
      throw new IntegrationException(e.getMessage());
    }
  }
}