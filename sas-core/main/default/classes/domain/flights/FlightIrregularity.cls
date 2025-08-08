public without sharing class FlightIrregularity extends AbstractSObjectWrapper implements Comparable {
  public FlightIrregularities__c underlyingSObject { get; private set; }

  public DateTime cancellationTime;
  public String code;
  public String description;
  public Decimal durationMinutes;
  public EU261Eligibility eligibleForEU261;
  public String flightId;
  public String nameC;
  public String reason;
  public String type;

  public class IrregularityException extends Exception {
  }

  public class IrregularityTypeException extends Exception {
  }

  public class UnknownIrregularityException extends Exception {
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Cancellation_Time__c = this.cancellationTime;
    this.underlyingSObject.Code__c = this.code;
    this.underlyingSObject.Description__c = this.description;
    this.underlyingSObject.Duration_minutes__c = this.durationMinutes;
    this.underlyingSObject.Eligible_For_EU261__c = EU261_ENUM_TO_PICKLIST_VALUE.get(
      this.eligibleForEU261
    );
    this.underlyingSObject.Flight__c = this.flightId;
    this.underlyingSObject.Name__c = this.nameC;
    this.underlyingSObject.Reason__c = this.reason;
    this.underlyingSObject.Type__c = this.type;
  }

  public enum EU261Eligibility {
    Tentative,
    Yes,
    No
  }

  private FlightIrregularity() {
    this.underlyingSObject = new FlightIrregularities__c();
  }

  public FlightIrregularity(FlightIrregularities__c fi) {
    super(fi);
    this.underlyingSObject = fi;

    this.cancellationTime = fi.Cancellation_Time__c;
    this.code = fi.Code__c;
    this.description = fi.Description__c;
    this.durationMinutes = fi.Duration_minutes__c;
    this.eligibleForEU261 = EU261_PICKLIST_VALUE_TO_ENUM.get(
      fi.Eligible_For_EU261__c
    );
    this.flightId = fi.Flight__c;
    this.nameC = fi.Name__c;
    this.reason = fi.Reason__c;
    this.type = fi.Type__c;
  }

  public enum CODE {
  } // TODO

  public enum IrregularityType {
    CANCELLATION,
    DELAY,
    INVALID
  }

  /**
   * All keywords and their responsibility. In a class to avoid loading the whole
   * list into memory every time.
   *
   * If isResponsible is null, the responsibility is tentative.
   *
   * The explanations should fit in a sentence like this:
   * "...was cancelled/delayed because of EXPLANATION. This is an event outside SAS control..."
   */
  public class KeywordResponsibility {
    public EU261Eligibility eligibility { get; set; }
    public String explanation { get; set; }
    public List<String> keywords { get; set; }

    public KeywordResponsibility(
      EU261Eligibility eligibility,
      String explanation,
      List<String> keywords
    ) {
      this.eligibility = eligibility;
      this.explanation = explanation;
      this.keywords = keywords;
    }
  }

  public static final List<KeywordResponsibility> keyWordResponsibilities = new List<KeywordResponsibility>{
    new KeywordResponsibility(
      EU261Eligibility.Yes,
      'damage related to ground handling',
      new List<String>{ 'GROUND DAMA', 'DAMA ON GROUND' }
    ),
    new KeywordResponsibility(
      EU261Eligibility.No,
      'a bird strike on the aircraft assigned to your flight',
      new List<String>{ 'BIRD STRIKE', 'BIRDSTRIKE' }
    ),
    new KeywordResponsibility(
      EU261Eligibility.No,
      'a lightning strike on the aircraft assigned to your flight',
      new List<String>{ 'LIGHTNING STRIKE', 'LIGHTNINGSTRIKE' }
    ),
    new KeywordResponsibility(
      EU261Eligibility.No,
      'adverse weather conditions',
      new List<String>{
        'THUNDER',
        'THUNDERSTORM',
        'WIND',
        'HAIL',
        'SNOW',
        'ICE',
        'FOG',
        'SMOG',
        'SMOKE',
        'ASH',
        'VOLCANO',
        'ERUPTION',
        'EARTHQUAKE',
        'TORNADO',
        'HURRICANE',
        'CYCLONE',
        'TYPHOON',
        'TROPICAL STORM',
        'STORM',
        'FLOOD',
        'VISIBILITY',
        'VIS',
        'TS'
      }
    )
  };

  public static List<KeywordResponsibility> getMatchingKeywords(String reason) {
    if (reason == null) {
      return new List<KeywordResponsibility>();
    }

    Map<Pattern, KeywordResponsibility> patternToResponsibility = new Map<Pattern, KeywordResponsibility>();
    for (KeywordResponsibility responsibility : keyWordResponsibilities) {
      Pattern responsibilityPattern = Pattern.compile(
        String.format(
          '\\b{0}\\b',
          new List<String>{ String.join(responsibility.keywords, '\\b|\\b') }
        )
      );
      patternToResponsibility.put(responsibilityPattern, responsibility);
    }

    String upperCaseReason = reason.toUpperCase();
    List<KeywordResponsibility> matchingKeywords = new List<KeywordResponsibility>();
    for (Pattern p : patternToResponsibility.keySet()) {
      Matcher m = p.matcher(upperCaseReason);
      if (m.find()) {
        matchingKeywords.add(patternToResponsibility.get(p));
      }
    }

    return matchingKeywords;
  }

  // This should likely be stored in CancellationCode.globalValueSet. However, db calls makes that very annoying.
  // TODO: Populate, get help from liability: https://docs.google.com/spreadsheets/d/1lo-pu7Ew-f-5z18Ke51962j_VZkI9FfA8kYiKTFUw5o/edit#gid=801456937
  public static final Map<String, Boolean> codeToSASIsResponsible = new Map<String, Boolean>{
    'WEAT' => false,
    'TECH' => true,
    'CREW' => true,
    'AE' => false,
    '83' => false,
    'AF' => false,
    '87' => false,
    'AG' => false,
    '86' => false,
    'AM' => false,
    '89' => false,
    'AT' => false,
    '81' => false,
    'AW' => false,
    '84' => false,
    'AX' => false,
    '82' => false,
    'CA' => true,
    '29' => true,
    'CC' => true,
    '23' => true,
    'CD' => true,
    '21' => true,
    'CE' => true,
    '27' => true,
    'CI' => false,
    '24' => false,
    'CL' => true,
    '28' => true,
    'CO' => true,
    '25' => true,
    'CP' => true,
    '22' => true,
    'D' => false,
    'DF' => false,
    '51' => false,
    'EC' => true,
    '56' => true,
    'ED' => true,
    '55' => true,
    'EF' => true,
    '57' => true,
    'EO' => true,
    '58' => true,
    'FA' => true,
    '68' => true,
    'FB' => false,
    '69' => false,
    'FL' => true,
    '66' => true,
    'FP' => true,
    '61' => true,
    'FR' => true,
    '65' => true,
    'FT' => true,
    '63' => true,
    'GB' => true,
    '37' => true,
    'GE' => true,
    '33' => true,
    'GF' => true,
    '36' => true,
    'GL' => true,
    '32' => true,
    'GS' => true,
    '34' => true,
    'GT' => true,
    '39' => true,
    'GU' => true,
    '38' => true,
    'HL' => true,
    '02' => true,
    'MI' => false,
    '97' => false,
    'MO' => false,
    '98' => false,
    'OA' => true,
    '06' => true,
    'PB' => true,
    '18' => true,
    'PC' => true,
    '17' => true,
    'PD' => true,
    '11' => true,
    'PE' => true,
    '13' => true,
    'RL' => true,
    '91' => true,
    'RT' => false,
    '92' => false,
    'SK' => true,
    '01' => true,
    'TA' => true,
    '45' => true,
    'TL' => true,
    '47' => true,
    'TM' => true,
    '42' => true,
    'TS' => true,
    '44' => true,
    'TV' => true,
    '48' => true,
    'WG' => false,
    '77' => false,
    'WO' => false,
    '71' => false,
    'WR' => false,
    '73' => false,
    'WS' => false,
    '76' => false,
    'WT' => false,
    '72' => false,
    '49' => true
  };

  private static final Set<String> ROTATION_CODES = new Set<String>{
    'RA',
    '93',
    'RC',
    '95',
    'RS',
    '94'
  };

  private static final Set<String> CANCELLATION_CODES = new Set<String>{
    'AIRS',
    'ARPT',
    'AUTH',
    'COMM',
    'CREW',
    'DAMA',
    'EQUI',
    'FUEL',
    'HDLG',
    'HOLI',
    'INDU',
    'NODE',
    'OPCO',
    'OPER',
    'PERF',
    'POLI',
    'REPO',
    'RTNS',
    'RUNW',
    'TECH',
    'WEAT'
  };

  private static final Set<String> DELAY_CODES = new Set<String>{
    'AE',
    '83',
    'AF',
    '87',
    'AG',
    '86',
    'AM',
    '89',
    'AS',
    '85',
    'AT',
    '81',
    'AW',
    '84',
    'AX',
    '82',
    'CA',
    '29',
    'CC',
    '23',
    'CD',
    '21',
    'CE',
    '27',
    'CI',
    '24',
    'CL',
    '28',
    'CO',
    '25',
    'CP',
    '22',
    'CU',
    '26',
    'D',
    'DF',
    '51',
    'DG',
    '52',
    'EC',
    '56',
    'ED',
    '55',
    'EF',
    '57',
    'EO',
    '58',
    'FA',
    '68',
    'FB',
    '69',
    'FC',
    '67',
    'FF',
    '62',
    'FL',
    '66',
    'FP',
    '61',
    'FR',
    '65',
    'FS',
    '64',
    'FT',
    '63',
    'GB',
    '37',
    'GC',
    '35',
    'GD',
    '31',
    'GE',
    '33',
    'GF',
    '36',
    'GL',
    '32',
    'GS',
    '34',
    'GT',
    '39',
    'GU',
    '38',
    'HL',
    '02',
    'MI',
    '97',
    'MO',
    '98',
    'MX',
    '99',
    'OA',
    '06',
    'PB',
    '18',
    'PC',
    '17',
    'PD',
    '11',
    'PE',
    '13',
    'PF',
    '03',
    'PH',
    '15',
    'PL',
    '12',
    'PO',
    '14',
    'PS',
    '16',
    'PW',
    '19',
    'RA',
    '93',
    'RC',
    '95',
    'RL',
    '91',
    'RO',
    '96',
    'RS',
    '94',
    'RT',
    '92',
    'RX',
    '04',
    'SK',
    '01',
    'TA',
    '45',
    'TC',
    '46',
    'TD',
    '41',
    'TL',
    '47',
    'TM',
    '42',
    'TN',
    '43',
    'TS',
    '44',
    'TV',
    '48',
    'WG',
    '77',
    'WI',
    '75',
    'WO',
    '71',
    'WR',
    '73',
    'WS',
    '76',
    'WT',
    '72',
    '49',
    '07'
  }; // Note! Does not contain subcode, e.g. WI01, TV02 etc.

  private static final Map<String, String> codeToExplanation = new Map<String, String>{
    'AIRS' => 'airspace restrictions',
    'ARPT' => 'airport restrictions',
    'AUTH' => 'a diversion caused by ATC, security control or local authorities',
    'COMM' => 'commercial reasons',
    'CREW' => 'crew shortage',
    'DAMA' => 'damage to the aircraft',
    'EQUI' => 'equipment short-falls',
    'FUEL' => 'fuel related reasons',
    'HDLG' => 'a ground staff and/or handling agent shortage',
    'HOLI' => 'the holiday season',
    'INDU' => 'industrial action',
    'NODE' => 'reduced or no commercial demand',
    'OPCO' => 'operational conditions causing timetable changes',
    'OPER' => 'operational conditions causing timetable changes',
    'PERF' => 'the aircraft being unable to perform the specific flight',
    'POLI' => 'political unrest, war, or war-like situations, etc.',
    'REPO' => 'aircraft repositioning',
    'RTNS' => 'a flight scheduling anomaly',
    'RUNW' => 'technical restrictions of a runway',
    'TECH' => 'technical issues',
    'WEAT' => 'weather conditions. Cancellations due to weather can happen for several reasons, for example, heavy storms, icy conditions, low visibility, strong winds, or even diversions or cancellations of previous flights which impacted our ability to fulfill regular operations'
  }; // TODO: Check with liability and process owners that this is ok

  private static final Map<String, EU261Eligibility> EU261_PICKLIST_VALUE_TO_ENUM = new Map<String, EU261Eligibility>{
    'Tentative' => EU261Eligibility.Tentative,
    'Yes' => EU261Eligibility.Yes,
    'No' => EU261Eligibility.No
  };

  private static final Map<EU261Eligibility, String> EU261_ENUM_TO_PICKLIST_VALUE = new Map<EU261Eligibility, String>{
    EU261Eligibility.Tentative => 'Tentative',
    EU261Eligibility.Yes => 'Yes',
    EU261Eligibility.No => 'No'
  };

  public String getExplanation() {
    if (this.description != null && this.description != '') {
      return this.description;
    }

    String explanation = codeToExplanation.get(this.code);
    if (explanation == null) {
      explanation = 'code "' + this.code + '"'; // Should not happen
    }
    return explanation;
  }

  public String getOutsideControlExplanationCancellation() {
    String explanation = 'The flight was cancelled because of '; // TODO: improve
    explanation += getExplanation();
    explanation += ', which is not within SAS control.';

    return explanation;
  }

  public Boolean isRotation() {
    return ROTATION_CODES.contains(this.code);
  }

  public Boolean isCancellation() {
    return getType() == IrregularityType.CANCELLATION;
  }

  public Boolean isDelay() {
    return getType() == IrregularityType.DELAY;
  }

  public Boolean isInvalid() {
    return getType() == IrregularityType.INVALID;
  }

  public IrregularityType getType() {
    Boolean hasCancellationCode = CANCELLATION_CODES.contains(this.code);
    Boolean hasDelayCode = DELAY_CODES.contains(this.code);
    if (
      this.code != null &&
      this.code.length() == 4 &&
      this.code.substring(2, 4).isNumeric()
    ) {
      hasDelayCode = DELAY_CODES.contains(this.code.substring(2, 4));
    }

    if (hasDelayCode) {
      return IrregularityType.DELAY;
    } else if (hasCancellationCode) {
      return IrregularityType.CANCELLATION;
    }

    if (this.code == 'N/A' || this.code == null || this.code == '') {
      if (
        this.cancellationTime != null &&
        this.cancellationTime > DateTime.newInstance(1950, 1, 1)
      ) {
        // If the cancellationtime exist and is not invalid, it is a kind of valid cancellation
        return IrregularityType.CANCELLATION;
      } else if (this.durationMinutes != null && this.durationMinutes > 0) {
        // If the duration exisits and is more than 0, it is a kind of valid delay
        return IrregularityType.DELAY;
      } else if (
        (this.type.toLowerCase().contains('cancellation') ||
        this.type.toLowerCase().contains('cancelled')) &&
        !this.type.toLowerCase().contains('arrival')
      ) {
        // Special case, cancellation departure with no code or cancellation time
        throw new UnknownIrregularityException(
          'Unable to identify irregularity (' +
          this.id +
          ')'
        );
      } else {
        // Cancellation N/A "arrival" with no cancellation time and delays without
        // a code or duration minutes get here.
        return IrregularityType.INVALID;
      }
    }

    throw new UnknownIrregularityException(
      String.format(
        'Unknown irregularity code: {0} ({1})',
        new List<Object>{ this.code, this.id }
      )
    );
  }

  public void setEligibility() {
    // Check code
    this.eligibleForEU261 = getEligibilityBasedOnCode();
    if (this.eligibleForEU261 != EU261Eligibility.Tentative) {
      return;
    }

    // Check reason
    List<KeywordResponsibility> matchingKeywords = getMatchingKeywords(
      this.reason
    );

    if (matchingKeywords.size() != 1) {
      return; // If more than one we should try to combine them in the future
    }

    KeywordResponsibility responsibility = matchingKeywords[0];
    this.eligibleForEU261 = responsibility.eligibility;
    this.description = responsibility.explanation;
  }

  private EU261Eligibility getEligibilityBasedOnCode() {
    Boolean isResponsible = codeToSASIsResponsible.get(this.code);
    if (isResponsible == null) {
      return EU261Eligibility.Tentative;
    } else if (isResponsible) {
      return EU261Eligibility.Yes;
    } else {
      return EU261Eligibility.No;
    }
  }

  public Boolean isWithinSASControl() {
    Boolean SASIsResponsible;

    switch on this.eligibleForEU261 {
      when Yes {
        SASIsResponsible = true;
      }
      when No {
        SASIsResponsible = false;
      }
      when else {
        SASIsResponsible = codeToSASIsResponsible.get(this.code);
      }
    }

    if (SASIsResponsible == null) {
      throw new IrregularityException(
        'Cannot determine whether SAS is within control or not.'
      );
    }

    return SASisResponsible;
  }

  /**
   * Returns a new list with all duplicates from the given list removed.
   */
  public static List<FlightIrregularity> unique(
    List<FlightIrregularity> irregularities
  ) {
    List<FlightIrregularity> toReturn = new List<FlightIrregularity>{};

    for (FlightIrregularity fi : irregularities) {
      if (!toReturn.contains(fi)) {
        toReturn.add(fi);
      }
    }

    return toReturn;
  }

  public Boolean equals(Object compareTo) {
    FlightIrregularity otherIrregularity = (FlightIrregularity) compareTo;

    if (
      this.code == otherIrregularity.code &&
      this.flightId == otherIrregularity.flightId &&
      this.reason == otherIrregularity.reason &&
      this.durationMinutes == otherIrregularity.durationMinutes &&
      this.type == otherIrregularity.type &&
      this.description == otherIrregularity.description &&
      this.cancellationTime == otherIrregularity.cancellationTime
    ) {
      return true;
    } else {
      return false;
    }
  }

  public Integer compareTo(Object other) {
    FlightIrregularity otherIrregularity = (FlightIrregularity) other;
    if (otherIrregularity.cancellationTime < this.cancellationTime) {
      return 1;
    } else if (otherIrregularity.cancellationTime > this.cancellationTime) {
      return -1;
    } else {
      return 0;
    }
  }
}
