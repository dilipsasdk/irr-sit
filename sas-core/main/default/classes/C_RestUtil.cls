/**
 * Class with utility methods for rest services
 * @author Peter Södergren
 */
public with sharing class C_RestUtil {
    /**
     * The current savepoint of the REST transaction
     */
    private static Savepoint sp;
    /**
     * Cached version of HTTP data used for logging
     */
    private static C_Log.HttpData http;
    /**
     * Exception for errors in REST services
     */
    public virtual class RestException extends Exception{
        /**
         * The HTTP status code of the excpetion
         */
        public Integer statusCode;
        /**
         * Creates a REST Exception
         * @param statusCode The http status code
         */
        public RestException(Integer statusCode,String message){
            this(message);
            this.statusCode = statusCode;
        }
    }
    /**
     * Throws a bad request excpetion
     * @param msg The message communicated for the bad request
     */
    public static void badRequest(String msg){
        throw new RestException(400,msg);
    }
    /**
     * Parses the JSON body into the supplied type
     * Note: The caller needs to cast returned object into the correct type
     * @param t The type to which to convert the JSON body
     * @return The result as an object
     */
    public static Object getJSONBody(Type t){
        Object o = null;
        try{
            o = JSON.deserializeStrict(RestContext.request.requestBody.toString(), t);
        }
        catch(Exception e){
            badRequest('Failed to deserialize body: '+e.getMessage());
        }
        return o;
    }
    /**
     * Initalizes the REST utils by doing the following
     * Sets the timestamp in the logging framework
     * Sets the savespoint
     * Sets the transaction UUID if mapped in the X-Transaction header
     */
    public static void init(){
        init(true);
    }

    /**
     * Initalizes the REST utils by doing the following
     * Sets the timestamp in the logging framework
     * Sets the savespoint, if specified
     * Sets the transaction UUID if mapped in the X-Transaction header
     * @param setSavepoint Whether to set a savepoint as part of the init. (Consumes DML call so transactions with following callouts should avoid setting a savepoint)
     */
    public static void init(Boolean setSavepoint){
        C_Log.init();
        if(setSavepoint)setSavepoint();
        String t = RestContext.request.headers.get('X-Transaction');
        if(!String.isBlank(t))C_Util.setUUID(t);
    }

    /**
     * Sets a savepoint to roll back to in case of an error
     * Note: only sets a avepoint if an existing savepoint is not set
     */
    public static void setSavepoint(){
        if(sp==null)sp = Database.setSavepoint();
    }

    /**
     * Handles exceptions by rolling back to the last savepoint
     * Ensures the error is logged in the logging framework
     * If the exception is rest exception the status code and message is used, 
     * otherwise an internal server error is set as the rest response
     * @param e The exception
     */
    public static void handleException(Exception e){
        if(sp!=null){
            Database.rollback(sp);
            sp = null;
        }
        if(e instanceof RestException){
            RestException re = (RestException)e;
            set(re.statusCode,re.getMessage());
        }
        else {
            set(500,'Internal Server Error');
        }
        C_Log.logException(e, null, getLogHttpData());
    }
    
	/**
     * Sets the response to input msg and returns a 200 status code.
     * @param msg The message given after the successful call. 	 
	 */    
    public static void setOK(String msg){
        set(200,msg);
    }

    /**
     * Sets the response to the status code and the provided message
     * @param statusCode The status code to set for the response
     * @param msg The message to set for the response
     */
    public static void set(Integer statusCode,String msg){
        RestContext.response.responseBody = Blob.valueOf(msg);
        RestContext.response.statusCode = statusCode;
    }

    /**
     * Retireves log http data to enable inclusion of the data
     * in log records.
     * @return The log HTTP data
     */
    public static C_Log.HttpData getLogHttpData(){
        if(http!=null)return http;
        http = C_Log.generateLogHttpData(RestContext.request);
        return http;
    }

    /**
     * Retirevs query parameters as a parameter collection object
     * @return The query params as a parameter collection
     */
    public static ParamCollection getQueryParams(){
        return new ParamCollection(RestContext.request.params);
    }

    /**
     * Paramaeter collection object to provide methods for interacting with the parameters
     */
    public class ParamCollection{
        /**
         * The map of parameters for the collection
         */
        Map<String,String> params;
        /**
         * Creates the parameter collection using a string key value map 
         * as the source
         * @params The parameters of the collection
         */
        private ParamCollection(Map<String,String> params){
            this.params = params;
        }

        /**
         * Retrieves the parameter value for the provided key
         * If set as required the method will throw a bad request exception if the value is null or blank
         * @param k The key for which to fetch the value
         * @param req Whether the parameter is required
         * @return The parameter value
         */
        public String get(String k,Boolean req){
            String v = params.get(k);
            if(String.isBlank(v))v=null;
            if(req && v==null)badRequest('Must specify parameter: '+k);
            return v;
        }

        /**
         * Retrieves the parameter value for the provided key as an integer
         * The method will throw a bad request exception if the parameter is not an integer
         * If set as required the method will throw a bad request exception if the value is null or blank
         * @param k The key for which to fetch the value
         * @param req Whether the parameter is required
         * @return The integer value of the parameter
         */
        public Integer getInt(String k,Boolean req){
            String v = get(k,req);
            Integer i;
            try{
                i = v!=null ? Integer.valueOf(v) : null;
            }
            catch(Exception e){
                badRequest('Parameter value not of integer type: '+k);
            }
            return i;
        }
    }
}
