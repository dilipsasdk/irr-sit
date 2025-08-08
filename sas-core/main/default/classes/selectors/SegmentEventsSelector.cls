public inherited sharing class SegmentEventsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Segment__c.Id,
      Segment__c.Name,
      Segment__c.CreatedDate,
      Segment__c.LastModifiedDate,
      Segment_Event__c.Segment__c,
      Segment_Event__c.New_Status__c,
      Segment_Event__c.Office_Code__c,
      Segment_Event__c.Operation_Type__c,
      Segment_Event__c.Previous_Status__c,
      Segment_Event__c.Update_Date__c,
      Segment_Event__c.Update_Number__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Segment_Event__c.SObjectType;
  }

  public static SegmentEventsSelector newInstance() {
    return (SegmentEventsSelector) SAS_Service_Application.Selector.newInstance(
      Segment_Event__c.SObjectType
    );
  }

  public List<Segment_Event__c> selectById(Set<Id> ids) {
    return (List<Segment_Event__c>) selectSObjectsById(ids);
  }

  public List<Segment_Event__c> selectBySegmentId(Set<Id> segmentIds) {
    return (List<Segment_Event__c>) Database.query(
      newQueryFactory().setCondition('Segment__c IN :segmentIds').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Segment__c, Update_Number__c';
  }
}
