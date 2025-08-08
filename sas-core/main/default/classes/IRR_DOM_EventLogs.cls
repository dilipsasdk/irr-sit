/**
* @author Chetan Singh, Coforge
* @date 2020
*
* @description Domain to process Event Logs
*/

public  class IRR_DOM_EventLogs extends fflib_SObjectDomain implements IRR_DOM_IEventLogs{
    
    public static IRR_DOM_IEventLogs newInstance(List<SObject> sObjectList) {
            return (IRR_DOM_IEventLogs) IRR_Application.Domain.newInstance(sObjectList);
    }

    public Set<Id> getRecordIds(){
        Set<Id> idSet = new Set<Id>();
        for(IRR_EventLog__c record : (List<IRR_EventLog__c>) Records){

            IdSet.add(record.Id);
        }
        return idSet;
        
        
    }

    public IRR_DOM_EventLogs(List<SObject> records) {

        //Domain classes are initialised with lists to enforce bulkification througout
            super(records);
    }

    //inner Constructor class,Apex Commons Trigger framework uses the Domain classes as "Trigger Handler"
    //via the inner "Constructor" class
    

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new IRR_DOM_EventLogs(records);
        }
    }
}