/**
 * @description       : 
 * @author            : Gaurav Singh
 * @group             : 
 * @last modified on  : 09-08-2022
**/
@IsTest
public class IRR_SVC_ICouponServiceTest {
    @IsTest
    static void testcreateFlightIrregularity() {
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK2840-20220608-ATH-FRA';
        delayInfo.flightRef ='SK2840';
        delayInfo.stationDeparture ='ATH';
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        delayInfo.delayedMinutes = 130;
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now();
        Map<String ,List<String>> classWithPassenger = new Map<String ,List<String>>();
        List<String> boardingSequences = new List<String>();
        boardingSequences.add('1');
        classWithPassenger.put('C',boardingSequences);
        Test.setMock(HttpCalloutMock.class, new IRR_SVC_ICouponMockClass());
        test.startTest();
        IRR_SVC_ICouponService.createFlightIrregularity(delayInfo,classWithPassenger);
        IRR_SVC_ICouponService.service();
        test.stopTest();
        
    }
}