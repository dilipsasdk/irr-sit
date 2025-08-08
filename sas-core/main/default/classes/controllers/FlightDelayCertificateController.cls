public without sharing class FlightDelayCertificateController {
  public final static String CREATION_CONFIRM_MESSAGE = 'Flight Delay Certificate has been created. Please go to the related case to view the created file';
  public List<FlightWrapper> flightWrappers { get; set; }
  public Id bookingId { get; set; }
  public Id fdcrId { get; set; }
  public String enteredFlight { get; set; }
  public String bookingReference { get; set; }
  public String passengerName { get; set; }
  public String caseNumber { get; set; }
  public String imageLink { get; set; }
  public Boolean manualEntry { get; set; }

  public FlightDelayCertificateController() {
    bookingId = ApexPages.currentPage().getParameters().get('bookingId') != null
      ? Id.valueOf(ApexPages.currentPage().getParameters().get('bookingId'))
      : null;
    enteredFlight = ApexPages.currentPage()
      .getParameters()
      .get('enteredFlight');
    passengerName = ApexPages.currentPage()
      .getParameters()
      .get('passengerName');
    bookingReference = ApexPages.currentPage()
      .getParameters()
      .get('bookingReference');
    caseNumber = ApexPages.currentPage().getParameters().get('caseNumber');
    fdcrId = ApexPages.currentPage().getParameters().get('fdcrId');
    manualEntry = !ApexPages.currentPage()
      .getUrl()
      .contains('flightdelaycertificatepage');

    imageLink =
      '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' +
      ContentVersionsSelector.newInstance().selectByTitle('SAS_Header')[0]?.Id;

    flightWrappers = new List<FlightWrapper>();
    if (bookingId != null && !manualEntry) {
      List<Flight__c> flightsInBooking = FlightsSelector.newInstance()
        .selectByBookingIds(new Set<Id>{ bookingId });

      for (Flight__c flight : flightsInBooking) {
        String flightId = flight.TEDS_Identifier__c.substringBefore('-');
        FlightWrapper fw = new FlightWrapper();
        fw.ScheduledTimeOfDeparture = flight.Scheduled_Departure_Time__c
          ?.formatGmt('yyyy-MM-dd HH:mm');
        fw.ScheduledTimeOfArrival = flight.Scheduled_Arrival_Time__c
          ?.formatGmt('yyyy-MM-dd HH:mm');
        fw.ActualTimeOfArrival = flight.Actual_Arrival_Time__c
          ?.formatGmt('yyyy-MM-dd HH:mm');
        fw.FlightNumber = flightId;
        fw.FlightDate = flight.TEDS_Identifier__c?.substring(6, 14);
        fw.ArrivalAirport = flight.Arrival_Airport__c;
        fw.DepartureAirport = flight.Departure_Airport__c;
        fw.FlightStatus = flight.Arrival_Status__c;
        flightWrappers.add(fw);
      }
    } else {
      FlightWrapper fw = new FlightWrapper();
      flightWrappers.add(fw);
    }
  }

  public void createManualCertificateFromData() {
    List<Flight_Delay_Certificate_Request__c> requests = FlightDelayCertificateRequestsSelector.newInstance()
      .selectByIdFull(new Set<Id>{ fdcrId });
    updateFdcr(requests[0]);
    Blob generatedCertificate = FlightDelayCertificateRequests.newInstance(
        requests
      )
      .generateFlightDelayCertificate(null);
    ContentVersion createdDocument = new ContentVersion(
      ContentLocation = 'S',
      Title = passengerName +
        '_' +
        bookingReference +
        '_' +
        Date.today().format() +
        '.pdf',
      PathOnClient = passengerName +
        '_' +
        bookingReference +
        '_' +
        Date.today().format() +
        '.pdf',
      VersionData = generatedCertificate
    );
    insert createdDocument;

    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(new Set<Id>{ createdDocument.Id });

    ContentDocumentLink linkToCreate = new ContentDocumentLink(
      ContentDocumentId = contentToLink[0].ContentDocumentId,
      LinkedEntityId = requests[0].Case__r.Id
    );

    insert linkToCreate;
    ApexPages.addmessage(
      new ApexPages.message(
        ApexPages.severity.CONFIRM,
        CREATION_CONFIRM_MESSAGE
      )
    );
  }

  public void addFlight() {
    FlightWrapper fw = new FlightWrapper();
    flightWrappers.add(fw);
  }

  public void removeFlight() {
    Integer indexVal = Integer.valueof(
      ApexPages.currentPage().getParameters().get('index')
    );
    flightWrappers.remove(indexVal - 1);
  }

  public void updateFdcr(Flight_Delay_Certificate_Request__c fdcr) {
    fdcr.Booking_Reference__c = bookingReference;
    update fdcr;
  }

  /**
   * Wrapper class needed to retrieve flight data in the Visualforce page
   * Data is retrieved on the page by calling the getter as a property
   */
  public class FlightWrapper {
    public String ScheduledTimeOfDeparture { get; set; }
    public String ScheduledTimeOfArrival { get; set; }
    public String ActualTimeOfArrival { get; set; }
    public String FlightNumber { get; set; }
    public String FlightDate { get; set; }
    public String ArrivalAirport { get; set; }
    public String DepartureAirport { get; set; }
    public String FlightStatus { get; set; }
  }
}
