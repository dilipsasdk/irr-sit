/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Contains common functionality for Integration Executor implementations.
*/

public class C_IntegrationExecutor {
    /**
     * The response received from the integrated service
     */
    public class IntegrationResponse{
        /**
         * The status code received from the integrated web service
         */
        public Integer statusCode{get;private set;}
        /**
         * The response body from the integrated web service
         */
        public String responseBody{get;private set;}
        /**
         * Created an instance of an integration response
         * @param statusCode The status code received from the integrated web service
         * @param responseBody The response body from the integrated web service
         */
        public IntegrationResponse(Integer statusCode,String responseBody){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
    }

    public enum Method { GET, POST }

    public interface IConstructable {
        C_IIntegrationExecutor construct(String baseUrl, Map<String, String> requestHeaders);
    }
}