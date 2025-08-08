/**
 * A class for evaluating claims against the EU261 regulation to determine
 * whether the claims should be compensated.
 *
 * Individuals instances of this class are individual claims from a customer.
 *
 * See EU261Service and Confluence for more details.
 */
public class EU261Claim {
  public enum SemiAutomationReason {
    RequiresPowerOfAttorney,
    HasPotentialDuplicates,
    HasHighClaimExpenses,
    InvalidSettlementDetails
  }

  public static final Set<Claim.Type> DELAY_CLAIM_TYPES = new Set<Claim.Type>{
    Claim.Type.FlightDelayCompensation,
    Claim.Type.FlightDelayExpenses
  };
  public static final Set<Claim.Type> CANCELLATION_CLAIM_TYPES = new Set<Claim.Type>{
    Claim.Type.FlightCancellationCompensation,
    Claim.Type.FlightCancellationExpenses
  };
  public static final Set<Claim.Type> MISSED_CONNECTION_CLAIM_TYPES = new Set<Claim.Type>{
    Claim.Type.MissedConnectionCompensation,
    Claim.Type.MissedConnectionExpenses
  };
  public static final Set<Claim.Type> EXPENSE_CLAIM_TYPES = new Set<Claim.Type>{
    Claim.Type.MissedConnectionExpenses,
    Claim.Type.FlightDelayExpenses,
    Claim.Type.FlightCancellationExpenses
  };
  public static final Set<Claim.Type> COMPENSATION_CLAIM_TYPES = new Set<Claim.Type>{
    Claim.Type.MissedConnectionCompensation,
    Claim.Type.FlightDelayCompensation,
    Claim.Type.FlightCancellationCompensation
  };

  public Decision evaluateProtocolWithoutErrors(EU261AgentProtocol p) {
    Decision d;
    try {
      d = evalauteProtocol(p);
    } catch (Exception e) {
      d = new EU261Claim.Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Uncaught exception: ' + e.getMessage()
      );
    }

    return d;
  }

  public static Decision evalauteProtocol(EU261AgentProtocol p) {
    if (p.tripWithRootCauseFlight != null && !p.isFiledOnTime) {
      p.denialReason = EU261Protocol.DenialReason.NOTFILEDONTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Claim was not filed on on time'
      );
    } else if (p.isCancellationClaim && p.flightCancelledWellInTime) {
      p.denialReason = EU261Protocol.DenialReason.CANCELLEDWELLINTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Flight was cancelled 14 or more days in advance'
      );
    }

    // Execute
    if (
      p.canCalculateWithLittleInformaiton && !p.cancellationIsWithinSASControl
    ) {
      if (
        p.rootCauseFlightProactivities != null &&
        p.rootCauseFlightProactivities.size() > 0
      ) {
        p.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLPROACTIVITY;
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Cancellation code not within SAS control (proactivity)'
        );
      } else {
        p.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROL;
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Cancellation code not within SAS control'
        );
      }
    }

    if (p.isCancellationClaim && p.customerCancelledTheFlight) {
      p.denialReason = EU261Protocol.DenialReason.CUSTOMERCANCELLED;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'The customer cancelled the flight'
      );
    }

    Decision d;
    if (p.isExpenseClaim) {
      d = evaluateProtocolExpense(p);
      setProtocolSemiAutomationReasonsExpense(d, p);
    } else {
      d = evaluateProtocolCompensation(p);
      setProtocolSemiAutomationReasonsCompensation(d, p);
    }
    return d;
  }

  private static void setProtocolSemiAutomationReasonsExpense(
    Decision d,
    EU261AgentProtocol p
  ) {
    if (d.verdict == Claim.EU261HandlingStatus.ReimbursementOnly) {
      d.caveats = p.caveats;
    }
  }

  private static void setProtocolSemiAutomationReasonsCompensation(
    Decision d,
    EU261AgentProtocol p
  ) {
    if (
      d.verdict == Claim.EU261HandlingStatus.EligibleForCompensation &&
      p.caveats.size() != 0
    ) {
      d.verdict = Claim.EU261HandlingStatus.PossiblyEligibleForCompensation;
      d.caveats = p.caveats;
    }
  }

  private static Decision evaluateProtocolExpense(
    EU261AgentProtocol theProtocol
  ) {
    // EXPENSE EVALUATION

    if (theProtocol.hasSubmittedClaimExpenses) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'No expenses submitted'
      );
    }

    // TODO: refactor
    Integer netDelay;
    if (theProtocol.isCancellationClaim) {
      if (theProtocol.timeDifference == null) {
        netDelay = 600; // No replacement, just consider it a 10h delay
      } else {
        netDelay = theProtocol.timeDifference.minutesLateArrival;
      }
    } else if (theProtocol.isDelayClaim) {
      netDelay = theProtocol.netDelayedMinutesDelay;
    } else {
      throw new AutomationException('Unsupported claim type');
    }

    Decision d;
    if (netDelay >= 120) {
      d = new Decision(
        Claim.EU261HandlingStatus.ReimbursementOnly,
        'Arrived 2h late or more'
      );
      d.reimbursementAmountInSEK = theProtocol.claimedReimbursementInSEK;
    } else {
      d = new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'Arrived less than 2h late'
      );
      theProtocol.denialReason = EU261Protocol.DenialReason.DELAYUNDER2HOURS;
    }

    return d;
  }

  private static Decision evaluateProtocolCompensation(
    EU261AgentProtocol theProtocol
  ) {
    // COMPENSATION EVALUATION
    if (theProtocol.isStaffBooking) {
      theProtocol.denialReason = EU261Protocol.DenialReason.STAFFBOOKING;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Staff booking'
      );
    } else if (!theProtocol.isWithinEU261Jurisdiction) {
      theProtocol.denialReason = EU261Protocol.DenialReason.NOTWITHINEU261JURISDICTON;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Not covered by EU261'
      );
    }

    if (theProtocol.isCancellationClaim) {
      return evaluateProtocolCompensationCancellation(theProtocol);
    }

    if (theProtocol.isDelayClaim) {
      return evaluateProtocolCompensationDelay(theProtocol);
    }

    throw new AutomationException('Unsupported claim type');
  }

  private static Decision evaluateProtocolCompensationCancellation(
    EU261AgentProtocol theProtocol
  ) {
    final Integer MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL = 240;
    final Integer MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE = 120;

    Boolean isEligible =
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL,
        theProtocol.minutesLateOnArrivalCancellation,
        theProtocol.daysUntilFlightWhenInformedOfCancellation
      ) ||
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE,
        theProtocol.minutesEarlyOnDeparture,
        theProtocol.daysUntilFlightWhenInformedOfCancellation
      );

    if (!isEligible) {
      theProtocol.denialReason = EU261Protocol.DenialReason.NOTOUTSIDETIMEFRAME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'The offered rebooking is not outside the timeframe allowed by EU261'
      );
    }

    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();
    Money m = performEU261CalculationCancellation(theProtocol);

    for (ClaimCustomer passenger : theProtocol.eligibleCustomers) {
      compensationByCustomer.put(passenger, m);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.SEK)
    );
  }

  private static Decision evaluateProtocolCompensationDelay(
    EU261AgentProtocol theProtocol
  ) {
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;

    if (theProtocol.delayWithinSASControl < MINIMUM_DELAY_FOR_COMPENSATION) {
      if (
        theProtocol.netDelayedMinutesDelay >= MINIMUM_DELAY_FOR_COMPENSATION
      ) {
        Decision d = new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'SAS is not responsible for 3 hours or more of the delay'
        );
        theProtocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLDELAY;

        if (
          theProtocol.rootCauseFlightProactivities != null &&
          theProtocol.rootCauseFlightProactivities.size() > 0
        ) {
          d.reasoning += ' (proactivity)'; // TODO: fix
          theProtocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLPROACTIVITY;
        }
        return d;
      } else {
        theProtocol.denialReason = EU261Protocol.DenialReason.DELAYTOOSMALL;
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Delayed less than 180 minutes'
        );
      }
    }

    Money m;
    try {
      m = performEU261CalculationDelay(theProtocol);
    } catch (AutomationException e) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        e.getMessage()
      );
    }
    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : theProtocol.eligibleCustomers) {
      compensationByCustomer.put(p, m);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.SEK)
    );
  }

  private static Money performEU261CalculationDelay(
    EU261AgentProtocol theProtocol
  ) {
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;
    final Integer MINIMUM_DELAY_FOR_INCREASED_COMPENSATION = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Money compensationAmount = new Money(0, Money.CurrencyCode.EUR);
    Boolean halveCompensation = false;
    if (theProtocol.flightDistance <= MEDIUM_DISTANCE) {
      compensationAmount = new Money(250, Money.CurrencyCode.EUR);
    } else if (
      theProtocol.flightDistance > MEDIUM_DISTANCE &&
      (theProtocol.flightDistance <= LONG_DISTANCE ||
      theProtocol.isIntraCommunity)
    ) {
      compensationAmount = new Money(400, Money.CurrencyCode.EUR);
    } else if (
      theProtocol.delayWithinSASControl <
      MINIMUM_DELAY_FOR_INCREASED_COMPENSATION
    ) {
      halveCompensation = true;
      compensationAmount = new Money(300, Money.CurrencyCode.EUR);

      // Temp until we create emails (~1/1000 edge case). TODO: write email
      throw new AutomationException(
        'Cannot handle halved delay compensation before email templates are created'
      );
    } else {
      compensationAmount = new Money(600, Money.CurrencyCode.EUR);
    }
    theProtocol.compensationIsHalved = halveCompensation;

    return compensationAmount;
  }

  private static Money performEU261CalculationCancellation(
    EU261AgentProtocol theProtocol
  ) {
    final Integer MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL = 240;
    final Integer MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE = 180;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Money compensation;
    Boolean halveCompensation;
    Boolean isShortDistance = theProtocol.flightDistance <= MEDIUM_DISTANCE;
    Boolean isMediumDistanceOrIntraCommunity =
      theProtocol.flightDistance > MEDIUM_DISTANCE &&
      (theProtocol.flightDistance <= LONG_DISTANCE ||
      theProtocol.isIntraCommunity);

    if (isShortDistance) {
      compensation = new Money(250, Money.CurrencyCode.EUR);
      halveCompensation =
        theProtocol.minutesLateOnArrivalCancellation <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
      }
    } else if (isMediumDistanceOrIntraCommunity) {
      compensation = new Money(400, Money.CurrencyCode.EUR);
      halveCompensation =
        theProtocol.minutesLateOnArrivalCancellation <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
      }
    } else {
      compensation = new Money(600, Money.CurrencyCode.EUR);
      halveCompensation =
        theProtocol.minutesLateOnArrivalCancellation <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
      }
    }

    theProtocol.compensationIsHalved = halveCompensation;

    return compensation;
  }

  public Decision fillProtocolWithoutErrors(EU261AgentProtocol p) {
    Decision d;
    try {
      d = fillProtocol(p);
    } catch (Exception e) {
      d = new EU261Claim.Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Uncaught exception: ' + e.getMessage()
      );
    }

    return d;
  }

  public Decision fillProtocol(EU261AgentProtocol p) {
    p.hasPotentiallyDuplicateClaims = this.hasPotentiallyDuplicateClaims;
    p.foundMultipleMatchingBookings = this.foundMultipleMatchingBookings;
    p.claimFlight = this.claimFlight; // Might need to be calculated

    // CAN WE EVALUATE?
    // Is correct type?
    p.regardsPersonWithReducedMobility = this.claimObj.personWithReducedMobility;
    p.regardsUnaccompaniedMinor = this.claimObj.unaccompaniedMinor;

    Decision d = isCorrectType();
    if (d != null) {
      return d;
    }

    p.isCorrectType = true;
    p.hasClaimProactivities =
      this.claimProactivities != null &&
      this.claimProactivities.size() > 0;

    // HAS VALID DATA?
    d = hasValidData();
    if (d != null) {
      return d;
    }

    p.hasValidData = true; // Debug

    // SORT AND SET ROOT CAUSE
    try {
      sortAndSetRootCause(); // TODO: This should be divided, this should also be better labled as it does not touch cancellations
    } catch (Trip.InvalidException e) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'could not sort and set root cause | ' + e.getMessage()
      );
    }
    if (this.rootCause != null) {
      p.rootCause = this.rootCause; // The issue with having these early for cancellations is that you might be able to deny without getting into detail.
      p.rootCauseFlight = this.rootCause.flight;
    } else {
      p.rootCauseFlight = this.claimFlight;
    }

    if (p.rootCauseFlight != null) {
      // Shortdelay
      p.rootCauseFlightProactivities = flightIdToProactivities.get(
        p.rootCauseFlight.id
      );
    }

    p.isCancellationClaim = CANCELLATION_CLAIM_TYPES.contains(
      this.claimObj.type
    );
    p.isDelayClaim = DELAY_CLAIM_TYPES.contains(this.claimObj.type);
    p.isExpenseClaim = EXPENSE_CLAIM_TYPES.contains(this.claimObj.type);

    if (p.isCancellationClaim && !this.hasCancellation) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is not cancelled'
      );
    } else if (p.isDelayClaim && !this.hasDelay()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'flight not cancelled and not delayed'
      );
    }

    p.caveats = this.getSemiAutomationReasons();
    p.claimedReimbursementInSEK = this.claimObj.submittedClaimExpenses.setScale(
      0
    );

    p.canCalculateWithLittleInformaiton = false;
    if (p.isCancellationClaim) {
      d = canEvaluateWithoutCalculatingTripsCancellation();
      p.flightCancelledWellInTime = flightCancelledWellInTime();
      p.timeDifference = getTimeDifferenceCancellation();
      if (d != null && d.verdict == Claim.EU261HandlingStatus.UnableToHandle) {
        return d;
      } else if (
        d != null &&
        (d.verdict == Claim.EU261HandlingStatus.IneligibleForCompensation)
      ) {
        p.canCalculateWithLittleInformaiton = true;
        p.cancellationIsWithinSASControl = this.cancellationCodeIsWithinSASControl();
        return null;
      } else if (d != null) {
        return d;
      }
      p.cancellationIsWithinSASControl = this.cancellationCodeIsWithinSASControl();
    }

    // To continue the evaluation we have to construct the trip(s)
    this.couldInitializeTrips = false;
    Exception tripCalculationError;
    try {
      this.calculateAndSetTrips(); // This should be removed (integrate better with root cause)
      this.couldInitializeTrips = true;
    } catch (Exception e) {
      Type error = Type.forName(e.getTypeName());
      if (tripSetExceptions.contains(error)) {
        tripCalculationError = e;
      } else {
        throw e;
      }
    }

    d = isTooComplex(tripCalculationError);
    if (d != null) {
      p.isTooComplex = true; // Debug
      return d;
    }

    // TODO: Remove this logic in favour of root cause ananlysis (NOTE: dependent on handling cancellations in root cause analysis better)
    if (this.rootCause != null && this.rootCause.originalTrip != null) {
      p.tripWithRootCauseFlight = this.rootCause.originalTrip;
      p.tripAfterEffectOfRootCause = this.rootCause.resultingTrip;
    } else {
      p.tripWithRootCauseFlight = this.tripWithClaimFlight;
      p.tripAfterEffectOfRootCause = this.tripWithClaimFlightReplacement;
    }

    // FILL OTHER DATA:
    p.claimFilingTimeLimitInMonths = getClaimFilingTimeLimitInMonths();
    p.isFiledOnTime = isFiledOnTime();
    if (!p.isFiledOnTime) {
      return null;
    }
    p.hasSubmittedClaimExpenses =
      this.claimObj.submittedClaimExpenses.amount == 0;
    Decimal flightDistanceInM = Airport.distanceBetweenAirportsInMeters(
      p.tripWithRootCauseFlight.originAirport,
      p.tripWithRootCauseFlight.destinationAirport
    );
    Integer flightDistanceInKm = (flightDistanceInM / 1000).intValue();
    p.flightDistance = flightDistanceInKm;
    p.isIntraCommunity = p.tripWithRootCauseFlight.isIntraCommunity();
    p.isStaffBooking = isStaffBooking();
    p.isWithinEU261Jurisdiction = this.isWithinEU261Jurisdiction();
    p.eligibleCustomers = getPassengersEligibleForCompensation();

    if (p.isCancellationClaim) {
      p.daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture(); // Todo: refactor
      p.cancellationWasWithinSASControl = this.cancellationCodeIsWithinSASControl(); //  Code, proactivity and description,
      p.flightCancelledWellInTime = flightCancelledWellInTime(); // Needs to be filled twich in cases where delays have been resorted
      p.customerCancelledTheFlight = p.tripWithRootCauseFlight.customerCancelled();
    } else {
      p.delayWithinSASControl = getProtocolDelayWithinSASControl(); // Complex
    }

    p.originalDeparture = p.tripWithRootCauseFlight.getScheduledDeparture();
    p.originalArrival = p.tripWithRootCauseFlight.getScheduledArrival();
    Integer minutesLateOnArrival = 0;
    Integer minutesEarlyOnDeparture = 0;
    if (p.isCancellationClaim) {
      if (p.tripAfterEffectOfRootCause != null) {
        p.newArrival = p.tripAfterEffectOfRootCause.getFinalDestinationArrivalTime();
        p.newDeparture = p.tripAfterEffectOfRootCause.getScheduledDeparture(); // TODO: check this

        Integer departureDifference =
          DateUtils.getMinutesBetween(p.newDeparture, p.originalDeparture) + 1; // Add 1 minute to make sure we don't round down
        Integer arrivalDifference =
          DateUtils.getMinutesBetween(p.newArrival, p.originalArrival) + 1;

        if (p.newArrival > p.originalArrival) {
          minutesLateOnArrival = arrivalDifference;
        } else {
          minutesLateOnArrival = 0;
        }
        if (p.newDeparture < p.originalDeparture) {
          minutesEarlyOnDeparture = departureDifference;
        } else {
          minutesEarlyOnDeparture = 0;
        }
        p.minutesLateOnArrivalCancellation = minutesLateOnArrival;
        p.minutesEarlyOnDeparture = minutesEarlyOnDeparture;
      } else {
        p.minutesLateOnArrivalCancellation = 600; // See as 10h late
      }
    } else {
      p.netDelayedMinutesDelay = getNetDelayedMinutesDelay();
    }

    return null;
  }

  public Decision newEvaluate() {
    Decision d;
    try {
      EU261AgentProtocol p = new EU261AgentProtocol();
      d = fillProtocol(p);
      if (d == null) {
        d = evalauteProtocol(p);
      }
    } catch (Exception e) {
      d = new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Uncaught exception: ' + e.getMessage()
      );
      throw e;
    }

    return d;
  }

  /**
   * Evaluates the claim according to the EU261 rules and returns the decision
   * made on whether the claim should be paid out.
   *
   * The result is also stored in this.decision.
   */
  public Decision evaluate() {
    Decision d;
    try {
      d = this.canWeEvaluate();

      if (d != null) {
        this.decision = d;
        return d; // Unable to handle
      }

      if (EXPENSE_CLAIM_TYPES.contains(this.claimObj.type)) {
        d = doEvaluationExpense();
      } else if (COMPENSATION_CLAIM_TYPES.contains(this.claimObj.type)) {
        d = doEvaluationCompensation();
      } else {
        throw new AutomationException(
          'Claim type not supported: ' + this.claimObj.type
        );
      }
    } catch (Exception e) {
      d = new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Uncaught exception: ' + e.getMessage()
      );
    }

    this.decision = d;
    writeProtocol();
    return d;
  }

  private Decision doEvaluationExpense() {
    Decision d = determineEligibilityAndCalculateReimbursement();

    if (d.verdict == Claim.EU261HandlingStatus.ReimbursementOnly) {
      d.caveats = this.getSemiAutomationReasons();
    }

    return d;
  }

  private Decision doEvaluationCompensation() {
    Decision d = this.determineEligibilityAndCalculateCompensation();

    if (
      d.verdict == Claim.EU261HandlingStatus.EligibleForCompensation &&
      this.getSemiAutomationReasons().size() != 0
    ) {
      d.verdict = Claim.EU261HandlingStatus.PossiblyEligibleForCompensation;
      d.caveats = this.getSemiAutomationReasons();
    }

    return d;
  }

  private void writeProtocol() {
    this.protocol.decision = this.decision;
    this.protocol.claimFlight = this.claimFlight;
    this.protocol.initialTrip = this.tripWithClaimFlight;
    this.protocol.replacementTrip = this.tripWithClaimFlightReplacement;
    this.protocol.claimObj = this.claimObj;
    this.protocol.claimProactivities = this.claimProactivities;
    this.protocol.flightIdToProactivities = this.flightIdToProactivities;
    if (
      this.claimFlight != null &&
      this.claimFlight.irregularities.size() == 1
    ) {
      this.protocol.irregularity = claimFlight.irregularities[0];
    }
  }

  private static Set<String> invalidFareBases = new Set<String>{};

  public class CreateException extends Exception {
  }

  /**
   * Represents the outcome of evaluating a customer claim according to EU261
   * rules.
   *
   * Consists of the overall verdict of whether the customer is eligible for
   * compensation or not, or that we can't handle the claim.
   *
   * When the claim should be paid out, the decision also contains information
   * about the amounts of compensation and reimbursement that should be paid
   * out.
   */
  public class Decision {
    /**
     * The total reimbursement that can be paid out based on this decision in
     * SEK.
     *
     * There's only one total for reimbursement because the costs are not tied
     * to a specific customer like they are with compensation.
     */
    public Money reimbursementAmountInSEK { get; private set; }

    /**
     * The compensation which should be paid out based on this decision.
     * Keys are the claimed customers and values the amount to be paid out to
     * that customer in euros.
     */
    public Map<ClaimCustomer, Money> compensationPerCustomerInEUR {
      get;
      private set;
    }

    /**
     * The overall verdict of whether a customer is eligible for compensation.
     */
    public Claim.EU261HandlingStatus verdict { get; private set; }

    /**
     * Clarifications on how the decision was reached, if available.
     */
    public String reasoning { get; private set; }

    /**
     * Any caveats to the decision. Must be populated if verdict is PossiblyEligibleForCompensation.
     * Otherwise empty.
     */
    public List<SemiAutomationReason> caveats = new List<SemiAutomationReason>();

    Decision(Claim.EU261HandlingStatus verdict, String reasoning) {
      if (verdict == Claim.EU261HandlingStatus.EligibleForCompensation) {
        throw new CreateException(
          'Cannot create an eligible decision without compensation or reimbursement amount.'
        );
      }
      this.verdict = verdict;
      this.reasoning = reasoning;
      this.reimbursementAmountInSEK = new Money(0, Money.CurrencyCode.SEK);
      this.compensationPerCustomerInEUR = null;
    }

    Decision(
      String reasoning,
      Map<ClaimCustomer, Money> compensationByCustomer,
      Money reimbursementAmountInSEK
    ) {
      if (
        reimbursementAmountInSEK.amount == 0 &&
        (compensationByCustomer == null || compensationByCustomer.isEmpty())
      ) {
        throw new CreateException(
          'Cannot create an eligible decision with compensation and reimbursement amount both set to 0.'
        );
      }
      this.verdict = Claim.EU261HandlingStatus.EligibleForCompensation;
      this.reasoning = reasoning;
      this.compensationPerCustomerInEUR = compensationByCustomer;
      this.reimbursementAmountInSEK = reimbursementAmountInSEK;
    }
  }

  public Claim claimObj { public get; private set; }
  @TestVisible
  private Booking claimedBooking;
  private Trip tripWithClaimFlight;
  private Trip tripWithClaimFlightReplacement;
  private Boolean hasPotentiallyDuplicateClaims = false;
  private Boolean foundMultipleMatchingBookings = false;
  private Boolean hasCancellation;
  private Boolean hasInvalidIrregularity;
  private Boolean couldInitializeTrips;
  private Flight claimFlight;
  private Trip.RootCause rootCause;
  public EU261Protocol protocol = new EU261Protocol();
  public Boolean hasSegmentWithoutFlight = false;
  public Set<Proactivity__c> claimProactivities;
  public Map<Id, Set<Proactivity__c>> flightIdToProactivities = new Map<Id, Set<Proactivity__c>>{};

  private EU261Service.Config config;

  /**
   * The decision made on this claim. Populated by this.evaluate().
   */
  public Decision decision { public get; private set; }

  public EU261Claim(
    Claim c,
    List<Booking> b,
    Boolean hasPotentiallyDuplicateClaims,
    EU261Service.Config config
  ) {
    this.claimObj = c;
    this.config = config;

    this.hasPotentiallyDuplicateClaims = hasPotentiallyDuplicateClaims; // TODO: This should be moved out of here. Decision should be based only on this single claim, comparison to others can be done elsewhere.

    if (b != null && b.size() != 0) {
      this.claimedBooking = b[0];
      this.foundMultipleMatchingBookings = b.size() > 1;

      String flightNumberDate = Flight.constructTEDSFlightNumberDate(
        c.flightNumber,
        c.departureDate
      );

      for (Flight f : this.claimedBooking.flights) {
        String flightId = Flight.TEDSIdToSimpleFlightIds(f.tedsIdentifier)[0];
        if (flightId == flightNumberDate) {
          setClaimFlight(f);
          break;
        }
      }
    }
  }

  public static List<LIA_Claim__c> getClaimSObjectsFor(
    Set<EU261Claim> eu261Claims
  ) {
    return getClaimSObjectsFor(new List<EU261Claim>(eu261Claims));
  }

  public static List<LIA_Claim__c> getClaimSObjectsFor(
    List<EU261Claim> eu261Claims
  ) {
    List<LIA_Claim__c> toReturn = new List<LIA_Claim__c>();

    for (EU261Claim cl : eu261Claims) {
      toReturn.add(cl.claimObj.underlyingSObject);
    }

    return toReturn;
  }

  private Boolean hasTripWithClaimFlight() {
    if (tripWithClaimFlight != null) {
      return true;
    }
    return false;
  }

  private Boolean hasDelay() {
    if (claimFlight == null) {
      throw new AutomationException('tripWithClaimFlight not set');
    } else if (
      rootCause == null ||
      rootCause.originalTrip == null ||
      rootCause.resultingTrip == null
    ) {
      throw new AutomationException(
        'Root cause and/or original and resulting trip not set'
      );
    }

    Datetime originalArrival = rootCause.originalTrip.getScheduledArrival();
    Datetime resultingArrival = rootCause.resultingTrip.getFinalDestinationArrivalTime();

    return originalArrival < resultingArrival;
  }

  private Boolean claimFlightHasMoreThanOneCancellation() {
    Integer count = 0;
    for (FlightIrregularity fi : claimFlight.irregularities) {
      if (fi.isCancellation()) {
        // We can ignore arrival cancellation in here because there's always
        // one if the departure is cancelled.
        count += 1;
      }
    }
    return count > 1;
  }

  private Boolean hasOnlyOneFlightRoute() {
    String firstFlightRoute =
      this.claimedBooking.segments[0].flight.departureAirport +
      this.claimedBooking.segments[0].flight.arrivalAirport;
    for (Segment s : this.claimedBooking.segments) {
      String segmentFlightRoute =
        s.flight.departureAirport + s.flight.arrivalAirport;
      if (segmentFlightRoute != firstFlightRoute) {
        return false;
      }
    }
    return true;
  }

  private void setClaimFlight(Flight f) {
    this.claimFlight = f;
    try {
      this.hasCancellation = f.getCancellations().size() > 0;
      this.hasInvalidIrregularity = false;
    } catch (FlightIrregularity.UnknownIrregularityException e) {
      this.hasInvalidIrregularity = true;
    }
  }

  private static Set<Type> tripSetExceptions = new Set<Type>{
    Trip.BookingTypeNotSupportedException.class,
    Segment.UnsupportedException.class,
    Trip.RouteException.class,
    Trip.InvalidException.class,
    AbstractSObjectWrapper.MissingDataException.class,
    Booking.UnsupportedException.class
  };

  /**
   * Calculates and sets the trip objects tripWithClaimFlight and tripWithClaimFlightReplacement
   *
   * TODO: This needs to play better with the root cause analysis. Now there are two very similar
   * checks. The only difference being cancellation claims which have not been sorted which are
   * currently handled a bit different.
   *
   * @throws Trip.InvalidException if the trips calculated are invalid.
   * @throws Trip.BookingTypeNotSupportedException if the booking type is not yet supported.
   * @throws Segment.UnsupportedException if there are unsupported segment event statuses
   * @throws Trip.RouteException if there is an error when checking the trip validity (infinite loop)
   * @throws AbstractSObjectWrapper.MissingDataException if there is no cancellation time
   * @throws Booking.UnsupportedException if there is more than one cancellation
   */
  private void calculateAndSetTrips() {
    if (this.hasCancellation) {
      List<Trip> beforeAndAfterCancellation = claimedBooking.getTripsBeforeAndAfterCancellation(
        claimFlight
      );

      this.tripWithClaimFlight = beforeAndAfterCancellation[0];
      this.tripWithClaimFlightReplacement = beforeAndAfterCancellation[1];
    } else {
      if (rootCause.originalTrip != null) {
        this.tripWithClaimFlight = rootCause.originalTrip;
      } else {
        this.tripWithClaimFlight = claimedBooking.getTripWithFlight(
          claimFlight
        );
      }
    }
  }

  private Boolean canGetSegmentStatuses() {
    for (Segment s : this.claimedBooking.segments) {
      try {
        s.getStatus(Datetime.now());
      } catch (Segment.UnsupportedException e) {
        continue;
      } catch (U.InvalidArgumentException e) {
        return false;
      }
    }
    return true;
  }

  private Boolean bookingHasUnsupportedEvents() {
    for (Segment s : this.claimedBooking.segments) {
      try {
        s.getStatus(Datetime.now());
      } catch (Segment.UnsupportedException e) {
        return true;
      } catch (U.InvalidArgumentException e) {
        continue;
      }
    }
    return false;
  }

  private Decision isCorrectType() {
    Claim c = this.claimObj;

    if (c.category != Claim.Category.FlightDisruptions) {
      return new Decision(
        Claim.EU261HandlingStatus.WillNotHandle,
        'can handle only claims in category "Flight disruptions"'
      );
    } else if (
      !(CANCELLATION_CLAIM_TYPES.contains(c.type) ||
      DELAY_CLAIM_TYPES.contains(c.type) ||
      MISSED_CONNECTION_CLAIM_TYPES.contains(c.type))
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.WillNotHandle,
        'can handle only claims in type "Flight cancellation", "Flight delay" or "Missed Connection"'
      );
    } else if (c.recordType != Claim.RecordType.CustomerClaim) {
      return new Decision(
        Claim.EU261HandlingStatus.WillNotHandle,
        'can handle only claims with record type CustomerClaim'
      );
    } else if (
      this.claimProactivities != null &&
      this.claimProactivities.size() > 0
    ) {
      if (this.claimProactivities.size() > 1) {
        return new Decision(
          Claim.EU261HandlingStatus.WillNotHandle,
          'can handle only claims with one proactivity'
        );
      }
      Proactivity__c p = this.claimProactivities.iterator().next();
      if (p.EU261_Eligibility__c == 'Tentative') {
        return new Decision(
          Claim.EU261HandlingStatus.WillNotHandle,
          'claim has a "Tentative" proactivity'
        );
      } else {
        throw new AutomationException(
          'Invalid proactivity eligibility: ' + p.EU261_Eligibility__c
        );
      }
    }
    return null;
  }

  private Decision hasValidData() {
    Claim c = this.claimObj;

    if (this.claimedBooking == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim is not associated with a booking'
      );
    } else if (this.hasSegmentWithoutFlight) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the booking has a segment without a flight'
      );
    } else if (this.foundMultipleMatchingBookings) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only one booking per claim'
      );
    } else if (this.claimedBooking.flights.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'no flight associated with the claim'
      );
    } else if (c.customers == null || c.customers.isEmpty()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims without any travellers'
      );
    } else if (this.claimFlight == null) {
      /**
       * The issue here is a lot due to the wrong date being selected.
       * We could maybe try to match and adjust the date. However, we
       * need to be careful not to select another part of the trip. ~53%
       *
       * It is also quite common that a single number or letter of the
       * flight number is off. (maybe ~35%, uncertain)
       *
       * Then there are those who are just plain wrong. (maybe ~10%, uncertain)
       *
       * There are also rare cases where there are two bookings for
       * one PNR (e.g. MQGO98).
       */
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot find claimed flight from booking'
      );
    } else if (hasInvalidIrregularity) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight has an invalid irregularity'
      );
    } else if (!canGetSegmentStatuses()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot get segment statuses'
      );
    } else if (bookingHasUnsupportedEvents()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'booking has unsupported event(s)'
      );
    } else if (this.claimedBooking.hasHiddenCancellation()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'this claim likely has a hidden cancellation'
      ); // TODO: This should be looked into, check is too broad currently
    } else if (this.claimedBooking.hasFlightWithoutTimes()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the booking has a flight without scheduled departure or arrival time(s)'
      ); // This could be moved further down, this way more cases than necessary will get stuck because of flights which are inactive
    }

    return null;
  }

  private Decision canEvaluateWithoutCalculatingTripsCancellation() {
    // Ineligible decisions should not be returned directly
    if (claimFlightHasMoreThanOneCancellation()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'there are more than one cancellation connected to the claim flight'
      );
    } else if (flightCancelledWellInTime()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'flight was cancelled well in time (eval)'
      ); // If flight was cancelled 14 days, or more, in advance the customer is not eligible
    }

    if (EXPENSE_CLAIM_TYPES.contains(this.claimObj.type)) {
      return null; // The other checks are not important for expense claims
    }

    if (!this.canDetermineIfSASIsResponsibleForCancellation()) {
      try {
        this.cancellationCodeIsWithinSASControl();
      } catch (Exception e) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'cannot determine wether SAS is responsible or not for the cancellation | ' +
          e.getMessage()
        );
      }
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot determine wether SAS is responsible or not for the cancellation'
      );
    } else if (
      !this.cancellationCodeIsWithinSASControl() &&
      this.claimObj.submittedClaimExpenses.amount == 0
    ) {
      // This probably works, maybe tell customer that this was automated (a lot of process issues)
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'cancellation code is not within SAS control (eval)'
      ); // If we are not responsible, and if the customer did not submit expenses, we don't need any more checks
    }

    return null;
  }

  private Decision isTooComplex(Exception tripCalculationError) {
    Boolean isCancellationClaim = CANCELLATION_CLAIM_TYPES.contains(
      this.claimObj.type
    );
    Boolean isDelayClaim = DELAY_CLAIM_TYPES.contains(this.claimObj.type);

    if (!this.couldInitializeTrips) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'was not able to divide the booking into trips (' +
          tripCalculationError.getMessage() +
          ')'
      );
    } else if (this.tripWithClaimFlight == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'could not set trip with claim flight'
      );
    } else if (this.claimFlight.getOperator() == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot parse claim flight operator'
      );
    } else if (!this.claimFlight.isOperatedByStarAlliance()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight is not operated by Star Alliance'
      );
    } else if (!this.claimFlight.isOperatedBySAS()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight is not operated by SAS'
      );
    }

    if (isCancellationClaim) {
      if (this.tripWithClaimFlight == this.tripWithClaimFlightReplacement) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'the trip did not change before and after the cancellation (likely "cancellation <-> event" time mismatch)'
        );
      } else if (this.tripWithClaimFlight.isUncertainWhoCancelled()) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'it is uncertain if SAS or the customer cancelled the flight'
        );
      } else if (this.tripWithClaimFlight.customerCancelled()) {
        return null; // Deny, customer cancelled the flight
      } else if (this.claimedBooking.hasReinstated(this.claimFlight)) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'claim flight was reinstated'
        );
      }
    } else if (isDelayClaim) {
      if (!this.canCalculateDelay()) {
        String errorMessage = '';
        try {
          this.rootCause.flight.getDelayedMinutesWithinOperatorsControl(
            flightIdToProactivities.get(rootCause.flight.id)
          );
        } catch (Exception e) {
          errorMessage = e.getMessage();
        }
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          errorMessage
        );
      } else if (!this.isSimpleDelay()) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'the delay is too complicated'
        );
      }
    }

    return null;
  }

  private void sortAndSetRootCause() {
    // Currently we only sort the delay and missed connection claims
    // TODO: this should be divided into several steps
    Claim c = this.claimObj;

    List<Trip.RootCauseType> delayRootCauseTypes = new List<Trip.RootCauseType>{
      Trip.RootCauseType.DELAYMISSEDCONNECTION,
      Trip.RootCauseType.DELAYPLACEDONOTHERFLIGHT,
      Trip.RootCauseType.SHORTDELAY,
      Trip.RootCauseType.SIMPLEDELAY
    };

    // TODO: This should be done for all claims, not just delays and missed connections
    if (
      DELAY_CLAIM_TYPES.contains(c.type) ||
      MISSED_CONNECTION_CLAIM_TYPES.contains(c.type)
    ) {
      this.rootCause = this.claimedBooking.getRootCauseAndEffect(
        this.claimFlight
      );
      if (this.rootCause.type == Trip.RootCauseType.CANCELLATION) {
        switch on c.type {
          when FlightDelayCompensation, MissedConnectionCompensation {
            c.type = Claim.Type.FlightCancellationCompensation;
          }
          when FlightDelayExpenses, MissedConnectionExpenses {
            c.type = Claim.Type.FlightCancellationExpenses;
          }
        }
      } else if (delayRootCauseTypes.contains(this.rootCause.type)) {
        switch on c.type {
          when FlightCancellationCompensation, MissedConnectionCompensation {
            c.type = Claim.Type.FlightDelayCompensation;
          }
          when FlightCancellationExpenses, MissedConnectionExpenses {
            c.type = Claim.Type.FlightDelayExpenses;
          }
        }
      }

      if (this.rootCause.flight != null) {
        setClaimFlight(this.rootCause.flight);
      }
    }
  }

  /**
   * Checks whether we're able to evaluate this claim with the data we have on
   * it. Returns a decision with verdict of UnableToHandle if we cannot handle
   * this claim. Returns null if we _can_ evaluate it.
   */
  private Decision canWeEvaluate() {
    Decision d;

    d = isCorrectType(); // This should be in SF
    if (d != null) {
      return d;
    }

    d = hasValidData(); // This should partly be in SF
    if (d != null) {
      return d;
    }

    try {
      sortAndSetRootCause(); // TODO: This should be divided
    } catch (Trip.InvalidException e) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'could not sort and set root cause | ' + e.getMessage()
      );
    }

    Boolean isCancellationClaim = CANCELLATION_CLAIM_TYPES.contains(
      this.claimObj.type
    );
    Boolean isDelayClaim = DELAY_CLAIM_TYPES.contains(this.claimObj.type);

    if (isCancellationClaim && !this.hasCancellation) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is not cancelled'
      );
    } else if (isDelayClaim && this.hasCancellation) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the flight is cancelled but the customer has claimed for a delay'
      );
    } else if (!isDelayClaim && !isCancellationClaim) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'did not manage to sort the claim properly'
      );
    }

    if (isCancellationClaim) {
      d = canEvaluateWithoutCalculatingTripsCancellation();
      if (d != null) {
        if (d.verdict == Claim.EU261HandlingStatus.IneligibleForCompensation) {
          return null; // We should not evaluate here, let the rest of the automated process handle it
        }
        return d;
      }
    }

    // To continue the evaluation we have to construct the trip(s)
    this.couldInitializeTrips = false;
    Exception tripCalculationError;
    try {
      this.calculateAndSetTrips();
      this.couldInitializeTrips = true;
    } catch (Exception e) {
      Type error = Type.forName(e.getTypeName());
      if (tripSetExceptions.contains(error)) {
        tripCalculationError = e;
      } else {
        throw e;
      }
    }

    return isTooComplex(tripCalculationError);
  }

  private Boolean contactIsATraveler() {
    Claim c = this.claimObj;

    Boolean contactFoundInBooking = false;
    for (ClaimCustomer cust : c.customers) {
      if (cust.normalizedFullName == c.normalizedContactFullName) {
        contactFoundInBooking = true;
      }
    }

    return contactFoundInBooking;
  }

  /**
   * Asserts that all claimed travelers can be found from the booking's passengers
   */
  private Boolean allClaimedTravelersAreInBooking() {
    Claim c = this.claimObj;

    for (ClaimCustomer cust : c.customers) {
      Boolean claimedCustomerFoundInBooking = false;
      for (Passenger p : this.claimedBooking.passengers) {
        if (p.normalizedFullName == cust.normalizedFullName) {
          claimedCustomerFoundInBooking = true;
        }
      }

      if (!claimedCustomerFoundInBooking) {
        return false;
      }
    }

    return true;
  }

  /**
   * Returns false if the contact person is allowed to make the claim for all
   * customers claimed in the claim without a power of attorney.
   *
   * They are allowed to do this only if all of the following are true:
   * 1. Claimant is a private customer
   * 2. All claimed passengers have the same last name as the contact person
   * 3. There are five or fewer people overall in the claim
   */
  private Boolean requiresPowerOfAttorney() {
    Claim c = this.claimObj;
    if (
      c.contactType != Claim.ContactType.PrivateCustomer ||
      (c.customers.size() > 5)
    ) {
      // The larger than 5 customer is an arbitrary number to ensure that large
      // groups are always vetted by an agent for safety.
      return true;
    }

    if (!contactIsATraveler()) {
      return true;
    }

    if (!allClaimedTravelersAreInBooking()) {
      return true;
    }

    for (ClaimCustomer cust : c.customers) {
      if (cust.normalizedLastName != c.normalizedContactLastName) {
        return true;
      }
    }

    return false;
  }

  private Boolean canCalculateDelay() {
    Flight causeOfDelay = this.rootCause.flight;
    if (this.rootCause.type == Trip.RootCauseType.SHORTDELAY) {
      return true;
    }

    try {
      causeOfDelay.getDelayedMinutesWithinOperatorsControl(
        flightIdToProactivities.get(causeOfDelay.id)
      );
    } catch (Flight.FlightException e) {
      return false;
    } catch (FlightIrregularity.IrregularityException e) {
      // Tentative delay
      // Check if the delay is less than 3 hours or if it is an expense claim
      // -> If yes we don't need to know the details
      if (
        getNetDelayedMinutesDelay() >= 180 &&
        !EXPENSE_CLAIM_TYPES.contains(this.claimObj.type)
      ) {
        return false;
      }
    }
    return true;
  }

  private Integer getNetDelayedMinutesDelay() {
    Integer netDelayedMinutes;

    switch on this.rootCause.type {
      when SIMPLEDELAY {
        netDelayedMinutes = Integer.valueOf(
          this.rootCause.flight.arrivalDelayedMinutes
        );
      }
      when DELAYPLACEDONOTHERFLIGHT {
        throw new AutomationException(
          'Delay handling for when the customer was placed on another flight are not implemented yet'
        );
      }
      when DELAYMISSEDCONNECTION, SHORTDELAY {
        Datetime originalTripLastArrival = this.rootCause.originalTrip.getScheduledArrival();
        Datetime finalTripLastArrival = this.rootCause.resultingTrip.getFinalDestinationArrivalTime();

        Integer arrivalDifferenceMinutes = DateUtils.getMinutesBetween(
          originalTripLastArrival,
          finalTripLastArrival
        );

        if (originalTripLastArrival > finalTripLastArrival) {
          netDelayedMinutes = 0;
        } else {
          netDelayedMinutes = arrivalDifferenceMinutes;
        }
      }
      when else {
        throw new AutomationException(
          'Unknown root cause type: ' + this.rootCause.type
        );
      }
    }

    this.protocol.totalDelay = netDelayedMinutes;

    return netDelayedMinutes;
  }

  private Boolean flightCancelledWellInTime() {
    try {
      Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();
      return daysUntilFlightWhenInformedOfCancellation >= 14;
    } catch (AutomationException e) {
      return false; // Not perfect, wanted to avoid another canDetermineIfSASIsResponsibleForCancellation
    }
  }

  private Boolean isStaffBooking() {
    if (this.claimedBooking.isStaffBooking == null) {
      return false;
    } else {
      return this.claimedBooking.isStaffBooking;
    }
  }

  /**
   * Returns true if the claim was filed on time and the customer is entitled
   * to compensation based on that.
   *
   * The time limit for filing a claim is different in different jurisdictions.
   * We pick the longest of arrival and departure countries' filing limit, so
   * to the benefit of the customer.
   */
  private Boolean isFiledOnTime() {
    Date claimCreationDate = this.claimObj.createdDate.date();
    Date tripDate = this.claimFlight.scheduledArrivalTime.date();

    Integer timelimit = getClaimFilingTimeLimitInMonths();
    this.protocol.claimFilingTimeLimit = timeLimit;

    Boolean filedWithinTimelimit =
      Math.abs(claimCreationDate.monthsBetween(tripDate)) <= timeLimit;

    return filedWithinTimelimit;
  }

  public Integer getClaimFilingTimeLimitInMonths() {
    Integer limitInDepartureCountry = DateUtils.getClaimTimeLimitInMonths(
      this.tripWithClaimFlight.originAirport.countryCode
    );
    Integer limitInArrivalCountry = DateUtils.getClaimTimeLimitInMonths(
      this.tripWithClaimFlight.destinationAirport.countryCode
    );

    if (limitInDepartureCountry == null || limitInArrivalCountry == null) {
      throw new AutomationException(
        'Claim filing time limit not defined for either departure or arrival country'
      );
    }

    Integer timeLimit = Math.max(
      limitInDepartureCountry,
      limitInArrivalCountry
    );

    if (timeLimit < 2) {
      throw new AutomationException(
        'Claim filing time limit is less than 2 months, which should not be possible (Swedish time limit)'
      );
    }

    return timeLimit;
  }

  private Decision determineEligibilityAndCalculateCompensationCancellation() {
    if (flightCancelledWellInTime()) {
      this.protocol.denialReason = EU261Protocol.DenialReason.CANCELLEDWELLINTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Flight was cancelled 14 or more days in advance'
      );
    } else if (!this.cancellationCodeIsWithinSASControl()) {
      if (
        flightIdToProactivities.get(claimFlight.id) != null &&
        flightIdToProactivities.get(claimFlight.id).size() > 0
      ) {
        this.protocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLPROACTIVITY;
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Cancellation code not within SAS control (proactivity)'
        );
      } else {
        this.protocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROL;
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Cancellation code not within SAS control'
        );
      }
    } else if (!this.isFiledOnTime()) {
      this.protocol.denialReason = EU261Protocol.DenialReason.NOTFILEDONTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Claim was not filed on on time'
      );
    } else if (this.tripWithClaimFlight.customerCancelled()) {
      this.protocol.denialReason = EU261Protocol.DenialReason.CUSTOMERCANCELLED;
      this.calculateCompensationForCancellation(); // For protocol reasons
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'The customer cancelled the flight'
      );
    } else {
      // If the claim flight was cancelled the customer should receive compensation according to the cancellation logic
      Decision compensationDecision = this.calculateCompensationForCancellation();
      if (
        compensationDecision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation
      ) {
        this.protocol.denialReason = EU261Protocol.DenialReason.NOTOUTSIDETIMEFRAME;
      }
      return compensationDecision;
    }
  }

  private Decision determineEligibilityAndCalculateCompensationDelay() {
    Decision compensationDecision = this.calculateCompensationForDelay();
    if (!this.isFiledOnTime()) {
      this.protocol.denialReason = EU261Protocol.DenialReason.NOTFILEDONTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Claim was not filed on on time'
      );
    } else if (
      compensationDecision.verdict ==
      Claim.EU261HandlingStatus.IneligibleForCompensation
    ) {
      // Check reason:
      if (compensationDecision.reasoning == 'Delayed less than 180 minutes') {
        this.protocol.denialReason = EU261Protocol.DenialReason.DELAYTOOSMALL;
      } else if (
        compensationDecision.reasoning ==
        'SAS is not responsible for 3 hours or more of the delay'
      ) {
        if (
          flightIdToProactivities.get(rootCause.flight.id) != null &&
          flightIdToProactivities.get(rootCause.flight.id).size() > 0
        ) {
          this.protocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLPROACTIVITY;
          compensationDecision.reasoning += ' (proactivity)';
        } else {
          this.protocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROLDELAY;
        }
      } else {
        throw new AutomationException(
          'Unknown reason for ineligibility for compensation'
        );
      }
    }
    return compensationDecision;
  }

  private Decision determineEligibilityAndCalculateCompensation() {
    if (this.isStaffBooking()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Id and staff tickets are not eligible'
      );
    } else if (!this.isWithinEU261Jurisdiction()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'Not covered by EU261'
      );
    }

    if (this.hasCancellation) {
      return determineEligibilityAndCalculateCompensationCancellation();
    } else if (this.hasDelay()) {
      return determineEligibilityAndCalculateCompensationDelay();
    } else {
      this.protocol.denialReason = EU261Protocol.DenialReason.NODELAYORCANCELLATION;
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'flight not cancelled and not delayed'
      );
    }
  }

  public class TimeDifference {
    public Integer minutesEarlyDeparture { get; set; }
    public Integer minutesLateArrival { get; set; }
  }

  private TimeDifference getTimeDifferenceCancellation() {
    Integer minutesLateOnArrival;
    Integer minutesEarlyOnDeparture;
    Trip newTrip = this.tripWithClaimFlightReplacement;

    if (newTrip == null) {
      // No suggested rebooking
      return null;
    } else {
      Datetime originalDeparture = this.tripWithClaimFlight.getFirstFlight()
        .scheduledDepartureTime;
      Datetime originalArrival = this.tripWithClaimFlight.getFlightToFinalDestination()
        .scheduledArrivalTime;

      Datetime newDeparture = newTrip.getFirstFlight().scheduledDepartureTime;
      Flight finalFlight = newTrip.getFlightToFinalDestination();
      Datetime newArrival = finalFlight.actualArrivalTime;
      if (newArrival == null) {
        newArrival = finalFlight.scheduledArrivalTime;
      }

      // Compare the original rebooking against the suggested rebooking and calculate compensation
      Integer departureDifference =
        DateUtils.getMinutesBetween(newDeparture, originalDeparture) + 1; // Add 1 minute to make sure we don't round down
      Integer arrivalDifference =
        DateUtils.getMinutesBetween(newArrival, originalArrival) + 1;

      if (newArrival > originalArrival) {
        minutesLateOnArrival = arrivalDifference;
      } else {
        minutesLateOnArrival = 0;
      }
      if (newDeparture < originalDeparture) {
        minutesEarlyOnDeparture = departureDifference;
      } else {
        minutesEarlyOnDeparture = 0;
      }
    }

    TimeDifference result = new TimeDifference();
    result.minutesEarlyDeparture = minutesEarlyOnDeparture;
    result.minutesLateArrival = minutesLateOnArrival;

    return result;
  }

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding cancellations.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * Returns the result as either a decision of Ineligible with explanations,
   * or Eligible with compensation amounts set.
   */
  private Decision calculateCompensationForCancellation() {
    // FLight plan before the cancellation
    Trip originalTrip = this.tripWithClaimFlight;
    Decimal flightDistanceInKm =
      Airport.distanceBetweenAirportsInMeters(
        originalTrip.originAirport,
        originalTrip.destinationAirport
      ) / 1000;
    Integer flightDistanceInKmRounded = flightDistanceInKm.intValue();
    Boolean isIntraCommunity = originalTrip.isIntraCommunity(); // TODO: GB -> CH can be handled as EU
    Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();

    Money compensation;
    TimeDifference difference = getTimeDifferenceCancellation();
    if (difference == null) {
      // No suggested rebooking => full EU261 (10h outside timeframe => full compensation, except if you were informed on time)
      compensation = compensation = calculateCompensationCancellation(
        600,
        0,
        flightDistanceInKmRounded,
        daysUntilFlightWhenInformedOfCancellation,
        isIntraCommunity
      );
    } else {
      compensation = calculateCompensationCancellation(
        difference.minutesLateArrival,
        difference.minutesEarlyDeparture,
        flightDistanceInKmRounded,
        daysUntilFlightWhenInformedOfCancellation,
        isIntraCommunity
      );
    }

    List<ClaimCustomer> eligiblePassengers = this.getPassengersEligibleForCompensation();

    if (eligiblePassengers.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'There are no passengers which are eligible for compensation'
      );
    } else if (compensation == new Money(0, Money.CurrencyCode.EUR)) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'The offered rebooking is not outside the timeframe allowed by EU261'
      );
    }

    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : eligiblePassengers) {
      compensationByCustomer.put(p, compensation);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.SEK)
    );
  }

  /**
   * Checks if the delay caused the trip to be altered in any major way.
   * E.g. if the customer had to catch another plane.
   * If not, the delay is simple.
   * @throws InsufficientDataException If there is no info about the boarding status
   * @return If we currently consider the delay automatically handleable.
   *
   * NOTE: If this logic is altered there are several things about the rest of the
   * implementation which need to be changed, most notably "calculateCompensationForDelay"
   */
  private Boolean isSimpleDelay() {
    if (!rootCause.resultingTrip.allFlightsAreBoarded()) {
      return false; // If the customers did not board all flights something is going on
    } else if (rootcause.type == Trip.RootCauseType.SHORTDELAY) {
      return true;
    }

    // Check that the last flight only either is delayed less than 180 minutes or has only EU no delays or EU yes delays
    Flight cause = this.rootCause.flight;
    Set<Proactivity__c> causeProactivities = flightIdToProactivities.get(
      cause.id
    );

    if (causeProactivities != null && causeProactivities.size() > 0) {
      return true;
    }

    Integer delay = Integer.valueOf(cause.arrivalDelayedMinutes);
    Integer totalIrregularityDelay = cause.getTotalIrregularityDelay(); // This is really the only thing we have to check
    Integer netDelay = getNetDelayedMinutesDelay();

    Boolean hasSmallDelay = netDelay < 180;
    Boolean delayIsResonable = Math.abs(delay - totalIrregularityDelay) < 60;
    Boolean hasMixedDelays = cause.hasMixedDelays();
    Boolean isExpenseClaim = EXPENSE_CLAIM_TYPES.contains(this.claimObj.type);

    Boolean canMakeDecision =
      (!hasMixedDelays || hasSmallDelay || isExpenseClaim) && delayIsResonable;

    return canMakeDecision;
  }

  private List<ClaimCustomer> getPassengersEligibleForCompensation() {
    List<Passenger> passengers = this.claimedBooking.passengers;

    List<ClaimCustomer> customers = this.claimObj.customers;

    List<ClaimCustomer> eligibleCustomers = new List<ClaimCustomer>();

    // If an infant has a paid ticket they should receive compensation, otherwise not.
    // We currently do not have payment data. But we know domestic flights in Sweden and Norway
    // are free for infants, therefore we can deny these passengers.
    for (Passenger passenger : passengers) {
      for (ClaimCustomer cc : customers) {
        Boolean isInfant = passenger.identifier.toLowerCase().contains('inf');

        if (!isInfant || !tripWithClaimFlight.isIntraSEorIntraNO()) {
          eligibleCustomers.add(cc);
        }
      }
    }

    return eligibleCustomers;
  }

  private Decision determineEligibilityAndCalculateReimbursement() {
    // Check if arrived 2h late or not
    if (this.claimObj.submittedClaimExpenses.amount == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'No expenses submitted'
      );
    }

    Boolean flightCancelledWellInTime =
      CANCELLATION_CLAIM_TYPES.contains(this.claimObj.type) &&
      flightCancelledWellInTime();
    if (flightCancelledWellInTime) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'Flight was cancelled 14 or more days in advance'
      );
    }

    Boolean customerCancelled =
      CANCELLATION_CLAIM_TYPES.contains(this.claimObj.type) &&
      this.tripWithClaimFlight.customerCancelled();
    if (customerCancelled) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'The customer cancelled the flight'
      );
    }

    Integer netDelay;
    if (CANCELLATION_CLAIM_TYPES.contains(this.claimObj.type)) {
      TimeDifference difference = getTimeDifferenceCancellation();
      if (difference == null) {
        netDelay = 600; // No replacement, just consider it a 10h delay
      } else {
        netDelay = difference.minutesLateArrival;
      }
    } else if (DELAY_CLAIM_TYPES.contains(this.claimObj.type)) {
      netDelay = getNetDelayedMinutesDelay();
    } else {
      throw new AutomationException('Unsupported claim type');
    }

    Decision d;
    if (netDelay >= 120) {
      d = new Decision(
        Claim.EU261HandlingStatus.ReimbursementOnly,
        'Arrived 2h late or more'
      );
      d.reimbursementAmountInSEK = this.claimObj.submittedClaimExpenses.setScale(
        0
      );
    } else {
      d = new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensationAndExpenses,
        'Arrived less than 2h late'
      );
      this.protocol.denialReason = EU261Protocol.DenialReason.DELAYUNDER2HOURS;
    }

    return d;
  }

  public class ProactivityException extends Exception {
  }

  private Boolean cancellationCodeIsWithinSASControl() {
    Set<Proactivity__c> proactivities = flightIdToProactivities.get(
      this.claimFlight.Id
    );

    return claimFlight.cancellationIsWithinSASControl(proactivities);
  }

  private Boolean canDetermineIfSASIsResponsibleForCancellation() {
    try {
      this.cancellationCodeIsWithinSASControl();
      return true;
    } catch (FlightIrregularity.IrregularityException e) {
      return false;
    } catch (Trip.ResponsibilityException e2) {
      return false;
    }
  }

  private Integer getDaysBetweenCancellationAndDeparture() {
    List<FlightIrregularity> claimIrregularities = new List<FlightIrregularity>();

    for (FlightIrregularity fi : this.claimFlight.irregularities) {
      if (fi.isCancellation()) {
        claimIrregularities.add(fi);
      }
    }

    if (claimIrregularities.size() == 0) {
      throw new AutomationException('Claim flight is not cancelled.');
    }

    if (claimIrregularities.size() > 1) {
      throw new AutomationException(
        'Cancelled flight does not have exactly one irregularity.'
      );
    }
    FlightIrregularity cancellation = claimIrregularities[0];

    Datetime departureTime = this.claimFlight.scheduledDepartureTime;
    Datetime cancellationTime = cancellation.cancellationTime;
    if (cancellationTime == null) {
      throw new AutomationException(
        'Cancellation does not have a cancellation time.'
      );
    }
    Decimal hoursBetween = DateUtils.getHoursBetween(
      departureTime,
      cancellationTime
    );
    Integer daysBetween = (hoursBetween / 24).intValue();
    return daysBetween;
  }

  // TODO: Get rid of this.
  public class AutomationException extends Exception {
  }

  /**
   *
   * Checks whether the claim is covered by EU261 jurisdiction.
   * EU261 is only applicable for flights leaving and/or arriving to an airport in the European Union, Iceland, Norway or Switzerland.
   * Also, if the customer has already received benefits related to a law of a non-EU country they are not eligable for compensation.
   * Source: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm
   */
  private Boolean isWithinEU261Jurisdiction() {
    return true; // Until we have other operating carriers.
    // As SAS is EU carrier, we're always under EU jurisdiction as operating carrier.

    /* 
    Airport__c originAirport = this.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = this.tripWithClaimFlight.destinationAirport;
    Boolean isToOrFromEU261Territory = (originAirport.Is_EU261_Applicable__c ||
    destinationAirport.Is_EU261_Applicable__c);
    return (isToOrFromEU261Territory && !hasReceivedBenefitsWhichVoidEU261);
    */
  }

  private Integer getProtocolDelayWithinSASControl() {
    Flight cause = this.rootCause.flight;
    Integer delay;
    Integer totalIrregularityDelay;
    Integer delayWithinSASControl = 0;
    Integer netDelayedMinutes = getNetDelayedMinutesDelay();
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;

    if (cause != null) {
      delay = Integer.valueOf(cause.arrivalDelayedMinutes);
      Set<Proactivity__c> causeProactivities = flightIdToProactivities.get(
        rootCause.flight.id
      );
      totalIrregularityDelay = cause.getTotalIrregularityDelay(); // This is really the only thing we have to check
      delayWithinSASControl = cause.getDelayedMinutesWithinOperatorsControl(
        causeProactivities
      );
      if (
        cause.hasMixedDelays() &&
        (causeProactivities == null ||
        causeProactivities.size() == 0) &&
        netDelayedMinutes >= MINIMUM_DELAY_FOR_COMPENSATION
      ) {
        throw new AutomationException('Mixed delays are not supported');
      }
    }

    switch on this.rootCause.type {
      when SIMPLEDELAY {
        Integer delayOutsideSASControl = Math.max(
          netDelayedMinutes - delayWithinSASControl,
          0
        );
      }
      when DELAYPLACEDONOTHERFLIGHT {
        throw new AutomationException(
          'Delay handling for when the customer was placed on another flight are not implemented yet'
        );
      }
      when DELAYMISSEDCONNECTION, SHORTDELAY {
        // Mix (thrown above)
        if (netDelayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
          // < 180 -> Deny
        } else if (delayWithinSASControl == 0) {
          // EU no -> Deny
        } else {
          // EU yes -> approve if significant, else: throw, not supported
          if (delayWithinSASControl < 30) {
            throw new AutomationException(
              'Delay handling for approval settlements when the customer missed a connection due to a small delay are not implemented yet'
            );
          }
          delayWithinSASControl = netDelayedMinutes;
        }
      }
      when else {
        throw new AutomationException(
          'Delay handling for this type of root cause are not implemented yet'
        );
      }
    }

    return delayWithinSASControl;
  }

  /**
   * Calculates the actual amount of compensation in EUR the customer(s) is/are
   * entitled according to EU261 for _delays_.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * This is all based on Sturgeon v. Condor.
   */
  private Decision calculateCompensationForDelay() {
    List<ClaimCustomer> passengersEligibleForCompensation = this.getPassengersEligibleForCompensation();
    if (passengersEligibleForCompensation.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'No passenger in this claim has a revenue ticket.'
      ); // Not yet handled, currently result in thrown exception (cases like this will not reach here right now)
    }

    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;
    final Integer MINIMUM_DELAY_FOR_INCREASED_COMPENSATION = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Flight cause = this.rootCause.flight;
    Integer delay;
    Integer totalIrregularityDelay;
    Integer delayWithinSASControl = 0;
    Integer netDelayedMinutes = getNetDelayedMinutesDelay();

    if (cause != null) {
      delay = Integer.valueOf(cause.arrivalDelayedMinutes);
      Set<Proactivity__c> causeProactivities = flightIdToProactivities.get(
        rootCause.flight.id
      );
      totalIrregularityDelay = cause.getTotalIrregularityDelay(); // This is really the only thing we have to check
      delayWithinSASControl = cause.getDelayedMinutesWithinOperatorsControl(
        causeProactivities
      );
      if (
        cause.hasMixedDelays() &&
        (causeProactivities == null ||
        causeProactivities.size() == 0) &&
        netDelayedMinutes >= MINIMUM_DELAY_FOR_COMPENSATION
      ) {
        throw new AutomationException('Mixed delays are not supported');
      }
    }

    switch on this.rootCause.type {
      when SIMPLEDELAY {
        Integer delayOutsideSASControl = Math.max(
          netDelayedMinutes - delayWithinSASControl,
          0
        );
      }
      when DELAYPLACEDONOTHERFLIGHT {
        throw new AutomationException(
          'Delay handling for when the customer was placed on another flight are not implemented yet'
        );
      }
      when DELAYMISSEDCONNECTION, SHORTDELAY {
        // Mix (thrown above)
        if (netDelayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
          // < 180 -> Deny
        } else if (delayWithinSASControl == 0) {
          // EU no -> Deny
        } else {
          // EU yes -> approve if significant, else: throw, not supported
          if (delayWithinSASControl < 30) {
            throw new AutomationException(
              'Delay handling for approval settlements when the customer missed a connection due to a small delay are not implemented yet'
            );
          }
          delayWithinSASControl = netDelayedMinutes;
        }
      }
      when else {
        throw new AutomationException(
          'Delay handling for this type of root cause are not implemented yet'
        );
      }
    }

    this.protocol.delayWithinSASControl = delayWithinSASControl;
    this.protocol.rootCause = this.rootCause;

    if (delayWithinSASControl < MINIMUM_DELAY_FOR_COMPENSATION) {
      if (netDelayedMinutes >= MINIMUM_DELAY_FOR_COMPENSATION) {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'SAS is not responsible for 3 hours or more of the delay'
        );
      } else {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'Delayed less than 180 minutes'
        );
      }
    }

    Decimal flightDistanceInM = Airport.distanceBetweenAirportsInMeters(
      this.tripWithClaimFlight.originAirport,
      this.tripWithClaimFlight.destinationAirport
    );
    Integer flightDistanceInKm = (flightDistanceInM / 1000).intValue();

    Money compensationAmount = new Money(0, Money.CurrencyCode.EUR);
    Boolean halveCompensation = false;
    if (flightDistanceInKm <= MEDIUM_DISTANCE) {
      compensationAmount = new Money(250, Money.CurrencyCode.EUR);
    } else if (
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE ||
      this.tripWithClaimFlight.isIntraCommunity())
    ) {
      compensationAmount = new Money(400, Money.CurrencyCode.EUR);
    } else if (
      delayWithinSASControl < MINIMUM_DELAY_FOR_INCREASED_COMPENSATION
    ) {
      halveCompensation = true;
      compensationAmount = new Money(300, Money.CurrencyCode.EUR);

      // Temp until we create emails (~1/1000 edge case). TODO: write email
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Cannot handle halved delay compensation before email templates are created'
      );
    } else {
      compensationAmount = new Money(600, Money.CurrencyCode.EUR);
    }
    this.protocol.compensationIsHalved = halveCompensation;
    this.protocol.minutesEarlyOnDeparture = 0;
    this.protocol.minutesLateOnArrival = netDelayedMinutes;
    this.protocol.flightDistanceInKm = flightDistanceInKm;

    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : passengersEligibleForCompensation) {
      compensationByCustomer.put(p, compensationAmount);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.SEK)
    );
  }

  private Money calculateCompensationCancellation(
    Integer minutesLateOnArrival,
    Integer minutesEarlyOnDeparture,
    Integer flightDistanceInKm,
    Integer daysUntilFlightWhenInformedOfCancellation,
    Boolean isIntraCommunity
  ) {
    final Integer MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL = 240;
    final Integer MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE = 180;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Boolean isEligableForCompensation =
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL,
        minutesLateOnArrival,
        daysUntilFlightWhenInformedOfCancellation
      ) ||
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE,
        minutesEarlyOnDeparture,
        daysUntilFlightWhenInformedOfCancellation
      );

    this.protocol.minutesEarlyOnDeparture = minutesEarlyOnDeparture;
    this.protocol.minutesLateOnArrival = minutesLateOnArrival;
    this.protocol.flightDistanceInKm = flightDistanceInKm;
    this.protocol.isOutsideTimeFrame = isEligableForCompensation;
    this.protocol.daysUntilFlightWhenInformedOfCancellation = daysUntilFlightWhenInformedOfCancellation;

    if (!isEligableForCompensation) {
      return new Money(0, Money.CurrencyCode.EUR);
    }

    Money compensation;
    Boolean halveCompensation;
    Boolean isShortDistance = flightDistanceInKm <= MEDIUM_DISTANCE;
    Boolean isMediumDistanceOrIntraCommunity =
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE || isIntraCommunity);
    if (isShortDistance) {
      compensation = new Money(250, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        this.protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE;
      }
    } else if (isMediumDistanceOrIntraCommunity) {
      compensation = new Money(400, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        this.protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE;
      }
    } else {
      compensation = new Money(600, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        this.protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE;
      }
    }

    this.protocol.compensationIsHalved = halveCompensation;

    return compensation;
  }

  private static Boolean isOutSideTimeFrame(
    Integer timeFrame,
    Integer deviation,
    Integer daysUntilFlightWhenInformedOfCancellation
  ) {
    Integer minutesOutsideTimeFrame;
    if (daysUntilFlightWhenInformedOfCancellation > 14) {
      minutesOutsideTimeFrame = 0;
    } else if (
      daysUntilFlightWhenInformedOfCancellation <= 14 &&
      daysUntilFlightWhenInformedOfCancellation > 7
    ) {
      minutesOutsideTimeFrame = Math.max(0, deviation - timeFrame);
    } else {
      minutesOutsideTimeFrame = Math.max(0, deviation - timeFrame / 2);
    }

    return minutesOutsideTimeFrame > 0;
  }

  public Boolean hasHighClaimedExpenses() {
    if (
      this.claimObj.submittedClaimExpenses == null ||
      this.claimObj.submittedClaimExpenses.equals(
        new Money(0, Money.CurrencyCode.SEK)
      )
    ) {
      return false;
    }

    Boolean anySingleExpenseOverLimit = false;

    for (ClaimExpense ce : this.claimObj.expenses) {
      Money expenseLimit = new Money(0, Money.CurrencyCode.SEK);

      switch on ce.type {
        when Accommodation {
          expenseLimit = this.config.expenseLimitAccommodation;
        }
        when Food {
          expenseLimit = this.config.expenseLimitFood;
        }
        when PhoneCalls {
          expenseLimit = this.config.expenseLimitPhoneCalls;
        }
        when Transportation {
          expenseLimit = this.config.expenseLimitTransportation;
        }
      }

      if (
        (new Money(ce.amountInSEK, Money.CurrencyCode.SEK))
          .greaterThan(expenseLimit)
      ) {
        anySingleExpenseOverLimit = true;
        break;
      }
    }

    return anySingleExpenseOverLimit ||
      this.claimObj.submittedClaimExpenses.greaterThan(
        config.expenseLimitTotal
      );
  }

  public Boolean hasInvalidSettlementDetails() {
    if (this.decision == null) {
      return false;
    }

    return this.decision.caveats.contains(
      EU261Claim.SemiAutomationReason.InvalidSettlementDetails
    );
  }

  public List<SemiAutomationReason> getSemiAutomationReasons() {
    List<SemiAutomationReason> toReturn = new List<SemiAutomationReason>();

    if (this.hasPotentiallyDuplicateClaims) {
      toReturn.add(SemiAutomationReason.HasPotentialDuplicates);
    }

    if (this.hasHighClaimedExpenses()) {
      toReturn.add(SemiAutomationReason.HasHighClaimExpenses);
    }

    if (this.requiresPowerOfAttorney()) {
      toReturn.add(SemiAutomationReason.RequiresPowerOfAttorney);
    }

    if (this.hasInvalidSettlementDetails()) {
      toReturn.add(SemiAutomationReason.InvalidSettlementDetails);
    }

    return toReturn;
  }
}
