@IsTest
public class ICOUPON_AuthConnector_v2Test {
 @IsTest
    static void testauthenticate() {
        Test.setMock(HttpCalloutMock.class, new ICOUPON_AuthConnector_v2Mock());
        test.startTest();
        ICOUPON_AuthConnector_v2 obj = new ICOUPON_AuthConnector_v2();
        obj.authenticate('test','test','test','test');
        test.stopTest();
        
        
    }
}