public without sharing class Knowledges extends ApplicationDomain {
  public Knowledges(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Knowledge__kav>) Records;
  }

  public List<Knowledge__kav> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Knowledges(records);
    }
  }

  public static Knowledges newInstance(List<Knowledge__kav> sObjectList) {
    return (Knowledges) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public Knowledges deletePublishedArticles() {
    for (Knowledge__kav knowledgeArticle: this.instanceRecords) {
      KbManagement.PublishingService.archiveOnlineArticle(knowledgeArticle.KnowledgeArticleId, null);
      KbManagement.PublishingService.deleteArchivedArticle(knowledgeArticle.KnowledgeArticleId);
    }

    return this;
  }
}