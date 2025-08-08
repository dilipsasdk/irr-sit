/**
 * @author Anton Norell
 * @date 2019-12-03
 * @description Test class for FCS_FrequentFlyerService. Focuses on functionality contained within the service,
 * e.g. query results, and not explicitly on the result from underlying services.
 */
@IsTest
private class FCS_FrequentFlyerService_Test {
  /**
   * Asserts that the Frequent Flyer service throws an exception if the query is not filtered
   */
  @IsTest
  static void shouldThrowExceptionIfMissingFilter() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();

    FCS_FrequentFlyerService.InvalidSearchException returnedException;
    try {
      FCS_FrequentFlyerService.handleQuery(queryContext);
    } catch (FCS_FrequentFlyerService.InvalidSearchException e) {
      returnedException = e;
    }

    System.assertNotEquals(
      null,
      returnedException,
      'An exception was expected when no filter was provided'
    );
    System.assertEquals(
      'The query must include a valid search term for the C-Shark API',
      returnedException.getMessage(),
      'The returned message in the exception was not the one expected. Check if message has been changed.'
    );
  }

  /**
   * Asserts that the Frequent Flyer service throws an exception if the query does not contain
   * a search term that is valid for the C-Shark API
   */
  @IsTest
  static void shouldThrowExceptionWhenMissingValidSearchTerm() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.EQUALS,
      'HomePhone',
      '123'
    );

    FCS_FrequentFlyerService.InvalidSearchException returnedException;
    try {
      FCS_FrequentFlyerService.handleQuery(queryContext);
    } catch (FCS_FrequentFlyerService.InvalidSearchException e) {
      returnedException = e;
    }

    System.assertNotEquals(
      null,
      returnedException,
      'An exception was expected when no valid search terms was provided'
    );
    System.assertEquals(
      'The query must include a valid search term for the C-Shark API',
      returnedException.getMessage(),
      'The returned message in the exception was not the one expected. Check if message has been changed.'
    );
  }

  /**
   * Asserts that the Frequent Flyer service throws an exception if the query included multiple search values
   * for search terms that are used to search in the C-Shark service
   */
  @IsTest
  static void shouldThrowExceptionWhenMultipleApiSearchValuesProvided() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.OR_,
      null,
      null
    );
    queryContext.tableSelection.filter.subfilters = new List<DataSource.Filter>();
    queryContext.tableSelection.filter.subfilters.add(
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'EuroBonusNumber',
        '123'
      )
    );
    queryContext.tableSelection.filter.subfilters.add(
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'EuroBonusNumber',
        '456'
      )
    );

    FCS_FrequentFlyerService.InvalidSearchException returnedException;
    try {
      FCS_FrequentFlyerService.handleQuery(queryContext);
    } catch (FCS_FrequentFlyerService.InvalidSearchException e) {
      returnedException = e;
    }

    System.assertNotEquals(
      null,
      returnedException,
      'An exception was expected when multiple search values was provided'
    );
    System.assertEquals(
      'Only one search value per field can be included in the query for this service',
      returnedException.getMessage(),
      'The returned message in the exception was not the one expected. Check if message has been changed.'
    );
  }

  /**
   * Asserts that a query is handled correctly through all underlying services and that a table
   * with customer rows is returned.
   */
  @IsTest
  static void shouldReturnTableOfCustomerRowsBasedOnEBNumber() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.EQUALS,
      'EuroBonusNumber',
      '700001423'
    );

    Test.startTest();
    DataSource.TableResult tableResult = FCS_FrequentFlyerService.handleQuery(
      queryContext
    );
    Test.stopTest();

    System.assertEquals(
      1,
      tableResult.rows.size(),
      'An unexpected number of customer rows was returned.'
    );
  }

  /**
   * Asserts that a query is handled correctly through all underlying services and that a table
   * with customer rows is returned.
   */
  @IsTest
  static void shouldReturnTableOfCustomerRowsBasedOnExternalId() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.EQUALS,
      'ExternalId',
      '10401209'
    );

    Test.startTest();
    DataSource.TableResult tableResult = FCS_FrequentFlyerService.handleQuery(
      queryContext
    );
    Test.stopTest();

    System.assertEquals(
      1,
      tableResult.rows.size(),
      'An unexpected number of customer rows was returned.'
    );
  }

  /**
   * Asserts that a query is handled correctly through all underlying services and that the returned
   * table is empty if the provided search value does not match a record in the external system
   */
  @IsTest
  static void shouldReturnEmptyTableOfCustomerRowsDueToNoMatch() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.EQUALS,
      'EuroBonusNumber',
      '123'
    );

    Test.startTest();
    DataSource.TableResult tableResult = FCS_FrequentFlyerService.handleQuery(
      queryContext
    );
    Test.stopTest();

    System.assertEquals(
      0,
      tableResult.rows.size(),
      'An unexpected number of customer rows was returned.'
    );
  }

  /**
   * Asserts that a query is handled correctly through all underlying services and that the returned
   * table is empty if a provided search value does not match the returned record during post-callout filtering
   */
  @IsTest
  static void shouldReturnEmptyTableOfCustomerRowsDueToFilterCriteria() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    queryContext.tableSelection.filter.subfilters = new List<DataSource.Filter>();
    queryContext.tableSelection.filter.subfilters.add(
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'EuroBonusNumber',
        '700001423'
      )
    );
    queryContext.tableSelection.filter.subfilters.add(
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'IncentiveLevel',
        'NonMatchingLevel'
      )
    );

    Test.startTest();
    DataSource.TableResult tableResult = FCS_FrequentFlyerService.handleQuery(
      queryContext
    );
    Test.stopTest();

    System.assertEquals(
      0,
      tableResult.rows.size(),
      'An unexpected number of customer rows was returned.'
    );
  }

  @IsTest
  static void shouldReturnNoMatchWhenSeveralProfilesAreFound() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomersGetResponseWithTwoCustomers');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = C_TestUtil.generateFilter(
      DataSource.FilterType.EQUALS,
      'HomeE-mail',
      'test@example.com'
    );

    Test.startTest();
    DataSource.TableResult tableResult = FCS_FrequentFlyerService.handleQuery(
      queryContext
    );
    Test.stopTest();

    System.assertEquals(
      0,
      tableResult.rows.size(),
      'If C-Shark response includes more than one profile we should return no matches, because we have no way of identifying the correct one.'
    );
  }
}
