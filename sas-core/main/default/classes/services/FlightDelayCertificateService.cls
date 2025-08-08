public without sharing class FlightDelayCertificateService {
  private static final String TEMPLATE_IF_VALID_BOOKING = 'bookingExists';
  private static final String TEMPLATE_IF_INVALID_BOOKING = 'bookingDoesNotExist';
  private static final String replyToAddress = 'customercare@sas.se';
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Flight Delay Certificate DK',
    'no-no' => 'Form - Flight Delay Certificate NO',
    'se-sv' => 'Form - Flight Delay Certificate SE',
    'default' => 'Form - Flight Delay Certificate International'
  };

  public static String processFlightDelayCertificateRequest(
    FlightDelayCertificateFormJSON2Apex form
  ) {
    Id delayCertificateQueue = GroupsSelector.newInstance()
        .selectQueuesByDepartment(new Set<String>{ 'Customer Claim' })[0]
      .Id;
    Case caseToInsert = new Case(
      Origin = marketToOrigin.get(form.metaData.market) == null
        ? marketToOrigin.get('default')
        : marketToOrigin.get(form.metaData.market),
      Flight_Date__c = String.isBlank(form.formdata.departureDate)
        ? null
        : Date.valueOf(form.formdata.departureDate),
      Flight_Number__c = Flight.normalizeFlightNumber(
        form.formdata.flightNumber
      ),
      OwnerId = delayCertificateQueue,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Flight Delay Certificate: ' + form.formData.bookingReference,
      SuppliedEmail = form.formData.email
    );
    insert caseToInsert;

    Flight_Delay_Certificate_Request__c certificateRequest = new Flight_Delay_Certificate_Request__c(
      Booking_Reference__c = form.formData.bookingReference,
      Contact_First_Name__c = form.formData.firstName,
      Contact_Last_Name__c = form.formData.lastName,
      Flight_Number__c = Flight.normalizeFlightNumber(
        form.formdata.flightNumber
      ),
      Flight_Date__c = String.isBlank(form.formdata.departureDate)
        ? null
        : Date.valueOf(form.formdata.departureDate),
      Case__c = caseToInsert.Id
    );

    insert certificateRequest;

    System.enqueueJob(
      new AddBookingForRequest(caseToInsert.Id, certificateRequest.Id)
    );

    return '';
  }

  public static void sendFlightDelayCertificate(
    String caseId,
    List<Flight_Delay_Certificate_Request__c> insertedRequests,
    List<Booking__c> insertedBookings
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    FlightDelayCertificateRequests newRequests = FlightDelayCertificateRequests.newInstance(
      insertedRequests
    );
    Flight_Delay_Certificate_Request__c currentRequest = newRequests.instanceRecords[0];

    Booking currentBooking;

    Boolean isValidBooking = false;

    Cases insertedCase = Cases.newInstance(
      CasesSelector.newInstance().selectById(new Set<Id>{ caseId })
    );

    if (insertedBookings.size() > 0) {
      currentBooking = new Booking(insertedBookings[0]); // Recreate the object to ensure data has been reloaded.
      Boolean bookingHasDelays = currentBooking.hasDelayedOrCancelledFlights();
      Boolean passengerInBooking = currentBooking.containsPassenger(
        currentRequest.Contact_Last_Name__c
      );
      Boolean enteredFlightInBooking = currentBooking.containsFlight(
        currentRequest.Flight_Number__c +
        '-' +
        String.valueOf(currentRequest.Flight_Date__c).replace('-', '')
      );

      isValidBooking =
        bookingHasDelays &&
        passengerInBooking &&
        enteredFlightInBooking;
    }

    String nameOfEmailTemplateToUse = isValidBooking
      ? TEMPLATE_IF_VALID_BOOKING
      : TEMPLATE_IF_INVALID_BOOKING;

    Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
      nameOfEmailTemplateToUse,
      caseId
    );
    emailToSend.setReplyTo(replyToAddress);
    // Send delay certificate if associated booking contains delayed/cancelled flights.
    // If booking does not exist or if the associated booking does not contain delayed/cancelled flights, we send a generic response
    if (isValidBooking) {
      String fileName =
        currentRequest.Contact_Full_Name__c +
        '_' +
        currentRequest.Booking_Reference__c +
        '.pdf';
      Blob fdcPdf = newRequests.generateFlightDelayCertificate(
        currentBooking.Id
      );

      Messaging.EmailFileAttachment pdfToAttach = EmailMessages.createEmailAttachmentFromBlob(
        fdcPdf,
        fileName,
        'application/pdf'
      );
      emailToSend.setFileAttachments(
        new List<Messaging.EmailFileAttachment>{ pdfToAttach }
      );
    }

    insertedCase.emailOwner(emailToSend, uow).close(uow);

    try {
      uow.commitWork();
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'FlightDelayCertificateService',
        null
      );
    }
  }

  public without sharing class AddBookingForRequest implements Queueable, Database.AllowsCallouts {
    private String caseId;
    private String certificateRequestId;

    public AddBookingForRequest(String caseId, String certificateRequestId) {
      this.caseId = caseId;
      this.certificateRequestId = certificateRequestId;
    }

    public void execute(QueueableContext ctx) {
      List<Flight_Delay_Certificate_Request__c> insertedRequests = FlightDelayCertificateRequestsSelector.newInstance()
        .selectByIdFull(new Set<Id>{ this.certificateRequestId });
      Bookings bookings = BookingService.addBookingToCase(
        caseId,
        insertedRequests[0].Booking_Reference__c
      );
      List<Booking__c> insertedBookings = bookings != null
        ? BookingsSelector.newInstance()
            .selectByIdFull(
              new Map<Id, Booking__c>(bookings.instanceRecords).keySet()
            )
        : new List<Booking__c>();

      //Chained Queueables are not allowing in tests
      if (!Test.isRunningTest()) {
        System.enqueueJob(
          new FlightDelayCertificateSend(
            caseId,
            insertedRequests,
            insertedBookings
          )
        );
      }
    }
  }
  public without sharing class FlightDelayCertificateSend implements Queueable, Database.AllowsCallouts {
    private String caseId;
    private List<Flight_Delay_Certificate_Request__c> insertedRequests;
    private List<Booking__c> insertedBookings;
    public FlightDelayCertificateSend(
      String caseId,
      List<Flight_Delay_Certificate_Request__c> insertedRequests,
      List<Booking__c> insertedBookings
    ) {
      this.caseId = caseId;
      this.insertedRequests = insertedRequests;
      this.insertedBookings = insertedBookings;
    }
    public void execute(QueueableContext ctx) {
      sendFlightDelayCertificate(
        this.caseId,
        this.insertedRequests,
        this.insertedBookings
      );
    }
  }
}
