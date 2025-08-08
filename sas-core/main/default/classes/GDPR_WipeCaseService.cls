/**
Service class providing the functionality to wipe and Delete the case
I.e. remove fields except the fields to retain and delete
all interactions connected to the case.
@author Peter Södergren
*/
global with sharing class GDPR_WipeCaseService {
  /**
      Used to store the sobject name and related number of records going to wipe/Delete;
    */
  public static Map<String, Integer> mapSobjToNumberOfRecords;
  /*
  /*    Wipes the cases with the supplied case ids and deletes any connected interactions
  @param caseIds THe ids of the cases to wipe
  */
  global static void wipeCases(Id[] caseIds) {
    Integer sz = caseIds.size();
    Case[] caseList = new List<Case>(sz);
    for (Integer i = 0; i < sz; i++) {
      caseList[i] = new Case(Id = caseIds[i]);
    }
    wipeCases(caseList);
  }

  /**
  Wipes the provided cases and deletes any connected interactions
  @param caseList The list of cases to wipe
  */
  global static void wipeCases(Case[] caseList) {
    wipeCases(caseList, GDPR_Util.getCaseFieldsToClear('Case'), null);
  }
  /**
  Wipes the provided cases and wipe any connected interactions
  with a custom set of connected fields.
  @param caseList The list of cases to wipe
  @param fieldsToClear The fields to clear on the case record
  */
  global static Map<String, Integer> wipeCases(
    Case[] caseList,
    String[] fieldsToClear,
    String batchName
  ) {
    Set<Id> caseIds = new Set<Id>();
    mapSobjToNumberOfRecords = new Map<String, Integer>();
    caseIds = C_Util.getIdSet(caseList);
    wipeRelatedEntities(caseIds, batchName);
    List<Sobject> lstCaseSobject = GDPR_Util.createSobjectFieldsToClear(
      caseList,
      'Case'
    );
    mapSobjToNumberOfRecords.put('Case', lstCaseSobject.size());
    update lstCaseSobject;

    return mapSobjToNumberOfRecords;
  }

  /**
  Deletes the entities related to the provided case ids
  @param caseIds The case ids for which to delete the related entities
  @param wipecase used to recognize whether we are wiping the cases or deleting the cases.
  
  */
  global static Map<String, Integer> deleteRelatedEntities(
    Set<Id> caseIds,
    String batchName
  ) {
    mapSobjToNumberOfRecords = new Map<String, Integer>();
    List<String> socialAccts = new List<String>(); // lst to store social accounts
    Set<Id> setLinkEntityIds = new Set<Id>(); // set to capture the related case and messagesession Ids;
    Set<Id> setContDocumentIds = new Set<Id>(); // set to remove the duplicates
    List<Sobject> lstSobjectDelete = new List<SObject>();
    Map<String, List<Sobject>> mapSobjects = new Map<String, List<Sobject>>(); // map used to store the Object name and List of Sobject
    // form Object
    FieldDefinition[] fdList = [
      SELECT QualifiedAPIName, ComplianceGroup, EntityDefinitionId
      FROM FieldDefinition
      WHERE EntityDefinitionId = 'Case' AND ComplianceGroup = 'lookup'
    ];

    for (FieldDefinition fld : fdList) {
      Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Case.fields.getMap();
      Schema.DescribeFieldResult f = fieldMap.get(fld.QualifiedAPIName)
        .getDescribe();
      for (Schema.SObjectType reference : f.getReferenceTo()) {
        mapSobjects.put(
          reference.getDescribe().getName(),
          (getRelatedParentRecordsForCase(
            caseIds,
            reference.getDescribe().getName(),
            fld.QualifiedAPIName
          ))
        );
      }
    }
    List<GDPR_Retention_Link__mdt> lstRetenMdt = [
      SELECT
        DeveloperName,
        GDPR_Related_Channel_Object_Link__c,
        GDPR_Related_Channel_Object__c,
        GDPR_Related_Channel_Object__r.Related_Case_Lookup_Field__c,
        GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c,
        GDPR_Related_Channel_Object__r.Related_SObject_Name__c,
        GDPR_Related_Channel_Object__r.SObject_Name__c
      FROM GDPR_Retention_Link__mdt
      WHERE
        GDPR_Related_Channel_Object_Link__c IN (
          SELECT GDPR_Related_Channel_Object__c
          FROM GDPR_Retention_Policy__mdt
          WHERE DeveloperName = :batchName
        )
    ];

    for (GDPR_Retention_Link__mdt mdt : lstRetenMdt) {
      if (
        mdt.GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c !=
        null
      ) {
        List<SObject> listSobjects = getRelatedChildRecordsForCase(
          caseIds,
          mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
          mdt.GDPR_Related_Channel_Object__r.Related_Case_Lookup_Field__c,
          mdt.GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c
        );
        mapSobjects.put(
          mdt.GDPR_Related_Channel_Object__r.Related_SObject_Name__c,
          (getRelatedChildRecordsForChannelObject(
            listSobjects,
            mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
            mdt.GDPR_Related_Channel_Object__r.Related_SObject_Name__c,
            mdt.GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c
          ))
        );
      } else {
        mapSobjects.put(
          mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
          (getRelatedChildRecordsForCase(
            caseIds,
            mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
            mdt.GDPR_Related_Channel_Object__r.Related_Case_Lookup_Field__c,
            mdt.GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c
          ))
        );
      }
    }

    socialAccts.add(
      C_Settings.getSettings('Social Accounts').get('ManagedFacebookPage')
    );
    socialAccts.add(
      C_Settings.getSettings('Social Accounts').get('ManagedTwitterPage')
    );

    SocialPost[] spList = [
      SELECT Id
      FROM SocialPost
      WHERE ParentId IN :caseIds AND Persona.name NOT IN :socialAccts
    ];
    mapSobjects.put('SocialPost', lstSobjectDelete);
    Map<ID, EmailMessage> mapEmailMessages = new Map<ID, EmailMessage>(
      [SELECT Id FROM EmailMessage WHERE ParentId IN :caseIds]
    );
    EmailMessage[] emList = mapEmailMessages.values();

    mapSobjects.put('EmailMessage', emList);

    setLinkEntityIds.addAll(caseIds);
    setLinkEntityIds.addAll(mapEmailMessages.keySet());
    ContentDocumentLink[] cdlList = [
      SELECT
        Id,
        ContentDocumentId,
        ContentDocument.LatestPublishedVersion.FirstPublishLocationId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :setLinkEntityIds
    ];
    List<ContentDocument> cdDelList = new List<ContentDocument>();
    for (ContentDocumentLink cdl : cdlList) {
      if (
        cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId !=
        null &&
        !setContDocumentIds.contains(
          cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId
        )
      ) {
        cdDelList.add(new ContentDocument(Id = cdl.ContentDocumentId));
        setContDocumentIds.add(
          cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId
        );
      }
    }

    mapSobjects.put('ContentDocument', cdDelList);

    for (String SobjectName : mapSobjects.keySet()) {
      Set<Id> setSobjecIds = C_Util.getIdSet(mapSobjects.get(SobjectName));
      String q = 'Select Id From ' + SobjectName + ' Where Id IN :setSobjecIds';

      List<Sobject> lstSobject = Database.Query(q);
      mapSobjToNumberOfRecords.put(SobjectName, lstSobject.size());
      lstSobjectDelete.addAll(lstSobject);
    }

    delete lstSobjectDelete;

    return mapSobjToNumberOfRecords;
  }
  /**
  wipe the related connection to case
  @param caseIds setof CaseIds needs to wiped
  */
  global static void wipeRelatedEntities(Set<Id> caseIds, String batchName) {
    // Channel Objects
    List<Sobject> lstWipeRelatedRecords = new List<Sobject>();
    List<GDPR_Retention_Link__mdt> lstRetenMdt = [
      SELECT
        DeveloperName,
        GDPR_Related_Channel_Object_Link__c,
        GDPR_Related_Channel_Object__c,
        GDPR_Related_Channel_Object__r.Related_Case_Lookup_Field__c,
        GDPR_Related_Channel_Object__r.Related_Sobject_Lookup_Field__c,
        GDPR_Related_Channel_Object__r.Related_SObject_Name__c,
        GDPR_Related_Channel_Object__r.SObject_Name__c
      FROM GDPR_Retention_Link__mdt
      WHERE
        GDPR_Related_Channel_Object_Link__c IN (
          SELECT GDPR_Related_Channel_Object__c
          FROM GDPR_Retention_Policy__mdt
          WHERE DeveloperName = :batchName
        )
    ];
    for (GDPR_Retention_Link__mdt mdt : lstRetenMdt) {
      List<SObject> listSobjects = getRelatedChildRecordsForCase(
        caseIds,
        mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
        mdt.GDPR_Related_Channel_Object__r.Related_Case_Lookup_Field__c,
        null
      );
      mapSobjToNumberOfRecords.put(
        mdt.GDPR_Related_Channel_Object__r.SObject_Name__c,
        listSobjects.size()
      );
      lstWipeRelatedRecords.addAll(
        GDPR_Util.createSobjectFieldsToClear(
          listSobjects,
          mdt.GDPR_Related_Channel_Object__r.SObject_Name__c
        )
      );
    }
    FieldDefinition[] fdList = [
      SELECT QualifiedAPIName, ComplianceGroup, EntityDefinitionId
      FROM FieldDefinition
      WHERE EntityDefinitionId = 'Case' AND ComplianceGroup = 'Lookup'
    ];
    for (FieldDefinition fld : fdList) {
      Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Case.fields.getMap();
      Schema.DescribeFieldResult f = fieldMap.get(fld.QualifiedAPIName)
        .getDescribe();
      for (Schema.SObjectType reference : f.getReferenceTo()) {
        List<SObject> listSobjects = getRelatedParentRecordsForCase(
          caseIds,
          reference.getDescribe().getName(),
          fld.QualifiedAPIName
        );
        mapSobjToNumberOfRecords.put(
          reference.getDescribe().getName(),
          listSobjects.size()
        );
        lstWipeRelatedRecords.addAll(
          GDPR_Util.createSobjectFieldsToClear(
            listSobjects,
            reference.getDescribe().getName()
          )
        );
      }
    }
    update lstWipeRelatedRecords;
    // Deleting of the Email Messages while wiping the case
    List<EMailMessage> lstEmailMessage = [
      SELECT Id
      FROM EmailMessage
      WHERE ParentId = :caseIds
    ];
    mapSobjToNumberOfRecords.put('EmailMessage', lstEmailMessage.size());
    if (!lstEmailMessage.isEmpty()) {
      delete lstEmailMessage;
    }
  }

  global static List<Sobject> getRelatedChildRecordsForChannelObject(
    List<Sobject> sObjScope,
    String sObjectName,
    String relSObjName,
    String relSObjField
  ) {
    Set<Id> relIds = new Set<Id>();
    for (SObject sObj : sObjScope) {
      if (relSObjField != null) {
        Id relId = (Id) sObj.get(relSObjField);
        if (relId != null)
          relIds.add(relId);
      }
    }
    mapSobjToNumberOfRecords.put(sObjectName, sObjScope.size());
    delete sObjScope;
    return Database.query(
      'SELECT Id FROM ' +
      relSObjName +
      ' WHERE Id IN :relIds AND Id NOT IN (SELECT ' +
      relSObjField +
      ' FROM ' +
      sObjectName +
      ' WHERE ' +
      relSObjField +
      ' IN :relIds)'
    );
  }
  /**
  Set the Related records of the case for wiping
  @params caseIds, set of case caseIds
  @params sot The Sobject related to Case
  @params caseField the fields which related the case and related Object
  */
  global static List<Sobject> getRelatedChildRecordsForCase(
    Set<Id> caseIds,
    String sot,
    String caseField,
    String relSObjField
  ) {
    String q = 'SELECT Id, CreatedDate';
    q = relSObjField != null ? q + ', ' + relSObjField : q;
    q += ' FROM ' + sot + ' WHERE ';
    q += caseField + '=:caseIds';
    return Database.query(q);
  }
  global static List<SObject> getRelatedParentRecordsForCase(
    Set<Id> caseIds,
    String sot,
    String caseField
  ) {
    String q = 'SELECT Id, CreatedDate FROM ' + sot + ' WHERE Id IN ';
    q += '( SELECT ' + sot + ' FROM CASE WHERE Id IN :caseIds )';
    return Database.query(q);
  }
}
