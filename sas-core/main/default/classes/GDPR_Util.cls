/**
Util class for all GDPR jobs
*/

public class GDPR_Util {
  /**
  Additional retained fields used by test due to a Salesforce bug with testing and field definitions
  */
  @TestVisible
  static Set<String> RETAIN_ADD;

  /**
return the fields to be wiped for particular SObject
@param objectname
*/
  public static String[] getCaseFieldsToClear(String sObjectName) {
    Set<String> wipeFields = RETAIN_ADD != null
      ? RETAIN_ADD
      : new Set<String>();
    Set<String> retainedFields = new Set<String>();
    List<String> fieldsToClear = new List<String>();
    //TODO When issue related to retrieving multiple field definitions in on transaction os solved, remove Account filter from this query and filter in loop below
    FieldDefinition[] fdList = [
      SELECT QualifiedAPIName, ComplianceGroup, EntityDefinitionId
      FROM FieldDefinition
      WHERE EntityDefinitionId = :sObjectName AND ComplianceGroup != NULL
    ];
    for (FieldDefinition fd : fdList) {
      if (fd.ComplianceGroup.split(';').contains('Wipe')) {
        wipeFields.add(fd.QualifiedAPIName);
      }
    }

    //Add fields for which compliance cannot be set
    retainedFields.add('RecordTypeId');
    Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(sObjectName);
    Map<String, Schema.SObjectField> fMap = sobjType.getDescribe()
      .fields.getMap();
    for (String k : fMap.keySet()) {
      Schema.SObjectField f = fMap.get(k);
      if (!retainedFields.contains(f + '') && wipeFields.contains(f + '')) {
        Schema.DescribeFieldResult dfr = f.getDescribe();
        if (
          dfr.isNillable() &&
          dfr.getType() != Schema.DisplayType.ADDRESS &&
          dfr.isUpdateable()
        ) {
          fieldsToClear.add(k);
        }
      }
    }
    return fieldsToClear;
  }
  /**
Create the Sobject List to be wiped
@param lstSobjects the sobject collections needs to wiped
@param sObjectName the name of the Sobject
*/
  public static List<sObject> createSobjectFieldsToClear(
    List<sObject> lstSobjects,
    String sObjectName
  ) {
    List<String> lstFieldsToClear = GDPR_Util.getCaseFieldsToClear(sObjectName);
    List<Sobject> listSObjects = new List<Sobject>();
    for (SObject obj : lstSobjects) {
      for (String field : lstFieldsToClear) {
        obj.put(field, null);
      }
      obj.put('GDPR_Wiped__c', true);
      listSObjects.add(obj);
    }

    return listSObjects;
  }
}
