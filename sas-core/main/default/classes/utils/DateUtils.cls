/**
 * Utility class which handles dates
 */
public without sharing class DateUtils {
  private static final Map<String, Integer> COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS = new Map<String, Integer>{
    'BE' => 12,
    'DK' => 3 * 12,
    'FI' => 3 * 12,
    'FR' => 5 * 12,
    'DE' => 3 *
    12, // TODO: Change to 2 years + time until end of year 3 (e.g. 25 months 2022-12 -> 2024-12-31)
    'IT' => 2 * 12,
    'NL' => 5 * 12,
    'NO' => 3 * 12,
    'PL' => 12,
    'ES' => 5 * 12,
    'SE' => 2,
    'UK' => 6 * 12,
    'IE' => 6 * 12,
    'LV' => 6,
    'default' => 3 * 12
  };

  public static Integer getClaimTimeLimitInMonths(String countryCode) {
    Integer monthTimeLimit = COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS.get(
      countryCode
    );

    if (monthTimeLimit == null) {
      if (CountryUtils.isInEUOrNorwaySwitzerlandIceland(countryCode)) {
        monthTimeLimit = COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS.get('default');
      } else {
        monthTimeLimit = 2;
      }
    }

    return monthTimeLimit;
  }

  public class DurationTooLongException extends Exception {
  }

  /**
   * Tries to parse a date from a flightId (String). If it fails the function returns null
   * @param flightId A String with the flight Id, typically with the type "SK1-20220101" or "SK1-2022-01-01"
   *
   * @return The Date parsed from the flight id or null.
   */
  public static Date parseDateFromFlightId(String flightId) {
    // Move to Flights domain
    String flightDate = flightId.substringAfter('-');
    Date cleanDate;
    try {
      // If flightId ~= SK1-2022-01-01 or SK1-2022/01/01
      cleanDate = Date.parse(flightDate);
    } catch (Exception e1) {
      try {
        // If flightId ~= SK1-20220101
        cleanDate = Date.newInstance(
          Integer.valueOf(flightDate.substring(0, 4)),
          Integer.valueOf(flightDate.substring(4, 6)),
          Integer.valueOf(flightDate.substring(6, 8))
        );
      } catch (Exception e2) {
        // Return null
      }
    }

    return cleanDate;
  }

  /**
   * Calculates whether there is X years or less between two datetimes.
   * Used to determine whether a claim has been filed in time to be eligable for EU261 compensation.
   *
   * @param datetime1
   * @param datetime2
   * @param timeLimitYears a decimal with the time limit in years before a customer is no longer eligable for compensation.
   *
   * @return true if there is X years or less difference between the two datetimes.
   */
  public static Boolean areWithinTimeLimit( // Move to somewhere, - Nathan: Now a bit more general, this seems like an ok place?
    Datetime datetime1,
    Datetime datetime2,
    Decimal timeLimitYears
  ) {
    Date date1 = datetime1.date();
    Date date2 = datetime2.date();
    Integer dayDelta = date1.daysBetween(date2);
    if (Math.abs(dayDelta) > Math.round(timeLimitYears * 365.25 + 1)) {
      return false;
    }

    return true;
  }

  /**
   * @param datetime1
   * @param datetime2
   *
   * Calculates whether there is 24 hours or more between two datetimes.
   * Used to determine whether a destinaiton should be considered a final destination or not.
   */
  public static Boolean isMoreThan24HoursBetween(
    Datetime datetime1,
    Datetime datetime2
  ) {
    Decimal hourDelta = getHoursBetween(datetime1, datetime2);

    if (hourDelta > 24.0) {
      return true;
    }
    return false;
  }

  public static Decimal getHoursBetween(
    Datetime datetime1,
    Datetime datetime2
  ) {
    return getMinutesBetween(datetime1, datetime2) / 60;
  }

  public static Integer getMinutesBetween(
    Datetime datetime1,
    Datetime datetime2
  ) {
    Decimal millisecondDelta = Math.abs(
      datetime1.getTime() - datetime2.getTime()
    );
    Decimal minuteDelta = millisecondDelta / 60000;
    return minuteDelta.intValue();
  }

  /**
   * Converts a TEDS duration into an Apex Integer which represents the duration in minutes.
   * ISO 8601 duration has the form: P(n)Y(n)M(n)DT(n)H(n)M(n)S.
   * Source: https://www.digi.com/resources/documentation/digidocs/90001437-13/reference/r_iso_8601_duration_format.htm
   *
   * @param duration A String which holds the duration received from TEDS
   *
   * @throws DurationTooLongException When the duration contains years or months.
   *
   * @return An Apex Integer containing the the time in minutes converted from the duration.
   */
  public static Integer convertISO8601DurationToMinutes(String duration) {
    if (duration == null) {
      return 0;
    }
    List<Integer> characters = duration.getChars();
    Integer count = 0;
    Integer minutes = 0;
    Boolean isDate = true;
    for (Integer character : characters) {
      if (47 < character && character < 58) {
        count = 10 * count + character - 48;
      }
      if (character == 89) {
        // Year
        throw new DurationTooLongException('Duration contains years.'); // Because of time ambiguity
      }
      if (character == 77 && isDate) {
        // Month
        throw new DurationTooLongException('Duration contains months.'); // Because of time ambiguity
      }
      if (character == 68) {
        // Day
        minutes += count * 24 * 60; // Convert days to hours
        count = 0;
      }
      if (character == 84) {
        // T (the next m stands for "minutes" not "months")
        isDate = false;
      }
      if (character == 72) {
        // Hour
        minutes += count * 60;
        count = 0;
      }
      if (character == 77 && !isDate) {
        // Minute
        minutes += count;
        count = 0;
      }
    }

    return minutes;
  }

  /**
   * Matches:
   *  2021-10-13T04:13:00+01:00
   *  2021-10-13T12:13:00-08:00
   *  2021-10-13T12:13:00
   * Non-Matches:
   *  2021-10-13
   *
   * @param datetimeString String to validate
   *
   * @return true/false if it matches
   */
  public static Boolean isValidIsoDatetime(String datetimeString) {
    Boolean isValid = false;
    Pattern validIsoDatetime = Pattern.compile(
      '^\\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\d(\\.\\d+)?(([+-]\\d\\d:\\d\\d)|Z)?$'
    );
    if (validIsoDatetime.matcher(datetimeString).matches()) {
      isValid = true;
    }
    return isValid;
  }

  /**
   * @param datetimeString A String like: 2021-10-13T12:13:00
   *
   * @return The corresponding Apex Datetime
   */
  public static Datetime isoDatetimeToApexDateTime(String isoDateTime) {
    return (Datetime) json.deserialize('"' + isoDateTime + '"', Datetime.class);
  }

  public static Datetime verifyDatetime(Datetime toVerify) {
    //1970-01-01
    Datetime toCompare = Datetime.newInstance(0);
    return verifyDatetime(toVerify, toCompare);
  }

  /**
   * Verifies if a specific Datetime falls after a certain comparison Datetime
   * @param toVerify The Datetime to verify
   * @param toCompare The Datetime that should be used as a reference
   */
  public static Datetime verifyDatetime(Datetime toVerify, Datetime toCompare) {
    U.verifyNotNull(toVerify);
    U.verifyNotNull(toCompare);
    Boolean isReasonable = toVerify.getTime() > toCompare.getTime();
    return isReasonable ? toVerify : null;
  }

  public static Datetime convertTimestampToDatetime(Long toVerify) {
    //1970-01-01
    Long toCompare = 0L;
    return convertTimestampToDatetime(toVerify, toCompare);
  }
  /**
   * Verifies if a specific Unix timestamp falls after a certain comparison timestamp
   * @param toVerify The Unix timestamp to verify
   * @param toCompare The Unix timestamp that should be used as a reference
   */
  public static Datetime convertTimestampToDatetime(
    Long toVerify,
    Long toCompare
  ) {
    U.verifyNotNull(toVerify);
    U.verifyNotNull(toCompare);
    Boolean isReasonable = toVerify > toCompare;
    return isReasonable ? Datetime.newInstance(toVerify) : null;
  }

  public static Datetime convertRACERDateToDatetime(String toConvert) {
    // 01/28/2022 01:00:00 -> Datetime

    // Split the date and time components
    List<String> dateAndTime = toConvert.split(' ');
    List<String> dateParts = dateAndTime[0].split('/');
    List<String> timeParts = dateAndTime[1].split(':');

    DateTime dt;

    try {
      dt = DateTime.newInstanceGmt(
        Integer.valueOf(dateParts[2]), // year
        Integer.valueOf(dateParts[0]), // month
        Integer.valueOf(dateParts[1]), // day
        Integer.valueOf(timeParts[0]), // hour
        Integer.valueOf(timeParts[1]), // minute
        Integer.valueOf(timeParts[2]) // second
      );
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        'Failed to parse RACER-file date',
        e.getStackTraceString(),
        'RACER',
        null
      );
      throw e;
    }

    return dt;
  }
}
