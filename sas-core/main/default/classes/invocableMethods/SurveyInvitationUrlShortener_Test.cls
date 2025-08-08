@IsTest
public class SurveyInvitationUrlShortener_Test {
  private static final String CONTENT_TYPE = 'application/json';
  private static final String SURVEY_INVITE_ID = '0KsRR0000000Kd3';
  private static final Integer STATUS_CODE_SUCCESS = 201;
  private static final Integer STATUS_CODE_FAILURE = 401;
  private static final String SURVEY_INVITE_LINK = 'https://www.flysas.com';
  private static final String BODY = '{"shortenedURL":"sas.se/travel/t/1N1Fq"}';
  
  @IsTest
  static void surveyInvitationUrlShortenerSuccessTest() {
      List<SurveyInvitationUrlShortener.RequestWrapper> requests = new List<SurveyInvitationUrlShortener.RequestWrapper>();
      SurveyInvitationUrlShortener.RequestWrapper reqWrap = new SurveyInvitationUrlShortener.RequestWrapper();
      reqWrap.surveyInviteId = SURVEY_INVITE_ID;
      reqWrap.surveyInvitationLink = SURVEY_INVITE_LINK;
      requests.add(reqWrap);
      C_CalloutMock mockObj = new C_CalloutMock(BODY, STATUS_CODE_SUCCESS, CONTENT_TYPE);
      Test.setMock(HttpCalloutMock.class, mockObj);
      SurveyInvitationUrlShortener.executeSurveyInvitationShortUrl(requests);
  }
    
  @IsTest
  static void surveyInvitationUrlShortenerFailTest() {
      List<SurveyInvitationUrlShortener.RequestWrapper> requests = new List<SurveyInvitationUrlShortener.RequestWrapper>();
      SurveyInvitationUrlShortener.RequestWrapper reqWrap = new SurveyInvitationUrlShortener.RequestWrapper();
      reqWrap.surveyInviteId = SURVEY_INVITE_ID;
      reqWrap.surveyInvitationLink = SURVEY_INVITE_LINK;
      requests.add(reqWrap);
      C_CalloutMock mockObj = new C_CalloutMock(BODY, STATUS_CODE_FAILURE, CONTENT_TYPE);
      Test.setMock(HttpCalloutMock.class, mockObj);
      try{
          SurveyInvitationUrlShortener.executeSurveyInvitationShortUrl(requests);
      }catch(Exception ex){
          system.debug(ex.getMessage());
      }
      
  }
}