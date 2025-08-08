/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description Selector class for the IRR Icoupon Voucher metadata object.
*/

public class IRR_SEL_IcouponVoucherSelector extends fflib_SObjectSelector implements IRR_SEL_IIcouponVoucherSelector  {
    
    public static IRR_SEL_IIcouponVoucherSelector newInstance() 
    {

        return (IRR_SEL_IIcouponVoucherSelector) IRR_Application.Selector.newInstance(
            IRR_Icoupon_Voucher__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Icoupon_Voucher__mdt.DeveloperName,
            IRR_Icoupon_Voucher__mdt.MasterLabel,
            IRR_Icoupon_Voucher__mdt.AirportCode__c,
            IRR_Icoupon_Voucher__mdt.CoupanValue__c,
            IRR_Icoupon_Voucher__mdt.Currency__c,
            IRR_Icoupon_Voucher__mdt.Min_Delay__c,
            IRR_Icoupon_Voucher__mdt.Max_Delay__c,
            IRR_Icoupon_Voucher__mdt.ReasonComment__c,
            IRR_Icoupon_Voucher__mdt.Service_Class_Code__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Icoupon_Voucher__mdt.SobjectType ;
    }

    public List<IRR_Icoupon_Voucher__mdt> getIcouponVoucher(){

         return Database.query(newQueryFactory().toSOQL());
               
    }

}