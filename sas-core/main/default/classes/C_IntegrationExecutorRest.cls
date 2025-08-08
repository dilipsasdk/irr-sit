/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Integration Executor Implementation for Rest Integrations.
*/

public class C_IntegrationExecutorRest implements C_IIntegrationExecutor {

    @TestVisible
    private final String BASE_URL;

    @TestVisible
    private final Map<String, String> REQUEST_HEADERS;

    public C_IntegrationExecutorRest(String baseUrl, Map<String, String> requestHeaders) {
        this.BASE_URL = baseUrl;
        this.REQUEST_HEADERS = requestHeaders;
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Executes a request according to the provided parameters.
     *      - Supports GET and POST methods
     *      - Supports Query and Body Parameters
     *      - Null responses are handled
     *
     * @param path Relative callout path
     * @param method HTTP Method
     * @param body Body Parameter Map
     * @param queryParams Query Parameter Map
     *
     * @return Map structure, empty Map if nothing was returned from the callout
     */
    public C_IntegrationExecutor.IntegrationResponse executeRequest(String path, C_IntegrationExecutor.Method method,
            Map<String, Object> body, Map<String, Object> queryParams) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + path);
        request.setTimeout(120000);
        request.setMethod(String.valueOf(method));
        if (REQUEST_HEADERS!=null && !REQUEST_HEADERS.isEmpty()) {
            setRequestHeaders(request, REQUEST_HEADERS);
            
        }
        if (body != null && !body.isEmpty()) {
            setRequestBody(request, body);
        }
        if (queryParams!=null && !queryParams.isEmpty()) {
            setRequestQueryParams(request, queryParams);
        }
        HttpResponse res = http.send(request);
        String response = String.isNotBlank(res.getBody()) ? res.getBody() : '';
        System.debug(response);
        return new C_IntegrationExecutor.IntegrationResponse(res.getStatusCode(), response);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Constructs a Query Endpoint using a map of query parameters and assigns it to the request.
     *
     * @param request HttpRequest object to modify
     * @param requestHeaders Map of Request Headers
     */
    private void setRequestHeaders(HttpRequest request, Map<String, String> requestHeaders) {
        for (String key : requestHeaders.keySet()) {
            String value = requestHeaders.get(key);
            request.setHeader(key, value);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Constructs a Query Endpoint using a map of query parameters and assigns it to the request.
     *
     * @param request HttpRequest object to modify
     * @param queryParams Map of Query Parameters
     */
    @TestVisible
    private void setRequestQueryParams(HttpRequest request, Map<String, Object> queryParams) {
        String queryString = '';
        for (String key : queryParams.keySet()) {
            Object value = queryParams.get(key);
            queryString += String.isBlank(queryString) ? '?' : '&';
            queryString += key + '=' + value;
        }

        request.setEndpoint(request.getEndpoint() + queryString);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Constructs the JSON body from a Map and assigns it to the request.
     *
     * @param request HttpRequest to modify
     * @param body Map of Body Parameters
     */
    @TestVisible
    private void setRequestBody(HttpRequest request, Map<String, Object> body) {
        String jsonBody = JSON.serialize(body);
        request.setBody(jsonBody);
        request.setHeader('Content-Type', 'application/json');
        System.debug(JSON.serializePretty(body));
    }

    public class Constructor implements C_IntegrationExecutor.IConstructable {
        public C_IIntegrationExecutor construct(String baseUrl, Map<String, String> requestHeaders) {
            return (C_IIntegrationExecutor) new C_IntegrationExecutorRest(baseUrl, requestHeaders);
        }
    }
}