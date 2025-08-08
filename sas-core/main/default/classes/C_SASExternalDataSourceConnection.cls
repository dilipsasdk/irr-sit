/**
 * @author Anton Norell
 * @date 2019-10-25
 * @description This class composes a custom adapter for Salesforce Connect.
 */
global with sharing class C_SASExternalDataSourceConnection extends DataSource.Connection{
    /**
     * Constructor for class. Contains no logic but is required for Salesforce to recognize the
     * class as an external data source type.
     * @param connectionParams Contains the credentials for authenticating to the external system.
     */
    global C_SASExternalDataSourceConnection(DataSource.ConnectionParams connectionParams) {

    }

    /**
     * Invoked when an administrator clicks Validate and Sync on the external data source detail page.
     * The method is not used as external objects for this connection are created manually.
     * @return Returns a list of tables that describe the external system’s schema.
     */
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        return tables;
    }

    /**
     * Invoked by a SOQL query of an external object. A SOQL query is generated and executed when
     * a user visits an external object’s list view or record detail page in Salesforce.
     * @return Returns the results of the query.
     */
    override global DataSource.TableResult query(DataSource.QueryContext queryContext) {
        DataSource.TableResult tableResult;

        if(queryContext.tableSelection.tableSelected == 'FrequentFlyers'){
            tableResult = FCS_FrequentFlyerService.handleQuery(queryContext);
        }

        return tableResult;
    }
}