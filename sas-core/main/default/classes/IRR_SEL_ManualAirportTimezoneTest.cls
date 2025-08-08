/**
* @author Gaurav Singh, Coforge
* @date 2023
*
* @description Test class for IRR_SEL_ManualAirportTimezone Selector.
*/

@IsTest
public with sharing class IRR_SEL_ManualAirportTimezoneTest {
    @IsTest
    static void testgetSObjectFieldList() {
        Test.startTest();
        IRR_SEL_ManualAirportTimezone obj = new IRR_SEL_ManualAirportTimezone();
        obj.getSObjectFieldList();
        obj.getTimezoneByAirport();
        IRR_SEL_ManualAirportTimezone.newInstance();
        Test.stopTest();
    }
}