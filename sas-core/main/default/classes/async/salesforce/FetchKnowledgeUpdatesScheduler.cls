public with sharing class FetchKnowledgeUpdatesScheduler implements Schedulable {
  public void execute(SchedulableContext ctx) {
    KnowledgeService.initiateContentFetch();
  }
}