/**
 * @author Anton Norell
 * @date 2019-10-15
 * @description  The class informs Salesforce of the functional and authentication capabilities
 *               that are supported by or required to connect to the external system.
 */
global class C_SASExternalDataSourceProvider extends DataSource.Provider{
    /**
     * Returns the types of authentication that can be used to access the external system.
     * Only Anonymous auth is supported for data source, as authentication is handled ba classes making callouts.
     * @return List of capabilities for authentication.
     */
    override global List<DataSource.AuthenticationCapability> getAuthenticationCapabilities() {
        List<DataSource.AuthenticationCapability> capabilities = new List<DataSource.AuthenticationCapability>();
        capabilities.add(DataSource.AuthenticationCapability.ANONYMOUS);
        return capabilities;
    }

    /**
     * Returns the functional operations that the external system supports and the
     * required endpoint settings for the external data source definition in Salesforce.
     * Currently the SAS data source only supports read operations.
     * @return List of CRUD capabilities for data source
     */
    override global List<DataSource.Capability> getCapabilities(){
        List<DataSource.Capability> capabilities = new List<DataSource.Capability>();
        capabilities.add(DataSource.Capability.ROW_QUERY);
        //capabilities.add(DataSource.Capability.SEARCH);
        //capabilities.add(DataSource.Capability.ROW_CREATE);
        //capabilities.add(DataSource.Capability.ROW_UPDATE);
        //capabilities.add(DataSource.Capability.ROW_DELETE);
        return capabilities;
    }

    /**
     * Implementation of required method to return a custom connection
     * @param connectionParams Credentials for authenticating to the external system.
     * @return Returns a connection that points to an instance of the external data source.
     */
    override global DataSource.Connection getConnection(DataSource.ConnectionParams connectionParams) {
        return new C_SASExternalDataSourceConnection(connectionParams);
    }
}