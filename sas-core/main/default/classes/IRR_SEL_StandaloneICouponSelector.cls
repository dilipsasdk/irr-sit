/**
* @author Rati Mehra, Coforge
* @date 2024
* @purpose Selector class to load the metadata of Standalone iCoupon Voucher
*/
public class IRR_SEL_StandaloneICouponSelector extends fflib_SObjectSelector implements IRR_SEL_IStandaloneIcouponSelector{
    
    public static IRR_SEL_IStandaloneICouponSelector newInstance() {

        return (IRR_SEL_IStandaloneIcouponSelector) IRR_Application.Selector.newInstance(
            IRR_Standalone_Icoupon_Voucher__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Standalone_Icoupon_Voucher__mdt.IRR_Airport_List__c,
            IRR_Standalone_Icoupon_Voucher__mdt.IRR_Voucher_Profile__c,
            IRR_Standalone_Icoupon_Voucher__mdt.IRR_Reason__c,
            IRR_Standalone_Icoupon_Voucher__mdt.Type__c,
            IRR_Standalone_Icoupon_Voucher__mdt.UniqueID__c,
            IRR_Standalone_Icoupon_Voucher__mdt.IRR_Voucher_Amount__c,
            IRR_Standalone_Icoupon_Voucher__mdt.IRR_Voucher_Currency__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Standalone_Icoupon_Voucher__mdt.SobjectType ;
    }

    public List<IRR_Standalone_Icoupon_Voucher__mdt> getStandaloneICouponVoucher(){

        return Database.query(newQueryFactory().toSOQL());
              
   }

}