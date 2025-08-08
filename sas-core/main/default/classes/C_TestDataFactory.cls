/**
* @author Niklas Lundkvist, Deloitte
* @date 2019
*
* @description Provides functionality for creating SObjects in tests.
*       - Can set read only variables and sub-select variables
*       - Can register work, including relationships, to a Unit Of Work
*/

@IsTest
public class C_TestDataFactory {

    //Set in order to register work to a unit of work instance.
    public static fflib_ISObjectUnitOfWork uow { get; set; }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Creates a SObject record using the provided parameters.
     *      Uses (de-)serialization to set read only fields and sub-select variables.
     *
     * @param objectType SObjectType to be created
     * @param valuesByFieldName Map of values to set by fields
     * @param relationships Relationships to register in the unit of work (if set)
     *
     * @return The created SObject
     */
    public static SObject createSObject(SObjectType objectType, Map<String, Object> valuesByFieldName,
            List<RelationshipInfo> relationships) {
        SObject sob = objectType.newSObject();
        if (valuesByFieldName!=null && !valuesByFieldName.isEmpty()) {
            String jsonString = JSON.serialize(sob);
            Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
            for (String fieldName : valuesByFieldName.keySet()) {
                Object value = valuesByFieldName.get(fieldName);
                if (value instanceof List<SObject>) value = createSubSelectMap((List<SObject>) value);
                dataMap.put(fieldName, value);
            }
            jsonString = JSON.serialize(dataMap);
            sob = (SObject) JSON.deserialize(jsonString, SObject.class);
        }
        if (relationships!=null && !relationships.isEmpty() && uow!=null) {
            for (Integer i = 0; i < relationships.size(); i++) {
                RelationshipInfo ri = relationships[i];
                if (i == 0) {
                    uow.registerNew(sob, ri.field, ri.sob);
                } else {
                    uow.registerRelationship(sob, ri.field, ri.sob);
                }
            }
        }
        else if (uow!=null) uow.registerNew(sob);
        return sob;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Creates a SObject record using the provided parameters, without relationships.
     *
     * @param objectType SObjectType to be created
     * @param valuesByFieldName Map of values by String field name
     *
     * @return The created SObject
     */
    public static SObject createSObject(SObjectType objectType, Map<String, Object> valuesByFieldName) {
        return createSObject(objectType, valuesByFieldName, null);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Creates a SObject record using the provided parameters.
     *
     * @param objectType SObjectType to be created
     * @param valuesByFieldName Map of values to set by fields
     * @param relationships Relationships to register in the unit of work (if set)
     *
     * @return The created SObject
     */
    public static SObject createSObject(SObjectType objectType, Map<SObjectField, Object> valuesByFieldName,
            List<RelationshipInfo> relationships) {
        Map<String, Object> valuesByFieldString = new Map<String, Object>();
        for (SObjectField sObjectField : valuesByFieldName.keySet()) {
            valuesByFieldString.put(sObjectField.getDescribe().name, valuesByFieldName.get(sObjectField));
        }
        return createSObject(objectType, valuesByFieldString, relationships);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Creates a SObject record using the provided parameters, without relationships.
     *
     * @param objectType SObjectType to be created
     * @param valuesByFieldName Map of values by SObjectFields
     *
     * @return The created SObject
     */
    public static SObject createSObject(SObjectType objectType, Map<SObjectField, Object> valuesByFieldName) {
        return createSObject(objectType, valuesByFieldName, null);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Creates a map for subselect variables so they deserialize correctly.
     *
     * @param children List of children
     *
     * @return Created map
     */
    private static Map<String, Object> createSubSelectMap(List<Object> children) {
        return new Map<String, Object> {
                'totalSize' => children.size(),
                'done' => true,
                'records' => children
        };
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Used to store relationship information.
     */
    public class RelationshipInfo {
        SObjectField field { get; set; }
        SObject sob { get; set; }

        public RelationshipInfo(SObjectField field, SObject sob) {
            this.field = field;
            this.sob = sob;
        }
    }
}