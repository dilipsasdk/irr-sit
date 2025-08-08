/**
 * Utility class which contains various small tools for working within the HTTP
 * layer.
 */
public without sharing class HttpUtils {
  public enum HTTP_METHOD {
    GET,
    POST
  }

  /**
   * Constructs a query parameter string from a list of (name, value) parameter tuples.
   * Does not url encode the string.
   *
   * @param params A list of (name, value) tuples of query params. Can be repeated.
   * @return Input parameters as a string of query parameters which can be appended to a url.
   */
  public static String constructQueryParamString(List<List<String>> params) {
    if (params == null || params.size() == 0) {
      return '';
    }

    String toReturn = '?';

    Boolean isFirst = true;
    for (List<String> param : params) {
      if (isFirst) {
        toReturn += param[0] + '=' + param[1];
        isFirst = false;
      } else {
        toReturn += '&' + param[0] + '=' + param[1];
      }
    }

    return toReturn;
  }
}
