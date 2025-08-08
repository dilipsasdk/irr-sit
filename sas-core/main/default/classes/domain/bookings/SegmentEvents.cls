public without sharing class SegmentEvents extends ApplicationDomain {
  public SegmentEvents(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Segment_Event__c>) Records;
  }

  public List<Segment_Event__c> instanceRecords;
  //public Map<String, List<Segment_Event__c>> segmentIdToEvents = new Map<String, List<Segment_Event__c>>();
  public Map<String, Map<String, List<Segment_Event__c>>> segmentIdToEventsPerPassenger = new Map<String, Map<String, List<Segment_Event__c>>>();

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new SegmentEvents(records);
    }
  }

  public static SegmentEvents newInstance(List<Segment_Event__c> sObjectList) {
    return (SegmentEvents) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }
}
