/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface C_IIntegrationExecutorBuilder {
    C_IIntegrationExecutorBuilder setBaseURL(String baseUrl);
    C_IIntegrationExecutorBuilder setAPIMSubscriptionKey(String subscriptionKey);
    C_IIntegrationExecutorBuilder setAPIVersion(String apiVersion);
    C_IIntegrationExecutorBuilder enableSASTracking();
    C_IIntegrationExecutor build();
}