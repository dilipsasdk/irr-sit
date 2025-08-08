/**
 * A base class for domain objects.
 */
public without sharing abstract class ApplicationDomain extends fflib_SObjectDomain {
  public ApplicationDomain(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public Set<Id> ids {
    get {
      Set<Id> toReturn = new Set<Id>();

      for (SObject c : this.Records) {
        toReturn.add(c.Id);
      }

      return toReturn;
    }
  }
}
