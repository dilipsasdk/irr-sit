/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector for the Delay Logs custom object.
*/

public class IRR_SEL_DelayLogsSelector extends fflib_SObjectSelector implements IRR_SEL_IDelayLogsSelector {

    public static IRR_SEL_IDelayLogsSelector newInstance() {
        return (IRR_SEL_IDelayLogsSelector) IRR_Application.Selector.newInstance(IRR_DelayLog__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                IRR_DelayLog__c.fields.Id,
                IRR_DelayLog__c.fields.IRR_DelayMinutes__c,
                IRR_DelayLog__c.fields.IRR_FlightId__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_DelayLog__c.SObjectType;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves a map of the latest communicated delay minutes by flight ids.
     *
     * @param flightIds Flight Ids to retrieve communicated delay logs for
     *
     * @return Last communicated delay minutes by flight id if found
     */
    public Map<String, Integer> getLatestDelayByFlightIds(Set<String> flightIds) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('IRR_FlightId__c IN :flightIds')
                .setOrdering(IRR_DelayLog__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        System.debug(queryFactory.toSOQL());
        List<IRR_DelayLog__c> delayLogs = Database.query(queryFactory.toSOQL());
        Map<String, Integer> delayByFlightIds = new Map<String, Integer>();
        for (IRR_DelayLog__c delayLog : delayLogs) {
            if (!delayByFlightIds.containsKey(delayLog.IRR_FlightId__c)) {
                delayByFlightIds.put(delayLog.IRR_FlightId__c, (Integer) delayLog.IRR_DelayMinutes__c);
            }
        }
        return delayByFlightIds;
    }


       /**
     * @author Gaurav, Coforge
     * @date 2023
     *
     * @description Retrieves a total number  delay  by flight ids.
     *
     * @param flightIds Flight Ids to retrieve communicated delay logs for
     *
     * @return total number of delay
     */
    public Integer getDelayByFlightIds(Set<String> flightIds) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('IRR_FlightId__c IN :flightIds')
                .setOrdering(IRR_DelayLog__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        System.debug(queryFactory.toSOQL());
        List<IRR_DelayLog__c> delayLogs = Database.query(queryFactory.toSOQL());
       
        return delayLogs.size();
    }
}