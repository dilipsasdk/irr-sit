public without sharing class KnowledgeService {
  public static KnowledgeService newInstance() {
    return (KnowledgeService) SAS_Service_Application.Service.newInstance(
      KnowledgeService.class
    );
  }

  @future(callout=true)
  public static void initiateContentFetch() {
    KnowledgeJsonToApex contentfulContent = KnowledgeIntegrationService.fetchContentfulContent();
    processContentfulContent(contentfulContent);
  }

  public static void processContentfulContent(KnowledgeJsonToApex contentfulContent) {
    Map<String, KnowledgeJsonToApex.Item> contentfulContentMap = transformContentToMap(
      contentfulContent
    );

    Map<String, Knowledge__kav> existingKnowledges = getExistingKnowledges(
      contentfulContentMap.keySet()
    );

    if (!contentfulContentMap.isEmpty()) {
      Map<String, String> draftKnowledgesIds = createDraftKnowledges(
        contentfulContentMap,
        existingKnowledges
      );
      updateAndPublishKnowledges(draftKnowledgesIds, contentfulContentMap);
    }
  }

  public static Map<String, KnowledgeJsonToApex.Item> transformContentToMap(
    KnowledgeJsonToApex contentfulContent
  ) {
    Map<String, KnowledgeJsonToApex.Item> contentfulContentMap = new Map<String, KnowledgeJsonToApex.Item>();

    for (KnowledgeJsonToApex.Item item : contentfulContent.items) {
      contentfulContentMap.put(item.sys.id, item);
    }
    return contentfulContentMap;
  }

  public static Map<String, Knowledge__kav> getExistingKnowledges(
    Set<String> contentfulContentIds
  ) {
    Map<String, Knowledge__kav> knowledgesMap = new Map<String, Knowledge__kav>();

    List<Knowledge__kav> existingKnowledgesList = [
      SELECT Id, Contentful_Id__c, LastPublishedDate, KnowledgeArticleId
      FROM Knowledge__kav
      WHERE
        Contentful_Id__c IN :contentfulContentIds
        AND PublishStatus = 'Online'
    ];
    for (Knowledge__kav knowledge : existingKnowledgesList) {
      knowledgesMap.put(knowledge.Contentful_Id__c, knowledge);
    }

    return knowledgesMap;
  }

  public static Map<String, String> createDraftKnowledges(
    Map<String, KnowledgeJsonToApex.Item> contentfulContentMap,
    Map<String, Knowledge__kav> existingKnowledges
  ) {
    List<Knowledge__kav> newKnowledgesToCreate = new List<Knowledge__kav>();
    Map<String, String> draftKnowledgeIds = new Map<String, String>();

    for (String contentfulId : contentfulContentMap.keySet()) {
      KnowledgeJsonToApex.Item contentfulContent = contentfulContentMap.get(
        contentfulId
      );
      Knowledge__kav knowledgeArticle = existingKnowledges.get(contentfulId);
      Id draftKnowledgeId;

      if (knowledgeArticle == null) {        
        Knowledge__kav newKnowledgeArticle = new Knowledge__kav(
          Title = contentfulContent.fields.title == null
            ? contentfulContent.fields.id
            : contentfulContent.fields.title,
          UrlName = contentfulContent.fields.id,
          FCS_Body__c = contentfulContent.fields.body,
          FCS_Type__c = contentfulContent.fields.type,
          FCS_SubType__c = contentfulContent.fields.subType,
          Contentful_Id__c = contentfulContent.sys.id,
          Confidential__c = contentfulContent.fields.confidential == null
            ? false
            : contentfulContent.fields.confidential,
          Searchable__c = contentfulContent.fields.searchable == null
            ? true
            : contentfulContent.fields.searchable
        );
        newKnowledgesToCreate.add(newKnowledgeArticle);
      }
  
      if (
        knowledgeArticle != null &&
        contentfulContent.sys.updatedAt > knowledgeArticle.LastPublishedDate
      ) {
        draftKnowledgeId = KbManagement.PublishingService.editOnlineArticle(
          knowledgeArticle.KnowledgeArticleId,
          false
        );
        draftKnowledgeIds.put((String) draftKnowledgeId, contentfulId);
      }
    }

    insert newKnowledgesToCreate;

    for (Knowledge__kav newKnowledgeArticle : newKnowledgesToCreate) {
      draftKnowledgeIds.put(
        newKnowledgeArticle.Id,
        newKnowledgeArticle.Contentful_Id__c
      );
    }

    return draftKnowledgeIds;
  }

  public static void updateAndPublishKnowledges(
    Map<String, String> draftKnowledgeIds,
    Map<String, KnowledgeJsonToApex.Item> contentfulContentMap
  ) {
    List<Knowledge__kav> draftKnowledges = [
      SELECT
        Id,
        Title,
        FCS_Body__c,
        KnowledgeArticleId,
        UrlName,
        Contentful_Id__c
      FROM Knowledge__kav
      WHERE Id IN :draftKnowledgeIds.keySet()
    ];

    for (Knowledge__kav knowledgeArticle : draftKnowledges) {
      String contentfulId = draftKnowledgeIds.get(knowledgeArticle.Id);
      KnowledgeJsonToApex.Item contentfulContent = contentfulContentMap.get(
        contentfulId
      );

      knowledgeArticle.Title = contentfulContent.fields.title == null
        ? contentfulContent.fields.id
        : contentfulContent.fields.title;
        knowledgeArticle.UrlName = contentfulContent.fields.id;
        knowledgeArticle.FCS_Body__c = contentfulContent.fields.body;
        knowledgeArticle.FCS_Type__c = contentfulContent.fields.type;
        knowledgeArticle.FCS_SubType__c = contentfulContent.fields.subType;
        knowledgeArticle.Confidential__c = contentfulContent.fields.confidential == null
          ? false
          : contentfulContent.fields.confidential;
        knowledgeArticle.Searchable__c = contentfulContent.fields.searchable == null
          ? true
          : contentfulContent.fields.searchable;
    }

    update draftKnowledges;

    for (Knowledge__kav knowledgeArticle : draftKnowledges) {
      KbManagement.PublishingService.publishArticle(
        knowledgeArticle.KnowledgeArticleId,
        true
      );
    }
  }

  public static void deleteArticlesFromContentfulId(String contentfulId) {
    List<Knowledge__kav> knowledgeArticles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Contentful_Id__c = :contentfulId AND PublishStatus = 'Online'];

    if (knowledgeArticles.isEmpty()) return;

    Knowledges.newInstance(knowledgeArticles).deletePublishedArticles();
  }
}