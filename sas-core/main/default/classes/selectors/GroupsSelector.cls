public inherited sharing class GroupsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Group.Id, Group.Name };
  }

  public Schema.SObjectType getSObjectType() {
    return Group.SObjectType;
  }

  public static GroupsSelector newInstance() {
    return (GroupsSelector) SAS_Service_Application.Selector.newInstance(
      Group.SObjectType
    );
  }

  public List<Group> selectById(Set<Id> ids) {
    return (List<Group>) selectSObjectsById(ids);
  }

  public List<Group> selectGroupsByName(Set<String> queueNames) {
    String groupType = 'Queue';

    return (List<Group>) Database.query(
      newQueryFactory()
        .setCondition('Type = :groupType AND Name IN :queueNames')
        .toSOQL()
    );
  }
  public List<Group> selectQueuesByDeveloperName(Set<String> queueNames) {
    String groupType = 'Queue';

    return (List<Group>) Database.query(
      newQueryFactory()
        .setCondition('Type = :groupType AND DeveloperName IN :queueNames')
        .toSOQL()
    );
  }

  /**
   * Finds a queue for a given department name. Each department has a single
   * default queue the name of which is the same as the department. Spaces in
   * department name are replaced with underscores.
   */
  public List<Group> selectQueuesByDepartment(Set<String> departmentNames) {
    String groupType = 'Queue';
    Set<String> departmentsWithoutSpaces = new Set<String>();
    for (String department : departmentNames) {
      departmentsWithoutSpaces.add(department.replace(' ', '_'));
    }
    return (List<Group>) Database.query(
      newQueryFactory()
        .setCondition(
          'Type = :groupType AND DeveloperName IN :departmentsWithoutSpaces'
        )
        .toSOQL()
    );
  }
}
