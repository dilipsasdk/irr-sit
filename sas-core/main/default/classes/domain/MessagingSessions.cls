public without sharing class MessagingSessions extends ApplicationDomain {
  public MessagingSessions(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<MessagingSession>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new MessagingSessions(records);
    }
  }

  private List<MessagingSession> instanceRecords;
}
