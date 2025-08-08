/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector for the Manual Override object.
*/

public class IRR_SEL_ManualOverridesSelector extends fflib_SObjectSelector
        implements IRR_SEL_IManualOverridesSelector {

    public static IRR_SEL_IManualOverridesSelector newInstance()
    {
        return (IRR_SEL_IManualOverridesSelector) IRR_Application.Selector.newInstance(
                IRR_ManualOverride__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
                IRR_ManualOverride__c.Id
        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_ManualOverride__c.SObjectType;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Selects Active Manual Overrides based on a flight id.
     *      The flight id is split to find matches based on Flight Number, Departure Date and Stations.
     *      Only active manual overrides are returned.
     *
     * @return Active matched manual overrides
     */
    public List<IRR_ManualOverride__c> selectActiveManualOverridesByFlightId(String flightId) {
        IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                new IRR_SVC_CommunicationService.FlightIdSplit(flightId);
        String flightNumber = flightIdSplit.flightNumber;
        String stationArrival = flightIdSplit.stationArrival;
        String stationDeparture = flightIdSplit.stationDeparture;
        Date departureDate = flightIdSplit.departureDate;

        Datetime now = Datetime.now();
        Decimal nowValue = Decimal.valueOf(now.formatGmt('yyyyMMddHHmm'));

        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('IRR_StartBlockValue__c < :nowValue AND IRR_StopBlockValue__c > :nowValue AND ' +
                        '(IRR_FlightId__c = :flightId OR IRR_FlightId__c = NULL ) AND ' +
                        '(IRR_FlightNumber__c = :flightNumber OR IRR_FlightNumber__c = NULL) AND ' +
                        '(IRR_StationArrival__c = :stationArrival OR IRR_StationArrival__c = NULL) AND ' +
                        '(IRR_StationDeparture__c = :stationDeparture OR IRR_StationDeparture__c = NULL) AND' +
                        '(IRR_DepartureDate__c = :departureDate OR IRR_DepartureDate__c = NULL)');
        return Database.query(queryFactory.toSOQL());
    }
}