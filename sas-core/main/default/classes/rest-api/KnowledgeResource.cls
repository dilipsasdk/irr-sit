@RestResource(urlMapping='/KnowledgeResource/*')
global with sharing class KnowledgeResource {
  public class APIException extends Exception {
  }

  @HttpPost
  global static void doUpsert(KnowledgeJsonToApex contentfulContent) {
    RestResponse res = RestContext.response;

    KnowledgeService.processContentfulContent(contentfulContent);
    res.responseBody = Blob.valueOf('Successfully upserted article.');
  }

  @HttpDelete
  global static void doDelete() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    String contentfulId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1 );

    KnowledgeService.deleteArticlesFromContentfulId(contentfulId);
    res.responseBody = Blob.valueOf('Successfully deleted article.');
  }
}