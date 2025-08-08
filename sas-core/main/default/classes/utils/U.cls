/**
 * Generic utilities
 */
public without sharing class U {
  public class InvalidArgumentException extends Exception {
  }

  /**
   * Throws InvalidArgumentException if the given argument is null.
   */
  public static void verifyNotNull(Object arg) {
    if (arg == null) {
      throw new InvalidArgumentException('Required argument is null');
    }
  }

  /**
   * Throws InvalidArgumentException if any of the given arguments or the list of arguments is null.
   */
  public static void verifyNotNull(List<Object> args) {
    if (args == null) {
      throw new InvalidArgumentException('Required argument is null');
    }
    for (Object arg : args) {
      verifyNotNull(arg);
    }
  }

  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Blob getOr(Blob defaultValue, Blob toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Boolean getOr(Boolean defaultValue, Boolean toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Date getOr(Date defaultValue, Date toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static DateTime getOr(DateTime defaultValue, DateTime toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Decimal getOr(Decimal defaultValue, Decimal toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Double getOr(Double defaultValue, Double toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Id getOr(Id defaultValue, Id toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Integer getOr(Integer defaultValue, Integer toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Long getOr(Long defaultValue, Long toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Object getOr(Object defaultValue, Object toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static String getOr(String defaultValue, String toGet) {
    return toGet == null ? defaultValue : toGet;
  }
  /**
   * Returns the second value unless it is null. If it's null, returns the first value.
   */
  public static Time getOr(Time defaultValue, Time toGet) {
    return toGet == null ? defaultValue : toGet;
  }
}
