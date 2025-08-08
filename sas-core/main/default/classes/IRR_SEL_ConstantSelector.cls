/**
* @author Gaurav Singh, Coforge
* @date 2024
*
* @description Selector class for the IRR constant metadata object.
*/

public class IRR_SEL_ConstantSelector extends fflib_SObjectSelector implements IRR_SEL_IConstantSelector  {
    
    public static IRR_SEL_IConstantSelector newInstance() 
    {

        return (IRR_SEL_IConstantSelector) IRR_Application.Selector.newInstance(
            IRR_Constant__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Constant__mdt.DeveloperName,
            IRR_Constant__mdt.MasterLabel,
            IRR_Constant__mdt.AIRLINE__c,
            IRR_Constant__mdt.ERROR_BOOKING_ID__c,
            IRR_Constant__mdt.ERROR_BOOKING_REF__c,
            IRR_Constant__mdt.ERROR_DELAY_MINUTES__c,
            IRR_Constant__mdt.ERROR_DEPT_TIME__c,
            IRR_Constant__mdt.ERROR_FLIGHT_ID__c,
            IRR_Constant__mdt.ERROR_NEW_INFO_TIME__c,
            IRR_Constant__mdt.ERROR_NO_ADDED_SEGMENTS__c,
            IRR_Constant__mdt.ERROR_NO_EVENT_TIME__c,
            IRR_Constant__mdt.ERROR_SCHD_TIME__c,
            IRR_Constant__mdt.ERROR_NO_EVENT__c,
            IRR_Constant__mdt.EVENT_FLOW_NAME__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Constant__mdt.SobjectType ;
    }

    public List<IRR_Constant__mdt> getEventContant(String eventName){


        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('DeveloperName =:eventName');
        List<IRR_Constant__mdt> constantMetadata = Database.query(queryFactory.toSOQL());
        return constantMetadata;
    }
               
}