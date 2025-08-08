public class SurveyInvitationUrlShortener {

  @InvocableMethod(label='SurveyInvitation_ShortUrl')
  public static List<String> executeSurveyInvitationShortUrl(List<RequestWrapper> requests) {
      String surveyInviteId = (!requests.isEmpty() && requests[0].surveyInviteId != null) ? String.valueOf(requests[0].surveyInviteId) : null;
      String surveyLink = (!requests.isEmpty() && requests[0].surveyInvitationLink != null) ? String.valueOf(requests[0].surveyInvitationLink) : null;
      if(!String.isEmpty(surveyLink) && 
         !String.isEmpty(surveyInviteId)){
          ShortUrlService.makeRequest(surveyLink, surveyInviteId);
      }
      return null;
 }

public class RequestWrapper {
  @InvocableVariable(label='surveyInviteId' description='surveyInviteIds')
  public String surveyInviteId;
  @InvocableVariable(label='surveyInvitationLink' description='surveyInvitationLinks')  
  public String surveyInvitationLink;
}
}