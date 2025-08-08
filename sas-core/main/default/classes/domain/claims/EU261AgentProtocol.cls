public without sharing class EU261AgentProtocol {
  /**
   * TODO: Make this into an s_object for better analytics, tracking and interoperability with agents.
   * If a variable needs to be filled before evaluation it is highlighted with |||
   */
  // INITIALIZATION
  public Boolean hasPotentiallyDuplicateClaims; // |||
  public Boolean foundMultipleMatchingBookings; // |||
  public Flight claimFlight; // Might need to be calculated // |||
  public Boolean regardsPersonWithReducedMobility; // |||
  public Boolean regardsUnaccompaniedMinor; // |||
  public Boolean isCorrectType; // |||
  public Boolean hasClaimProactivities; // |||
  public Boolean hasValidData;

  public Boolean isCancellationClaim; // Could be done with an enum, but more readable this way // |||
  public Boolean isDelayClaim; // |||
  public Boolean isExpenseClaim; // |||

  public Trip.RootCause rootCause; // |||
  public Flight rootCauseFlight; // |||
  public Boolean canCalculateWithLittleInformaiton; // |||
  public Boolean isTooComplex; // |||
  public Boolean flightCancelledWellInTime; // |||
  public Boolean isOperatedBySAS; // |||
  public Boolean customerCancelled; // |||
  public Integer daysUntilFlightWhenInformedOfCancellation; // |||

  public List<EU261Claim.SemiAutomationReason> caveats; // |||

  public Trip tripWithRootCauseFlight;
  public Trip tripAfterEffectOfRootCause;
  public Boolean hasSubmittedClaimExpenses; // |||
  public Boolean isStaffBooking; // |||
  public Boolean isWithinEU261Jurisdiction; // |||

  public Datetime originalDeparture; // |||
  public Datetime originalArrival; // |||
  public Datetime newDeparture; // |||
  public Datetime newArrival; // |||
  public List<ClaimCustomer> eligibleCustomers; // |||

  public Boolean isFiledOnTime; // |||
  public Integer flightDistance; // |||
  public Boolean isIntraCommunity; // |||
  public Boolean cancellationWasWithinSASControl; // |||
  public Integer delayWithinSASControl; // |||
  public Integer netDelayedMinutesDelay; // |||
  public Integer minutesLateOnArrivalCancellation; // |||
  public Integer minutesEarlyOnDeparture = 0; // |||
  public EU261Claim.TimeDifference timeDifference; // ||| TODO: remove and consolidate with the other variables

  public Money claimedReimbursementInSEK; // |||

  public Integer generalMinutesLateOnArrival {
    get {
      if (this.isCancellationClaim) {
        return this.minutesLateOnArrivalCancellation;
      } else {
        return this.netDelayedMinutesDelay;
      }
    }
  }

  public Boolean compensationIsHalved; // |||
  public Boolean customerCancelledTheFlight; // |||
  public Boolean cancellationIsWithinSASControl; // |||

  // Necessary for email only
  public Integer claimFilingTimeLimitInMonths; // |||
  public Set<Proactivity__c> rootCauseFlightProactivities; // |||
  public EU261Protocol.DenialReason denialReason;

  public FlightIrregularity firstIrregularity {
    get {
      return claimFlight.irregularities[0];
    }
  }

  public EU261AgentProtocol() {
  }

  public Map<String, String> getVariableMap() {
    Flight f = claimFlight;

    String proactivityReasonNotWithinSASControl;

    String flightPlan = this.getFlightPlanHistory();
    String flightDate = StringUtils.dateToReadable(
      f.scheduledDepartureTime.date()
    );
    String flightNumber = f.getFlightNumber();
    String flightDistanceKm = String.valueOf(this.flightDistance);
    String departureAirport = f.departureAirport;
    String departureAirportName = f.departureAirportObject.name;
    String departureCountry = f.departureAirportObject.countryName;
    String departureTime = StringUtils.dateTimeToReadable(
      f.scheduledDepartureTime
    );
    String arrivalAirport = f.arrivalAirport;
    String arrivalAirportName = f.arrivalAirportObject.name;
    String arrivalCountry = f.arrivalAirportObject.countryName;

    String minutesDelayed;
    if (this.isCancellationClaim) {
      // This is suboptimal, todo: combine into one
      minutesDelayed = String.valueOf(this.minutesLateOnArrivalCancellation);
    } else {
      minutesDelayed = String.valueOf(this.netDelayedMinutesDelay);
    }
    String minutesEarly = String.valueOf(this.minutesEarlyOnDeparture);

    String monthLimit = '|||NONE|||';
    if (this.tripWithRootCauseFlight != null) {
      monthLimit = String.valueOf(claimFilingTimeLimitInMonths);
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
    if (this.isCancellationClaim && !this.isExpenseClaim) {
      cancellationDate = StringUtils.dateToReadable(
        this.firstIrregularity.cancellationTime.date()
      );
      cancellationTime = StringUtils.dateTimeToReadable(
        this.firstIrregularity.cancellationTime
      );
      cancellationReason = this.firstIrregularity.getExplanation();
      daysBetweenInformedAndDeparture = String.valueOf(
        this.daysUntilFlightWhenInformedOfCancellation
      );
      timeFrame = this.daysUntilFlightWhenInformedOfCancellation <= 7
        ? '1 hour early departure and 2 hours late arrival'
        : '2 hours early departure and 4 hours late arrival';
      cancellationType = '|||NONE|||';
      if (tripWithRootCauseFlight != null) {
        cancellationType = SegmentEvent.getOfficeCodeExplanation(
          tripWithRootCauseFlight.cancellationTimeInfo.officeRemoving
        );
      }
      if (
        this.rootCauseFlightProactivities != null &&
        this.rootCauseFlightProactivities.size() > 0
      ) {
        proactivityReasonNotWithinSASControl = this.rootCauseFlightProactivities.iterator()
          .next()
          .Eligibility_Explanation__c;
      }
    } else if (
      this.isDelayClaim &&
      this.denialReason != EU261Protocol.DenialReason.NOTFILEDONTIME &&
      !this.isExpenseClaim
    ) {
      delayExplanaiton = this.getDelayExplanation();
      Flight causeFlight = this.rootCauseFlight;
      Set<Proactivity__c> causeProactivities;
      if (this.rootCauseFlight != null) {
        rootCauseFlightNumber = this.rootCauseFlight.getFlightNumber();
        rootCauseFlightMinutesDelayed = String.valueOf(
          this.rootCauseFlight.arrivalDelayedMinutes
        );
        rootCauseFlightDepartureAirport = this.rootCauseFlight.departureAirport;
        rootCauseFlightArrivalAirport = this.rootCauseFlight.arrivalAirport;
        rootCauseOutsideSASControlExplanation = this.rootCauseFlight.getOutsideSASControlExplanationDelay();
        rootCauseFlightDate = StringUtils.dateToReadable(
          this.rootCauseFlight.scheduledDepartureTime.date()
        );
      }

      flightDate = rootCauseFlightDate;
      flightNumber = rootCauseFlightNumber;
      departureAirport = rootCauseFlightDepartureAirport;
      arrivalAirport = rootCauseFlightArrivalAirport;

      if (
        this.rootCauseFlightProactivities != null &&
        this.rootCauseFlightProactivities.size() > 0
      ) {
        proactivityReasonNotWithinSASControl = this.rootCauseFlightProactivities.iterator()
          .next()
          .Eligibility_Explanation__c;
      }
    }

    String tripDestinationArrivalType = departureCountry == arrivalCountry
      ? 'domestic trip within ' + departureCountry
      : 'trip between ' + departureCountry + ' and ' + arrivalCountry; // The reservation was for a ... trip between Sweden and USA, ... domestic trip within Sweden

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
      '|||delayExplanation|||' => delayExplanaiton,
      '|||rootCauseFlightNumber|||' => rootCauseFlightNumber,
      '|||rootCauseFlightMinutesDelayed|||' => rootCauseFlightMinutesDelayed,
      '|||rootCauseFlightDepartureAirport|||' => rootCauseFlightDepartureAirport,
      '|||rootCauseFlightArrivalAirport|||' => rootCauseFlightArrivalAirport,
      '|||totalDelay|||' => String.valueOf(this.netDelayedMinutesDelay),
      '|||rootCauseOutsideSASControlExplanation|||' => rootCauseOutsideSASControlExplanation,
      '|||proactivityReasonNotWithinSASControl|||' => proactivityReasonNotWithinSASControl,
      '|||delayWithinSASControl|||' => String.valueOf(
        this.delayWithinSASControl
      )
    };
  }

  public String getFlightPlanHistory() {
    List<String> toReturn = new List<String>{
      buildFlightPlan(this.tripWithRootCauseFlight)
    };

    if (this.tripAfterEffectOfRootCause == null) {
      toReturn.add('There was no replacement flight plan.');
    } else {
      toReturn.add('The offered replacement for this trip was:');
      toReturn.add(buildFlightPlan(this.tripAfterEffectOfRootCause));
    }

    return String.join(toReturn, '\n');
  }

  private static String buildFlightPlan(Trip t) {
    if (t == null) {
      return 'No flights';
    }

    List<String> totalFlightPlan = new List<String>{ 'Flight plan:' };
    for (Trip.Leg l : t.sortedLegs) {
      String actualDeparture = '';
      String actualArrival = '';
      Flight f = l.flight;
      if (f.actualDepartureTime != null) {
        actualDeparture = StringUtils.dateTimeToReadable(f.actualDepartureTime);
      }
      if (f.actualArrivalTime != null) {
        actualArrival = StringUtils.dateTimeToReadable(f.actualArrivalTime);
      }

      String departureTime = StringUtils.dateTimeToReadable(
        f.scheduledDepartureTime
      );
      String arrivalTime = StringUtils.dateTimeToReadable(
        f.scheduledArrivalTime
      );

      String flightPlan = String.format(
        '{0} {1}-{2} (scheduled: {3} to {4}',
        new List<String>{
          f.tedsIdentifier.substringBefore('-'),
          f.departureAirport,
          f.arrivalAirport,
          departureTime,
          arrivalTime
        }
      );

      if (actualDeparture != '' && actualArrival != '') {
        flightPlan += String.format(
          ', actual: {0} to {1})',
          new List<String>{ actualDeparture, actualArrival }
        );
      } else {
        flightPlan += ')';
      }
      totalFlightPlan.add(flightPlan);
    }

    return String.join(totalFlightPlan, '\n');
  }

  /**
   * TODO: talk to liability and Markus about this
   */
  public String getDelayExplanation() {
    if (!this.isDelayClaim) {
      throw new EU261Claim.AutomationException(
        'Cannot get delay explanation for non-delay claim.'
      );
    }

    String delayExplanation;
    switch on this.rootCause.type {
      when SIMPLEDELAY {
        delayExplanation = getDelayExplanationSimple();
      }
      when DELAYPLACEDONOTHERFLIGHT {
        throw new EU261Claim.AutomationException(
          'Protocol for delays when the customer was placed on another flight are not implemented yet'
        );
      }
      when DELAYMISSEDCONNECTION {
        delayExplanation = getDelayExplanationMissedConnection();
      }
    }

    return delayExplanation;
  }

  private String getDelayExplanationSimple() {
    String delayExplanationTemplate = 'The last flight of the trip was delayed {0} minutes on arrival.';
    String complicatedDelayExplanationTemplate = 'The last flight of the trip was delayed {0} minutes on arrival of which {1} minutes were within SAS control. {2}';
    String delayExplanation;
    if (this.netDelayedMinutesDelay > this.delayWithinSASControl) {
      String outsideControlExplanation = this.rootCause.flight.getOutsideSASControlExplanationDelay();

      if (outsideControlExplanation == null) {
        throw new EU261Claim.AutomationException(
          'No explanation for delay outside SAS control.'
        );
      }

      delayExplanation = String.format(
        complicatedDelayExplanationTemplate,
        new List<String>{
          String.valueOf(this.netDelayedMinutesDelay),
          String.valueOf(this.delayWithinSASControl),
          outsideControlExplanation
        }
      );
    } else {
      delayExplanation = String.format(
        delayExplanationTemplate,
        new List<String>{ String.valueOf(this.netDelayedMinutesDelay) }
      );
    }

    return delayExplanation;
  }

  private String getDelayExplanationMissedConnection() {
    String missedConnectionTemplate = 'The root cause of the delay was {0}, which was {1} minutes late on arrival. The delay of this flight caused the passenger to miss their connecting flight. This ultimately resulted in a delay of {2} minutes compared to the original flight plan.';
    String missedConnectionTemplateOutsideControl = 'The root cause of the delay was {0}, which was {1} minutes late on arrival of which {2} minutes were within SAS control. {3}. The delay of this flight caused the passenger to miss their connecting flight. This ultimately resulted in a delay of {4} minutes compared to the original flight plan.';
    String delayExplanation;

    try {
      String outsideControlExplanation = this.rootCause.flight.getOutsideSASControlExplanationDelay();
      delayExplanation = String.format(
        missedConnectionTemplateOutsideControl,
        new List<Object>{
          this.rootCause.flight.getFlightNumber(),
          this.rootCause.flight.arrivalDelayedMinutes,
          this.delayWithinSASControl,
          outsideControlExplanation,
          this.netDelayedMinutesDelay
        }
      );
    } catch (Flight.FlightException e) {
      // No delay outside SAS control
      delayExplanation = String.format(
        missedConnectionTemplate,
        new List<Object>{
          this.rootCause.flight.getFlightNumber(),
          this.rootCause.flight.arrivalDelayedMinutes,
          this.netDelayedMinutesDelay
        }
      );
    }

    return delayExplanation;
  }
}
