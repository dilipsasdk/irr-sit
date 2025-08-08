@IsTest
public with sharing class Knowledges_IntegrationTest {

  private static final String USER_EMAIL = 'Test.TestLoginFlow@sas.se.test';

  @TestSetup 
  static void setup() {
    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    String uName = USER_EMAIL + C_Util.generateUUID();
    User u = new User(
      FirstName = 'TEST',
      LastName = 'TESTLoginFlow',
      Email = USER_EMAIL,
      Username = uName,
      EmailEncodingKey = 'ISO-8859-1',
      Alias = uName.substring(uName.length()-6),
      TimeZoneSidKey = 'Europe/Berlin',
      LocaleSidKey = 'en_US',
      LanguageLocaleKey = 'en_US',
      ProfileId = p.Id
    );
    u.UserPermissionsKnowledgeUser = true;
    insert u;

    System.runAs(u) {
      List<Knowledge__kav> knowledges = new List<Knowledge__kav>();

      knowledges.add(new Knowledge__kav(
        Title = 'Knowledge1 title',
        FCS_Body__c = 'Knowledge1 body',
        UrlName = 'testy1',
        Contentful_Id__c = 'testy1')
      );

      knowledges.add(new Knowledge__kav(
        Title = 'Knowledge2 title',
        FCS_Body__c = 'Knowledge2 body',
        UrlName = 'testy2',
        Contentful_Id__c = 'testy2')
      );

      knowledges.add(new Knowledge__kav(
        Title = 'randomTitle',
        FCS_Body__c = 'test3',
        UrlName = 'testy3',
        Contentful_Id__c = 'testy3')
      );

      insert knowledges;

      knowledges = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav];
      for (Knowledge__kav knowledge: knowledges) {
        KbManagement.PublishingService.publishArticle(knowledge.KnowledgeArticleId, true);
      }
    }
  }

  @IsTest
  public static void shouldFetchAndCreateKnowledges() {
    User u = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
    System.runAs(u) {
      Test.setMock(HttpCalloutMock.class, new APIMMock());

      Test.startTest();
      KnowledgeService.initiateContentFetch();
      Test.stopTest();

      List<Knowledge__kav> knowledges = [SELECT Id FROM Knowledge__kav];		
      System.assert(knowledges.size() == 4, 'Missing knowledge should be created');
    }
  }

  @IsTest
  public static void shouldFetchAndUpdateKnowledges() {
    User u = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
    System.runAs(u) {
      Test.setMock(HttpCalloutMock.class, new APIMMock());

      Test.startTest();
      KnowledgeService.initiateContentFetch();
      Test.stopTest();

      Knowledge__kav knowledge = [SELECT Id, Title, UrlName FROM Knowledge__kav WHERE UrlName = 'testy3' limit 1];	
      System.assert(knowledge.Title == 'testy3', 'The title should be updated');
    }
  }

  @IsTest
  public static void shouldCreateKnowledgeFromWebhook() {
    User u = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
    KnowledgeJsonToApex requestBody = KnowledgeJsonToApex.parse(APIMMockResponses.CONTENTFUL_PUBLISHED_ARTICLE_BODY);

    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();
    RestContext.request.httpMethod = 'POST';
        
    System.runAs(u) {
      Test.setMock(HttpCalloutMock.class, new APIMMock());

      Test.startTest();
      KnowledgeResource.doUpsert(requestBody);
      Test.stopTest();

      List<Knowledge__kav> knowledges = [SELECT Id, Contentful_Id__c FROM Knowledge__kav WHERE Contentful_Id__c = 'testy11'];	
      System.assert(!knowledges.isEmpty(), 'The knowledge should have been created');
    }
  }

  @IsTest
  public static void shouldDeleteKnowledgeFromWebhook() {
    User u = [SELECT Id FROM User WHERE Email = :USER_EMAIL];

    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();
    RestContext.request.requestURI = 'KnowledgeResource/testy1';
    RestContext.request.httpMethod = 'DELETE';

    System.runAs(u) {
      Test.setMock(HttpCalloutMock.class, new APIMMock());

      Test.startTest();
      KnowledgeResource.doDelete();
      Test.stopTest();

      List<Knowledge__kav> knowledges = [SELECT Id, Contentful_Id__c FROM Knowledge__kav WHERE Contentful_Id__c = 'testy1'];	
      System.assert(knowledges.isEmpty(), 'The knowledge should be deleted');
    }
  }
}