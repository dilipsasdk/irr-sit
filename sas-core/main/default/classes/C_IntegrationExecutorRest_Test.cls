/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Rest Integration Executor.
*/

@IsTest
private class C_IntegrationExecutorRest_Test {

    @IsTest
    static void testExecuteRequest_POST() {
        //Set up mocks
        C_CalloutMock calloutMock = new C_CalloutMock(null, 204, null);

        //Given
        String baseUrl = 'TEST_BASE_URL';
        Map<String, String> headers = new Map<String, String>{
                'TEST_HEADER' => 'TEST_HEADER_VALUE'
        };
        Map<String, Object> bodyParameters = new Map<String, Object>{
                'TEST_BODY_PARAMETER' => 'TEST_BODY_VALUE',
                'OTHER_BODY_PARAMETER' => 'OTHER_BODY_VALUE'
        };
        Test.setMock(HttpCalloutMock.class, calloutMock);
        C_IntegrationExecutorRest executor = new C_IntegrationExecutorRest(baseUrl, headers);

        //When
        C_IntegrationExecutor.IntegrationResponse response = executor.executeRequest('/test/path',
                C_IntegrationExecutor.Method.POST, bodyParameters, null);

        //Then
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(204, response.statusCode);
        System.assertEquals('', response.responseBody);
        System.assertNotEquals(null, calloutMock.request);
        HttpRequest request = calloutMock.request;
        Map<String, Object> serializedBody = (Map<String,Object>) JSON.deserializeUntyped(request.getBody());
        System.assertEquals('TEST_BODY_VALUE', serializedBody.get('TEST_BODY_PARAMETER'));
        System.assertEquals('OTHER_BODY_VALUE', serializedBody.get('OTHER_BODY_PARAMETER'));
        System.assertEquals('TEST_HEADER_VALUE', request.getHeader('TEST_HEADER'));
        System.assertEquals('TEST_BASE_URL/test/path' , request.getEndpoint());
        System.assertEquals('POST', request.getMethod());
    }

    @IsTest
    static void testExecuteRequest_GET() {
        //Set up mocks
        C_CalloutMock calloutMock = new C_CalloutMock('TEST_RESPONSE_BODY', 200, 'TEST_CONTENT_TYPE');

        //Given
        String baseUrl = 'TEST_BASE_URL';
        Map<String, String> headers = new Map<String, String>{
                'TEST_HEADER' => 'TEST_HEADER_VALUE'
        };
        Map<String, Object> queryParameters = new Map<String, Object>{
                'TEST_QUERY_PARAMETER' => 'TEST_QUERY_VALUE',
                'OTHER_QUERY_PARAMETER' => 'OTHER_QUERY_VALUE'
        };
        Test.setMock(HttpCalloutMock.class, calloutMock);
        C_IntegrationExecutorRest executor = new C_IntegrationExecutorRest(baseUrl, headers);

        //When
        C_IntegrationExecutor.IntegrationResponse response = executor.executeRequest('/test/path',
                C_IntegrationExecutor.Method.GET, null, queryParameters);

        //Then
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(200, response.statusCode);
        System.assertEquals('TEST_RESPONSE_BODY', response.responseBody);
        System.assertNotEquals(null, calloutMock.request);
        HttpRequest request = calloutMock.request;
        System.assertEquals('TEST_HEADER_VALUE', request.getHeader('TEST_HEADER'));
        System.assertEquals(
                'TEST_BASE_URL/test/path?TEST_QUERY_PARAMETER=TEST_QUERY_VALUE&OTHER_QUERY_PARAMETER=OTHER_QUERY_VALUE',
                request.getEndpoint());
        System.assertEquals('GET', request.getMethod());
    }
}