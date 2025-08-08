/**
* @author Chetan Singh, Coforge
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_SegmentInfo { 

    @AuraEnabled
    public String segmentId { get; set; }

    @AuraEnabled
    public Boolean isSASTicket { get; set; }
    @AuraEnabled
    public Boolean isWideroeTicket { get; set; }

    @AuraEnabled
    public String ticketNumber { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }
    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public String departureTimeLocal { get; set; }
    @AuraEnabled
    public String arrivalTimeLocal { get; set; }
    @AuraEnabled
    public String departureTimeUTC { get; set; }
    @AuraEnabled
    public String arrivalTimeUTC { get; set; }

    @AuraEnabled
    public Boolean isConfirmed { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String statusCode { get; set; }

    @AuraEnabled
    public String bookingClass { get; set; }

    @AuraEnabled
    public String serviceClass { get; set; }
    // Added for Icoupon
    @AuraEnabled
    public Integer boardingSequenceNumber { get; set; }

    @AuraEnabled
    public String couponBatchId { get; set; }

    @AuraEnabled
    public Decimal couponAmount { get; set; }

    @AuraEnabled
    public String currencyCode { get; set; }

    @AuraEnabled
    public String serviceClassLabel { get; set; }

    @AuraEnabled
    public String emailBackBody { get; set; }

    @AuraEnabled
    public String flightId { get; set; }

    @AuraEnabled
    public String flightNumber { get; set; }

    @AuraEnabled
    public String departureCity { get; set; }

    @AuraEnabled
    public String arrivalCity { get; set; }

    @AuraEnabled
    public String rxType { get; set; }

    @AuraEnabled
    public String qrCodeFormat { get; set; }

    @AuraEnabled
    public String seat { get; set; }

    @AuraEnabled
    public String checkInStatus { get; set; }

    @AuraEnabled
    public String isShowBarcode { get; set; }
    
    @AuraEnabled
    public String qrCodeSMSLink { get; set; }
    
    @AuraEnabled
    public String passengerRightURL { get; set; }

    @AuraEnabled
    public Boolean isIncludedBoarded { get; set; }
    //added new variable for Standalone iCoupon
    @AuraEnabled
    public String barcode { get; set; }

    
    @AuraEnabled
    public String commTypeForEWR { get; set; }

}