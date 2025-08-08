/**
 * Logging framework to ensures that events can be logged in the platform
 * Commonly used to log errors
 * @author Peter Södergren
 */
public with sharing class C_Log {
  /**
   * Timestamp when the log class was first initated
   */
  private static Long TS;
  /**
   * Whether the log class operates in buffered mode
   */
  private static Boolean BUFFERED = false;
  /**
   * The buffer list of log records to be commited on next flush
   */
  private static List<C_Log__c> BUFFER = new List<C_Log__c>();

  /**
   * The severity types logs in created
   */
  public enum Severity {
    Info,
    Warning,
    Error
  }
  /**
   * Stores the start time of the transaction
   * Note: Calling this method is not required for generating logs but is useful
   * for establishing the duration of a transaction
   */
  public static void init() {
    if (TS == null)
      TS = System.currentTimeMillis();
  }
  /**
   * Sets whether the log class should operate in a buffered mode.
   * In buffered mode the log class stores incoming logs in a list and only commits them once flush is called.
   * @param buffered Whether the log class should operate in buffered mode
   * @return The previous value of whether the log class operates in buffered mode
   */
  public static Boolean setBuffered(Boolean buffered) {
    Boolean prevVal = C_Log.BUFFERED;
    C_Log.BUFFERED = buffered;
    if (!buffered)
      flush();
    return prevVal;
  }
  /**
   * Flushes the buffer and commits the log records
   */
  public static void flush() {
    insert BUFFER;
    BUFFER.clear();
  }
  /**
   * Creates a log record
   * @param severity The severity of the log record
   * @param msg The message to log
   * @param stackTrace The strack trace to log
   * @param logGroup The group of logs to which the log record belongs
   * @param http HTTP inforamation supplied in the log
   */
  public static void log(
    Severity severity,
    String msg,
    String stackTrace,
    String logGroup,
    HttpData http
  ) {
    Long tsNow = System.currentTimeMillis();
    C_Log__c l = new C_Log__c();
    l.Severity__c = severity.name();
    if (msg != null)
      l.Message__c = msg.abbreviate(10000);
    if (stackTrace != null)
      l.StackTrace__c = stackTrace.abbreviate(10000);
    l.LogGroup__c = logGroup;
    if (http != null)
      http.setRecord(l);
    l.Timestamp__c = tsNow;
    if (TS != null)
      l.Duration__c = tsNow - TS;
    l.Transaction__c = C_Util.getUUID();
    insert l;
  }

  /*
     log can not captured during set up and non set up in single transaction
     setup object and non set up object can not run in Single transaction(Mixed DML error)
     so created future method to capture logs in these situations.
    */
  @future
  public static void log(
    String errorType,
    String msg,
    String stackTrace,
    String userName
  ) {
    Long tsNow = System.currentTimeMillis();
    C_Log__c l = new C_Log__c();
    l.Severity__c = errorType;
    if (msg != null)
      l.Message__c = msg.abbreviate(10000);
    if (stackTrace != null)
      l.StackTrace__c = stackTrace.abbreviate(10000);
    l.Timestamp__c = tsNow;
    if (TS != null)
      l.Duration__c = tsNow - TS;
    l.Transaction__c = C_Util.getUUID();
    l.User_Name__c = userName;
    insert l;
  }
  /**
   * Logs an error from an exception
   * @param e The exception which should be logged
   * @param logGroup The group of logs to which the log record belongs
   * @param http HTTP inforamation supplied in the log
   */
  public static void logException(Exception e, String logGroup, HttpData http) {
    log(
      Severity.Error,
      e.getTypeName() +
      ': ' +
      e.getMessage(),
      e.getStackTraceString(),
      logGroup,
      http
    );
  }

  /**
   * Generates http log data from the provided rest request
   * @param req The rest request from which to generate log data
   * @return The HTTP log data
   */
  public static HttpData generateLogHttpData(RestRequest req) {
    if (req == null)
      return null;
    HttpData http = new HttpData();
    http.resource = req.resourcePath;
    http.method = req.httpMethod;
    http.remoteAddress = req.remoteAddress;
    http.headers = '';
    for (String k : req.headers.keySet()) {
      http.headers += k + ': ' + req.headers.get(k) + '\n';
    }
    http.queryParams = '';
    for (String k : req.params.keySet()) {
      http.queryParams += k + ': ' + req.params.get(k) + '\n';
    }
    try {
      http.body = req.requestBody.toString();
    } catch (Exception e) {
      if (req.requestBody != null) {
        http.body = 'Blob Data (' + req.requestBody.size() + ')'; 
      } else {
        http.body = '';
      }
    }
    return http;
  }

  /**
   * Generates http log data from the provided http request
   * @param req The rest request from which to generate log data
   * @return The HTTP log data
   */
  public static HttpData generateLogHttpData(HttpRequest req) {
    if (req == null)
      return null;
    HttpData http = new HttpData();
    http.resource = req.getEndpoint();
    http.method = req.getMethod();

    http.queryParams = '';
    Integer qIdx = http.resource.indexOf('?');
    if (qIdx != -1) {
      String[] qParams = http.resource.substring(qIdx + 1).split('&');
      for (String qp : qParams) {
        Integer eqIdx = qp.indexOf('=');
        http.queryParams +=
          (eqIdx != -1
            ? qp.substring(0, eqIdx) + ':' + qp.substring(eqIdx + 1)
            : qp) + '\n';
      }
      http.resource = http.resource.substring(0, qIdx);
    }
    try {
      http.body = req.getBodyAsBlob().toString();
    } catch (Exception e) {
      if (req.getBodyAsBlob() != null) {
        http.body = 'Blob Data (' + req.getBodyAsBlob().size() + ')';
      } else {
        http.body = '';
      }
    }
    return http;
  }

  /**
   * HTTP data which can be logged to a record
   */
  public class HttpData {
    /**
     * The HTTP resource
     */
    public String resource;
    /**
     * The HTTP method
     */
    public String method;
    /**
     * The IP address of the remote host which initated the request
     */
    public String remoteAddress;
    /**
     * The HTTP headers sent when calling the REST resource
     */
    public String headers;
    /**
     * The query parameters sent when calling the REST resoruce
     */
    public String queryParams;
    /**
     * The body sent when calling the REST resource
     */
    public String body;
    /**
     * Sets the HTTP information on the supplied log record
     * @param l The log record
     */
    private void setRecord(C_Log__c l) {
      if (resource != null)
        l.HttpResource__c = resource.abbreviate(255);
      if (method != null)
        l.HttpMethod__c = method.abbreviate(10);
      if (remoteAddress != null)
        l.HttpRemoteAddress__c = remoteAddress.abbreviate(60);
      if (headers != null)
        l.HttpHeaders__c = headers.abbreviate(10000);
      if (queryParams != null)
        l.HttpQueryParameters__c = queryParams.abbreviate(10000);
      if (body != null)
        l.HttpBody__c = body.abbreviate(100000);
    }
  }

  @AuraEnabled(cacheable = true)
  public static C_Log__c createLog(
    String errorType,
    String errorMsg,
    String stackTrace,
    String logGroup
  ) {
    Long tsNow = System.currentTimeMillis();
    C_Log__c log = new C_Log__c();
    log.Severity__c = errorType;
    if (errorMsg != null)
      log.Message__c = errorMsg.abbreviate(10000);
    if (stackTrace != null)
      log.StackTrace__c = stackTrace.abbreviate(10000);
    log.Timestamp__c = tsNow;
    if (TS != null)
      log.Duration__c = tsNow - TS;
    log.Transaction__c = C_Util.getUUID();
    log.LogGroup__c = logGroup;
    insert log;

    return log;
  }
}