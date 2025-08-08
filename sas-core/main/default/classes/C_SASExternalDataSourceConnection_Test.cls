/**
 * @author Anton Norell
 * @date 2019-12-03
 * @description Test class for C_SASExternalDataSourceConnection. Focuses in checking that the
 * included methods are running correctly, not in the result of underlying services.
 */
@IsTest
private class C_SASExternalDataSourceConnection_Test {
  /**
   * Asserts that the sync method, which is not being used in this implementation,
   * returns an empty list of tables tables.
   */
  @IsTest
  static void shouldReturnEmptyTableFromSyncMethod() {
    DataSource.ConnectionParams connectionParams = new DataSource.ConnectionParams();
    C_SASExternalDataSourceConnection connection = new C_SASExternalDataSourceConnection(
      connectionParams
    );
    List<DataSource.Table> tables = connection.sync();
    System.assertNotEquals(
      null,
      tables.size(),
      'The method should return an empty list - returned null.'
    );
    System.assertEquals(
      0,
      tables.size(),
      'The method should return an empty list - returned tables in list.'
    );
  }

  /**
   * Asserts that the query method in the connection returns a null values if the table in the
   * query is not supported
   */
  @IsTest
  static void shouldReturnNullIfTableNotSupported() {
    DataSource.ConnectionParams connectionParams = new DataSource.ConnectionParams();
    C_SASExternalDataSourceConnection connection = new C_SASExternalDataSourceConnection(
      connectionParams
    );
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.tableSelected = 'Non existing table';

    DataSource.TableResult tableResult = connection.query(queryContext);

    System.assertEquals(
      null,
      tableResult,
      'As the table does not exist, the method should have returned null'
    );
  }

  /**
   * Asserts that that correct service is called if the table selected is FrequentFlyers. An exception is
   * deliberately triggered as the scope for this test is to see that the correct service is called, not
   * to assert the result.
   */
  @IsTest
  static void shouldThrowExceptionWhenFrequentFlyerServiceIsCalled() {
    DataSource.ConnectionParams connectionParams = new DataSource.ConnectionParams();
    C_SASExternalDataSourceConnection connection = new C_SASExternalDataSourceConnection(
      connectionParams
    );
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.tableSelected = 'FrequentFlyers';

    FCS_FrequentFlyerService.InvalidSearchException returnedException;
    try {
      connection.query(queryContext);
    } catch (FCS_FrequentFlyerService.InvalidSearchException e) {
      returnedException = e;
    }

    System.assertNotEquals(
      null,
      returnedException,
      'Should have returned an exception if the correct service was called. ' +
      'Check that exception logic in FCS_FrequentFlyerService has not changed'
    );
  }
}
