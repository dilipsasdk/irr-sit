/**
* @author Gaurav Singh, Coforge
* @date 2023
*
* @description Test class for IRR_SEL_ManualIcouponVoucher Selector.
*/

@IsTest


public class IRR_SEL_ManualIcouponVoucherSelectorTest {
    @IsTest
    static void testgetSObjectFieldList() {
        Test.startTest();
        IRR_SEL_ManualIcouponVoucherSelector obj = new IRR_SEL_ManualIcouponVoucherSelector();
        obj.getSObjectFieldList();
        obj.getManualIcouponVoucher();
        IRR_SEL_ManualIcouponVoucherSelector.newInstance();
        Test.stopTest();
    }
}