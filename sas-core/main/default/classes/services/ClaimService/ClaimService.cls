public without sharing class ClaimService {
  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    // TODO: Remove when we deprecate old forms
    '0-2' => '0-2',
    '2-3' => '2-3',
    '3-4' => '3-4',
    '4+' => '4+',
    'accident-and-injury' => 'Accident & injury',
    'accommodation' => 'Accommodation',
    'airport-experience' => 'Airport experience',
    'damaged-baggage' => 'Baggage damaged',
    'baggage-delayed' => 'Baggage delayed/lost',
    'baggage' => 'Baggage',
    'booking' => 'Booking',
    'booking-error' => 'Booking error',
    'cabin-environment' => 'Cabin environment',
    'claims-management-company' => 'Claim firm',
    'complaint-about-refund' => 'Complaint about a refund',
    'corporate' => 'Corporate customer',
    'denied-boarding' => 'Denied boarding',
    'downgrading' => 'Downgrading',
    'eurobonus' => 'EuroBonus Points',
    'extra-baggage' => 'Extra baggage',
    'flight-cancellation' => 'Flight cancellation',
    'flight-delay' => 'Flight delay',
    'flight-disruptions' => 'Flight disruptions',
    'flight-experience' => 'Flight experience',
    'food' => 'Food',
    'gate-issues' => 'Gate issues',
    'insurance-company' => 'Insurance company',
    'in-flight-meal' => 'In-flight meal',
    'in-flight-service' => 'In-flight service',
    'less-than-21-days' => 'Less than 21 days',
    'lounge' => 'Lounge',
    'meals-drinks' => 'Meals/Drinks',
    'missed-connection' => 'Missed connection',
    'items-missing' => 'Items missing from checked-in baggage',
    'monetary' => 'Monetary',
    'more-than-21-days' => '21 days or more',
    'never-arrived' => 'Never arrived',
    'other-representative' => 'Other representative',
    'other' => 'Other',
    'personal-injury' => 'Personal injury',
    'phone-calls' => 'Phone calls',
    'prepaid-seat' => 'Prepaid seat',
    'private' => 'Private customer',
    'regression' => 'Regression',
    'special-assistance' => 'Special assistance',
    'transportation' => 'Transportation',
    'travel-agency' => 'Travel agency',
    'travel-document-control' => 'Travel document control',
    'travel-extras-bought-not-rendered' => 'Travel extras bought not rendered',
    'voucher' => 'Voucher',
    'wifi' => 'WiFi'
  };

  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Flight Delay Certificate DK',
    'no-no' => 'Form - Flight Delay Certificate NO',
    'se-sv' => 'Form - Flight Delay Certificate SE',
    'default' => 'Form - Flight Delay Certificate International'
  };

  private static final String TEMPLATE_IF_VALID_BOOKING = 'bookingExists';
  private static final String TEMPLATE_IF_INVALID_BOOKING = 'bookingDoesNotExist';
  private static final String replyToAddress = 'customercare@sas.se';

  public static final String COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME = 'compensation_card_success';
  public static final String COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME = 'compensation_card_failure';
  public static final String COMPENSATION_CARD_REPLY_TO_ADDRESS = 'customercare@sas.se';
  public static final String COMPENSATION_CARD_OMNI_QUEUE_NAME = 'Claims_Compensation_Card'; //TODO: Switch to compensation card
  public static final String APPROVAL_QUEUE_NAME = 'Approval_levels_2_3'; //Routing cases to this queue for now. Process team will observe during the summer and then decide if want move forward with the same.

  public static ClaimService newInstance() {
    return (ClaimService) SAS_Service_Application.Service.newInstance(
      ClaimService.class
    );
  }

  public class MissingArgumentsException extends Exception {
  }

  public class InsertingException extends Exception {
  }

  public static String createClaim(CreateClaimRequest request) {
    try {
      Claims c = Claims.createFromClaims(
        new List<Claim>{ createClaimRecord(request) }
      );
      c.upsertToDB();

      Claim claimToCreate = c.objects[0];

      List<SObject> objectsToCreate = new List<SObject>();
      Map<Id, SObject> fileIdsToObjects = new Map<Id, SObject>();

      String travelersRichTextForAutoResponseEmail = '';
      for (CreateClaimRequest.Traveler traveler : request.travelers) {
        ClaimCustomer cust = createCustomer(traveler, claimToCreate);
        objectsToCreate.add(cust.underlyingSObject);

        travelersRichTextForAutoResponseEmail += traveler.toString() + '<br>';

        for (Id contentId : traveler.contentVersionIds) {
          fileIdsToObjects.put(contentId, cust.underlyingSObject);
        }
      }

      String expensesRichTextForAutoResponseEmail = '';
      for (CreateClaimRequest.Expense expense : request.expenses) {
        ClaimExpense exp = createClaimExpense(expense, claimToCreate);
        objectsToCreate.add(exp.underlyingSObject);

        expensesRichTextForAutoResponseEmail += expense.toString() + '<br>';

        for (Id contentId : expense.contentVersionIds) {
          fileIdsToObjects.put(contentId, exp.underlyingSObject);
        }
      }

      String rebookedFlightsRichTextForAutoResponseEmail = '';
      for (CreateClaimRequest.RebookedFlight flight : request.rebookedFlights) {
        ClaimRebookedFlight rf = createRebookedFlight(flight, claimToCreate);
        objectsToCreate.add(rf.underlyingSObject);

        rebookedFlightsRichTextForAutoResponseEmail +=
          flight.toString() + '<br>';

        for (Id contentId : flight.contentVersionIds) {
          fileIdsToObjects.put(contentId, rf.underlyingSObject);
        }
      }

      if (objectsToCreate.size() > 0) {
        insert objectsToCreate;
      }

      for (Id contentId : request.filesToLink) {
        if (!fileIdsToObjects.containsKey(contentId)) {
          fileIdsToObjects.put(contentId, claimToCreate.underlyingSObject);
        }
      }

      insert constructContentLinks(fileIdsToObjects, claimToCreate.id);

      Case caseToCreate = createCaseRecord(request, claimToCreate);
      caseToCreate.Claim_Expenses__c = expensesRichTextForAutoResponseEmail;
      caseToCreate.Claim_Rebooked_Flights__c = rebookedFlightsRichTextForAutoResponseEmail;
      caseToCreate.Claim_Travelers__c = travelersRichTextForAutoResponseEmail;

      // Auto-response emails are not triggered by default for cases created
      // through Apex. Setting the triggerAutoResponseEmail header forces
      // them to be sent.
      Database.DMLOptions DMLOptions = new Database.DMLOptions();
      DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

      database.insert(caseToCreate, DMLOptions);

      Case insertedCase = CasesSelector.newInstance()
        .selectById(new Set<Id>{ caseToCreate.Id })[0];

      // We need to do this dance because we want claim name to match the case
      // number, and they to be linked to each other.
      claimToCreate.parentCaseId = insertedCase.Id;
      claimToCreate.underlyingSObject.Name = insertedCase.CaseNumber;
      c.upsertToDB();

      System.enqueueJob(
        new CaseService.AssignPriorityAndRouteToQueueAsync(
          new Set<Id>{ insertedCase.Id }
        )
      );

      return insertedCase.CaseNumber;
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() + ': ' + e.getMessage(),
        e.getStackTraceString(),
        'CaseFormV2 - Create Claim',
        null
      );
      throw new InsertingException();
    }
  }

  public static String createCompensationCardClaim(CreateClaimRequest request) {
    try {
      Claims c = Claims.createFromClaims(
        new List<Claim>{ createDeniedBoardingClaimRecord(request) }
      );
      c.upsertToDB();

      Claim claimToCreate = c.objects[0];

      ClaimCustomer cust = new ClaimCustomer(claimToCreate);
      cust.firstName = request.contact.firstName == null
        ? ' '
        : request.contact.firstName;
      cust.lastName = request.contact.lastName == null
        ? ' '
        : request.contact.lastName;
      cust.updateSObjectFields();
      insert cust.underlyingSObject;

      Case caseToCreate = createCaseRecord(request, claimToCreate);
      // Auto-response emails are not triggered by default for cases created
      // through Apex. Setting the triggerAutoResponseEmail header forces
      // them to be sent.
      Database.DMLOptions DMLOptions = new Database.DMLOptions();
      DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

      database.insert(caseToCreate, DMLOptions);

      Case insertedCase = CasesSelector.newInstance()
        .selectById(new Set<Id>{ caseToCreate.Id })[0];

      claimToCreate.parentCaseId = insertedCase.Id;
      claimToCreate.underlyingSObject.Name = insertedCase.CaseNumber;
      c.upsertToDB();

      List<Feature_Switch__mdt> automationSwitch = [
        SELECT Active__c
        FROM Feature_Switch__mdt
        WHERE QualifiedApiName = 'Process_Compensation_Cards_Automatically'
      ];

      if (
        automationSwitch == null ||
        automationSwitch.size() > 0 && automationSwitch[0].Active__c
      ) {
        System.enqueueJob(new RedeemCompensationCardClaim(claimToCreate.id));
      }

      return insertedCase.CaseNumber;
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() + ': ' + e.getMessage(),
        e.getStackTraceString(),
        'CaseFormV2 - Denied Boarding',
        null
      );
      throw new InsertingException();
    }
  }

  public static String createCompensationCardClaim(
    RedeemCompensationCardRequest request
  ) {
    Claims c = Claims.createFromClaims(
      new List<Claim>{ createClaimRecord(request) }
    );
    c.upsertToDB();

    Claim claimToCreate = c.objects[0];

    ClaimCustomer cust = new ClaimCustomer(claimToCreate);
    cust.firstName = request.contact.firstName == null
      ? ' '
      : request.contact.firstName;
    cust.lastName = request.contact.lastName == null
      ? ' '
      : request.contact.lastName;
    cust.updateSObjectFields();
    insert cust.underlyingSObject;

    Case caseToCreate = createCaseRecord(request, claimToCreate);
    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseToCreate.Id })[0];

    claimToCreate.parentCaseId = insertedCase.Id;
    claimToCreate.underlyingSObject.Name = insertedCase.CaseNumber;
    c.upsertToDB();

    List<Feature_Switch__mdt> automationSwitch = [
      SELECT Active__c
      FROM Feature_Switch__mdt
      WHERE QualifiedApiName = 'Process_Compensation_Cards_Automatically'
    ];

    if (
      automationSwitch == null ||
      automationSwitch.size() > 0 && automationSwitch[0].Active__c
    ) {
      System.enqueueJob(new RedeemCompensationCardClaim(claimToCreate.id));
    }

    return insertedCase.CaseNumber;
  }

  public static String processFlightDelayCertificateRequest(
    CaseFormJSONV2 form
  ) {
    try {
      Id delayCertificateQueue = GroupsSelector.newInstance()
          .selectQueuesByDepartment(new Set<String>{ 'Customer Claim' })[0]
        .Id;
      Case caseToInsert = new Case(
        Origin = marketToOrigin.get(form.metaData.market) == null
          ? marketToOrigin.get('default')
          : marketToOrigin.get(form.metaData.market),
        Flight_Date__c = String.isBlank(form.formdata.claim.departureDate)
          ? null
          : Date.valueOf(form.formdata.claim.departureDate),
        Flight_Number__c = Flight.normalizeFlightNumber(
          form.formdata.claim.flightNumber
        ),
        OwnerId = delayCertificateQueue,
        RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
        Subject = 'Flight Delay Certificate: ' +
          form.formData.claim.bookingReference,
        SuppliedEmail = form.formData.contact.email,
        SuppliedFirstname__c = form.formData.contact.firstName,
        SuppliedLastname__c = form.formData.contact.lastName
      );
      insert caseToInsert;

      Flight_Delay_Certificate_Request__c certificateRequest = new Flight_Delay_Certificate_Request__c(
        Booking_Reference__c = form.formData.claim.bookingReference == null
          ? form.formData.claim.travelAgentBookingReference
          : form.formData.claim.bookingReference,
        Contact_First_Name__c = form.formData.contact.firstName,
        Contact_Last_Name__c = form.formData.contact.lastName,
        Flight_Number__c = Flight.normalizeFlightNumber(
          form.formdata.claim.flightNumber
        ),
        Flight_Date__c = String.isBlank(form.formdata.claim.departureDate)
          ? null
          : Date.valueOf(form.formdata.claim.departureDate),
        Case__c = caseToInsert.Id
      );

      insert certificateRequest;

      System.enqueueJob(
        new AddBookingForRequest(caseToInsert.Id, certificateRequest.Id)
      );
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() + ': ' + e.getMessage(),
        e.getStackTraceString(),
        'CaseFormV2 - Delay Certificate',
        null
      );
      throw new InsertingException();
    }

    return '';
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
        e.getTypeName() + ': ' + e.getMessage(),
        e.getStackTraceString(),
        'FlightDelayCertificateService',
        null
      );
    }
  }

  public class RedeemCompensationCardClaim implements Queueable, Database.AllowsCallouts {
    private Id claimId;
    public RedeemCompensationCardClaim(Id claimId) {
      this.claimId = claimId;
    }
    public void execute(QueueableContext ctx) {
      attemptToRedeemCompensationCardClaim(this.claimId);
    }
  }

  /**
   * Attempts to redeem the given compensation card claim. A compensation card
   * can be renewed if it is a valid compensation card as defined by by the
   * Vouchers API validate endpoint, and it has not yet been paid out.
   *
   * Information about whether a given compensation card has been paid out is
   * stored in Salesforce.
   *
   * Also closes the parent case for the claim, and emails the customer about
   * whether the card was redeemed successfully.
   */
  public static void attemptToRedeemCompensationCardClaim(Id claimId) {
    LIA_Claim__c claim = ClaimsSelector.newInstance()
      .selectById(new Set<Id>{ claimId })[0];

    Cases parentCase = Cases.newInstance(
      CasesSelector.newInstance().selectById(new Set<Id>{ claim.Case__c })
    );

    String caseId = parentCase.instanceRecords[0].Id;

    //QwikCilver does not support PNR for now
    Boolean cardHasBeenPaidOut = RedeemedCompensationCards.hasBeenPaidOut(
      claim.Compensation_Card_Number__c
    );

    if (cardHasBeenPaidOut) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        caseId
      );
      emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

      parentCase.emailOwner(emailToSend, uow)
        .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
        .close(uow);
      uow.commitWork();
    } else {
      Boolean canBeRedeemed = false;

      try {
        fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
        // Check Voucher API whether this is a valid compensation card number and
        // a matching PNR.
        VoucherValidateResponseV2 response = VoucherOrchestrationService.newInstance()
          .validateVoucher(
            claim.Compensation_Card_Number__c,
            claim.Liability_PNR__c
          );
        Redeemed_Compensation_Card__c validatedCompensationCard = RedeemedCompensationCards.createFromValidVoucher(
            response,
            claim,
            uow
          )
          .instanceRecords[0];

        Settlements.createFromCompensationCard(
          new List<LIA_Claim__c>{ claim },
          new Map<Id, Redeemed_Compensation_Card__c>{
            claim.Id => validatedCompensationCard
          },
          uow
        );
        uow.commitWork();
        canBeRedeemed = true;
      } catch (VoucherOrchestrationService.InvalidVoucherException e) {
        handleValidationError(e, parentCase, caseId);
      } catch (Exception e) {
        Logger.error(e.getMessage(), parentCase.instanceRecords[0], e).addTag('CompensationCardRedemptionError');
        Logger.saveLog();
        throw e;
      }

      if (canBeRedeemed) {
        try {
          fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

          Claims.newInstance(new List<LIA_Claim__c>{ claim }).settle(uow);

          Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
            COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME,
            caseId
          );
          emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

          parentCase.emailOwner(emailToSend, uow)
            .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
            .close(uow);

          uow.commitWork();
        } catch (Exception e) {
          fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
          Settlements.newInstance(
              SettlementsSelector.newInstance()
                .selectByClaimId(new Set<Id>{ claim.Id })
            )
            .markAsFailed(e.getMessage(), uow);
          parentCase.routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow);
          CaseService.createChatterPost(
            parentCase.instanceRecords,
            e.getMessage(),
            uow
          );
          uow.commitWork();
        }
      }
    }
  }

  private static void handleValidationError(
    VoucherOrchestrationService.InvalidVoucherException e,
    Cases parentCase,
    Id caseId
  ) {
    Logger.error('Invalid voucher exception', parentCase.instanceRecords[0], e).addTag('CompensationCardRedemptionError');
    Logger.saveLog();

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
      COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
      caseId
    );
    emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

    parentCase.emailOwner(emailToSend, uow)
      .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
      .close(uow);

    uow.commitWork();
  }

  public static void fetchCAREClaimsFromEDW(
    String bookingReference,
    String pir,
    String caseId
  ) {
    String queryType;
    String queryText;

    // Skip querying CARE if the query has been done already.
    if (bookingReference != null && pir == null && caseId == null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :bookingReference AND Query_Type__c = 'PNR'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'PNR';
      queryText = bookingReference;
    } else if (bookingReference == null && pir != null && caseId == null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :pir AND Query_Type__c = 'PIR'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'PIR';
      queryText = pir;
    } else if (bookingReference == null && pir == null && caseId != null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :caseId AND Query_Type__c = 'CaseId'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'CaseId';
      queryText = caseId;
    }

    ClaimsIntegrationService.FetchCAREClaimsQuery query = new ClaimsIntegrationService.FetchCAREClaimsQuery();
    query.pnr = bookingReference;
    query.caseId = caseId;
    query.pir = pir;

    try {
      FetchCAREClaimsResponse response = ClaimsIntegrationService.fetchClaimsByQuery(
        query
      );

      if (queryType != null) {
        // Query type will be null if there were several fields queried. Let's not store those queries.
        Executed_CARE_Query__c ecq = new Executed_CARE_Query__c(
          Query_Text__c = queryText,
          Query_Type__c = queryType
        );

        insert ecq;
      }

      if (response == null) {
        return;
      }

      CAREClaims.create(response).upsertToDB();
    } catch (Exception e) {
      System.debug(e);
      C_Log.log(
        C_Log.Severity.Error,
        'Error when fetching CARE claims: ' + e.getMessage(),
        null,
        'CARE',
        null
      );
    }
  }

  public class FetchCAREClaimsFromEDWAsync implements Queueable, Database.AllowsCallouts {
    private String bookingReference;
    private String pir;
    private String caseId;

    public FetchCAREClaimsFromEDWAsync(
      String bookingReference,
      String pir,
      String caseId
    ) {
      this.bookingReference = bookingReference;
      this.caseId = caseId;
      this.pir = pir;
    }
    public void execute(QueueableContext ctx) {
      fetchCAREClaimsFromEDW(bookingReference, pir, caseId);
    }
  }

  public static void makeDecisionOnClaimExclusionFromAutomation(
    Claims claimsInstance,
    Map<Id, LIA_Claim__c> existingRecords
  ) {
    List<LIA_Claim__c> claimRecordsList = new List<LIA_Claim__c>();
    List<Claim> claimInstancesList = new List<Claim>();

    if (existingRecords != null) {
      for (LIA_Claim__c c : claimsInstance.instanceRecords) {
        LIA_Claim__c existingRecord = existingRecords.get(c.Id);
        if (proactivityMatchersChanged(c, existingRecord)) {
          claimRecordsList.add(c);
          claimInstancesList.add(new Claim(c));
        }
      }
    } else {
      claimRecordsList = claimsInstance.instanceRecords;
      claimInstancesList = claimsInstance.objects;
    }

    if (claimRecordsList.isEmpty()) {
      return;
    }

    Map<Id, Set<Proactivity__c>> claimIdToProactivities = getProactivitiesFromClaims(
      claimRecordsList
    );
    List<LIA_Claim__c> claimsToPutOnHold = new List<LIA_Claim__c>(
      findClaimsToPutOnHold(claimIdToProactivities, claimInstancesList)
    );

    if (!claimsToPutOnHold.isEmpty()) {
      putOnHold(claimsToPutOnHold);
    }
  }

  public static void putOnHold(List<LIA_Claim__c> claimsToHold) {
    Claims claimsInstance = Claims.newInstance(claimsToHold);
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    claimsInstance.updateCasesAndClaimsStatuses(
      Claim.EU261HandlingStatus.OnHold,
      Cases.STATUS_ON_HOLD,
      uow
    );
    claimsInstance.lockCasesAndClaims();

    uow.commitWork();
  }

  public static void returnToAutomation(List<LIA_Claim__c> claimsToAutomate) {
    Claims claimsInstance = Claims.newInstance(claimsToAutomate);
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    claimsInstance.unlockCasesAndClaims();
    claimsInstance.updateCasesAndClaimsStatuses(
      Claim.EU261HandlingStatus.Unhandled,
      Cases.STATUS_NEW,
      uow
    );

    uow.commitWork();

    runAutomationScript(claimsToAutomate);
  }

  public static void runAutomationScript(List<LIA_Claim__c> claimsToAutomate) {
    Set<Id> claimIds = new Set<Id>();
    for (LIA_Claim__c c : claimsToAutomate) {
      claimIds.add(c.Id);
    }
    EU261Service.newInstance().batchProcessEU261Claims(claimIds);
  }

  private static Boolean proactivityMatchersChanged(
    LIA_Claim__c updatedRecord,
    LIA_Claim__c existingRecord
  ) {
    if (
      updatedRecord.Number_of_customers__c !=
      existingRecord.Number_of_customers__c
    ) {
      return true;
    }

    if (
      updatedRecord.Bank_Account_Number__c !=
      existingRecord.Bank_Account_Number__c
    ) {
      return true;
    }

    if (updatedRecord.Liability_PNR__c != existingRecord.Liability_PNR__c) {
      return true;
    }
    if (updatedRecord.Contact_Email__c != existingRecord.Contact_Email__c) {
      return true;
    }
    if (
      updatedRecord.EuroBonus_Number__c != existingRecord.EuroBonus_Number__c
    ) {
      return true;
    }
    if (updatedRecord.Phone_Number__c != existingRecord.Phone_Number__c) {
      return true;
    }
    if (updatedRecord.PIR__c != existingRecord.PIR__c) {
      return true;
    }

    if (updatedRecord.Claim_Firm__c != existingRecord.Claim_Firm__c) {
      return true;
    }

    return false;
  }

  private static Map<Id, Set<Proactivity__c>> getProactivitiesFromClaims(
    List<LIA_Claim__c> claimsList
  ) {
    ProactivitiesSelector proactivitiesSelector = ProactivitiesSelector.newInstance();
    Map<Id, Set<Proactivity__c>> claimIdToProactivities = proactivitiesSelector
      .selectProactivitiesByClaimsWithMatchingReasons(claimsList)
      .claimIdToProactivities;

    Map<Id, Id> directlyLinkedProactivitiesById = new Map<Id, Id>();

    for (LIA_Claim__c c : claimsList) {
      if (c.Case__r.Proactivity__c != null) {
        directlyLinkedProactivitiesById.put(c.Case__r.Proactivity__c, c.Id);
      }
    }

    if (!directlyLinkedProactivitiesById.isEmpty()) {
      List<Proactivity__c> directlyLinkedProactivities = proactivitiesSelector
        .selectById(directlyLinkedProactivitiesById.keySet());

      for (Proactivity__c p : directlyLinkedProactivities) {
        if (claimIdToProactivities.containsKey(p.Id)) {
          claimIdToProactivities.get(p.Id).add(p);
        } else {
          claimIdToProactivities.put(p.Id, new Set<Proactivity__c>{ p });
        }
      }
    }

    return claimIdToProactivities;
  }

  private static Set<LIA_Claim__c> findClaimsToPutOnHold(
    Map<Id, Set<Proactivity__c>> claimIdToProactivities,
    List<Claim> claimInstancesList
  ) {
    Set<LIA_Claim__c> claimsToPutOnHold = new Set<LIA_Claim__c>();
    Map<Id, Claim> claimInstancesMap = new Map<Id, Claim>();

    for (Claim c : claimInstancesList) {
      claimInstancesMap.put(c.Id, c);
    }

    for (Id claimId : claimIdToProactivities.keySet()) {
      Set<Proactivity__c> proactivities = claimIdToProactivities.get(claimId);

      for (Proactivity__c p : proactivities) {
        if (p.Claims_On_Hold__c) {
          Claim c = claimInstancesMap.get(claimId);
          if (c.eu261HandlingStatus != Claim.EU261HandlingStatus.OnHold) {
            claimsToPutOnHold.add(c.underlyingSObject);
          }
        }
      }
    }

    return claimsToPutOnHold;
  }

  private static Case createCaseRecord(
    CreateClaimRequest request,
    Claim createdClaim
  ) {
    Group claimsQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Customer_Claim' })[0];

    String bookingReference = request.bookingReference;
    if (!String.isBlank(request.travelAgentBookingReference)) {
      bookingReference = request.travelAgentBookingReference;
    }

    return new Case(
      Initially_Provided_PNR__c = request.bookingReference,
      Description = request.comment,
      FCS_EBNumber__c = request.contact.euroBonusNumber,
      LIA_Claim__c = createdClaim.id,
      OwnerId = claimsQueue.Id,
      Origin = request.origin,
      SuppliedEmail = request.contact.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + bookingReference,
      SuppliedFirstname__c = request.contact.firstName,
      SuppliedLastname__c = request.contact.lastName
    );
  }

  private static Case createCaseRecord(
    RedeemCompensationCardRequest request,
    Claim createdClaim
  ) {
    Group claimsQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Customer_Claim' })[0];

    return new Case(
      Initially_Provided_PNR__c = request.bookingReference,
      FCS_EBNumber__c = request.contact.euroBonusNumber,
      LIA_Claim__c = createdClaim.id,
      OwnerId = claimsQueue.Id,
      Origin = request.origin,
      SuppliedEmail = request.contact.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + request.bookingReference
    );
  }

  private static Claim createDeniedBoardingClaimRecord(CreateClaimRequest r) {
    Claim newClaim = new Claim();

    newClaim.bankAccountHolderName = r.compensationDetails.bankAccountHolderName;
    newClaim.bankName = r.compensationDetails.bankName;
    newClaim.bankAccountNumber = r.compensationDetails.bankAccountNumber;
    newClaim.bankBicSwift = r.compensationDetails.bankBic;
    newClaim.bankCountry = r.compensationDetails.bankCountry;
    newClaim.bookingReference = r.bookingReference;
    newClaim.compensationCardNumber = r.compensationCardNumber;
    newClaim.contactAddressLine1 = r.contact.addressLine1;
    newClaim.contactAddressLine2 = r.contact.addressLine2;
    newClaim.contactCountry = r.contact.country;
    newClaim.contactCity = r.contact.city;
    newClaim.contactEmail = r.contact.email;
    newClaim.contactFirstName = r.contact.firstName;
    newClaim.contactLastName = r.contact.lastName;
    newClaim.contactPhone = r.contact.phone;
    newClaim.contactPostalCode = r.contact.postalCode;
    newClaim.contactType = Claim.ContactType.PrivateCustomer;
    newClaim.euroBonusNumber = r.contact.euroBonusNumber;
    newClaim.preferredCurrency = r.compensationDetails.preferredCurrency;
    newClaim.preferredCompensationMethod = r.compensationDetails.preferredCompensationMethod;
    newClaim.preferredReimbursementMethod = r.compensationDetails.preferredReimbursementMethod;
    newClaim.recordType = Claim.RecordType.CompensationCard;
    newClaim.referenceNumber = r.compensationDetails.referenceNumber;
    newClaim.category = Claim.Category.CompensationCard;

    newClaim.updateSObjectFields();

    return newClaim;
  }

  private static Claim createClaimRecord(RedeemCompensationCardRequest r) {
    Claim newClaim = new Claim();

    newClaim.bankAccountHolderName = r.compensationDetails.bankAccountHolderName;
    newClaim.bankName = r.compensationDetails.bankName;
    newClaim.bankBicSwift = r.compensationDetails.bankBic;
    newClaim.bankCountry = r.compensationDetails.bankCountry;
    newClaim.bookingReference = r.bookingReference;
    newClaim.compensationCardNumber = r.compensationCardNumber;
    newClaim.contactAddressLine1 = r.contact.addressLine1;
    newClaim.contactAddressLine2 = r.contact.addressLine2;
    newClaim.contactCountry = r.contact.country;
    newClaim.contactCity = r.contact.city;
    newClaim.contactEmail = r.contact.email;
    newClaim.contactFirstName = r.contact.firstName;
    newClaim.contactLastName = r.contact.lastName;
    newClaim.contactPhone = r.contact.phone;
    newClaim.contactPostalCode = r.contact.postalCode;
    newClaim.contactType = Claim.ContactType.PrivateCustomer;
    newClaim.euroBonusNumber = r.contact.euroBonusNumber;
    newClaim.preferredCurrency = r.compensationDetails.preferredCurrency;
    newClaim.preferredCompensationMethod = r.compensationDetails.preferredCompensationMethod;
    newClaim.preferredReimbursementMethod = r.compensationDetails.preferredReimbursementMethod;
    newClaim.recordType = Claim.RecordType.CompensationCard;
    newClaim.referenceNumber = r.compensationDetails.referenceNumber;
    newClaim.category = Claim.Category.CompensationCard;

    newClaim.updateSObjectFields();

    return newClaim;
  }

  private static Claim createClaimRecord(CreateClaimRequest r) {
    Claim newClaim = new Claim();

    newClaim.bankAccountHolderName = r.compensationDetails.bankAccountHolderName;
    newClaim.bankAccountNumber = r.compensationDetails.bankAccountNumber;
    newClaim.bankName = r.compensationDetails.bankName;
    newClaim.bankBicSwift = r.compensationDetails.bankBic;
    newClaim.bankCountry = r.compensationDetails.bankCountry;
    newClaim.contactCity = r.contact.city;
    newClaim.comment = r.comment;
    newClaim.companyCode = r.contact.companyCode;
    newClaim.companyName = r.contact.companyName;
    newClaim.personWithReducedMobility = r.personWithReducedMobility;
    newClaim.unaccompaniedMinor = r.unaccompaniedMinor;
    newClaim.contactAddressLine1 = r.contact.addressLine1;
    newClaim.contactAddressLine2 = r.contact.addressLine2;
    newClaim.contactEmail = r.contact.email;
    newClaim.contactFirstName = r.contact.firstName;
    newClaim.contactLastName = r.contact.lastName;
    newClaim.contactCountry = r.contact.country;
    newClaim.preferredCurrency = r.compensationDetails.preferredCurrency;
    newClaim.category = r.category;
    newClaim.type = r.type;
    newClaim.referenceNumber = r.compensationDetails.referenceNumber;
    newClaim.baggageDelayLength = r.baggageDelayLength;
    newClaim.euroBonusNumber = r.contact.euroBonusNumber;
    newClaim.departureDate = r.departureDate;
    newClaim.flightNumber = r.flightNumber;
    newClaim.ticketNumber = r.ticketNumber;
    newClaim.bookingReference = r.bookingReference;
    newClaim.contactPhone = r.contact.phone;
    newClaim.contactPostalCode = r.contact.postalCode;
    newClaim.baggagePurchasePrice = r.baggagePurchasePrice;
    newClaim.baggagePurchaseCurrency = r.baggagePurchaseCurrency;
    newClaim.baggagePurchaseYear = r.baggagePurchaseYear;
    newClaim.pir = r.passengerIrregularityReportNumber;
    newClaim.preferredCompensationMethod = r.compensationDetails.preferredCompensationMethod;
    newClaim.preferredReimbursementMethod = r.compensationDetails.preferredReimbursementMethod;
    newClaim.recordType = r.recordType;
    newClaim.delayToDestination = r.delayLength;
    newClaim.contactType = r.contact.type;
    newClaim.travelAgentBookingReference = r.travelAgentBookingReference;
    newClaim.SamsoniteReferenceId = r.SamsoniteReferenceId;

    if (r.bookingReference != null) {
      if (Claim.EU261_TYPES.contains(newClaim.type)) {
        newClaim.externalDataStatus = Claim.ExternalDataStatus.NotStarted;
        newClaim.eu261HandlingStatus = Claim.EU261HandlingStatus.Unhandled;
        newClaim.externalDataRetrieveCount = 0;
      } else {
        newClaim.externalDataStatus = null;
        newClaim.eu261HandlingStatus = null;
      }
    }

    newClaim.updateSObjectFields();

    return newClaim;
  }

  private static List<ContentDocumentLink> constructContentLinks(
    Map<Id, SObject> fileIdsToObjects,
    Id claimId
  ) {
    List<ContentDocumentLink> toReturn = new List<ContentDocumentLink>();

    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(fileIdsToObjects.keySet());

    for (ContentVersion content : contentToLink) {
      toReturn.add(
        new ContentDocumentLink(
          ContentDocumentId = content.ContentDocumentId,
          LinkedEntityId = claimId
        )
      );
      if (
        fileIdsToObjects.get(content.Id) != null &&
        fileIdsToObjects.get(content.Id).Id != claimId
      ) {
        toReturn.add(
          new ContentDocumentLink(
            ContentDocumentId = content.ContentDocumentId,
            LinkedEntityId = fileIdsToObjects.get(content.Id).Id
          )
        );
      }
    }

    return toReturn;
  }

  private static ClaimExpense createClaimExpense(
    CreateClaimRequest.Expense expense,
    Claim parentClaim
  ) {
    ClaimExpense ce = new ClaimExpense(parentClaim);
    ce.amount = expense.amount;
    ce.currencyOfAmount = expense.expenseCurrency;
    ce.type = expense.type;
    ce.updateSObjectFields();
    return ce;
  }

  private static ClaimCustomer createCustomer(
    CreateClaimRequest.Traveler traveler,
    Claim parentClaim
  ) {
    ClaimCustomer c = new ClaimCustomer(parentClaim);
    c.firstName = traveler.firstName;
    c.lastName = traveler.lastName;
    c.updateSObjectFields();
    return c;
  }

  private static ClaimRebookedFlight createRebookedFlight(
    CreateClaimRequest.RebookedFlight rebookedFlight,
    Claim parentClaim
  ) {
    ClaimRebookedFlight rf = new ClaimRebookedFlight(parentClaim);
    rf.departureDate = rebookedFlight.departureDate;
    rf.flightNumber = rebookedFlight.flightNumber;
    rf.updateSObjectFields();
    return rf;
  }
}
