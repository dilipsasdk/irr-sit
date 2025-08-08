/**
 * An overall service class for running the automation process for EU261
 * claims. See EU261Claim.cls and Confluence for more details.
 *
 * Evaluation logic lives in EU261Claim and this class contains the infra
 * around that: fetching data, creating settlements and moving claims
 * around based on the results of the evaluation.
 *
 * An instance of this class is a single (batch) run of EU261 automation.
 */
public without sharing class EU261Service {
  private static final SettlementItem.CostAccount COMPENSATION_COST_ACCOUNT = SettlementItem.CostAccount.CA6727;
  private static final SettlementItem.CostAccount REIMBURSEMENT_COST_ACCOUNT = SettlementItem.CostAccount.CA6738;
  private static final Integer TTL_SECONDS = 10800;

  @TestVisible
  private static final String AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved';
  @TestVisible
  private static final String AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved_halved_late_arrival';
  @TestVisible
  private static final String AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved_halved_early_departure';
  @TestVisible
  private static final String AUTOMATION_APPROVED_DELAY_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved_delay';

  private static final Set<String> REASONINGS_NOT_AUTOMATABLE = new Set<String>{
    'The customer cancelled the flight',
    'Flight was cancelled 14 or more days in advance',
    'Id and staff tickets are not eligible',
    'SAS is not responsible for 3 hours or more of the delay',
    'No passenger in this claim has a revenue ticket.',
    'There are no passengers which are eligible for compensation',
    'No expenses submitted'
  };

  @TestVisible
  private static final Map<EU261Protocol.DenialReason, String> DENIAL_REASON_TO_EMAIL_TEMPLATE_NAME = new Map<EU261Protocol.DenialReason, String>{
    EU261Protocol.DenialReason.NOTOUTSIDETIMEFRAME => 'eu261_automation_rejected_not_outside_timeframe',
    EU261Protocol.DenialReason.NOTFILEDONTIME => 'eu261_automation_rejected_not_filed_on_time',
    EU261Protocol.DenialReason.CANCELLEDWELLINTIME => 'eu261_automation_rejected_cancelled_well_in_time',
    EU261Protocol.DenialReason.CUSTOMERCANCELLED => 'eu261_automation_rejected_cusomter_cancelled',
    EU261Protocol.DenialReason.NOTWITHINSASCONTROL => 'eu261_automation_rejected_not_within_SAS_control',
    EU261Protocol.DenialReason.NOTWITHINSASCONTROLDELAY => 'eu261_automation_rejected_delay_not_within_SAS_Control',
    EU261Protocol.DenialReason.DELAYTOOSMALL => 'eu261_automation_rejected_delay_too_small',
    EU261Protocol.DenialReason.NOTWITHINSASCONTROLPROACTIVITY => 'eu261_automation_rejected_proactivity',
    EU261Protocol.DenialReason.DELAYUNDER2HOURS => 'eu261_automation_expenses_rejected_delay_less_than_2_hours'
    // EU261Protocol.DenialReason.NODELAYORCANCELLATION => null
  };

  private static final String AUTOMATION_REPLY_TO_ADDRESS = 'customercare@sas.se';

  private static final String COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a total amount of {0} {1}.';
  private static final String COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a flat rate compensation of {0} {1} and with a reimbursement of {2} {3} for the expenses you experienced during the delay.';

  private static final String SEMI_AUTOMATION_QUEUE_COMPENSATION = 'Claims_EU261_Semi_Automation';
  private static final String SEMI_AUTOMATION_QUEUE_REIMBURSEMENT = 'Claims_Care_Semi_Automation';

  @TestVisible
  private static final Map<EU261Claim.SemiAutomationReason, String> SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS = new Map<EU261Claim.SemiAutomationReason, String>{
    EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney => 'Check passenger names so they match claim and PNR, and if needed ask/validate PoA and submit to approval.',
    EU261Claim.SemiAutomationReason.HasPotentialDuplicates => 'Potential duplicates might exist, validate potential duplicate according to duplicate procedure, and submit to approval.',
    EU261Claim.SemiAutomationReason.HasHighClaimExpenses => 'Validate the expenses, create settlement, and submit to approval.',
    EU261Claim.SemiAutomationReason.InvalidSettlementDetails => 'Ask/validate the account details, correct the settlement, and submit to approval.'
  };

  public Config config;
  private Datetime timeAtStartOfAutomation = DateTime.now();

  @TestVisible
  private Map<Id, Case> parentCasesById = new Map<Id, Case>();
  private Map<Id, Settlement__c> existingSettlementsByClaimId = new Map<Id, Settlement__c>();

  public class Config {
    public Decimal percentageRequiringManualApproval;

    public Boolean enabledCancellationAutomation;
    public Boolean enabledDelayAutomation;
    public Boolean enabledExpenseAutomation;
    public Boolean enabledSettlements;
    public Boolean enabledRejections;
    public Boolean enabledSemiAutomation;
    public Boolean enabledAutomationProactivities;

    public Money expenseLimitAccommodation;
    public Money expenseLimitFood;
    public Money expenseLimitPhoneCalls;
    public Money expenseLimitTransportation;
    public Money expenseLimitTotal;

    public Integer claimsPerBatch;

    public Config() {
      percentageRequiringManualApproval = 0;

      enabledCancellationAutomation = false;
      enabledDelayAutomation = false;
      enabledExpenseAutomation = false;
      enabledSettlements = false;
      enabledRejections = false;
      enabledSemiAutomation = false;
      enabledAutomationProactivities = false;

      expenseLimitAccommodation = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitFood = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitPhoneCalls = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitTransportation = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitTotal = new Money(0, Money.CurrencyCode.SEK);

      claimsPerBatch = 40;
    }

    public Config(EU261_Automation_Configuration__mdt config) {
      this.enabledCancellationAutomation = U.getOr(
        false,
        config.Cancellation_Automation__c
      );
      this.enabledDelayAutomation = U.getOr(false, config.Delay_Automation__c);
      this.enabledExpenseAutomation = U.getOr(
        false,
        config.Expense_Automation__c
      );
      this.enabledRejections = U.getOr(false, config.Automatic_Rejection__c);
      this.enabledSettlements = U.getOr(false, config.Automatic_Settlement__c);
      this.enabledSemiAutomation = U.getOr(
        false,
        config.Semi_Automation_Enabled__c
      );
      this.enabledAutomationProactivities = U.getOr(
        false,
        config.Automation_Proactivities__c
      );
      this.expenseLimitAccommodation = new Money(
        U.getOr(0, config.Expense_Limit_Accommodation__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitFood = new Money(
        U.getOr(0, config.Expense_Limit_Food__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitPhoneCalls = new Money(
        U.getOr(0, config.Expense_Limit_Phone_Calls__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitTransportation = new Money(
        U.getOr(0, config.Expense_Limit_Transportation__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitTotal = new Money(
        U.getOr(0, config.Claim_Expense_Max_Amount__c),
        Money.CurrencyCode.SEK
      );
      this.percentageRequiringManualApproval = U.getOr(
        0,
        config.Percentage_Sent_to_Control__c
      );
      this.claimsPerBatch = U.getOr(40, (Integer) config.Claims_Per_Batch__c);
    }
  }

  public static EU261Service newInstance() {
    return (EU261Service) SAS_Service_Application.Service.newInstance(
      EU261Service.class
    );
  }

  public EU261Service() {
    List<EU261_Automation_Configuration__mdt> automationConfig = [
      SELECT
        Automatic_Rejection__c,
        Automatic_Settlement__c,
        Delay_Automation__c,
        Cancellation_Automation__c,
        Expense_Automation__c,
        Claim_Expense_Max_Amount__c,
        Claims_Per_Batch__c,
        Expense_Limit_Accommodation__c,
        Expense_Limit_Food__c,
        Expense_Limit_Phone_Calls__c,
        Expense_Limit_Transportation__c,
        Percentage_Sent_to_Control__c,
        Semi_Automation_Enabled__c,
        Automation_Proactivities__c
      FROM EU261_Automation_Configuration__mdt
      WHERE Label = 'Default'
    ];

    if (automationConfig == null || automationConfig.size() != 1) {
      throw new AutomationException(
        'Missing EU261_Automation_Configuration__mdt.'
      );
    }

    this.config = new Config(automationConfig[0]);
  }

  public class AutomationException extends Exception {
  }
  public class EmailTemplateException extends Exception {
  }

  public void batchProcessEU261Claims(Set<Id> claimIds) {
    Integer limitPerBatchRun = this.config.claimsPerBatch;
    List<Id> claimIdsOdered = new List<Id>(claimIds);
    Integer claimsRemaining = claimIdsOdered.size();
    while (claimsRemaining > 0) {
      if (claimsRemaining > limitPerBatchRun) {
        // 200 is too much
        List<Id> notAllClaimIds = new List<Id>{};
        for (Integer i = 0; i < limitPerBatchRun; i++) {
          notAllClaimIds.add(claimIdsOdered[0]);
          claimIdsOdered.remove(0);
        }
        claimsRemaining = claimIdsOdered.size();
        System.enqueueJob(
          new ProcessEU261ClaimsAsync(new Set<Id>(notAllClaimIds), false)
        );
      } else {
        System.enqueueJob(
          new ProcessEU261ClaimsAsync(new Set<Id>(claimIdsOdered), true)
        );
        claimsRemaining = 0;
      }
    }
  }

  public class ProcessEU261ClaimsAsync implements Queueable, Database.AllowsCallouts {
    private Set<Id> claimIds;
    private Boolean isLastBatch;

    public ProcessEU261ClaimsAsync(Set<Id> claimIds, Boolean isLastBatch) {
      this.claimIds = claimIds;
      this.isLastBatch = isLastBatch;
    }

    public void execute(QueueableContext ctx) {
      EU261Service.newInstance()
        .processEU261Claims(claimIds, isLastBatch, ctx.getJobId());
    }
  }

  /**
   * Runs the EU261 evaluation and processing for the given set of claims
   * synchronously. See Config for options on what kinds of automation should
   * be done, and for other configuration parameters.
   *
   * @param claimIds A set of claim Ids to process.
   *
   * @return A list of EU261Claims which contain the decision of how the automation handled them.
   */
  public List<EU261Claim> processEU261Claims(
    Set<Id> claimIds,
    Boolean isLastBatch,
    String jobReference
  ) {
    U.verifyNotNull(claimIds);

    claimIds = filterProcessedClaims(claimIds, jobReference);

    List<EU261Claim> claimsToAutomate = gatherAllNecessaryInformation(claimIds);

    claimsToAutomate = filterAndRerouteUnsupportedClaimTypes(claimsToAutomate);

    for (EU261Claim c : claimsToAutomate) {
      c.evaluate();
    }

    storeClaimDecision(claimsToAutomate);

    settleAndRejectClaims(claimsToAutomate);

    if (isLastBatch) {
      Cache.Org.remove('processedClaims');
    }

    return claimsToAutomate;
  }

  /**
   * New, modularized version of the automation
   *
   * @param claimIds
   */
  public List<EU261Claim> processEU261Claims2(Set<Id> claimIds) {
    U.verifyNotNull(claimIds);

    List<EU261Claim> claimsToAutomate = gatherAllNecessaryInformation(claimIds);

    claimsToAutomate = filterAndRerouteUnsupportedClaimTypes(claimsToAutomate);

    List<EU261ProcessingBundle> processingBundles = new List<EU261ProcessingBundle>{};
    for (EU261Claim c : claimsToAutomate) {
      EU261ProcessingBundle bundle = new EU261ProcessingBundle();
      EU261Claim.Decision d;
      EU261AgentProtocol p = new EU261AgentProtocol();
      d = c.fillProtocolWithoutErrors(p);
      if (d == null) {
        d = c.evaluateProtocolWithoutErrors(p);
      }

      bundle.claim = c;
      bundle.decision = d;
      bundle.protocol = p;
      bundle.c = parentCasesById.get(c.claimObj.parentCaseId);
      processingBundles.add(bundle);
    }

    storeClaimDecision2(processingBundles);

    settleAndRejectClaims2(processingBundles);

    return claimsToAutomate;
  }

  public Set<Id> filterProcessedClaims(Set<Id> claimIds, String jobReference) {
    Map<Id, String> processedClaims = (Map<Id, String>) Cache.Org.get(
      'processedClaims'
    );

    if (processedClaims != null) {
      claimIds.removeAll(processedClaims.keySet());
    } else {
      processedClaims = new Map<Id, String>();
    }

    for (Id claimId : claimIds) {
      processedClaims.put(claimId, jobReference);
    }

    Cache.Org.put('processedClaims', processedClaims, TTL_SECONDS);

    return claimIds;
  }

  /**
   * Filters claims which are not enabled in the config.
   */
  public List<EU261Claim> filterAndRerouteUnsupportedClaimTypes(
    List<EU261Claim> claimsToAutomate
  ) {
    List<EU261Claim> filteredClaims = new List<EU261Claim>();
    List<EU261Claim> claimsWillNotHandle = new List<EU261Claim>();
    for (EU261Claim c : claimsToAutomate) {
      if (
        EU261Claim.EXPENSE_CLAIM_TYPES.contains(c.claimObj.type) &&
        !this.config.enabledExpenseAutomation
      ) {
        claimsWillNotHandle.add(c);
      } else if (
        !EU261Claim.DELAY_CLAIM_TYPES.contains(c.claimObj.type) &&
        !EU261Claim.CANCELLATION_CLAIM_TYPES.contains(c.claimObj.type) &&
        !EU261Claim.MISSED_CONNECTION_CLAIM_TYPES.contains(c.claimObj.type)
      ) {
        throw new AutomationException('Unsupported claim type');
      } else if (
        EU261Claim.CANCELLATION_CLAIM_TYPES.contains(c.claimObj.type) &&
        this.config.enabledCancellationAutomation
      ) {
        filteredClaims.add(c);
      } else if (
        (EU261Claim.DELAY_CLAIM_TYPES.contains(c.claimObj.type) ||
        EU261Claim.MISSED_CONNECTION_CLAIM_TYPES.contains(c.claimObj.type)) &&
        this.config.enabledDelayAutomation
      ) {
        filteredClaims.add(c);
      } else {
        claimsWillNotHandle.add(c);
      }
    }

    if (claimsWillNotHandle.size() > 0) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      rerouteAndSetWillNotHandle(claimsWillNotHandle, uow);
      uow.commitWork();
    }

    return filteredClaims;
  }

  private void rerouteAndSetWillNotHandle(
    List<EU261ProcessingBundle> bundlesUnableToHandle,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<EU261Claim> claimsWillNotHandle = new List<EU261Claim>();
    for (EU261ProcessingBundle b : bundlesUnableToHandle) {
      claimsWillNotHandle.add(b.claim);
    }
    rerouteAndSetWillNotHandle(claimsWillNotHandle, uow);
  }

  private void rerouteAndSetWillNotHandle(
    List<EU261Claim> claimsUnableToHandle,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<Case> toRoute = new List<Case>();
    List<Claim> toUpsert = new List<Claim>();
    for (EU261Claim c : claimsUnableToHandle) {
      if (
        c.claimObj.eu261HandlingStatus !=
        Claim.EU261HandlingStatus.UnableToHandle
      ) {
        c.claimObj.eu261HandlingStatus = Claim.EU261HandlingStatus.WillNotHandle;
      }
      c.claimObj.latestTimeOfEU261Automation = this.timeAtStartOfAutomation;
      toUpsert.add(c.claimObj);
      toRoute.add(parentCasesById.get(c.claimObj.parentCaseId));
    }

    Claims.newInstance(toUpsert).upsertToDB(uow);
    CaseService.assignPriorityAndRouteToQueue(toRoute);
  }

  /**
   * Fetches all of the necessary data to construct EU261Claim objects which
   * can be evaluated by the automation, and constructs the objects.
   *
   * All information must already exist in Salesforce.
   *
   * @return A list of EU261Claims, one per given Id.
   */
  public List<EU261Claim> gatherAllNecessaryInformation(Set<Id> claimIds) {
    ClaimsSelector claimsSel = ClaimsSelector.newInstance();
    List<Claim> claims = new List<Claim>();
    List<LIA_Claim__c> liaClaims = new List<LIA_Claim__c>();
    List<List<String>> pnrFlightNumberTuples = new List<List<String>>();

    Set<Id> claimIdsIgnored = new Set<Id>();

    for (LIA_Claim__c c : claimsSel.selectByIdWithCustomers(claimIds)) {
      try {
        Flight.normalizeFlightNumber(c.Flight_Number__c);
        claims.add(new Claim(c));
        liaClaims.add(c);
        pnrFlightNumberTuples.add(
          new List<String>{ c.Liability_PNR__c, c.Flight_Number__c }
        );
      } catch (Exception e) {
        System.debug(
          'Unable to normalize flight number: ' +
            c.Flight_Number__c +
            ' for claim: ' +
            c.Id
        );
        claimIdsIgnored.add(c.Id);
      }
    }

    Set<String> allCountriesInClaims = new Set<String>{};
    Set<Id> allCaseIdsInClaims = new Set<Id>();
    Set<String> allPnrsInClaims = new Set<String>();
    for (Claim c : claims) {
      allCountriesInClaims.add(c.contactCountry);
      allCaseIdsInClaims.add(c.parentCaseId);
      allPnrsInClaims.add(c.bookingReference);
    }

    List<Claim> otherClaimsWithMatchingPnrs = new List<Claim>();
    for (LIA_Claim__c c : claimsSel.selectByBookingReference(allPnrsInClaims)) {
      otherClaimsWithMatchingPnrs.add(new Claim(c));
    }

    List<CARE_Claim__c> possiblyDuplicateCAREClaims = CAREClaimsSelector.newInstance()
      .selectPotentialDuplicates(pnrFlightNumberTuples);

    List<CaseToBooking__c> ctbs = CaseToBookingsSelector.newInstance()
      .selectByCaseId(allCaseIdsInClaims);
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings = new Map<Id, List<CaseToBooking__c>>();
    Set<Id> allBookingIds = new Set<Id>();

    for (Case c : CasesSelector.newInstance().selectById(allCaseIdsInClaims)) {
      parentCasesById.put(c.Id, c);
    }

    if (ctbs != null) {
      for (CaseToBooking__c c : ctbs) {
        if (caseIdToCaseToBookings.get(c.Case__c) == null) {
          caseIdToCaseToBookings.put(
            c.Case__c,
            new List<CaseToBooking__c>{ c }
          );
        } else {
          caseIdToCaseToBookings.get(c.Case__c).add(c);
        }

        allBookingIds.add(c.Booking__c);
      }
    }

    checkForExistingSettlements(claimIds);

    List<Booking__c> allBookingsFoundInClaims = BookingsSelector.newInstance()
      .selectByIdFull(allBookingIds);

    Map<Id, Booking__c> bookingsById = new Map<Id, Booking__c>(
      allBookingsFoundInClaims
    );

    Set<String> allTEDSFlightIds = new Set<String>{};
    Set<String> allAirportCodes = new Set<String>{};
    Set<Id> segmentIds = new Set<Id>{};
    Set<Flight__c> allFlights = new Set<Flight__c>{};
    for (Booking__c b : allBookingsFoundInClaims) {
      for (Segment__c s : b.Segments__r) {
        if (s.flight__r == null) {
          continue;
        }
        allTEDSFlightIds.add(s.Flight__r.TEDS_Identifier__c);
        segmentIds.add(s.Id);
        allAirportCodes.add(s.Flight__r.Departure_Airport__c);
        allAirportCodes.add(s.Flight__r.Arrival_Airport__c);
        allFlights.add(s.Flight__r);
      }
    }

    Map<String, Airport> airportCodeToAirportObjects = new Airports(
        AirportsSelector.newInstance().selectByIATACode(allAirportCodes)
      )
      .getAirportCodeToAirportObject();

    List<Segment_Event__c> segmentEvents = SegmentEventsSelector.newInstance()
      .selectBySegmentId(segmentIds);

    List<FlightIrregularities__c> flightIrregularities = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(allTEDSFlightIds);

    Map<Id, List<FlightIrregularity>> flightIdToIrregularities = constructFlightIdToIrregularities(
      flightIrregularities
    );

    ProactivitiesSelector.ProactivityQueryResult proactivityData = new ProactivitiesSelector.ProactivityQueryResult();
    if (this.config.enabledAutomationProactivities) {
      proactivityData = ProactivitiesSelector.newInstance()
        .selectProactivitiesByClaimsFlightsAndIrregularitiesWithMatchingReasons(
          liaClaims,
          allFlights,
          flightIdToIrregularities,
          true
        );
    }

    return constructClaimWithCompensationDetails(
      claims,
      otherClaimsWithMatchingPnrs,
      caseIdToCaseToBookings,
      bookingsById,
      flightIdToIrregularities,
      segmentEvents,
      airportCodeToAirportObjects,
      possiblyDuplicateCAREClaims,
      proactivityData.flightIdToProactivities,
      proactivityData.claimIdToProactivities
    );
  }

  private Map<Id, List<FlightIrregularity>> constructFlightIdToIrregularities(
    List<FlightIrregularities__c> flightIrregularities
  ) {
    Map<Id, List<FlightIrregularity>> flightIdToIrregularities = new Map<Id, List<FlightIrregularity>>();

    for (FlightIrregularities__c fi : flightIrregularities) {
      FlightIrregularity newFi = new FlightIrregularity(fi);
      if (flightIdToIrregularities.get(newFi.flightId) == null) {
        flightIdToIrregularities.put(
          newFi.flightId,
          new List<FlightIrregularity>()
        );
      }

      try {
        if (!newFi.isInvalid()) {
          flightIdToIrregularities.get(newFi.flightId).add(newFi);
        }
      } catch (FlightIrregularity.UnknownIrregularityException e) {
        // If there is an invalid type, add it and let the automation handle it.
        flightIdToIrregularities.get(newFi.flightId).add(newFi);
      }
    }

    for (Id flightId : flightIdToIrregularities.keySet()) {
      flightIdToIrregularities.put(
        flightId,
        FlightIrregularity.unique(flightIdToIrregularities.get(flightId))
      );
    }

    return flightIdToIrregularities;
  }

  /**
   * Constructs a list of EU261Claims given all necessary information.
   *
   * Helper for gatherAllNecessaryInformation().
   *
   * TODO: break out and make better
   * Could be good to use something like the builder pattern here.
   * E.g.: List of bookings b = BookingsBuilder(records).withEvents.withAirport.withXYZ and then Bookings.newInstance(b)
   */
  private List<EU261Claim> constructClaimWithCompensationDetails(
    List<Claim> claims,
    List<Claim> otherClaimsWithMatchingPnrs,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById,
    Map<Id, List<FlightIrregularity>> flightIdToIrregularities,
    List<Segment_Event__c> segmentEvents,
    Map<String, Airport> airportCodeToAirportObjects,
    List<CARE_Claim__c> possiblyDuplicateCAREClaims,
    Map<Id, Set<Proactivity__c>> flightIdToProactivities,
    Map<Id, Set<Proactivity__c>> claimIdToProactivities
  ) {
    List<EU261Claim> toReturn = new List<EU261Claim>{};

    Map<Id, List<SegmentEvent>> segmentIdToSegmentEvents = new Map<Id, List<SegmentEvent>>();
    for (Segment_Event__c se : segmentEvents) {
      SegmentEvent newSe = new SegmentEvent(se);
      if (segmentIdToSegmentEvents.get(newSe.segmentId) == null) {
        segmentIdToSegmentEvents.put(newSe.segmentId, new List<SegmentEvent>());
      }

      segmentIdToSegmentEvents.get(newSe.segmentId).add(newSe);
    }

    for (Claim c : claims) {
      List<Booking__c> bookingsForClaim = new List<Booking__c>();

      List<CaseToBooking__c> ctbsForClaim = caseIdToCaseToBookings.get(
        c.parentCaseId
      );

      if (ctbsForClaim != null) {
        for (CaseToBooking__c ctb : ctbsForClaim) {
          Booking__c booking = bookingsById.get(ctb.Booking__c);
          if (booking != null) {
            bookingsForClaim.add(booking);
          }
        }
      }

      Bookings booking = Bookings.newInstance(bookingsForClaim);

      // Check if the claim matches any other claim by PNR
      Boolean hasPotentiallyDuplicateClaims = false;
      for (Claim otherClaim : otherClaimsWithMatchingPnrs) {
        // There can exist one expense and one compensation claim without being duplicates

        Boolean oneIsExpenseOneIsCompensation =
          (c.isExpenseClaim() && otherClaim.isCompensationClaim()) ||
          (c.isCompensationClaim() && otherClaim.isExpenseClaim());
        if (
          c.bookingReference == otherClaim.bookingReference &&
          c.id != otherClaim.id &&
          !oneIsExpenseOneIsCompensation
        ) {
          hasPotentiallyDuplicateClaims = true;
        }
      }
      for (CARE_Claim__c cc : possiblyDuplicateCAREClaims) {
        if (
          c.bookingReference == cc.Booking_Reference__c &&
          c.flightNumber == cc.Flight_Number__c
        ) {
          hasPotentiallyDuplicateClaims = true;
        }
      }

      Map<Id, List<FlightIrregularity>> claimSpecificIrregularities = new Map<Id, List<FlightIrregularity>>{};
      if (booking.instanceRecords.size() > 0) {
        for (Segment__c s : booking.instanceRecords[0].Segments__r) {
          List<FlightIrregularity> flightIrreg = flightIdToIrregularities.get(
            s.Flight__c
          );
          if (flightIrreg == null) {
            flightIrreg = new List<FlightIrregularity>{};
          }
          claimSpecificIrregularities.put(s.Flight__c, flightIrreg);
        }
      }

      Boolean hasSegmentWithoutFlight = false;
      for (Booking b : booking.objects) {
        for (Segment s : b.segments) {
          if (s.flight == null) {
            hasSegmentWithoutFlight = true;
            continue;
          }
          s.flight.irregularities = claimSpecificIrregularities.get(
            s.flight.id
          );
          List<SegmentEvent> events = segmentIdToSegmentEvents.get(s.Id);
          s.setEvents(events);
          b.setAirports(airportCodeToAirportObjects);
        }
      }

      EU261Claim fullClaim = new EU261Claim(
        c,
        booking.objects,
        hasPotentiallyDuplicateClaims,
        this.config
      );

      fullClaim.hasSegmentWithoutFlight = hasSegmentWithoutFlight; // This should not happen if there is not an issue with EDW
      fullClaim.claimProactivities = claimIdToProactivities.get(c.id);
      fullClaim.flightIdToProactivities = flightIdToProactivities;

      toReturn.add(fullClaim);
    }

    return toReturn;
  }

  public void storeClaimDecision2(
    List<EU261ProcessingBundle> processingBundles
  ) {
    List<Claim> toUpsert = new List<Claim>();
    String noteTemplate = 'Compensation: {0}';
    String caveatTemplate = 'Compensation: {0} {1}';
    String reimburementTemplate = 'Reimbursement OK, check receipts {0}';
    for (EU261ProcessingBundle processingBundle : processingBundles) {
      String handlingNote;
      EU261Claim.Decision d = processingBundle.decision;

      switch on d.verdict {
        when EligibleForCompensation {
          handlingNote = String.format(
            noteTemplate,
            new List<Object>{ d.compensationPerCustomerInEUR.values() }
          );
        }
        when PossiblyEligibleForCompensation {
          handlingNote = String.format(
            caveatTemplate,
            new List<Object>{
              d.compensationPerCustomerInEUR.values(),
              d.caveats
            }
          );
        }
        when ReimbursementOnly {
          handlingNote = String.format(
            reimburementTemplate,
            new List<Object>{ d.caveats }
          );
        }
        when else {
          handlingNote = d.reasoning;
        }
      }

      Claim c = processingBundle.claim.claimObj;
      c.eu261HandlingStatus = d.verdict;
      c.eu261HandlingNote = handlingNote;
      c.latestTimeOfEU261Automation = this.timeAtStartOfAutomation;
      toUpsert.add(c);
    }

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Claims.newInstance(toUpsert).upsertToDB(uow);
    uow.commitWork();
  }

  /**
   * Stores the evaluation decision and possible reasoning to the claim object.
   */
  private void storeClaimDecision(List<EU261Claim> claimsToAutomate) {
    List<EU261ProcessingBundle> processingBundles = new List<EU261ProcessingBundle>(); // Temp: during deprecation
    for (EU261Claim c : claimsToAutomate) {
      EU261ProcessingBundle b = new EU261ProcessingBundle();
      b.claim = c;
      b.decision = c.decision;
      processingBundles.add(b);
    }
    storeClaimDecision2(processingBundles);
  }

  private Boolean shouldAutomate(EU261Claim c) {
    return shouldAutomate2(c.decision); // Temp during refactor
  }

  private Boolean shouldAutomate2(EU261Claim.Decision d) {
    if (REASONINGS_NOT_AUTOMATABLE.contains(d.reasoning)) {
      // TODO: refactor, really ugly
      return false;
    }
    return true;
  }

  public enum Outcome {
    Approved,
    Rejected,
    SemiAutomated,
    ManualHandling,
    ManualApproval
  }

  public class EU261ProcessingBundle {
    public Outcome outcome;
    public EU261Claim claim;
    public EU261AgentProtocol protocol;
    public EU261Claim.Decision decision;
    public Case c; // case is reserved
  }

  // Temp: during refactor
  public void settleAndRejectClaims2(
    List<EU261ProcessingBundle> processingBundles
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    // Loop
    for (EU261ProcessingBundle b : processingBundles) {
      EU261Claim c = b.claim;
      EU261Claim.Decision d = b.decision;

      // Filter
      if (!shouldAutomate2(d)) {
        b.outcome = Outcome.ManualHandling;
        continue;
      }

      // Sort
      switch on d.verdict {
        when EligibleForCompensation {
          if (
            EU261Claim.EXPENSE_CLAIM_TYPES.contains(c.claimObj.type) &&
            c.hasHighClaimedExpenses()
          ) {
            // TODO: fix hasHighClaimedExpenses
            b.outcome = Outcome.SemiAutomated;
          } else if (shouldApproveAutomatically()) {
            b.outcome = Outcome.Approved;
          } else {
            b.outcome = Outcome.ManualApproval;
          }
        }
        when PossiblyEligibleForCompensation, ReimbursementOnly {
          b.outcome = Outcome.SemiAutomated;
        }
        when IneligibleForCompensation, IneligibleForCompensationAndExpenses {
          b.outcome = Outcome.Rejected;
        }
        when else {
          b.outcome = Outcome.ManualHandling;
        }
      }
    }

    // Create settlements
    if (this.config.enabledSettlements) {
      handleSettlementClaims2(processingBundles, uow);
    } else {
      // Change all approve automatically and manual approval to manual handling
      for (EU261ProcessingBundle b : processingBundles) {
        if (
          b.outcome == Outcome.Approved ||
          b.outcome == Outcome.ManualApproval
        ) {
          b.outcome = Outcome.ManualHandling;
        }
      }
    }

    List<EU261ProcessingBundle> bundlesToSemiAutomate = new List<EU261ProcessingBundle>();
    for (EU261ProcessingBundle b : processingBundles) {
      if (b.outcome == Outcome.SemiAutomated) {
        bundlesToSemiAutomate.add(b);
      }
    }
    handleSemiAutomationClaims2(bundlesToSemiAutomate, uow);

    // Handle rejections
    if (this.config.enabledRejections) {
      rejectClaims(processingBundles, uow);
    } else {
      for (EU261ProcessingBundle b : processingBundles) {
        if (b.outcome == Outcome.Rejected) {
          b.outcome = Outcome.ManualHandling;
        }
      }
    }

    List<EU261Claim> claimsToManualHandling = new List<EU261Claim>();
    for (EU261ProcessingBundle b : processingBundles) {
      if (b.outcome == Outcome.ManualHandling) {
        claimsToManualHandling.add(b.claim);
      }
    }

    if (claimsToManualHandling.size() > 0) {
      // TODO: see if we somehow can do this async (a queueable queuing error might stop this)
      rerouteAndSetWillNotHandle(claimsToManualHandling, uow);
    }

    uow.commitWork();
  }

  private void rejectClaims(
    List<EU261ProcessingBundle> processingBundles,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<Case> parentCasesForRejection = new List<Case>();
    List<EU261ProcessingBundle> bundlesToReject = new List<EU261ProcessingBundle>();
    for (EU261ProcessingBundle b : processingBundles) {
      if (b.outcome == Outcome.Rejected) {
        bundlesToReject.add(b);
        parentCasesForRejection.add(b.c);
      }
    }
    Cases.newInstance(parentCasesForRejection)
      .emailContactPeople(createRejectionEmails2(bundlesToReject), uow)
      .close(uow);
  }

  /**
   * Processes all of the claims which we can settle, reject or automate
   * partially. Creates settlements, emails and prepares them and the claim and
   * case to updated in the DB.
   *
   * Splits claims into several groups based on the evaluation decision and
   * finalizes the processing accordingly.
   *
   * At this stage claims can be split into four different categories based on
   * what we want to do with them:
   * 1. Ones we want to pay out automatically
   * 2. Ones where customer appears to be eligible for payment but there are some caveats
   * 3. Ones we can reject automatically
   * 4. Ones where we cannot determine eligibility at all
   *
   * Claims in the first category we pay out directly, but some of these fall
   * to the approval queue for spot checks. Claims in the second category we
   * can send to a specific manual handling queue with instructions for the
   * agents on what they need to check before rejecting or sending the claim to
   * approval. Claims in the third category we can just close and email the
   * customer the result and claims in the fourth category we do nothing with
   * as they need to go to manual handling.
   */
  private void settleAndRejectClaims(List<EU261Claim> claimsToAutomate) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    List<EU261Claim> claimsToApproveAutomatically = new List<EU261Claim>();
    List<EU261Claim> claimsToManualApproval = new List<EU261Claim>();
    List<EU261Claim> claimsToReject = new List<EU261Claim>();

    List<Case> parentCasesForAutomaticApproval = new List<Case>();
    List<Case> parentCasesForManualApproval = new List<Case>();
    List<Case> parentCasesForRejection = new List<Case>();

    Map<EU261Claim, Case> claimToSemiAutomateToCase = new Map<EU261Claim, Case>();

    List<EU261Claim> claimsToManualHandling = new List<EU261Claim>();

    // Loop
    for (EU261Claim c : claimsToAutomate) {
      // Filter
      if (!shouldAutomate(c)) {
        claimsToManualHandling.add(c);
        continue;
      }

      // Sort
      switch on c.decision.verdict {
        when EligibleForCompensation {
          if (
            EU261Claim.EXPENSE_CLAIM_TYPES.contains(c.claimObj.type) &&
            c.hasHighClaimedExpenses()
          ) {
            claimToSemiAutomateToCase.put(
              c,
              parentCasesById.get(c.claimObj.parentCaseId)
            );
          } else if (shouldApproveAutomatically()) {
            claimsToApproveAutomatically.add(c);
          } else {
            claimsToManualApproval.add(c);
          }
        }
        when PossiblyEligibleForCompensation, ReimbursementOnly {
          claimToSemiAutomateToCase.put(
            c,
            parentCasesById.get(c.claimObj.parentCaseId)
          );
        }
        when IneligibleForCompensation, IneligibleForCompensationAndExpenses {
          claimsToReject.add(c);
          parentCasesForRejection.add(
            parentCasesById.get(c.claimObj.parentCaseId)
          );
        }
        when else {
          claimsToManualHandling.add(c);
        }
      }
    }

    // Create settlements
    if (this.config.enabledSettlements) {
      handleSettlementClaims(
        claimsToManualApproval,
        claimsToApproveAutomatically,
        parentCasesForManualApproval,
        parentCasesForAutomaticApproval,
        uow
      );
    } else {
      claimsToManualHandling.addAll(claimsToApproveAutomatically);
      claimsToManualHandling.addAll(claimsToManualApproval);
    }

    if (claimToSemiAutomateToCase.size() > 0) {
      handleSemiAutomationClaims(claimToSemiAutomateToCase, uow);
    }

    // Handle rejections
    if (this.config.enabledRejections && claimsToReject.size() > 0) {
      Cases.newInstance(parentCasesForRejection)
        .emailContactPeople(createRejectionEmails(claimsToReject), uow)
        .close(uow);
    } else {
      claimsToManualHandling.addAll(claimsToReject);
    }

    if (claimsToManualHandling.size() > 0) {
      // TODO: see if we somehow can do this async (a queueable queuing error might stop this)
      rerouteAndSetWillNotHandle(claimsToManualHandling, uow);
    }

    uow.commitWork();
  }

  private void handleSemiAutomationClaims2(
    List<EU261ProcessingBundle> processingBundles,
    fflib_ISObjectUnitOfWork uow
  ) {
    // Handle semi-automation claims
    if (this.config.enabledSemiAutomation) {
      Map<Id, String> handlingInstructionsByCaseId = new Map<Id, String>();
      List<Case> casesForSemiAutomationCompensation = new List<Case>();
      List<Case> casesForSemiAutomationExpenses = new List<Case>();
      List<EU261ProcessingBundle> bundlesWhichNeedSettlements = new List<EU261ProcessingBundle>();
      for (EU261ProcessingBundle b : processingBundles) {
        List<EU261Claim.SemiAutomationReason> semiAutomationReasonsForClaim = b.decision.caveats;
        Boolean hasInvalidSettlement = false;

        List<String> handlingInstructions = new List<String>();
        for (
          EU261Claim.SemiAutomationReason reason : semiAutomationReasonsForClaim
        ) {
          handlingInstructions.add(
            SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS.get(reason)
          );

          if (
            reason == EU261Claim.SemiAutomationReason.InvalidSettlementDetails
          ) {
            hasInvalidSettlement = true;
          }
        }

        handlingInstructionsByCaseId.put(
          b.c.Id,
          String.join(handlingInstructions, ' | ')
        );

        if (b.protocol.isExpenseClaim) {
          casesForSemiAutomationExpenses.add(b.c);
        } else {
          casesForSemiAutomationCompensation.add(b.c);
          if (!hasInvalidSettlement) {
            bundlesWhichNeedSettlements.add(b);
          }
        }
      }

      // Create simple compensation settlements without submitting
      createSettlementsForClaims2(bundlesWhichNeedSettlements);

      Claims.newInstance(getClaimSObjectsFor(processingBundles))
        .upsertToDB(uow);

      Cases.newInstance(casesForSemiAutomationCompensation)
        .setHandlingInstructions(uow, handlingInstructionsByCaseId)
        .routeToQueue(SEMI_AUTOMATION_QUEUE_COMPENSATION, uow);

      Cases.newInstance(casesForSemiAutomationExpenses)
        .setHandlingInstructions(uow, handlingInstructionsByCaseId)
        .routeToQueue(SEMI_AUTOMATION_QUEUE_REIMBURSEMENT, uow);
    } else {
      rerouteAndSetWillNotHandle(processingBundles, uow);
    }
  }

  private List<LIA_Claim__c> getClaimSObjectsFor(
    List<EU261ProcessingBundle> processingBundles
  ) {
    List<LIA_Claim__c> theClaims = new List<LIA_Claim__c>();
    for (EU261ProcessingBundle b : processingBundles) {
      theClaims.add(b.claim.claimObj.underlyingSObject);
    }
    return theClaims;
  }

  private void handleSemiAutomationClaims(
    Map<EU261Claim, Case> claimToSemiAutomateToCase,
    fflib_ISObjectUnitOfWork uow
  ) {
    // Handle semi-automation claims
    if (this.config.enabledSemiAutomation) {
      Map<Id, String> handlingInstructionsByCaseId = new Map<Id, String>();
      List<Case> casesForSemiAutomationCompensation = new List<Case>();
      List<Case> casesForSemiAutomationExpenses = new List<Case>();
      List<EU261Claim> claimsWhichNeedSettlements = new List<EU261Claim>();
      for (EU261Claim cl : claimToSemiAutomateToCase.keySet()) {
        List<EU261Claim.SemiAutomationReason> semiAutomationReasonsForClaim = cl.getSemiAutomationReasons(); // TODO: remvoe
        Case c = claimToSemiAutomateToCase.get(cl);
        Boolean hasInvalidSettlement = false;

        List<String> handlingInstructions = new List<String>();
        for (
          EU261Claim.SemiAutomationReason reason : semiAutomationReasonsForClaim
        ) {
          handlingInstructions.add(
            SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS.get(reason)
          );

          if (
            reason == EU261Claim.SemiAutomationReason.InvalidSettlementDetails
          ) {
            hasInvalidSettlement = true;
          }
        }

        handlingInstructionsByCaseId.put(
          c.Id,
          String.join(handlingInstructions, ' | ')
        );

        if (EU261Claim.EXPENSE_CLAIM_TYPES.contains(cl.claimObj.type)) {
          casesForSemiAutomationExpenses.add(c);
        } else {
          casesForSemiAutomationCompensation.add(c);
          if (!hasInvalidSettlement) {
            claimsWhichNeedSettlements.add(cl);
          }
        }
      }

      // Create simple compensation settlements without submitting
      createSettlementsForClaims(claimsWhichNeedSettlements);

      Claims.newInstance(
          EU261Claim.getClaimSObjectsFor(claimToSemiAutomateToCase.keySet())
        )
        .upsertToDB(uow);

      Cases.newInstance(casesForSemiAutomationCompensation)
        .setHandlingInstructions(uow, handlingInstructionsByCaseId)
        .routeToQueue(SEMI_AUTOMATION_QUEUE_COMPENSATION, uow);

      Cases.newInstance(casesForSemiAutomationExpenses)
        .setHandlingInstructions(uow, handlingInstructionsByCaseId)
        .routeToQueue(SEMI_AUTOMATION_QUEUE_REIMBURSEMENT, uow);
    } else {
      rerouteAndSetWillNotHandle(
        new List<EU261Claim>(claimToSemiAutomateToCase.keySet()),
        uow
      );
    }
  }

  private void handleSettlementClaims2(
    List<EU261ProcessingBundle> processingBundles,
    fflib_ISObjectUnitOfWork uow
  ) {
    // Temp during refactor
    List<EU261ProcessingBundle> bundlesToManualApproval = new List<EU261ProcessingBundle>();
    List<EU261ProcessingBundle> bundlesToApproveAutomatically = new List<EU261ProcessingBundle>();
    for (EU261ProcessingBundle b : processingBundles) {
      if (b.outcome == Outcome.ManualApproval) {
        bundlesToManualApproval.add(b);
      } else if (b.outcome == Outcome.Approved) {
        bundlesToApproveAutomatically.add(b);
      }
    }

    handleSettlementClaims2(
      bundlesToManualApproval,
      bundlesToApproveAutomatically,
      uow
    );
  }

  private void handleSettlementClaims2(
    List<EU261ProcessingBundle> bundlesToManualApproval,
    List<EU261ProcessingBundle> bundlesToApproveAutomatically,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<EU261ProcessingBundle> bundlesWhichNeedSettlements = new List<EU261ProcessingBundle>();
    bundlesWhichNeedSettlements.addAll(bundlesToManualApproval);
    bundlesWhichNeedSettlements.addAll(bundlesToApproveAutomatically);

    Map<Id, List<Settlement__c>> settlementsByClaimId = createSettlementsForClaims2(
      bundlesWhichNeedSettlements
    );

    List<EU261ProcessingBundle> invalidBundles = new List<EU261ProcessingBundle>();

    List<EU261ProcessingBundle> validatedManualHandlingBundles = new List<EU261ProcessingBundle>();
    List<EU261ProcessingBundle> validatedAutomaticApprovalBundles = new List<EU261ProcessingBundle>();

    // Create settlements for manual approval
    for (EU261ProcessingBundle b : bundlesToManualApproval) {
      EU261Claim cl = b.claim;
      Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
          settlementsByClaimId.get(cl.claimObj.id)
        )
        .keySet()
        .size();

      if (numberOfSettlementsWithValidationErrors > 0) {
        invalidBundles.add(b);
      } else {
        validatedManualHandlingBundles.add(b);
      }
    }

    // Create settlements for automatic approval
    for (EU261ProcessingBundle b : bundlesToApproveAutomatically) {
      Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
          settlementsByClaimId.get(b.claim.claimObj.id)
        )
        .keySet()
        .size();

      if (numberOfSettlementsWithValidationErrors > 0) {
        invalidBundles.add(b);
      } else {
        validatedAutomaticApprovalBundles.add(b);
      }
    }

    // Handle manual handling claims
    if (validatedManualHandlingBundles.size() > 0) {
      List<Settlement__c> settlementsForManualApproval = new List<Settlement__c>();

      for (EU261ProcessingBundle b : validatedManualHandlingBundles) {
        settlementsForManualApproval.addAll(
          settlementsByClaimId.get(b.claim.claimObj.id)
        );
      }

      uow.registerNew(
        createDraftApprovedEmails2(
          validatedManualHandlingBundles,
          settlementsByClaimId
        )
      );

      Settlements.newInstance(settlementsForManualApproval)
        .validate()
        .submitToApproval(uow)
        .lock();

      Cases.newInstance(extractCases(bundlesToManualApproval))
        .submitToEU261Approvals(uow);
    }

    // Handle automatic approval claims
    if (validatedAutomaticApprovalBundles.size() > 0) {
      Cases.newInstance(extractCases(validatedAutomaticApprovalBundles))
        .emailContactPeople(
          createApprovedEmails2(
            validatedAutomaticApprovalBundles,
            settlementsByClaimId
          ),
          uow
        )
        .close(uow);

      Claims.newInstance(getClaimSObjectsFor(validatedAutomaticApprovalBundles))
        .settle(uow);
    }

    // Handle invalid settlements
    if (invalidBundles.size() > 0) {
      // If automatically created settlements aren't valid, we can't fully
      // resolve these claims automatically. An agent needs to either fix the
      // payment details, or reach out to the customer to ask for new ones.
      for (EU261ProcessingBundle b : invalidBundles) {
        b.decision.caveats.add(
          EU261Claim.SemiAutomationReason.InvalidSettlementDetails
        );
      }

      handleSemiAutomationClaims2(invalidBundles, uow);
    }
  }

  private static List<Case> extractCases(List<EU261ProcessingBundle> bundles) {
    List<Case> cases = new List<Case>();
    for (EU261ProcessingBundle b : bundles) {
      cases.add(b.c);
    }
    return cases;
  }

  private static List<EU261Claim> extractClaims(List<EU261Claim> bundles) {
    List<EU261Claim> claims = new List<EU261Claim>();
    for (EU261Claim b : bundles) {
      claims.add(b);
    }
    return claims;
  }

  private void handleSettlementClaims(
    List<EU261Claim> claimsToManualApproval,
    List<EU261Claim> claimsToApproveAutomatically,
    List<Case> parentCasesForManualApproval,
    List<Case> parentCasesForAutomaticApproval,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<EU261Claim> claimsWhichNeedSettlements = new List<EU261Claim>();
    claimsWhichNeedSettlements.addAll(claimsToManualApproval);
    claimsWhichNeedSettlements.addAll(claimsToApproveAutomatically);

    Map<Id, List<Settlement__c>> settlementsByClaimId = createSettlementsForClaims(
      claimsWhichNeedSettlements
    );

    Map<EU261Claim, Case> invalidSettlementClaimToCase = new Map<EU261Claim, Case>();

    List<EU261Claim> validatedManualHandlingClaims = new List<EU261Claim>();
    List<EU261Claim> validatedAutomaticApprovalClaims = new List<EU261Claim>();

    // Create settlements for manual approval
    for (EU261Claim cl : claimsToManualApproval) {
      Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
          settlementsByClaimId.get(cl.claimObj.id)
        )
        .keySet()
        .size();

      if (numberOfSettlementsWithValidationErrors > 0) {
        invalidSettlementClaimToCase.put(
          cl,
          parentCasesById.get(cl.claimObj.parentCaseId)
        );
      } else {
        validatedManualHandlingClaims.add(cl);
        parentCasesForManualApproval.add(
          parentCasesById.get(cl.claimObj.parentCaseId)
        );
      }
    }

    // Create settlements for automatic approval
    for (EU261Claim cl : claimsToApproveAutomatically) {
      Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
          settlementsByClaimId.get(cl.claimObj.id)
        )
        .keySet()
        .size();

      if (numberOfSettlementsWithValidationErrors > 0) {
        invalidSettlementClaimToCase.put(
          cl,
          parentCasesById.get(cl.claimObj.parentCaseId)
        );
      } else {
        validatedAutomaticApprovalClaims.add(cl);
        parentCasesForAutomaticApproval.add(
          parentCasesById.get(cl.claimObj.parentCaseId)
        );
      }
    }

    // Handle manual handling claims
    if (validatedManualHandlingClaims.size() > 0) {
      List<Settlement__c> settlementsForManualApproval = new List<Settlement__c>();

      for (EU261Claim cl : validatedManualHandlingClaims) {
        settlementsForManualApproval.addAll(
          settlementsByClaimId.get(cl.claimObj.id)
        );
        parentCasesForManualApproval.add(
          parentCasesById.get(cl.claimObj.parentCaseId)
        );
      }

      uow.registerNew(
        createDraftApprovedEmails(
          validatedManualHandlingClaims,
          settlementsByClaimId
        )
      );

      Settlements.newInstance(settlementsForManualApproval)
        .validate()
        .submitToApproval(uow)
        .lock();

      Cases.newInstance(parentCasesForManualApproval)
        .submitToEU261Approvals(uow);
    }

    // Handle automatic approval claims
    if (validatedAutomaticApprovalClaims.size() > 0) {
      Cases.newInstance(parentCasesForAutomaticApproval)
        .emailContactPeople(
          createApprovedEmails(
            validatedAutomaticApprovalClaims,
            settlementsByClaimId
          ),
          uow
        )
        .close(uow);

      Claims.newInstance(
          EU261Claim.getClaimSObjectsFor(validatedAutomaticApprovalClaims)
        )
        .settle(uow);
    }

    // Handle invalid settlements
    if (invalidSettlementClaimToCase.keySet().size() > 0) {
      // If automatically created settlements aren't valid, we can't fully
      // resolve these claims automatically. An agent needs to either fix the
      // payment details, or reach out to the customer to ask for new ones.
      for (EU261Claim cl : invalidSettlementClaimToCase.keySet()) {
        cl.decision.caveats.add(
          EU261Claim.SemiAutomationReason.InvalidSettlementDetails
        );
      }

      handleSemiAutomationClaims(invalidSettlementClaimToCase, uow);
    }
  }

  private Boolean shouldApproveAutomatically() {
    return Math.random() * 100 >= this.config.percentageRequiringManualApproval;
  }

  /**
   * Creates settlements with settlement items for the given claims and inserts
   * them to the DB.
   *
   * Creates one or two settlements for each claim. If a claim has only
   * reimbursement or compensation this creates one settlement. If the claim
   * has both reimbursement and compensation, it creates two. We could combine
   * these into one settlement when the preferred compensation and
   * reimbursement methods are the same, but separating them out makes later
   * processing simpler.
   *
   * Does two DB inserts.
   *
   * @param claimsToPayOut A list of claims to be paid out. Must not include claims which shouldn't be settled.
   * @return A map from claim id to settlements for that claim. There can be one or two settlements per claim.
   */
  @TestVisible
  private Map<Id, List<Settlement__c>> createSettlementsForClaims(
    List<EU261Claim> claimsToPayOut
  ) {
    Map<Id, List<Settlement__c>> allSettlementsByClaimId = new Map<Id, List<Settlement__c>>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromEURByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromSEKByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();

    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.EUR)
    ) {
      exchangeRatesFromEURByToCurrency.put(er.toCurrency, er);
    }
    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.SEK)
    ) {
      exchangeRatesFromSEKByToCurrency.put(er.toCurrency, er);
    }

    Set<Id> claimsRequiringSettlements = new Set<Id>();
    List<LIA_Claim__c> allPayableClaimSObjects = new List<LIA_Claim__c>();
    List<LIA_Claim__c> claimsRequiringTwoSettlements = new List<LIA_Claim__c>(); // Deprecated nomenclature (kind of)
    List<LIA_Claim__c> claimsWithoutSettlements = new List<LIA_Claim__c>();

    // Sort claims into groups
    for (EU261Claim c : claimsToPayOut) {
      claimsRequiringSettlements.add(c.claimObj.id);

      if (c.decision.reimbursementAmountInSEK.amount == 0) {
        allPayableClaimSObjects.add(c.claimObj.underlyingSObject);
      } else {
        if (c.hasHighClaimedExpenses()) {
          claimsWithoutSettlements.add(c.claimObj.underlyingSObject);
        } else {
          claimsRequiringTwoSettlements.add(c.claimObj.underlyingSObject);
        }
      }
    }

    // Perform a double check existing settlements & throw an error if they already exist
    checkForExistingSettlements(claimsRequiringSettlements);

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();
    Settlements compensationSettlements = Settlements.createFromClaim(
      allPayableClaimSObjects,
      null,
      false,
      uow1
    );
    Settlements reimbursementSettlements = Settlements.createFromClaim( // TODO: We shouldn't even create these if the amounts are too high.
      claimsRequiringTwoSettlements,
      null,
      true,
      uow1
    );
    uow1.commitWork();

    Map<Id, List<SettlementItem>> compensationSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();
    Map<Id, List<SettlementItem>> reimbursementSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();

    for (EU261Claim c : claimsToPayOut) {
      if (claimsWithoutSettlements.contains(c.claimObj.underlyingSObject)) {
        continue;
      }
      Settlement__c compensationSettlementForClaim;
      Settlement__c reimbursementSettlementForClaim;
      Boolean claimRequiresTwoSettlements = false;
      for (Settlement__c ss : compensationSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          compensationSettlementForClaim = ss;

          compensationSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          allSettlementsByClaimId.put(
            ss.Claim__c,
            new List<Settlement__c>{ ss }
          );
          break;
        }
      }
      for (Settlement__c ss : reimbursementSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          reimbursementSettlementForClaim = ss;

          reimbursementSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          claimRequiresTwoSettlements = true;

          if (allSettlementsByClaimId.get(ss.Claim__c) != null) {
            throw new AutomationException(
              'There should not be two settlements for one claim since the automation was split into compensation and expenses.'
            );
          }

          allSettlementsByClaimId.put(
            ss.Claim__c,
            new List<Settlement__c>{ ss }
          );
          break;
        }
      }

      if (
        c.decision.compensationPerCustomerInEUR != null &&
        compensationSettlementForClaim != null
      ) {
        for (
          ClaimCustomer customer : c.decision.compensationPerCustomerInEUR.keySet()
        ) {
          SettlementItem si = new SettlementItem();
          si.customerName = customer.fullName;
          si.costAccount = COMPENSATION_COST_ACCOUNT;
          si.comments = 'Automatic EU261 compensation';
          si.recordType = SettlementItem.RecordType.DefaultRecordType;
          compensationSettlementItemsBySettlementId.get(
              compensationSettlementForClaim.Id
            )
            .add(si);

          Money value = c.decision.compensationPerCustomerInEUR.get(customer);

          switch on c.claimObj.preferredCompensationMethod {
            when EBPoints {
              si.amount = value.inEuroBonusPoints();
            }
            when Voucher {
              si.setValue(
                value.multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                  .setScale(0)
              );
            }
            when else {
              // Default to monetary
              Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
                compensationSettlementForClaim.Currency__c
              );

              if (settlementCurrency != Money.CurrencyCode.EUR) {
                ExchangeRate exchangeRate = exchangeRatesFromEURByToCurrency.get(
                  settlementCurrency
                );
                if (exchangeRate == null) {
                  throw new AutomationException('Cannot find exchange rate.');
                } else {
                  value = value.convertTo(settlementCurrency, exchangeRate);
                }
              }

              si.setValue(value.setScale(0));
            }
          }
        }
      }

      Money reimbursement = c.decision.reimbursementAmountInSEK;
      if (
        reimbursement != null &&
        reimbursement.amount > 0 &&
        !c.hasHighClaimedExpenses()
      ) {
        // TODO: This needs to support creating a separate settlement in case we need to make a reimbusement
        // Cant have different methods in one settlement!
        SettlementItem si = new SettlementItem();
        si.customerName = c.claimObj.contactFullName;
        si.costAccount = REIMBURSEMENT_COST_ACCOUNT;
        si.comments = 'Automatic EU261 reimbursement';
        si.recordType = SettlementItem.RecordType.DefaultRecordType;

        reimbursementSettlementItemsBySettlementId.get(
            reimbursementSettlementForClaim.Id
          )
          .add(si);

        switch on c.claimObj.preferredReimbursementMethod {
          when EBPoints {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );
            si.amount = reimbursement.convertTo(
                Money.CurrencyCode.EUR,
                sekToEur
              )
              .inEuroBonusPoints();
          }
          when Voucher {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );

            si.setValue(
              reimbursement.convertTo(Money.CurrencyCode.EUR, sekToEur)
                .multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                .setScale(0)
            );
          }
          when else {
            // Default to monetary
            Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
              reimbursementSettlementForClaim.Currency__c
            );

            if (settlementCurrency != Money.CurrencyCode.SEK) {
              ExchangeRate exchangeRate = exchangeRatesFromSEKByToCurrency.get(
                settlementCurrency
              );
              if (exchangeRate == null) {
                throw new AutomationException('Cannot find exchange rate.');
              } else {
                reimbursement = reimbursement.convertTo(
                  settlementCurrency,
                  exchangeRate
                );
              }
            }

            si.setValue(reimbursement.setScale(0));
          }
        }
      }
    }

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    compensationSettlements.updateSettlementItems(
      compensationSettlementItemsBySettlementId,
      uow2
    );
    reimbursementSettlements.updateSettlementItems(
      reimbursementSettlementItemsBySettlementId,
      uow2
    );
    uow2.commitWork();

    return allSettlementsByClaimId;
  }

  @TestVisible
  private Map<Id, List<Settlement__c>> createSettlementsForClaims2(
    List<EU261ProcessingBundle> bundlesToPayOut
  ) {
    Map<Id, List<Settlement__c>> allSettlementsByClaimId = new Map<Id, List<Settlement__c>>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromEURByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromSEKByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();

    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.EUR)
    ) {
      exchangeRatesFromEURByToCurrency.put(er.toCurrency, er);
    }
    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.SEK)
    ) {
      exchangeRatesFromSEKByToCurrency.put(er.toCurrency, er);
    }

    List<LIA_Claim__c> allPayableClaimSObjects = new List<LIA_Claim__c>();
    List<LIA_Claim__c> claimsRequiringTwoSettlements = new List<LIA_Claim__c>(); // Deprecated nomenclature (kind of)
    List<LIA_Claim__c> claimsWithoutSettlements = new List<LIA_Claim__c>();

    // Sort claims into groups
    for (EU261ProcessingBundle b : bundlesToPayOut) {
      EU261Claim c = b.claim;
      if (b.decision.reimbursementAmountInSEK.amount == 0) {
        allPayableClaimSObjects.add(c.claimObj.underlyingSObject);
      } else {
        if (c.hasHighClaimedExpenses()) {
          // TODO: alter this to use the new protocol
          claimsWithoutSettlements.add(c.claimObj.underlyingSObject);
        } else {
          claimsRequiringTwoSettlements.add(c.claimObj.underlyingSObject);
        }
      }
    }

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();
    Settlements compensationSettlements = Settlements.createFromClaim(
      allPayableClaimSObjects,
      null,
      false,
      uow1
    );
    Settlements reimbursementSettlements = Settlements.createFromClaim( // TODO: We shouldn't even create these if the amounts are too high.
      claimsRequiringTwoSettlements,
      null,
      true,
      uow1
    );
    uow1.commitWork();

    Map<Id, List<SettlementItem>> compensationSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();
    Map<Id, List<SettlementItem>> reimbursementSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();

    for (EU261ProcessingBundle b : bundlesToPayOut) {
      EU261Claim c = b.claim;
      if (claimsWithoutSettlements.contains(c.claimObj.underlyingSObject)) {
        continue;
      }
      Settlement__c compensationSettlementForClaim;
      Settlement__c reimbursementSettlementForClaim;
      Boolean claimRequiresTwoSettlements = false;
      for (Settlement__c ss : compensationSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          compensationSettlementForClaim = ss;

          compensationSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          allSettlementsByClaimId.put(
            ss.Claim__c,
            new List<Settlement__c>{ ss }
          );
          break;
        }
      }
      for (Settlement__c ss : reimbursementSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          reimbursementSettlementForClaim = ss;

          reimbursementSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          claimRequiresTwoSettlements = true;

          if (allSettlementsByClaimId.get(ss.Claim__c) != null) {
            throw new AutomationException(
              'There should not be two settlements for one claim since the automation was split into compensation and expenses.'
            );
          }

          allSettlementsByClaimId.put(
            ss.Claim__c,
            new List<Settlement__c>{ ss }
          );
          break;
        }
      }

      if (
        b.decision.compensationPerCustomerInEUR != null &&
        compensationSettlementForClaim != null
      ) {
        for (
          ClaimCustomer customer : b.decision.compensationPerCustomerInEUR.keySet()
        ) {
          SettlementItem si = new SettlementItem();
          si.customerName = customer.fullName;
          si.costAccount = COMPENSATION_COST_ACCOUNT;
          si.comments = 'Automatic EU261 compensation';
          si.recordType = SettlementItem.RecordType.DefaultRecordType;
          compensationSettlementItemsBySettlementId.get(
              compensationSettlementForClaim.Id
            )
            .add(si);

          Money value = b.decision.compensationPerCustomerInEUR.get(customer);

          switch on c.claimObj.preferredCompensationMethod {
            when EBPoints {
              si.amount = value.inEuroBonusPoints();
            }
            when Voucher {
              si.setValue(
                value.multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                  .setScale(0)
              );
            }
            when else {
              // Default to monetary
              Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
                compensationSettlementForClaim.Currency__c
              );

              if (settlementCurrency != Money.CurrencyCode.EUR) {
                ExchangeRate exchangeRate = exchangeRatesFromEURByToCurrency.get(
                  settlementCurrency
                );
                if (exchangeRate == null) {
                  throw new AutomationException('Cannot find exchange rate.');
                } else {
                  value = value.convertTo(settlementCurrency, exchangeRate);
                }
              }

              si.setValue(value.setScale(0));
            }
          }
        }
      }

      Money reimbursement = b.decision.reimbursementAmountInSEK;
      if (
        reimbursement != null &&
        reimbursement.amount > 0 &&
        !c.hasHighClaimedExpenses() // TODO: replace with new protocol
      ) {
        // TODO: This needs to support creating a separate settlement in case we need to make a reimbusement
        // Cant have different methods in one settlement!
        SettlementItem si = new SettlementItem();
        si.customerName = c.claimObj.contactFullName;
        si.costAccount = REIMBURSEMENT_COST_ACCOUNT;
        si.comments = 'Automatic EU261 reimbursement';
        si.recordType = SettlementItem.RecordType.DefaultRecordType;

        reimbursementSettlementItemsBySettlementId.get(
            reimbursementSettlementForClaim.Id
          )
          .add(si);

        switch on c.claimObj.preferredReimbursementMethod {
          when EBPoints {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );
            si.amount = reimbursement.convertTo(
                Money.CurrencyCode.EUR,
                sekToEur
              )
              .inEuroBonusPoints();
          }
          when Voucher {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );

            si.setValue(
              reimbursement.convertTo(Money.CurrencyCode.EUR, sekToEur)
                .multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                .setScale(0)
            );
          }
          when else {
            // Default to monetary
            Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
              reimbursementSettlementForClaim.Currency__c
            );

            if (settlementCurrency != Money.CurrencyCode.SEK) {
              ExchangeRate exchangeRate = exchangeRatesFromSEKByToCurrency.get(
                settlementCurrency
              );
              if (exchangeRate == null) {
                throw new AutomationException('Cannot find exchange rate.');
              } else {
                reimbursement = reimbursement.convertTo(
                  settlementCurrency,
                  exchangeRate
                );
              }
            }

            si.setValue(reimbursement.setScale(0));
          }
        }
      }
    }

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    compensationSettlements.updateSettlementItems(
      compensationSettlementItemsBySettlementId,
      uow2
    );
    reimbursementSettlements.updateSettlementItems(
      reimbursementSettlementItemsBySettlementId,
      uow2
    );
    uow2.commitWork();

    return allSettlementsByClaimId;
  }

  @TestVisible
  private List<EmailMessage> createDraftApprovedEmails2(
    List<EU261ProcessingBundle> bundlesToApproval,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    List<EmailMessage> toReturn = new List<EmailMessage>();

    for (EU261ProcessingBundle b : bundlesToApproval) {
      EU261Claim cl = b.claim;
      Boolean isDelayClaim = !b.protocol.isCancellationClaim;
      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (b.protocol.compensationIsHalved) {
        if (
          b.protocol.generalMinutesLateOnArrival >=
          b.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      } else if (isDelayClaim) {
        templateName = AUTOMATION_APPROVED_DELAY_EMAIL_TEMPLATE_NAME; // TODO: fix further down
      }

      EmailMessage draftEmailForClaim = EmailMessages.createEmailMessageFromTemplate(
        templateName,
        cl.claimObj.parentCaseId
      );

      String compensationText;
      if (Test.isRunningTest()) {
        compensationText = 'placeholder';
      } else {
        compensationText = createCompesationText(
          settlementsByClaimId.get(cl.claimObj.id)
        );
      }

      draftEmailForClaim.HtmlBody = draftEmailForClaim.HtmlBody.replace(
        '|||compensationTextPlaceholder|||',
        compensationText
      );

      if (draftEmailForClaim.TextBody != null) {
        draftEmailForClaim.TextBody = draftEmailForClaim.TextBody.replace(
          '|||compensationTextPlaceholder|||',
          compensationText
        );
      }

      injectVariables2(draftEmailForClaim, b);

      Case parentCase = parentCasesById.get(cl.claimObj.parentCaseId);
      draftEmailForClaim.ToAddress = parentCase.SuppliedEmail;
      draftEmailForClaim.Subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          parentCase.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(parentCase.Id)
        }
      );

      toReturn.add(draftEmailForClaim);
    }

    return toReturn;
  }

  /**
   * Creates emails for valid claims which will go through approval process.
   *
   * These will be sent only after approvers have approved the claim, following
   * the normal claim process.
   */
  @TestVisible
  private List<EmailMessage> createDraftApprovedEmails(
    List<EU261Claim> claimsToApproval,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    List<EmailMessage> toReturn = new List<EmailMessage>();

    for (EU261Claim cl : claimsToApproval) {
      Boolean isDelayClaim = EU261Claim.DELAY_CLAIM_TYPES.contains(
        cl.claimObj.type
      );
      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (cl.protocol.compensationIsHalved) {
        if (
          cl.protocol.minutesLateOnArrival >=
          cl.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      } else if (isDelayClaim) {
        templateName = AUTOMATION_APPROVED_DELAY_EMAIL_TEMPLATE_NAME; // TODO: fix further down
      }

      EmailMessage draftEmailForClaim = EmailMessages.createEmailMessageFromTemplate(
        templateName,
        cl.claimObj.parentCaseId
      );

      String compensationText;
      if (Test.isRunningTest()) {
        compensationText = 'placeholder';
      } else {
        compensationText = createCompesationText(
          settlementsByClaimId.get(cl.claimObj.id)
        );
      }

      draftEmailForClaim.HtmlBody = draftEmailForClaim.HtmlBody.replace(
        '|||compensationTextPlaceholder|||',
        compensationText
      );

      if (draftEmailForClaim.TextBody != null) {
        draftEmailForClaim.TextBody = draftEmailForClaim.TextBody.replace(
          '|||compensationTextPlaceholder|||',
          compensationText
        );
      }

      injectVariables(draftEmailForClaim, cl);

      Case parentCase = parentCasesById.get(cl.claimObj.parentCaseId);
      draftEmailForClaim.ToAddress = parentCase.SuppliedEmail;
      draftEmailForClaim.Subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          parentCase.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(parentCase.Id)
        }
      );

      toReturn.add(draftEmailForClaim);
    }

    return toReturn;
  }

  private static void injectVariables2(
    EmailMessage email,
    EU261ProcessingBundle b
  ) {
    // Temp during refactor
    Map<String, String> placeholderToValue = b.protocol.getVariableMap();

    for (String placeholder : placeholderToValue.keySet()) {
      if (email.HtmlBody.contains(placeholder)) {
        email.HtmlBody = email.HtmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (email.TextBody != null && email.TextBody.contains(placeholder)) {
        email.TextBody = email.TextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static void injectVariables2(
    Messaging.SingleEmailMessage email,
    EU261ProcessingBundle b
  ) {
    Map<String, String> placeholderToValue = b.protocol.getVariableMap();

    String htmlBody = email.getHtmlBody();
    String plainTextBody = email.getPlainTextBody();
    for (String placeholder : placeholderToValue.keySet()) {
      if (htmlBody.contains(placeholder)) {
        htmlBody = htmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (plainTextBody != null && plainTextBody.contains(placeholder)) {
        plainTextBody = plainTextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    email.setHtmlBody(htmlBody);
    if (plainTextBody != null) {
      email.setPlainTextBody(plainTextBody);
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static void injectVariables(EmailMessage email, EU261Claim cl) {
    Map<String, String> placeholderToValue = getVariables(cl);

    for (String placeholder : placeholderToValue.keySet()) {
      if (email.HtmlBody.contains(placeholder)) {
        email.HtmlBody = email.HtmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (email.TextBody != null && email.TextBody.contains(placeholder)) {
        email.TextBody = email.TextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static void injectVariables(
    Messaging.SingleEmailMessage email,
    EU261Claim cl
  ) {
    Map<String, String> placeholderToValue = getVariables(cl);

    String htmlBody = email.getHtmlBody();
    String plainTextBody = email.getPlainTextBody();
    for (String placeholder : placeholderToValue.keySet()) {
      if (htmlBody.contains(placeholder)) {
        htmlBody = htmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (plainTextBody != null && plainTextBody.contains(placeholder)) {
        plainTextBody = plainTextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    email.setHtmlBody(htmlBody);
    if (plainTextBody != null) {
      email.setPlainTextBody(plainTextBody);
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static Map<String, String> getVariables(EU261Claim cl) {
    Flight f = cl.protocol.claimFlight;
    Boolean isDelay = EU261Claim.DELAY_CLAIM_TYPES.contains(
      cl.protocol.claimObj.type
    );
    Boolean isCancellation = EU261Claim.CANCELLATION_CLAIM_TYPES.contains(
      cl.protocol.claimObj.type
    );
    Boolean isExpenseClaim = EU261Claim.EXPENSE_CLAIM_TYPES.contains(
      cl.protocol.claimObj.type
    );

    String proactivityReasonNotWithinSASControl;

    String flightPlan = cl.protocol.getFlightPlanHistory();
    String flightDate = StringUtils.dateToReadable(
      f.scheduledDepartureTime.date()
    );
    String flightNumber = f.tedsIdentifier.substring(0, 6);
    String flightDistanceKm = String.valueOf(cl.protocol.flightDistanceInKm);
    String departureAirport = f.departureAirport;
    String departureAirportName = f.departureAirportObject.name;
    String departureCountry = f.departureAirportObject.countryName;
    String departureTime = StringUtils.dateTimeToReadable(
      f.scheduledDepartureTime
    );
    String arrivalAirport = f.arrivalAirport;
    String arrivalAirportName = f.arrivalAirportObject.name;
    String arrivalCountry = f.arrivalAirportObject.countryName;

    String minutesDelayed = String.valueOf(cl.protocol.minutesLateOnArrival);
    String minutesEarly = String.valueOf(cl.protocol.minutesEarlyOnDeparture);

    String monthLimit = '|||NONE|||';
    if (cl.protocol.initialTrip != null) {
      monthLimit = String.valueOf(cl.getClaimFilingTimeLimitInMonths());
    }

    // How the flight was cancelled, e.g. on the website
    String cancellationDate;
    String cancellationTime;
    String cancellationReason;
    String daysBetweenInformedAndDeparture;
    String timeFrame;
    String cancellationType;
    Trip.CancellationTime cancellationInfo;
    String delayExplanaiton = '';
    String rootCauseFlightNumber = '';
    String rootCauseFlightMinutesDelayed = '';
    String rootCauseFlightDepartureAirport = '';
    String rootCauseFlightArrivalAirport = '';
    String rootCauseOutsideSASControlExplanation = '';
    String rootCauseFlightDate = '';
    if (isCancellation && !isExpenseClaim) {
      cancellationDate = StringUtils.dateToReadable(
        cl.protocol.irregularity.cancellationTime.date()
      );
      cancellationTime = StringUtils.dateTimeToReadable(
        cl.protocol.irregularity.cancellationTime
      );
      cancellationReason = cl.protocol.irregularity.getExplanation();
      daysBetweenInformedAndDeparture = String.valueOf(
        cl.protocol.daysUntilFlightWhenInformedOfCancellation
      );
      timeFrame = cl.protocol.daysUntilFlightWhenInformedOfCancellation <= 7
        ? '1 hour early departure and 2 hours late arrival'
        : '2 hours early departure and 4 hours late arrival';
      cancellationType = '|||NONE|||';
      if (cl.protocol.initialTrip != null) {
        cancellationInfo = cl.protocol.initialTrip.cancellationTimeInfo;
        cancellationType = SegmentEvent.getOfficeCodeExplanation(
          cancellationInfo.officeRemoving
        );
      }
      Set<Proactivity__c> claimFlightProactivities = cl.protocol.flightIdToProactivities.get(
        cl.protocol.claimFlight.Id
      );
      if (
        claimFlightProactivities != null &&
        claimFlightProactivities.size() > 0
      ) {
        proactivityReasonNotWithinSASControl = claimFlightProactivities.iterator()
          .next()
          .Eligibility_Explanation__c;
      }
    } else if (
      isDelay &&
      cl.protocol.denialReason != EU261Protocol.DenialReason.NOTFILEDONTIME &&
      !isExpenseClaim
    ) {
      // the line below is commented to avoid the claims to be stuck because of the error "No explanation outside SAS control".
      // there should be found solution how to properly handle the error and avoid stucking claims, since when we throw an error,
      // the whole queueable with 40 records is failing, if we do not catch it.

      // at the same time, we can comment this for now, since delayExplanaiton variable is not used by the templates

      // delayExplanaiton = cl.protocol.getDelayExplanation();
      Flight causeFlight = cl.protocol.rootCause.flight;
      Set<Proactivity__c> causeProactivities;
      if (causeFlight != null) {
        rootCauseFlightNumber = causeFlight.getFlightNumber();
        rootCauseFlightMinutesDelayed = String.valueOf(
          causeFlight.arrivalDelayedMinutes
        );
        rootCauseFlightDepartureAirport = causeFlight.departureAirport;
        rootCauseFlightArrivalAirport = causeFlight.arrivalAirport;
        rootCauseOutsideSASControlExplanation = causeFlight.getOutsideSASControlExplanationDelay();
        rootCauseFlightDate = StringUtils.dateToReadable(
          causeFlight.scheduledDepartureTime.date()
        );
        causeProactivities = cl.protocol.flightIdToProactivities.get(
          causeFlight.Id
        );
      }

      flightDate = rootCauseFlightDate;
      flightNumber = rootCauseFlightNumber;
      departureAirport = rootCauseFlightDepartureAirport;
      arrivalAirport = rootCauseFlightArrivalAirport;

      if (causeProactivities != null && causeProactivities.size() > 0) {
        proactivityReasonNotWithinSASControl = causeProactivities.iterator()
          .next()
          .Eligibility_Explanation__c;
      }
    }

    String tripDestinationArrivalType = departureCountry == arrivalCountry
      ? 'domestic trip within ' + departureCountry
      : 'trip between ' + departureCountry + ' and ' + arrivalCountry; // The reservation was for a ... trip between Sweden and USA, ... domestic trip within Sweden

    // '|||delayExplanation|||' => delayExplanaiton - was removed (check the comment slightly above)

    return new Map<String, String>{
      '|||flightPlan|||' => flightPlan,
      '|||flightNumber|||' => flightNumber,
      '|||flightDistanceKm|||' => flightDistanceKm,
      '|||flightDate|||' => flightDate,
      '|||departureAirport|||' => departureAirport,
      '|||departureTime|||' => departureTime,
      '|||arrivalAirport|||' => arrivalAirport,
      '|||cancellationDate|||' => cancellationDate,
      '|||cancellationTime|||' => cancellationTime,
      '|||cancellationType|||' => cancellationType,
      '|||cancellationReason|||' => cancellationReason,
      '|||daysBetweenInformedAndDeparture|||' => daysBetweenInformedAndDeparture,
      '|||timeFrame|||' => timeFrame,
      '|||monthLimit|||' => monthLimit,
      '|||tripDestinationArrivalType|||' => tripDestinationArrivalType,
      '|||minutesDelayed|||' => minutesDelayed,
      '|||minutesEarly|||' => minutesEarly,
      '|||rootCauseFlightNumber|||' => rootCauseFlightNumber,
      '|||rootCauseFlightMinutesDelayed|||' => rootCauseFlightMinutesDelayed,
      '|||rootCauseFlightDepartureAirport|||' => rootCauseFlightDepartureAirport,
      '|||rootCauseFlightArrivalAirport|||' => rootCauseFlightArrivalAirport,
      '|||totalDelay|||' => String.valueOf(cl.protocol.totalDelay),
      '|||rootCauseOutsideSASControlExplanation|||' => rootCauseOutsideSASControlExplanation,
      '|||proactivityReasonNotWithinSASControl|||' => proactivityReasonNotWithinSASControl,
      '|||delayWithinSASControl|||' => String.valueOf(
        cl.protocol.delayWithinSASControl
      )
    };
  }

  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createRejectionEmails2(
    List<EU261ProcessingBundle> bundlesToReject
  ) {
    // Temp during refactor
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261ProcessingBundle b : bundlesToReject) {
      EU261Claim c = b.claim;
      List<EmailMessage> toReturn = new List<EmailMessage>();

      String templateName = DENIAL_REASON_TO_EMAIL_TEMPLATE_NAME.get(
        b.protocol.denialReason
      );

      if (templateName == null) {
        throw new EmailMessages.EmailTemplateNameException(
          'Denial reason does not have an email template'
        );
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        b.c.id
      );

      injectVariables2(emailToSend, b);

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      String subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          b.c.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(b.c.Id)
        }
      );
      emailToSend.setSubject(subject);

      String messageId = System.Cases.generateThreadingMessageId(b.c.Id);
      emailToSend.setReferences(messageId);

      emailsByClaimId.put(b.c.id, emailToSend);
    }

    return emailsByClaimId;
  }

  /**
   * Creates emails for rejected claims which will be closed automatically.
   */
  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createRejectionEmails(
    List<EU261Claim> claimsToReject
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToReject) {
      List<EmailMessage> toReturn = new List<EmailMessage>();

      String templateName = DENIAL_REASON_TO_EMAIL_TEMPLATE_NAME.get(
        c.protocol.denialReason
      );

      if (templateName == null) {
        throw new EmailMessages.EmailTemplateNameException(
          'Denial reason does not have an email template'
        );
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        c.claimObj.parentCaseId
      );

      injectVariables(emailToSend, c);

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      Case parentCase = parentCasesById.get(c.claimObj.parentCaseId);
      String subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          parentCase.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(parentCase.Id)
        }
      );
      emailToSend.setSubject(subject);

      String messageId = System.Cases.generateThreadingMessageId(parentCase.Id);
      emailToSend.setReferences(messageId);

      emailsByClaimId.put(c.claimObj.parentCaseId, emailToSend);
    }

    return emailsByClaimId;
  }

  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createApprovedEmails2(
    List<EU261ProcessingBundle> bundlesToSettle,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261ProcessingBundle b : bundlesToSettle) {
      EU261Claim c = b.claim;

      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (b.protocol.compensationIsHalved) {
        if (
          b.protocol.generalMinutesLateOnArrival >=
          b.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        c.claimObj.parentCaseId
      );

      String compensationText = createCompesationText(
        settlementsByClaimId.get(c.claimObj.id)
      );

      emailToSend.setHtmlBody(
        emailToSend.getHtmlBody()
          .replace('|||compensationTextPlaceholder|||', compensationText)
      );
      if (emailToSend.getPlainTextBody() != null) {
        emailToSend.setPlainTextBody(
          emailToSend.getPlainTextBody()
            .replace('|||compensationTextPlaceholder|||', compensationText)
        );
      }

      injectVariables2(emailToSend, b);

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      Case parentCase = parentCasesById.get(c.claimObj.parentCaseId);
      String subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          parentCase.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(parentCase.Id)
        }
      );
      emailToSend.setSubject(subject);

      String messageId = System.Cases.generateThreadingMessageId(parentCase.Id);
      emailToSend.setReferences(messageId);

      emailsByClaimId.put(c.claimObj.parentCaseId, emailToSend);
    }

    return emailsByClaimId;
  }

  /**
   * Creates emails for valid claims which will be approved automatically.
   */
  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createApprovedEmails(
    List<EU261Claim> claimsToSettle,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToSettle) {
      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (c.protocol.compensationIsHalved) {
        if (
          c.protocol.minutesLateOnArrival >=
          c.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        c.claimObj.parentCaseId
      );

      String compensationText = createCompesationText(
        settlementsByClaimId.get(c.claimObj.id)
      );

      emailToSend.setHtmlBody(
        emailToSend.getHtmlBody()
          .replace('|||compensationTextPlaceholder|||', compensationText)
      );
      if (emailToSend.getPlainTextBody() != null) {
        emailToSend.setPlainTextBody(
          emailToSend.getPlainTextBody()
            .replace('|||compensationTextPlaceholder|||', compensationText)
        );
      }

      injectVariables(emailToSend, c);

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      Case parentCase = parentCasesById.get(c.claimObj.parentCaseId);
      String subject = String.format(
        'Your case {0} has been processed {1}',
        new List<Object>{
          parentCase.CaseNumber,
          System.EmailMessages.getFormattedThreadingToken(parentCase.Id)
        }
      );
      emailToSend.setSubject(subject);

      String messageId = System.Cases.generateThreadingMessageId(parentCase.Id);
      emailToSend.setReferences(messageId);

      emailsByClaimId.put(c.claimObj.parentCaseId, emailToSend);
    }

    return emailsByClaimId;
  }

  /**
   * Returns the compensation text added to the email sent to the customer.
   *
   * @param settlementsByClaimId Values are lists of settlements where there should be one or two settlements.
   */
  private String createCompesationText(
    List<Settlement__c> settlementsForClaim
  ) {
    if (
      settlementsForClaim == null ||
      settlementsForClaim.isEmpty() ||
      settlementsForClaim.size() > 2
    ) {
      throw new U.InvalidArgumentException(
        'Invalid number of settlements: ' + settlementsForClaim
      );
    }

    String compensationText;

    Settlement__c compensationSettlement = settlementsForClaim[0];

    if (settlementsForClaim.size() == 1) {
      // There's only compensation
      List<Object> parameters = new List<Object>{
        getSettlementAmount(compensationSettlement),
        getSettlementCurrency(compensationSettlement)
      };
      compensationText = String.format(
        COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE,
        parameters
      );
    } else {
      // There is both compensation and reimbursement
      Settlement__c reimbursementSettlement = settlementsForClaim[1];
      List<Object> parameters = new List<Object>{
        getSettlementAmount(compensationSettlement),
        getSettlementCurrency(compensationSettlement),
        getSettlementAmount(reimbursementSettlement),
        getSettlementCurrency(reimbursementSettlement)
      };
      compensationText = String.format(
        COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE,
        parameters
      );
    }

    return compensationText;
  }

  private static String getSettlementCurrency(Settlement__c s) {
    Id euroBonusRtId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );

    if (s.RecordTypeId == euroBonusRtId) {
      return 'points';
    } else {
      return s.Currency__c;
    }
  }

  @TestVisible
  private static String getSettlementAmount(Settlement__c s) {
    Id euroBonusRtId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );

    if (s.RecordTypeId == euroBonusRtId) {
      return String.valueOf(s.EuroBonus_Points__c);
    } else {
      Decimal amount = s.Amount__c;
      return String.valueOf(amount.round(RoundingMode.FLOOR));
    }
  }

  private void checkForExistingSettlements(Set<Id> claimIds) {
    List<Settlement__c> allSettlementsForClaims = SettlementsSelector.newInstance()
      .selectByClaimId(claimIds);

    if (
      this.config.enabledSettlements &&
      allSettlementsForClaims != null &&
      allSettlementsForClaims.size() > 0
    ) {
      List<String> claimsHavingSettlements = new List<String>();
      for (Settlement__c s : allSettlementsForClaims) {
        claimsHavingSettlements.add(s.Claim__c);
      }
      throw new AutomationException(
        'Found settlements for claims: ' +
        String.join(claimsHavingSettlements, ', ')
      );
    }
  }
}
