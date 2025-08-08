/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_PassengerInfo {

    @AuraEnabled
    public String bookingReference { get; set; }

    @AuraEnabled
    public String SSR { get; set; }

    @AuraEnabled
    public String passengerId { get; set; }

    @AuraEnabled
    public String bookingFlightId { get; set; }

    @AuraEnabled
    public String title { get; set; }

    @AuraEnabled
    public String lastName { get; set; }

    @AuraEnabled
    public String lastNameSlashFirstName { get; set; }

    @AuraEnabled
    public String firstName { get; set; }

    @AuraEnabled
    public String ebLevel { get; set; }

    @AuraEnabled
    public String euroBonusNumber { get; set; }

    @AuraEnabled
    public String otherFQTVCarrier { get; set; }

    @AuraEnabled
    public String codsId { get; set; }

    @AuraEnabled
    public Boolean hasPhoneNumber { get; set; }
    @AuraEnabled
    public Boolean hasEmailAddress { get; set; }

    @AuraEnabled
    public Boolean hasBoarded { get; set; }

    @AuraEnabled
    public String phoneNumber { get; set; }
    @AuraEnabled
    public String emailAddress { get; set; }

    @AuraEnabled
    public Boolean hasThisSegment { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo thisSegment { get; set; }

    @AuraEnabled
    public Boolean hasRXLine { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo  rxType;
    
    @AuraEnabled
    public Boolean hasNextSegment { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo nextSegment { get; set; }

    @AuraEnabled
    public Boolean hasPrevSegment { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo prevSegment { get; set; }

    @AuraEnabled
    public List<IRR_MOD_TripInfo> itinerary { get; set; }
    //New requirement for a link to info on passenger rights for passengers with disabilities when traveling to/from the USA
    @AuraEnabled
    public String cancelledStationArrival { get; set; }

    @AuraEnabled
    public String cancelledStationDeparture { get; set; }
    
    @AuraEnabled
    public Boolean isRebookUSStation { get; set; }

     
    @AuraEnabled
    public String passengerRightURL { get; set; }
    
     @AuraEnabled
    public Boolean needToSendUsTemplate { get; set; }

    @AuraEnabled
    public String scheduledChangeMessageType { get; set; }
}