/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description Test class for IRR_SEL_IcouponVoucher Selector.
*/

@IsTest
public class IRR_SEL_IcouponVoucherSelectorTest {

    @IsTest
    static void testgetSObjectFieldList() {
        Test.startTest();
        IRR_SEL_IcouponVoucherSelector obj = new IRR_SEL_IcouponVoucherSelector();
        obj.getSObjectFieldList();
        obj.getIcouponVoucher();
        IRR_SEL_IcouponVoucherSelector.newInstance();
        Test.stopTest();
    }
}