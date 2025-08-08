/**
 * Utility class which contains various small tools for working within the HTTP
 * layer.
 */
public without sharing class StringUtils {
  /**
   * Constructs a query parameter string from a list of (name, value) parameter tuples.
   * Does not url encode the string.
   *
   * @param params A list of (name, value) tuples of query params. Can be repeated.
   * @return Input parameters as a string of query parameters which can be appended to a url.
   */
  public static Boolean isEmailAddress(String s) {
    if (s == null) {
      return false;
    }

    Pattern emailPattern = Pattern.compile(
      '([a-zA-Z0-9_\\-\\.\\+]+)@((\\[a-z]{1,}\\.[a-z]{1,}\\.[a-z]{1,}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,}|[0-9]{1,})'
    );

    Matcher emailMatcher = emailPattern.matcher(s);

    return emailMatcher.matches();
  }

  /**
   * Removes all whitespace from the given string and returns the result.
   */
  public static String removeWhitespace(String s) {
    if (s == null) {
      return null;
    }

    return s.replaceAll('[\\s\u00A0\u200B-\u200D\uFEFF]+', '');
  }

  /**
   * Converts scandics to one-letter forms.
   *
   * @param s String to sanitize
   */
  public static String scandicsToASCII(String s) {
    return s.replaceAll('ä', 'a')
      .replaceAll('Ä', 'A')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'O')
      .replaceAll('ø', 'o')
      .replaceAll('Ø', 'O')
      .replaceAll('æ', 'a')
      .replaceAll('Æ', 'A')
      .replaceAll('å', 'o')
      .replaceAll('Å', 'o');
  }
  /**
   * Removes accents and special characters.
   *
   * @param s String to sanitize
   */
  public static String removeSpecialCharacters(String s) {
    return s.replaceAll('á', 'a')
      .replaceAll('Á', 'A')
      .replaceAll('ú', 'u')
      .replaceAll('Ú', 'U')
      .replaceAll('í', 'i')
      .replaceAll('Í', 'I')
      .replaceAll('é', 'e')
      .replaceAll('É', 'E')
      .replaceAll('ó', 'o')
      .replaceAll('Ó', 'O')
      .replaceAll('ñ', 'n')
      .replaceAll('Ñ', 'N')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'C')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'U')
      .replaceAll('ß', 's');
  }
  /**
   * Sanitizes a string by removing all whitespace and special characters.
   *
   * @param s String to sanitize
   */
  public static String sanitize(String s) {
    if (s == null) {
      return null;
    }
    return removeSpecialCharacters(scandicsToASCII(removeWhitespace(s)));
  }

  public static String sanitizeWithoutRemovingSpaces(String s) {
    if (s == null) {
      return null;
    }
    return removeSpecialCharacters(scandicsToASCII(s));
  }

  /**
   * Returns a date with the form XXXXYYZZ
   */
  public static String dateToTEDSString(Date d) {
    String year = String.valueOf(d.year());
    String month = String.valueOf(d.month()).leftPad(2, '0');
    String day = String.valueOf(d.day()).leftPad(2, '0');
    return year + month + day;
  }

  /**
   * Returns a Date object from a TEDS Id
   */
  public static Date extractDateFromTEDSId(String tedsId) {
    String dateInfo = tedsId.substringAfter('-').substringBefore('-');

    if (dateInfo.length() != 8) {
      return null;
    }
    Integer year = Integer.valueOf(dateInfo.substring(0, 4));
    Integer month = Integer.valueOf(dateInfo.substring(4, 6));
    Integer day = Integer.valueOf(dateInfo.substring(6, 8));
    return Date.newInstance(year, month, day);
  }

  public static String dateToReadable(Date theDate) {
    if (theDate == null) {
      return '-';
    }
    String toReturn =
      String.valueOf(theDate.year()) +
      '-' +
      String.valueOf(theDate.month()) +
      '-' +
      String.valueOf(theDate.day());
    return toReturn;
  }

  public static String dateTimeToReadable(Datetime theDateTime) {
    if (theDateTime == null) {
      return '-';
    }
    String theDate = theDateTime.format('yyyy-MM-dd');
    String theTime = theDateTime.format('HH:mm'); // This re-converts the time dependent on time zone (bad, TODO: fix)
    return theDate + ' at ' + theTime;
  }

  private static final Set<String> supportedMergeFields = new Set<String>{
    'Case',
    'User',
    'Sender'
  };

  public static String populateMergeFields(String body, Case c, User sender) {
    // Pattern to identify merge fields. Assuming format is {!ObjectName.FieldName}
    Pattern p = Pattern.compile('\\{\\{\\{(\\w+)\\.(\\w+)\\}\\}\\}');
    Matcher m = p.matcher(body);

    while (m.find()) {
      String objectName = m.group(1);
      String fieldName = m.group(2);

      if (!supportedMergeFields.contains(objectName)) {
        // Log error
        continue;
      }

      String fieldValue;
      switch on objectName {
        when 'Case' {
          try {
            fieldValue = String.valueOf(c.get(fieldName));
          } catch (Exception e) {
            fieldValue = ''; // Would only happen if we introduce a new field on case or user and forget to the selector
          }
        }
        when 'User', 'Sender' {
          try {
            fieldValue = String.valueOf(sender.get(fieldName));
          } catch (Exception e) {
            fieldValue = ''; // Would only happen if we introduce a new field on case or user and forget to the selector
          }
        }
      }

      // Replace the merge field with the actual value
      body = body.replaceAll(
        '\\{\\{\\{' + objectName + '.' + fieldName + '\\}\\}\\}',
        fieldValue
      );
    }

    return body;
  }

  public static String formatTicketNumberForTEDS(String ticketNumber) {
    if (ticketNumber.length() != 13) {
      throw new IllegalArgumentException(
        'Ticket number must be 13 characters long'
      );
    }
    if (!ticketNumber.isNumeric()) {
      throw new IllegalArgumentException('Ticket number must be numeric');
    }
    return String.format(
      '{0}-{1}',
      new List<String>{
        ticketNumber.substring(0, 3),
        ticketNumber.substring(3)
      }
    );
  }
}
