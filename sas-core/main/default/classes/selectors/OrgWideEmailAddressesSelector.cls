public inherited sharing class OrgWideEmailAddressesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      OrgWideEmailAddress.Id,
      OrgWideEmailAddress.DisplayName,
      OrgWideEmailAddress.Address
    };
  }

  public Schema.SObjectType getSObjectType() {
    return OrgWideEmailAddress.SObjectType;
  }

  public static OrgWideEmailAddressesSelector newInstance() {
    return (OrgWideEmailAddressesSelector) SAS_Service_Application.Selector.newInstance(
      OrgWideEmailAddress.SObjectType
    );
  }

  public List<OrgWideEmailAddress> selectById(Set<Id> ids) {
    return (List<OrgWideEmailAddress>) selectSObjectsById(ids);
  }

  public List<OrgWideEmailAddress> selectByAddress(Set<String> addresses) {
    return (List<OrgWideEmailAddress>) Database.query(
      newQueryFactory().setCondition('Address IN :addresses').toSOQL()
    );
  }

  public List<OrgWideEmailAddress> selectPrimary() {
    Set<String> primaryAddress = new Set<String>{ 'customerservice-noreply@sas.se' };
    return (List<OrgWideEmailAddress>) Database.query(
      newQueryFactory().setCondition('Address = :primaryAddress').toSOQL()
    );
  }
}
