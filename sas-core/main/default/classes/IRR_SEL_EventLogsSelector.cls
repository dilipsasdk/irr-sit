/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
*/
public class IRR_SEL_EventLogsSelector extends fflib_SObjectSelector
    implements IRR_SEL_IEventLogsSelector {

    public static IRR_SEL_IEventLogsSelector newInstance() {
        return (IRR_SEL_IEventLogsSelector)
            IRR_Application.Selector.newInstance(IRR_EventLog__c.SObjectType);
        }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                IRR_EventLog__c.Id,
                IRR_EventLog__c.CreatedDate,
                IRR_EventLog__c.IRR_EventTime__c,
                IRR_EventLog__c.IRR_ScheduleTime__c,
                IRR_EventLog__c.IRR_FlightId__c,
                IRR_EventLog__c.IRR_Delayed_Minutes__c,
                IRR_EventLog__c.IRR_Station_Departure__c,
                IRR_EventLog__c.IRR_Event_Type__c,
                IRR_EventLog__c.MinuteDiff__c,
                IRR_EventLog__c.Is_Communication_Send__c,
                IRR_EventLog__c.IRR_Flight_Ref__c,
                IRR_EventLog__c.Is_Second_Communication_Send__c,
                IRR_EventLog__c.Last_Boarding_Sequence_Number__c,
                IRR_EventLog__c.IRR_EstimatedTime_Of_DepartureUTC__c
        };
    }   

    public Schema.SObjectType getSObjectType() {
    return IRR_EventLog__c.SObjectType;
    }

    public Database.QueryLocator getQueuedManualQueryLocator() {
        String eventType ='ICOUPON';
        Datetime currentTime = System.Now();
        fflib_QueryFactory queryFactory = newQueryFactory()
            .setCondition('IRR_ScheduleTime__c <= :currentTime AND IRR_Event_Type__c !=:eventType');
        return Database.getQueryLocator(queryFactory.toSOQL());

    }
    public Database.QueryLocator getQueuedIcouponQueryLocator(String flightId) {
        String eventType ='ICOUPON';
        fflib_QueryFactory queryFactory = newQueryFactory()
            .setCondition('IRR_Event_Type__c =:eventType AND IRR_FlightId__c =:flightId');
        return Database.getQueryLocator(queryFactory.toSOQL());

    }
    public Database.QueryLocator getQueuedIcouponBatchQueryLocator() {
        String eventType ='ICOUPON';
        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('(MinuteDiff__c > 0 AND MinuteDiff__c <= 120 AND IRR_Event_Type__c=:eventType AND Is_Communication_Send__c = false AND Is_Second_Communication_Send__c = false) OR (MinuteDiff__c > 0 AND MinuteDiff__c <= 60 AND IRR_Event_Type__c=:eventType AND Is_Communication_Send__c = true AND Is_Second_Communication_Send__c =false) OR (MinuteDiff__c > 0 AND MinuteDiff__c <= 60 AND IRR_Event_Type__c=:eventType AND Is_Communication_Send__c = false AND Is_Second_Communication_Send__c =false)');
         return Database.getQueryLocator(queryFactory.toSOQL());

    }
}