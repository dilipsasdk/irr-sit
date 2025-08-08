/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface C_IIntegrationExecutor {
    C_IntegrationExecutor.IntegrationResponse executeRequest(String path, C_IntegrationExecutor.Method method, Map<String, Object> body,
            Map<String, Object> queryParams);
}