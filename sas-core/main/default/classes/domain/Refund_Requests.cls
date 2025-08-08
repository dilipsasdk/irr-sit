public without sharing class Refund_Requests extends ApplicationDomain {
  public Refund_Requests(List<SObject> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Refund_Requests(records);
    }
  }

  public override void onBeforeInsert() {
    capitalisePNR();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    capitalisePNR();
  }

  private void capitalisePNR() {
    for (Refund_Request__c rq : (List<Refund_Request__c>) Records) {
      if (rq.PNR__c != null) {
        rq.PNR__c = rq.PNR__c.toUpperCase();
      }
    }
  }
}
