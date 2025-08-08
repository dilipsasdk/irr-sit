public inherited sharing class ContactsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Contact.Id,
      Contact.Name,
      Contact.FirstName,
      Contact.LastName,
      Contact.Phone,
      Contact.Email,
      Contact.MobilePhone,
      Contact.CreatedDate,
      Contact.LastModifiedDate
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Contact.SObjectType;
  }

  public static ContactsSelector newInstance() {
    return (ContactsSelector) SAS_Service_Application.Selector.newInstance(
      Contact.SObjectType
    );
  }

  public List<Contact> selectById(Set<Id> ids) {
    return (List<Contact>) selectSObjectsById(ids);
  }

  public List<Contact> selectByName(Set<String> names) {
    return (List<Contact>) Database.query(
      newQueryFactory().setCondition('Name IN :names').toSOQL()
    );
  }

  public List<Contact> selectByPhone(Set<String> phoneNumbers) {
    return (List<Contact>) Database.query(
      newQueryFactory()
      .setCondition('Phone IN :phoneNumbers OR MobilePhone IN :phoneNumbers').toSOQL()
    );
  }

  public List<Contact> selectByEmail(Set<String> emails) {
    return (List<Contact>) Database.query(
      newQueryFactory()
      .setCondition('Email IN :emails').toSOQL()
    );
  }
}