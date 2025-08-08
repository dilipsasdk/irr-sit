public without sharing class Customers extends ApplicationDomain {
  public Customers(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Customer__c>) Records;
  }

  private List<Customer__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Customers(records);
    }
  }

  public static Customers newInstance(List<Customer__c> sObjectList) {
    return (Customers) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public override void onBeforeInsert() {
    matchNameWithFirstLastName();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    matchNameWithFirstLastName();
  }

  private void matchNameWithFirstLastName() {
    for (Customer__c c : instanceRecords) {
      c.Name = c.First_Name__c + ' ' + c.Last_Name__c;
    }
  }
}
