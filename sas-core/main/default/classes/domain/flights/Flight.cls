public without sharing class Flight extends AbstractSObjectWrapper implements Comparable {
  public Flight__c underlyingSObject { get; private set; }

  public String tedsIdentifier;
  public String operationalControlCenter;
  public String aircraftRegistration;

  public String arrivalAirport;
  public Decimal arrivalDelayedMinutes;
  public String arrivalGate;
  public Status arrivalStatus;
  public String arrivalTerminal;

  public String departureAirport;
  public Decimal departureDelayedMinutes;
  public String departureGate;
  public Status departureStatus;
  public String departureTerminal;

  public DateTime actualArrivalTime;
  public String actualArrivalTimeLocal;
  public DateTime actualDepartureTime;
  public String actualDepartureTimeLocal;

  public DateTime estimatedArrivalTime;
  public String estimatedArrivalTimeLocal;
  public DateTime estimatedDepartureTime;
  public String estimatedDepartureTimeLocal;

  public DateTime scheduledArrivalTime;
  public String scheduledArrivalTimeLocal;
  public DateTime scheduledDepartureTime;
  public String scheduledDepartureTimeLocal;

  public Airport departureAirportObject;
  public Airport arrivalAirportObject;

  public String operatingCarrier;

  public List<FlightIrregularity> irregularities;

  public enum Status {
    Ontime,
    Delayed,
    Cancelled,
    Unknown
  }

  public class FlightException extends Exception {
  }

  private static final Map<String, Status> STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, Status>{
    'ontime' => Status.Ontime,
    'delayed' => Status.Delayed,
    'cancelled' => Status.Cancelled,
    'unknown' => Status.Unknown
  };

  private static final Map<Status, String> STATUS_ENUM_TO_PICKLIST_VALUE = new Map<Status, String>{
    Status.Ontime => 'ontime',
    Status.Delayed => 'delayed',
    Status.Cancelled => 'cancelled',
    Status.Unknown => 'unknown'
  };

  private static final String SAS_AIRLINE_IATA_DESIGNATOR = 'SK';

  private static final Set<String> STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS = new Set<String>{
    'A3',
    'AC',
    'AI',
    'AV',
    'BR',
    'CA',
    'CM',
    'ET',
    'LH',
    'LO',
    'LX',
    'MS',
    'NH',
    'NZ',
    'OS',
    'OU',
    'OZ',
    'SA',
    'SK',
    'SN',
    'SQ',
    'TG',
    'TK',
    'TP',
    'UA',
    'ZH'
  };

  private static final Set<String> hubAirports = new Set<String>{
    'ARN',
    'CPH',
    'OSL'
  };

  @TestVisible
  private Flight() {
    this.underlyingSObject = new Flight__c();
  }

  public Flight(Flight__c f) {
    super(f);
    this.underlyingSObject = f;

    this.tedsIdentifier = f.TEDS_Identifier__c;
    this.operationalControlCenter = f.Operational_Control_Center__c;
    this.operatingCarrier = f.Operating_Carrier__c;
    this.aircraftRegistration = f.Aircraft_Registration__c;

    this.arrivalAirport = f.Arrival_Airport__c;
    this.arrivalDelayedMinutes = f.Arrival_Delayed_Minutes__c;
    this.arrivalGate = f.Arrival_Gate__c;
    this.arrivalStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(f.Arrival_Status__c);
    this.arrivalTerminal = f.Arrival_Terminal__c;

    this.departureAirport = f.Departure_Airport__c;
    this.departureDelayedMinutes = f.Departure_Delayed_Minutes__c;
    this.departureGate = f.Departure_Gate__c;
    this.departureStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(
      f.Departure_Status__c
    );
    this.departureTerminal = f.Departure_Terminal__c;

    this.actualArrivalTime = f.Actual_Arrival_Time__c;
    this.actualArrivalTimeLocal = f.Actual_Arrival_Time_Local__c;
    this.actualDepartureTime = f.Actual_Departure_Time__c;
    this.actualDepartureTimeLocal = f.Actual_Departure_Time_Local__c;

    this.estimatedArrivalTime = f.Estimated_Arrival_Time__c;
    this.estimatedArrivalTimeLocal = f.Estimated_Arrival_Time_Local__c;
    this.estimatedDepartureTime = f.Estimated_Departure_Time__c;
    this.estimatedDepartureTimeLocal = f.Estimated_Departure_Time_Local__c;

    this.scheduledArrivalTime = f.Scheduled_Arrival_Time__c;
    this.scheduledArrivalTimeLocal = f.Scheduled_Arrival_Time_Local__c;
    this.scheduledDepartureTime = f.Scheduled_Departure_Time__c;
    this.scheduledDepartureTimeLocal = f.Scheduled_Departure_Time_Local__c;
  }

  public Flight(Flight__c f, Airport departureAirport, Airport arrivalAirport) {
    this(f);

    this.arrivalAirportObject = arrivalAirport;
    this.departureAirportObject = departureAirport;
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.TEDS_Identifier__c = this.tedsIdentifier;
    this.underlyingSObject.Operational_Control_Center__c = this.operationalControlCenter;
    this.underlyingSObject.Operating_Carrier__c = this.operatingCarrier;
    this.underlyingSObject.Aircraft_Registration__c = this.aircraftRegistration;

    this.underlyingSObject.Arrival_Airport__c = this.arrivalAirport;
    this.underlyingSObject.Arrival_Delayed_Minutes__c = this.arrivalDelayedMinutes;
    this.underlyingSObject.Arrival_Gate__c = this.arrivalGate;
    this.underlyingSObject.Arrival_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.arrivalStatus
    );
    this.underlyingSObject.Arrival_Terminal__c = this.arrivalTerminal;

    this.underlyingSObject.Departure_Airport__c = this.departureAirport;
    this.underlyingSObject.Departure_Delayed_Minutes__c = this.departureDelayedMinutes;
    this.underlyingSObject.Departure_Gate__c = this.departureGate;
    this.underlyingSObject.Departure_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.departureStatus
    );
    this.underlyingSObject.Departure_Terminal__c = this.departureTerminal;

    this.underlyingSObject.Actual_Arrival_Time__c = this.actualArrivalTime;
    this.underlyingSObject.Actual_Arrival_Time_Local__c = this.actualArrivalTimeLocal;
    this.underlyingSObject.Actual_Departure_Time__c = this.actualDepartureTime;
    this.underlyingSObject.Actual_Departure_Time_Local__c = this.actualDepartureTimeLocal;

    this.underlyingSObject.Estimated_Arrival_Time__c = this.estimatedArrivalTime;
    this.underlyingSObject.Estimated_Arrival_Time_Local__c = this.estimatedArrivalTimeLocal;
    this.underlyingSObject.Estimated_Departure_Time__c = this.estimatedDepartureTime;
    this.underlyingSObject.Estimated_Departure_Time_Local__c = this.estimatedDepartureTimeLocal;

    this.underlyingSObject.Scheduled_Arrival_Time__c = this.scheduledArrivalTime;
    this.underlyingSObject.Scheduled_Arrival_Time_Local__c = this.scheduledArrivalTimeLocal;
    this.underlyingSObject.Scheduled_Departure_Time__c = this.scheduledDepartureTime;
    this.underlyingSObject.Scheduled_Departure_Time_Local__c = this.scheduledDepartureTimeLocal;
  }

  /**
   * Returns true if this flight if the operating carrier of this flight belongs
   * to Star Alliance.
   */
  public Boolean isOperatedByStarAlliance() {
    return STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS.contains(this.getOperator());
  }

  public Boolean isOperatedBySAS() {
    return this.getOperator() == SAS_AIRLINE_IATA_DESIGNATOR;
  }

  /**
   * Returns true if this flight is delayed or cancelled based on departure and
   * arrival statuses.
   */
  public Boolean isDelayedOrCancelled() {
    return this.arrivalStatus == Status.Delayed ||
      (this.arrivalStatus == Status.Cancelled &&
      this.departureStatus == Status.Cancelled);
  }

  public List<FlightIrregularity> getCancellations() {
    if (this.irregularities == null) {
      throw new MissingDataException('Irregularities have not been set');
    }
    List<FlightIrregularity> cancellations = new List<FlightIrregularity>{};
    for (FlightIrregularity fi : this.irregularities) {
      if (fi.isCancellation()) {
        cancellations.add(fi);
      }
    }

    return cancellations;
  }

  public static Status getStatusFromPicklistValue(String picklistValue) {
    return STATUS_PICKLIST_VALUE_TO_ENUM.get(picklistValue);
  }

  /**
   * Calculates the direct distance between this flight's departure and
   * arrival airports.
   *
   * @throws MissingDataException if airport object fields have not been set for this flight.
   */
  public Integer getFlightDistancesInMeters() {
    if (
      this.arrivalAirportObject == null ||
      this.departureAirportObject == null
    ) {
      throw new MissingDataException('Missing airports.');
    }
    return this.departureAirportObject.distanceInMetersTo(
      this.arrivalAirportObject
    );
  }

  public Boolean departsHub() {
    return hubAirports.contains(this.departureAirport);
  }

  /*
   * Returns variations of the flight id written in plain text
   * @param TEDSId flightId in TEDS format, e.g. SK0151-20220713-RIX-OSL
   *
   * @return A tuple with ids with the following formats: BT0151-20220713, BT0151-2022-07-13
   */
  public static List<String> TEDSIdToSimpleFlightIds(String TEDSId) {
    String flightNumber = TEDSId.substringBefore('-'); // Should be normalized
    String flightDateConcat = TEDSId.substringAfter('-').substringBefore('-');
    String flightDateSeparated =
      flightDateConcat.substring(0, 4) +
      '-' +
      flightDateConcat.substring(4, 6) +
      '-' +
      flightDateConcat.substring(6, 8);

    String format1 = flightNumber + '-' + flightDateConcat;
    String format2 = flightNumber + '-' + flightDateSeparated;

    return new List<String>{ format1, format2 };
  }

  /**
   * Constructs a flightNumber + date combination like the one used in TEDS
   *
   * @param flightNumber E.g. SK1234
   * @param flightDate
   * @return a string like: SK1234-20220101
   */
  public static String constructTEDSFlightNumberDate(
    String flightNumber,
    Date flightDate
  ) {
    return normalizeFlightNumber(flightNumber) +
      '-' +
      StringUtils.dateToTEDSString(flightDate);
  }

  public String getFlightNumber() {
    return tedsIdentifier.substringBefore('-');
  }

  /**
   * Method to normalize a valid IATA flight number to the format used by TEDS.
   * TEDS format is valid IATA format with trailing numbers leftpadded with 0
   * Returns a normalized flight number.
   *
   *  @param enteredFlightNumber The flight number as entered by manual input (forms etc.)
   */
  public static String normalizeFlightNumber(String enteredFlightNumber) {
    String toNormalize = enteredFlightNumber.toUpperCase();
    String toReturn = '';
    Pattern validTEDSFormat = Pattern.compile('^([A-Z]\\w|\\w[A-Z])(\\d{4})$');
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Boolean validIATAFlightNumber = isValidIATAFlightNumber(toNormalize);
    if (validIATAFlightNumber) {
      String airlineCode = toNormalize.substring(0, 2);
      String flightNumber = toNormalize.substring(2, toNormalize.length());
      toReturn = airlineCode + flightNumber.leftPad(4, '0');
    }
    if (validTEDSFormat.matcher(toReturn).matches()) {
      return toReturn;
    } else {
      throw new FlightException('Unable to normalize Flight Number');
    }
  }

  public static Boolean canNormalizeFlightNumber(String enteredFlightNumber) {
    try {
      // Also crashes if Flight_Number__c == null
      Flight.normalizeFlightNumber(enteredFlightNumber);
    } catch (Exception e) {
      return false;
    }
    return true;
  }

  /* Method to validate if an entered flight number is a valid IATA flight number
   * Valid formats are:
   * [LETTER][NUMBER] followed by 1-4 numbers
   * [NUMBER][LETTER] followed by 1-4 numbers
   * [LETTER][LETTER] followed by 1-4 numbers
   */
  public static Boolean isValidIATAFlightNumber(String toCheck) {
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Matcher matcher = validFlightNumberFormat.matcher(toCheck);
    return matcher.matches();
  }

  public Boolean equals(Object obj) {
    if (obj instanceof Flight) {
      Flight that = (Flight) obj;

      return this.tedsIdentifier == that.tedsIdentifier;
    } else {
      return false;
    }
  }

  public Integer hashCode() {
    return 31 * this.tedsIdentifier.hashCode();
  }

  // If operatingCarrier is null, try to parse it from the teds identifier
  public String getOperator() {
    String oper = this.operatingCarrier;
    if (oper == null && this.tedsIdentifier != null) {
      oper = this.tedsIdentifier.substring(0, 2);
      if (oper == 'SK' && this.tedsIdentifier.substring(2, 3) == '3') {
        // Codeshare
        oper = null;
      }
    }
    return oper;
  }

  public class ResponsibilityException extends Exception {
  }

  public Boolean getEligibilityBasedOnProactivities(
    Set<Proactivity__c> proactivities
  ) {
    // Check the EU261_Eligibility__c for the proactivities connected to the flight.
    // If one of the proactivities is tentative or the proactivities are mixed, throw an exception.
    // If are the same (yes or no), return that value.
    String EU261Eligibility = proactivities.iterator()
      .next()
      .EU261_Eligibility__c;
    for (Proactivity__c proactivity : proactivities) {
      if (proactivity.EU261_Eligibility__c != EU261Eligibility) {
        throw new ResponsibilityException(
          'Proactivities connected to the flight have mixed EU261_Eligibility__c values.'
        );
      }
    }

    switch on EU261Eligibility {
      when 'Yes' {
        return true;
      }
      when 'No' {
        return false;
      }
      when 'Tentative' {
        throw new ResponsibilityException(
          'Proactivities connected to the flight have tentative EU261_Eligibility__c values'
        );
      }
      when else {
        throw new ResponsibilityException(
          'Proactivities connected to the flight have invalid EU261_Eligibility__c values'
        );
      }
    }
  }

  public Boolean cancellationIsWithinSASControl(
    Set<Proactivity__c> proactivities
  ) {
    if (this.irregularities == null || this.irregularities.size() == 0) {
      throw new ResponsibilityException(
        'Claim flight has no valid irregularities.'
      );
    }

    Boolean hasCancellation = false;
    for (FlightIrregularity fi : this.irregularities) {
      if (fi.getType() == FlightIrregularity.IrregularityType.CANCELLATION) {
        hasCancellation = true;
      }
    }

    if (hasCancellation && this.irregularities.size() > 1) {
      throw new ResponsibilityException(
        'Cancelled flight has more than one irregularity.'
      );
    }

    if (proactivities != null && proactivities.size() > 0) {
      return getEligibilityBasedOnProactivities(proactivities);
    }

    return this.irregularities[0].isWithinSASControl();
  }

  private Integer calculateArrivalDelay() {
    if (this.actualArrivalTime != null) {
      Integer minutesBetween = DateUtils.getMinutesBetween(
        this.scheduledArrivalTime,
        this.actualArrivalTime
      );
      if (this.scheduledArrivalTime < this.actualArrivalTime) {
        return minutesBetween;
      }
    }

    return 0;
  }

  /**
   * This is for double-checking. TODO: remove when EU261 calculation is more stable.
   */
  public Integer getTotalIrregularityDelay() {
    Integer totalIrregularityDelay = 0;
    for (FlightIrregularity fi : irregularities) {
      switch on fi.getType() {
        when DELAY {
          totalIrregularityDelay += Integer.valueOf(fi.durationMinutes);
        }
        when INVALID {
          throw new FlightException(
            'Invalid irregularity type: ' + fi.getType()
          );
        }
      }
    }
    return totalIrregularityDelay;
  }

  public Boolean hasMixedDelays() {
    Boolean hasEUYESDelay = false;
    Boolean hasEUNoDelay = false;
    for (FlightIrregularity fi : irregularities) {
      if (fi.getType() != FlightIrregularity.IrregularityType.Delay) {
        continue;
      }

      try {
        if (fi.isWithinSASControl()) {
          hasEUYESDelay = true;
        } else {
          hasEUNoDelay = true;
        }
      } catch (FlightIrregularity.IrregularityException e) {
        return true; // Tentative
      }
    }

    return hasEUYESDelay && hasEUNoDelay;
  }

  // We currently ignore special cases such as the "deicing 8+ minute"-rule.
  public Integer getDelayedMinutesWithinOperatorsControl(
    Set<Proactivity__c> proactivities
  ) {
    if (arrivalDelayedMinutes == null) {
      arrivalDelayedMinutes = 0;
    }

    if (calculateArrivalDelay() != arrivalDelayedMinutes) {
      throw new FlightException(
        'Flight arrival delay is not equal to the calculated arrival delay'
      );
    }

    if (proactivities != null && proactivities.size() > 0) {
      Boolean proactivityEligibility = getEligibilityBasedOnProactivities(
        proactivities
      );
      if (proactivityEligibility) {
        return Integer.valueOf(arrivalDelayedMinutes);
      } else {
        return 0;
      }
    }

    Boolean hasCancellation = false;
    Decimal totalIrregularityDelay = 0;
    Decimal delayWithinOperatorsControl = 0;
    for (FlightIrregularity fi : irregularities) {
      switch on fi.getType() {
        when DELAY {
          if (fi.isWithinSASControl()) {
            delayWithinOperatorsControl += fi.durationMinutes;
          }
          totalIrregularityDelay += fi.durationMinutes;
        }
        when CANCELLATION {
          hasCancellation = true;
        }
        when INVALID {
          throw new FlightException('Flight has an invalid irregularity');
        }
      }
    }

    Decimal finalDelay = Math.min(
      arrivalDelayedMinutes,
      delayWithinOperatorsControl
    ); // If we flew in time

    if (hasCancellation && arrivalDelayedMinutes > 0) {
      throw new FlightException('Flight has both cancellations and delays');
    } else if (arrivalDelayedMinutes > totalIrregularityDelay + 60) {
      // NOTE: Delays without irregularities are typically in-flight, which is not covered by EU261 (SAS interpretation)
      throw new FlightException(
        'There is a large delay which is not accounted for by the irregularities'
      );
    } else if (totalIrregularityDelay - arrivalDelayedMinutes > 120) {
      throw new FlightException(
        'We flew in more than 2 hours, likely incorrect data'
      );
    }

    return Integer.valueOf(finalDelay);
  }

  public String getReadableDelayExplanation() {
    if (irregularities == null) {
      throw new MissingDataException('Irregularities have not been set');
    }

    List<String> explanation = new List<String>();

    explanation.add(
      String.format(
        tedsIdentifier + 'Net delay: {0} min ({1})',
        new List<Object>{ calculateArrivalDelay(), arrivalDelayedMinutes }
      )
    );

    String delayTemplate = '{0} ({1} min)';
    Decimal delayAccountedFor = 0;
    for (FlightIrregularity fi : irregularities) {
      if (!fi.isDelay()) {
        continue;
      }

      delayAccountedFor += fi.durationMinutes;
      explanation.add(
        String.format(
          delayTemplate,
          new List<Object>{ fi.code, fi.durationMinutes }
        )
      );
    }

    String difference = String.valueOf(
      arrivalDelayedMinutes - delayAccountedFor
    );

    if (difference.contains('-')) {
      difference = difference.substringAfter('-');
      difference = 'Irrs > delay (' + difference + ')';
    } else {
      difference = 'Irrs < delay (' + difference + ')';
    }

    explanation.add(
      0,
      String.format(
        '{0} min, Irr tot: {1} min',
        new List<Object>{ difference, delayAccountedFor }
      )
    );

    return String.join(explanation, ', ');
  }

  /**
   * @return a String with an explanation which of the irregularities SAS is not responsible for.
   * NOTE: when this encounters tentative delays it just ignores it! (by design)
   * TODO: potentially add getExplanation() instead of code
   * TODO: Handle proactivities which might affect this
   */
  public String getOutsideSASControlExplanationDelay() {
    Decimal totalDelayOutsideSASControl = 0;
    Decimal totalIrregularityDelay = 0;
    Decimal totalTentativeDelay = 0;
    String explanation = 'SAS is not responsible for delays which occur in flight and delay(s) with reason code(s): ';
    for (FlightIrregularity f : irregularities) {
      Boolean SASisResponsible;
      try {
        SASisResponsible = f.isWithinSASControl();
      } catch (FlightIrregularity.IrregularityException e) {
        totalTentativeDelay += f.durationMinutes;
        totalIrregularityDelay += f.durationMinutes;
        continue;
      }

      if (!SASisResponsible) {
        totalDelayOutsideSASControl += f.durationMinutes;
        explanation += f.code + ' (' + f.durationMinutes + ' minutes), ';
      }
      totalIrregularityDelay += f.durationMinutes;
    }

    if (totalIrregularityDelay < arrivalDelayedMinutes) {
      totalDelayOutsideSASControl +=
        arrivalDelayedMinutes - totalIrregularityDelay;
      explanation +=
        'Delays occuring after pushback (' +
        (arrivalDelayedMinutes - totalIrregularityDelay) +
        ' minutes), ';
    }

    explanation += '(Total: ' + totalDelayOutsideSASControl + ' minutes)';

    if (totalDelayOutsideSASControl == 0) {
      return null;
    }

    return explanation;
  }

  public Integer compareTo(Object other) {
    Flight otherFlight = (Flight) other;
    if (otherFlight.scheduledDepartureTime < this.scheduledDepartureTime) {
      return 1;
    } else if (
      otherFlight.scheduledDepartureTime > this.scheduledDepartureTime
    ) {
      return -1;
    } else {
      return 0;
    }
  }
}
