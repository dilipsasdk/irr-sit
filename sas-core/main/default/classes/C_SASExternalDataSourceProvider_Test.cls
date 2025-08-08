/**
 * @author Anton Norell
 * @date 2019-12-03
 * @description Test class for C_SASExternalDataSourceProvider.
 */
@IsTest
private class C_SASExternalDataSourceProvider_Test {
    /**
     * Asserts that the correct Authentication capabilities for the Data Source Provided is returned.
     */
    @IsTest
    static void shouldReturnAuthenticationCapabilitiesForDataSourceProvider() {
        C_SASExternalDataSourceProvider provider = new C_SASExternalDataSourceProvider();
        List<DataSource.AuthenticationCapability> authenticationCapabilities = provider.getAuthenticationCapabilities();

        System.assertEquals(1, authenticationCapabilities.size(), 'The method returned an unexpected number of capabilities.');
    }

    /**
     * Asserts that the correct Operation capabilities for the Data Source Provided is returned.
     */
    @IsTest
    static void shouldReturnOperationCapabilitiesForDataSourceProvider() {
        C_SASExternalDataSourceProvider provider = new C_SASExternalDataSourceProvider();
        List<DataSource.Capability> operationCapabilities = provider.getCapabilities();

        System.assertEquals(1, operationCapabilities.size(), 'The method returned an unexpected number of capabilities.');
        System.assert(
                operationCapabilities.contains(DataSource.Capability.ROW_QUERY),
                'The method should have returned a ROW_QUERY capability'
        );
    }

    /**
     * Asserts that the correct Data Source Connection is returned, specific to this implementation.
     */
    @IsTest
    static void shouldReturnCorrectConnectionType(){
        C_SASExternalDataSourceProvider provider = new C_SASExternalDataSourceProvider();
        C_SASExternalDataSourceConnection connection;
        try{
            connection = (C_SASExternalDataSourceConnection)provider.getConnection(new DataSource.ConnectionParams());
        } catch (Exception e){
        }
        System.assertNotEquals(null, connection, 'The correct connection was not returned - failed to cast');
    }
}