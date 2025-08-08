/**
* @author Chetan Singh, Coforge
* @date 2020
*
* @description Domain Interface for Event Logs.Because of the loose coupling principles, all outside 
* concerns will work directly with the interface and not the concrete Domain class.
*/

public interface IRR_DOM_IEventLogs extends fflib_ISObjectDomain {
    
    Set<Id> getRecordIds();
}