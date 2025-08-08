/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for Delay Logs selector.
*/

@IsTest
private class IRR_SEL_DelayLogsSelector_Test {

    @IsTest
    static void testGetLatestDelayByFlightIds() {
        //Given
        List<IRR_DelayLog__c> delayLogs = new List<IRR_DelayLog__c>{
                new IRR_DelayLog__c(IRR_FlightId__c='TEST_FLIGHT', IRR_DelayMinutes__c=10)
        };
        insert delayLogs;

        //When
        Map<String, Integer> flightDelayByIds = IRR_SEL_DelayLogsSelector.newInstance()
                .getLatestDelayByFlightIds(new Set<String>{'TEST_FLIGHT', 'OTHER_FLIGHT'});

        //Then
        System.assert(!flightDelayByIds.containsKey('OTHER_FLIGHT'), 'Other flight has no delay logs');
        System.assert(flightDelayByIds.containsKey('TEST_FLIGHT'), 'Result should contain delay for TEST_FLIGHT');
        System.assertEquals(10 ,flightDelayByIds.get('TEST_FLIGHT'), 'Latest delay should be 10 for TEST_FLIGHT');
    }
}