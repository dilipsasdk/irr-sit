public with sharing class IRR_SEL_ManualAirportTimezone extends fflib_SObjectSelector implements IRR_SEL_IManualAirportTimezone  {
    public static IRR_SEL_IManualAirportTimezone newInstance() 
    {

        return (IRR_SEL_IManualAirportTimezone) IRR_Application.Selector.newInstance(
            IRR_Manual_Airport_Timezone__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Manual_Airport_Timezone__mdt.DeveloperName,
            IRR_Manual_Airport_Timezone__mdt.MasterLabel,
            IRR_Manual_Airport_Timezone__mdt.IRR_Airport_Code__c,
            IRR_Manual_Airport_Timezone__mdt.IRR_Time_Zone__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Manual_Airport_Timezone__mdt.SobjectType ;
    }

    public List<IRR_Manual_Airport_Timezone__mdt> getTimezoneByAirport(){

         return Database.query(newQueryFactory().toSOQL());
               
    }
}