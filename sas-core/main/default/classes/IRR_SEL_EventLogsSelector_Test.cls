/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
* @description Test class for Event Logs selector.
*/
@isTest
private class IRR_SEL_EventLogsSelector_Test {
    
    @isTest
    static void testGetQueuedManualQueryLocator(){

        //Given
        List<IRR_EventLog__c> eventLogs = new List<IRR_EventLog__c>{
            new IRR_EventLog__c(IRR_FlightId__c='TEST_FLIGHT', IRR_ScheduleTime__c=System.Now().addDays(-1))
        };

        insert eventLogs;

        //when
        Database.QueryLocator queryResult = IRR_SEL_EventLogsSelector.newInstance().getQueuedManualQueryLocator();
        // Get an iterator
        Database.QueryLocatorIterator i =  queryResult.iterator();
    
        //then
        System.assert(i.hasNext(),'Expected to find 1 record hence hasnext to be true');
    }
      @isTest
    static void testgetQueuedIcouponBatchQueryLocator(){

        //Given
        List<IRR_EventLog__c> eventLogs = new List<IRR_EventLog__c>{
            new IRR_EventLog__c(IRR_FlightId__c='TEST_FLIGHT',IRR_Event_Type__c='ICOUPON',Is_Communication_Send__c=false,
                                IRR_ScheduleTime__c=System.Now().addMinutes(30))
        };

        insert eventLogs;

        //when
        Database.QueryLocator queryResult = IRR_SEL_EventLogsSelector.newInstance().getQueuedIcouponBatchQueryLocator();
        // Get an iterator
        Database.QueryLocatorIterator i =  queryResult.iterator();
    
        //then
        System.assert(i.hasNext(),'Expected to find 1 record hence hasnext to be true');
    }
      @isTest
    static void testgetQueuedIcouponQueryLocator(){

        //Given
        List<IRR_EventLog__c> eventLogs = new List<IRR_EventLog__c>{
            new IRR_EventLog__c(IRR_FlightId__c='TEST_FLIGHT',IRR_Event_Type__c='ICOUPON',Is_Communication_Send__c=false,
                                IRR_ScheduleTime__c=System.Now().addDays(-1))
        };

        insert eventLogs;

        //when
        Database.QueryLocator queryResult = IRR_SEL_EventLogsSelector.newInstance().getQueuedIcouponQueryLocator('TEST_FLIGHT');
        // Get an iterator
        Database.QueryLocatorIterator i =  queryResult.iterator();
    
        //then
        System.assert(i.hasNext(),'Expected to find 1 record hence hasnext to be true');
    }

}