public without sharing class CreateRefundRequest {
  public Contact contact { get; private set; }
  public Refund refund { get; private set; }
  public String origin { get; private set; }
  public Set<Id> filesToLink { get; private set; }
  public String market { get; private set; }

  public class InvalidDataException extends Exception {
  }

  private static Map<String, String> relationshipMapping = new Map<String, String>{
    'spouse-or-co-habitant' => 'Spouse/Co-habitant partner',
    'child' => 'Child',
    'parent' => 'Parent',
    'sibling' => 'Sibling',
    'grandparent' => 'Grandparent',
    'grandchild' => 'Grandchild',
    'parent-in-law' => 'Parent-in-law',
    'brother-or-sister-in-law' => 'Brother/sister-in-law',
    'son-or-daughter-in-law' => 'Son/daughter-in-law',
    'deceased-person' => 'Deceased person'
  };

  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'death-certificate-dk-da' => 'Form - Death Certificate DK',
    'death-certificate-no-no' => 'Form - Death Certificate NO',
    'death-certificate-se-sv' => 'Form - Death Certificate SE',
    'death-certificate-default' => 'Form - Death Certificate International',
    'visa-rejection-dk-da' => 'Form - Visa Rejection DK',
    'visa-rejection-no-no' => 'Form - Visa Rejection NO',
    'visa-rejection-se-sv' => 'Form - Visa Rejection SE',
    'visa-rejection-default' => 'Form - Visa Rejection International',
    'normal-dk-da' => 'Form - Refunds Customer DK',
    'normal-no-no' => 'Form - Refunds Customer NO',
    'normal-se-sv' => 'Form - Refunds Customer SE',
    'normal-default' => 'Form - Refunds Customer International',
    'travel-agent-dk-da' => 'Form - Refunds Travel Agent DK',
    'travel-agent-no-no' => 'Form - Refunds Travel Agent NO',
    'travel-agent-se-sv' => 'Form - Refunds Travel Agent SE',
    'travel-agent-default' => 'Form - Refunds Travel Agent International'
  };

  public class Contact {
    public String firstName { get; private set; }
    public String lastName { get; private set; }
    public String email { get; private set; }
    public String phone { get; private set; }

    public Contact (CaseFormJSONV2.Contact jsonData) {
      firstName = jsonData.firstname;
      lastName = jsonData.lastName;
      email = jsonData.email;
      phone = jsonData.phone;
    }
  }

  public class Refund {
    public String refundType { get; private set; }
    public String bookingReference { get; private set; }
    public String bookedViaTravelAgent { get; private set; }
    public String notes { get; private set; }
    public String cancelEntireBooking { get; private set; }
    public String cancelAllPassengers { get; private set; }
    public String cancelDirection { get; private set; }
    public String ticketNumber { get; private set; }
    public String countryOfPurchase { get; private set; }
    public List<CaseFormJSONV2.Traveler> travelers;

    public Refund (CaseFormJSONV2.RefundRequest jsonData) {
      refundType = jsonData.refundType;
      bookingReference = jsonData.bookingReference;
      bookedViaTravelAgent = jsonData.bookedViaTravelAgent;
      notes = '';

      if (jsonData.travelers != null && jsonData.travelers.size() > 0) {
        notes += 'Cancel passengers: ' + jsonData.travelers.size() + '\r\n\r\n';

        for (CaseFormJSONV2.Traveler traveler : jsonData.travelers) {
          notes += traveler.firstName + ' ' + traveler.lastName + '\r\n';
          notes += 'Ticket number: ' + traveler.ticketNo + '\r\n';
          if (jsonData.refundType == 'death-certificate') {
            notes += 'Relationship to deceased: ' + relationshipMapping.get(traveler.relationshipToDeceased) + '\r\n';
          }
          notes += '\r\n';
        }
      }
      notes = notes.trim();

      cancelEntireBooking = jsonData.cancelEntireBooking;
      cancelAllPassengers = jsonData.cancelAllPassengers;
      cancelDirection = jsonData.cancelledRoute;
      ticketNumber = jsonData.ticketNumber;
      countryOfPurchase = jsonData.countryOfPurchase;
      travelers = jsonData.travelers;
    }
  }

  public CreateRefundRequest(CaseFormJSONV2 jsonData) {
    contact = new Contact(jsonData.formData.contact);
    refund = new Refund(jsonData.formData.refund);

    String origin = marketToOrigin.get(jsonData.metaData.market);
    String caseType = '';

    switch on jsonData.formData.refund.refundType {
      when 'death-certificate' {
        caseType = 'death-certificate';
      }
      when 'mmb' {
        caseType = 'normal';
      }
      when 'travel-agent' {
        caseType = 'travel-agent';
      }
      when 'visa-rejection' {
        caseType = 'visa-rejection';
      }
    }

    this.origin = origin != null ? origin : marketToOrigin.get(caseType + '-default');

    Set<Id> fileIds = new Set<Id>();
    if (jsonData.formData.contentVersionIds != null) {
      for (String s : jsonData.formData.contentVersionIds) {
        fileIds.add(Id.valueOf(s));
      }
    }

    filesToLink = fileIds;
    market = jsonData.metaData.market;
  }
}
