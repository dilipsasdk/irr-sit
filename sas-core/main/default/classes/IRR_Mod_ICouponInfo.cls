public class IRR_Mod_ICouponInfo {

    @AuraEnabled
    public String couponBatchId { get; set; }
    @AuraEnabled
    public String serviceClassCode { get; set; }
    @AuraEnabled
    public Decimal voucherAmount { get; set; }
    @AuraEnabled
    public String currencyCode { get; set; }
    //new variables for standalone iCoupon
    @AuraEnabled
    public String airportCode { get; set; }
    @AuraEnabled
    public String voucherProfile { get; set; }
    @AuraEnabled
    public String ReasonComment { get; set; }
    @AuraEnabled
    public List<IRR_Mod_ICouponBatch> couponBatches { get; set; }
}