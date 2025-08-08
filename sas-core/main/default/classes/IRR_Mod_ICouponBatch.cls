public class IRR_Mod_ICouponBatch {
    
        @AuraEnabled
        public String pnr { get; set; }
        @AuraEnabled
        public Integer couponBatchId { get; set; }
        @AuraEnabled
        public String[] barcodes { get; set; }
        @AuraEnabled
        public Boolean isIssued { get; set; }

}