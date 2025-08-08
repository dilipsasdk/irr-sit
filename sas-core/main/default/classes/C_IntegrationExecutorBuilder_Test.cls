/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Integration Executor Builder.
*/

@IsTest
private class C_IntegrationExecutorBuilder_Test {

    @IsTest
    static void testBuildIntegrationExecutor() {
        //When
        C_IntegrationExecutorBuilder builder =
                new C_IntegrationExecutorBuilder(C_IntegrationExecutorRest.Constructor.class);
        builder.setBaseURL('TEST_BASE_URL');
        builder.setAPIMSubscriptionKey('TEST_APIM_KEY');
        builder.setAPIVersion('TEST_API_VERSION');
        Object result = builder.build();

        //Then
        System.assert(result instanceof C_IntegrationExecutorRest,
                'Expected build result to be of type Integration Executor Rest');
        C_IntegrationExecutorRest executor = (C_IntegrationExecutorRest) result;
        System.assertEquals('TEST_BASE_URL', executor.BASE_URL);
        System.assertEquals('TEST_APIM_KEY', executor.REQUEST_HEADERS.get('Ocp-Apim-Subscription-Key'));
        System.assertEquals('TEST_API_VERSION', executor.REQUEST_HEADERS.get('api-version'));
    }
}