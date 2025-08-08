/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Integration Executor Builder class. Used to construct Integration Executors.
*/

public class C_IntegrationExecutorBuilder implements C_IIntegrationExecutorBuilder {

    @TestVisible
    private Map<String, String> requestHeaders = new Map<String, String>();

    @TestVisible
    private String baseUrl;

    @TestVisible
    private Type integrationExecutorType;

    private static final String API_SYSTEM_NAME = 'Salesforce';

    public C_IntegrationExecutorBuilder(Type integrationExecutorType) {
        this.integrationExecutorType = integrationExecutorType;
    }

    public C_IntegrationExecutorBuilder enableSASTracking() {
        requestHeaders.put('sas-system-name', API_SYSTEM_NAME);
        requestHeaders.put('sas-tracking-id', C_Util.getUUID());
        return this;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sets the Base URL to use.
     *
     * @param baseUrl Integration Base URL
     *
     * @return This builder instance
     */
    public C_IntegrationExecutorBuilder setBaseURL(String baseUrl) {
        this.baseUrl = baseUrl;
        return this;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sets the APIM Subscription Key to use.
     *
     * @param subscriptionKey Integration Subscription Key
     *
     * @return This builder instance
     */
    public C_IntegrationExecutorBuilder setAPIMSubscriptionKey(String subscriptionKey) {
        requestHeaders.put('Ocp-Apim-Subscription-Key', subscriptionKey);
        return this;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sets the API version to use.
     *
     * @param apiVersion Integration API version
     *
     * @return This builder instance
     */
    public C_IntegrationExecutorBuilder setAPIVersion(String apiVersion) {
        requestHeaders.put('api-version', apiVersion);
        return this;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Constructs and returns the Integration Executor using the builder configuration.
     *
     * @return Integration Executor instance
     */
    public C_IIntegrationExecutor build() {
        C_IntegrationExecutor.IConstructable integrationExecutorConstructable =
                (C_IntegrationExecutor.IConstructable) integrationExecutorType.newInstance();
        return integrationExecutorConstructable.construct(baseUrl, requestHeaders);
    }
}