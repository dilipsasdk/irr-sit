/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Class used to hold operations related to extracting personal data
 */
public with sharing class GDPR_DataExtractService {
    /**
     * Holds settings for extraction of objects. Should be accessed only through internal getter
     * method to guarantee that the variable is populated.
     */
    private static GDPRExtractObjectSetting__mdt[] objectSettings;

    /**
     * Determines the name of the ComplianceGroup field value on FieldDefinition that determines if field
     * should be included in GDPR Extract.
     */
    private static final String PII_TAG = 'PIIExtract';

    /**
     * Generates a JSON extract of a customer's Personal Identifiable Information based on the supplied account id.
     * Fields included per object are defined on field level with metadata "ComplianceGroup. If new objects should be
     * included in extract, the objects should be added to query for field definitions and to lost of queries in the method.
     * @param accountIds Accounts to generate extract for
     * @param fieldDefinitions Externally provided FieldDefinition. Available to set primarily for test purposes, but
     * should be null for most use cases.
     * @param extractObjectSettings Externally provided settings for extracting objects. Available to set primarily
     * for test purposes, but should be null for most use cases.
     * @return List of JSON structures with the customer's data, one instance for each account
     */
    public static String[] extractAccountPersonalData(Id[] accountIds, List<FieldDefinition> fieldDefinitions, List<GDPRExtractObjectSetting__mdt> extractObjectSettings){
        if(extractObjectSettings != null){
            objectSettings = extractObjectSettings;
        }

        if(fieldDefinitions == null){
            //ComplianceGroup filter set to != null due to inability to filter on list for field
            fieldDefinitions =
                    [SELECT QualifiedApiName, ComplianceGroup, SecurityClassification, EntityDefinitionId
                    FROM FieldDefinition
                    WHERE EntityDefinitionId
                    IN :getListOfIncludedObjectNames()
                    AND ComplianceGroup != NULL];
        }

        Map<Id, SObject[]> extractByAccountId = new Map<Id, SObject[]>();
        for(String query : getQueries(fieldDefinitions, accountIds)){
            //In cases where no fields for object are tagged as PII, only Id is retrieved
            SObject[] records = Database.query(query.replace('null', 'Id'));

            String accountIdentifierField;
            for(GDPRExtractObjectSetting__mdt setting:getObjectSettings()){
                if(setting.ObjectName__c == String.valueOf(records.getSObjectType())){
                    accountIdentifierField = setting.AccountIdFieldName__c;
                }
            }

            for(SObject record:records){
                Id recordAccountId = (Id)record.get(accountIdentifierField);
                if(extractByAccountId.get(recordAccountId) == null){
                    extractByAccountId.put(recordAccountId, new SObject[]{record});
                } else {
                    extractByAccountId.get(recordAccountId).add(record);
                }
            }
        }

        String[] jsonExtracts = new String[]{};
        for(SObject[] records:extractByAccountId.values()){
            jsonExtracts.add(JSON.serializePretty(records));
        }
        return jsonExtracts;
    }

    /**
     * Used to generate queries to extract Personal Information based on field metadata and an account
     * @param fieldDefinitions Field definitions containing information about which fields and objects
     * to include in queries
     * @param accountId Id for account to generate extract for
     * @return List of queries that can be used to retrieve personal data
     */
    @TestVisible
    private static List<String> getQueries(List<FieldDefinition> fieldDefinitions, Id[] accountIds) {
        String[] accountIdsAsStrings = new String[]{};
        for(Id accId : accountIds){
            accountIdsAsStrings.add('\'' + accId + '\'');
        }

        List<String> queries = new List<String>();
        Map<String, ExtractObject> extractObjectsByObjectName = new Map<String, ExtractObject>();
        for(GDPRExtractObjectSetting__mdt setting:getObjectSettings()){
                extractObjectsByObjectName.put(setting.ObjectName__c, new ExtractObject(setting));
        }
        for(GDPRExtractObjectSetting__mdt setting:getObjectSettings()){
            if(setting.ParentObjectName__c != null){
                if(extractObjectsByObjectName.get(setting.ParentObjectName__c) == null){
                    throw new DataExtractException('Object ' + setting.ParentObjectName__c + ' must be included ' +
                            'in extract configuration as it is set as parent for object ' + setting.ObjectName__c);
                } else {
                    extractObjectsByObjectName.get(setting.ParentObjectName__c).childObjects.add(new ExtractObject(setting));
                }
            }
        }
        for(ExtractObject extractObject : extractObjectsByObjectName.values()){
            if(extractObject.parentObjectName == null){
                queries.add(extractObject.getObjectQuery(getFieldSelectionsByObjectName(fieldDefinitions), accountIdsAsStrings));
            }
        }
        return queries;
    }

    /**
     * Generates a map of field selections for each object that should be included in extract.
     * @param fieldDefinitions Field definitions for object.
     * @return Map of field selections in string format, with object name as key.
     */
    private static Map<String, String> getFieldSelectionsByObjectName(List<FieldDefinition> fieldDefinitions) {
        Map<String, String> fieldSelectionsByObjectName = new Map<String, String>();
        for (FieldDefinition def : fieldDefinitions) {
            if (def.ComplianceGroup.contains(PII_TAG)) {
                String currentFieldSelection = fieldSelectionsByObjectName.get(def.EntityDefinitionId);
                if (currentFieldSelection == null) {
                    fieldSelectionsByObjectName.put(def.EntityDefinitionId, def.QualifiedApiName + ', ');
                } else {
                    fieldSelectionsByObjectName.put(def.EntityDefinitionId, currentFieldSelection += def.QualifiedApiName + ', ');
                }
            }
        }

        for (String fieldSelectionKey : fieldSelectionsByObjectName.keySet()) {
            fieldSelectionsByObjectName.put(fieldSelectionKey, fieldSelectionsByObjectName.get(fieldSelectionKey).removeEnd(', '));
        }
        return fieldSelectionsByObjectName;
    }

    /**
     * Used to retrieve setting for extracting objects. In no settings are already retrieved for session, the settings are queried.
     * @return List or settings for extracting objects
     */
    private static GDPRExtractObjectSetting__mdt[] getObjectSettings(){
        if(objectSettings == null){
            objectSettings = [  SELECT Id, AccountIdFieldName__c, ObjectName__c, ParentObjectName__c, RelationshipName__c
                                FROM GDPRExtractObjectSetting__mdt
                                ORDER BY ObjectName__c ASC
                            ];
        }
        if(objectSettings.isEmpty()){
            throw new DataExtractException('No configuration for Data Extract exists. Add at least on object to perform operation.');
        }
        return objectSettings;
    }

    /**
     * Used to generate a list of the object names that should be included in extract, retrieved from extract settings.
     * @return List of object names
     */
    private static String[] getListOfIncludedObjectNames(){
        String[] includedObjects = new String[]{};
        for(GDPRExtractObjectSetting__mdt setting:getObjectSettings()){
            includedObjects.add(setting.ObjectName__c);
        }
        return includedObjects;
    }

    /**
     * @author Anton Norell
     * @date 2020-01-10
     * @description Used to hold information about an object to extract, as well as some logic related to an individual extract object.
     */
    public class ExtractObject {
        public String objectName {get; private set;}
        public String accountIdentifier {get; private set;}
        public String parentObjectName {get; private set;}
        public String relationshipName {get; private set;}
        public ExtractObject[] childObjects;

        public ExtractObject(GDPRExtractObjectSetting__mdt setting){
            objectName = setting.ObjectName__c;
            accountIdentifier = setting.AccountIdFieldName__c;
            parentObjectName = setting.ParentObjectName__c;
            relationshipName = setting.RelationshipName__c;
            childObjects = new ExtractObject[]{};
        }

        /**
         * Used to generate a query for the instantiated extract object. If the object contains child objects, those
         * are included as sub queries.
         * @param fieldSelectionsByObjectName Map of field selections for each object, used to select fields for query.
         * @param accountIdsAsStrings Selection of which accounts to include in query filter.
         * @return A single query for the extract object.
         */
        public String getObjectQuery(Map<String, String> fieldSelectionsByObjectName, String[] accountIdsAsStrings){
            String subQueries = '';
            for(ExtractObject childObject:childObjects){
                subQueries += ', (SELECT ' + fieldSelectionsByObjectName.get(childObject.objectName) +
                                ' FROM ' + childObject.relationshipName + ')';
            }
            String query = 'SELECT ' + fieldSelectionsByObjectName.get(objectName) + subQueries + ' FROM ' + objectName +
                            ' WHERE ' + accountIdentifier + ' IN ' + accountIdsAsStrings;
            return query;
        }
    }

    /**
     * @author Anton Norell
     * @date 2020-01-10
     * @description  Internal exception for errors related to extraction logic
     */
    @TestVisible
    private class DataExtractException extends Exception{}
}