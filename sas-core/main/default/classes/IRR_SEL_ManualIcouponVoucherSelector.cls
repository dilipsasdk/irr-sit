public class IRR_SEL_ManualIcouponVoucherSelector extends fflib_SObjectSelector implements IRR_SEL_IManualIcouponVoucherSelector  {
    
    public static IRR_SEL_IManualIcouponVoucherSelector newInstance() 
    {

        return (IRR_SEL_IManualIcouponVoucherSelector) IRR_Application.Selector.newInstance(
            IRR_Manual_Icoupon_Voucher__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Manual_Icoupon_Voucher__mdt.DeveloperName,
            IRR_Manual_Icoupon_Voucher__mdt.MasterLabel,
            IRR_Manual_Icoupon_Voucher__mdt.IRR_Currency_Code__c,
            IRR_Manual_Icoupon_Voucher__mdt.IRR_Voucher_Amount__c,
            IRR_Manual_Icoupon_Voucher__mdt.IRR_Reason_Comment__c,
            IRR_Manual_Icoupon_Voucher__mdt.Type__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Manual_Icoupon_Voucher__mdt.SobjectType ;
    }

    public List<IRR_Manual_Icoupon_Voucher__mdt> getManualIcouponVoucher(){

         return Database.query(newQueryFactory().toSOQL());
               
    }

}