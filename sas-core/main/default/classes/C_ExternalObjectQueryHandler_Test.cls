/**
 * @author Anton Norell
 * @date 2019-12-01
 * @description Test class for C_ExternalObjectQueryHandler.
 * Functionality in class is tested separately from any service using the handler.
 */
@IsTest
public with sharing class C_ExternalObjectQueryHandler_Test {
  /**
   * Asserts that a query with a simple EQUALS condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryEqualsConditionCorrectly() {
    DataSource.Filter filter = new DataSource.Filter();
    filter.columnName = 'Column1';
    filter.columnValue = 100;
    filter.type = DataSource.FilterType.EQUALS;

    Map<String, Object> dataRow = new Map<String, Object>{ 'Column1' => 100 };
    C_ExternalObjectQueryHandler.QueryRowHandler queryIterator = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean iterationResult = queryIterator.filterRow(filter);

    System.assertEquals(
      true,
      iterationResult,
      'The query filter did not handle EQUALS condition correctly'
    );
  }

  /**
   * Asserts that a query with a simple NOT_EQUALS condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryNotEqualsConditionCorrectly() {
    DataSource.Filter filter = new DataSource.Filter();
    filter.columnName = 'Column1';
    filter.columnValue = 100;
    filter.type = DataSource.FilterType.NOT_EQUALS;
    Map<String, Object> dataRow = new Map<String, Object>{ 'Column1' => 50 };

    C_ExternalObjectQueryHandler.QueryRowHandler queryIterator = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean iterationResult = queryIterator.filterRow(filter);

    System.assertEquals(
      true,
      iterationResult,
      'The query filter did not handle NOT_EQUALS condition as expected.'
    );
  }

  /**
   * Asserts that a query with a simple GREATER_THAN condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryGreaterThanConditionCorrectly() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column1',
        100
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column2',
        '100'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column3',
        Date.today()
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column4',
        Datetime.now()
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column5',
        99.5
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Column6',
        false
      )
    };

    Map<String, Object> dataRow = new Map<String, Object>{
      'Column1' => 200,
      'Column2' => '200',
      'Column3' => Date.today().addYears(1),
      'Column4' => Datetime.now().addYears(1),
      'Column5' => 100.5,
      'Column6' => true
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryRowHandler = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean queryResult = queryRowHandler.filterRow(filter);

    System.assertEquals(
      true,
      queryResult,
      'The query filter did not handle GREATER_THAN condition correctly. ' +
      'Check that all data types for condition are evaluated correctly'
    );
  }

  /**
   * Asserts that a query with a simple GREATER_THAN_OR_EQUAL_TO condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryGreaterThanOrEqualsConditionCorrectly() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column1',
        100
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column2',
        '100'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column3',
        Date.today()
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column4',
        Datetime.now()
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column5',
        99.5
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO,
        'Column6',
        false
      )
    };

    Map<String, Object> dataRow = new Map<String, Object>{
      'Column1' => 100,
      'Column2' => '200',
      'Column3' => Date.today(),
      'Column4' => Datetime.now().addYears(1),
      'Column5' => 100.5,
      'Column6' => false
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryRowHandler = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean queryResult = queryRowHandler.filterRow(filter);

    System.assertEquals(
      true,
      queryResult,
      'The query filter did not handle GREATER_THAN_OR_EQUAL_TO' +
      ' condition correctly. Check that all data types for condition are evaluated correctly'
    );
  }

  /**
   * Asserts that a query with a simple LESS_THAN condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryLessThanConditionCorrectly() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column1',
        200
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column2',
        '200'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column3',
        Date.today().addYears(1)
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column4',
        Datetime.now().addYears(1)
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column5',
        100.5
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN,
        'Column6',
        true
      )
    };

    Map<String, Object> dataRow = new Map<String, Object>{
      'Column1' => 100,
      'Column2' => '100',
      'Column3' => Date.today(),
      'Column4' => Datetime.now(),
      'Column5' => 99.5,
      'Column6' => false
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryRowHandler = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean queryResult = queryRowHandler.filterRow(filter);

    System.assertEquals(
      true,
      queryResult,
      'The query filter did not handle LESS_THAN condition correctly. ' +
      'Check that all data types for condition are evaluated correctly'
    );
  }

  /**
   * Asserts that a query with a simple LESS_THAN_OR_EQUAL_TO condition filters correctly
   */
  @IsTest
  static void shouldFilterSimpleQueryLessThanOrEqualsConditionCorrectly() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column1',
        200
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column2',
        '200'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column3',
        Date.today().addYears(1)
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column4',
        Datetime.now().addYears(1)
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column5',
        100.5
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.LESS_THAN_OR_EQUAL_TO,
        'Column6',
        true
      )
    };

    Map<String, Object> dataRow = new Map<String, Object>{
      'Column1' => 100,
      'Column2' => '200',
      'Column3' => Date.today(),
      'Column4' => Datetime.now(),
      'Column5' => 99.5,
      'Column6' => false
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryRowHandler = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean queryResult = queryRowHandler.filterRow(filter);

    System.assertEquals(
      true,
      queryResult,
      'The query filter did not handle LESS_THAN_OR_EQUAL_TO ' +
      'condition correctly. Check that all data types for condition are evaluated correctly'
    );
  }

  /**
   * Asserts that a query with a simple LIKE_ condition throws an exception,
   * as the condition is not supported in the query handler
   */
  @IsTest
  static void shouldThrowExceptionOnLikeCondition() {
    DataSource.Filter filter = new DataSource.Filter();
    filter.columnValue = 'stringValue';
    filter.columnValue = 100;
    filter.type = DataSource.FilterType.LIKE_;
    Map<String, Object> dataRow = new Map<String, Object>{
      'Column1' => 'stringValue'
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryIterator = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    C_ExternalObjectQueryHandler.QueryException returnedException;
    try {
      Boolean iterationResult = queryIterator.filterRow(filter);
    } catch (C_ExternalObjectQueryHandler.QueryException e) {
      returnedException = e;
    }

    System.assertNotEquals(
      null,
      returnedException,
      'The query filter did not handle LIKE_ condition correctly - should throw an exception'
    );
    System.assertEquals(
      'LIKE is not a valid expression for this object',
      returnedException.getMessage(),
      'The query filter did not handle LIKE_ condition correctly - the error message is not correct'
    );
  }

  /**
   * Asserts that a complex query with multiple filters and sub filters returns
   * false when the conditions does not match the values in the data row
   */
  @IsTest
  static void shouldReturnFalseForComplexFilter() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub1_1',
        'value1_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.NOT_EQUALS,
        'sub1_2',
        'value1_2'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'sub1_3',
        3
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
    };
    filter.subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_1',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_2',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_2',
        'value2_1'
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
    };
    filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub3_1',
        'value3_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub3_2',
        'value3_1'
      )
    };
    Map<String, Object> dataRow = new Map<String, Object>{
      'sub1_1' => 'value1_1',
      'sub1_2' => 'value1_2',
      'sub1_3' => 5,
      'sub2_1' => 'value2_1',
      'sub2_2' => 'value2_1',
      'sub3_1' => 'value3_1',
      'sub3_2' => 'value3_1'
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryIterator = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean iterationResult = queryIterator.filterRow(filter);

    System.assertEquals(
      false,
      iterationResult,
      'Result from query was incorrect. The values in data row should not match filter.'
    );
  }

  /**
   * Asserts that a complex query with multiple filters and sub filters returns
   * true when the conditions matches the values in the data row
   */
  @IsTest
  static void shouldReturnTrueForComplexFilter() {
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub1_1',
        'value1_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.NOT_EQUALS,
        'sub1_2',
        'value1_2'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'sub1_3',
        3
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
    };
    filter.subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_1',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_2',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub2_2',
        'value2_1'
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
    };
    filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub3_1',
        'value3_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'sub3_2',
        'value3_1'
      )
    };
    Map<String, Object> dataRow = new Map<String, Object>{
      'sub1_1' => 'value1_1',
      'sub1_2' => 'value1_2_deviating_value',
      'sub1_3' => 5,
      'sub2_1' => 'value2_1',
      'sub2_2' => 'value2_1',
      'sub3_1' => 'value3_1',
      'sub3_2' => 'value3_1'
    };

    C_ExternalObjectQueryHandler.QueryRowHandler queryIterator = new C_ExternalObjectQueryHandler.QueryRowHandler(
      dataRow
    );
    Boolean iterationResult = queryIterator.filterRow(filter);

    System.assertEquals(
      true,
      iterationResult,
      'Result from query was incorrect. The values in data row should match filter.'
    );
  }

  /**
   * Asserts that the correct terms available for searching an api is returned when method for extracting api search
   * terms run. This test focuses on the extracted search terms in relation to supplied valid search terms.
   */
  @IsTest
  static void shouldReturnCorrectValidSearchTermsFromQueryFilter() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    Set<String> validApiSearchTerms = new Set<String>{
      'Term1',
      'Term2',
      'Term3',
      'Term4'
    };
    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term3',
        'value1_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.NOT_EQUALS,
        'OtherTerm',
        'value1_2'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'OtherTerm',
        3
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
    };
    filter.subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term1',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'OtherTerm',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term1',
        'value2_1'
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
    };
    filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term4',
        'value3_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term2',
        'value3_1'
      )
    };
    queryContext.tableSelection.filter = filter;

    C_ExternalObjectQueryHandler queryParser = new C_ExternalObjectQueryHandler(
      queryContext
    );
    Map<String, Object> filterSearchTerms = queryParser.getApiSearchTermsAndValues(
      validApiSearchTerms
    );

    System.assertEquals(
      4,
      filterSearchTerms.keySet().size(),
      'Search terms found was not the expected number'
    );
    System.assertEquals(
      true,
      validApiSearchTerms.containsAll(filterSearchTerms.keySet()),
      'Found search terms in filter that are not listed as valid search terms. Check filtering of search terms.'
    );
    System.assertEquals(
      validApiSearchTerms,
      filterSearchTerms.keySet(),
      'The search terms found did not match the order of terms in set with valid search terms'
    );
  }

  /**
   * Asserts that the correct terms and search values for searching an api are returned when method for extracting
   * api search terms run. This test focuses on the extracted search values for each search term.
   */
  @IsTest
  static void shouldReturnCorrectValidSearchTermsAndValuesFromQueryFilter() {
    Set<String> validApiSearchTerms = new Set<String>{
      'Term1',
      'Term2',
      'Term3',
      'Term4'
    };

    DataSource.Filter filter = C_TestUtil.generateFilter(
      DataSource.FilterType.AND_,
      null,
      null
    );
    filter.subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term3',
        'value1_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.NOT_EQUALS,
        'OtherTerm',
        'value1_2'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.GREATER_THAN,
        'Term4',
        'value1_3'
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
    };
    filter.subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term1',
        'value2_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term3',
        'value2_2'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term1',
        'value2_3'
      ),
      C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
    };
    filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term4',
        'value3_1'
      ),
      C_TestUtil.generateFilter(
        DataSource.FilterType.EQUALS,
        'Term2',
        'value3_2'
      )
    };
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = filter;

    C_ExternalObjectQueryHandler queryParser = new C_ExternalObjectQueryHandler(
      queryContext
    );
    Map<String, Set<Object>> filterSearchTerms = queryParser.getApiSearchTermsAndValues(
      validApiSearchTerms
    );

    System.assertEquals(
      4,
      filterSearchTerms.keySet().size(),
      'Search terms found was not the expected number'
    );
    System.assertEquals(2, filterSearchTerms.get('Term1').size());
    System.assertEquals(1, filterSearchTerms.get('Term2').size());
    System.assertEquals(2, filterSearchTerms.get('Term3').size());
    System.assertEquals(2, filterSearchTerms.get('Term4').size());
  }

  /**
   * Asserts that if the filter is supplied with multiple rows and only a subset matches the filter,
   * only that subset of rows is returned
   */
  @IsTest
  static void shouldReturnSubsetOfRowsThatMatchedFilter() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.filter = new DataSource.Filter();
    queryContext.tableSelection.filter.columnName = 'Column1';
    queryContext.tableSelection.filter.columnValue = 100;
    queryContext.tableSelection.filter.type = DataSource.FilterType.EQUALS;
    Map<String, Object> rowMatchingFilter = new Map<String, Object>{
      'Column1' => 100
    };
    Map<String, Object> rowNotMatchingFilter = new Map<String, Object>{
      'Column1' => 0
    };
    List<Map<String, Object>> dataRows = new List<Map<String, Object>>{
      rowMatchingFilter,
      rowNotMatchingFilter
    };

    C_ExternalObjectQueryHandler queryHandler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> validRows = queryHandler.filterRows(dataRows);

    System.assertEquals(
      1,
      validRows.size(),
      'The filter returned an unexpected number of rows.'
    );
    System.assertEquals(
      rowMatchingFilter,
      validRows[0],
      'The returned row was not the correct one.'
    );
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of String type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleStringOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order);
    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => 'Last3' },
      new Map<String, Object>{ 'ColumnName' => 'Last1' },
      new Map<String, Object>{ 'ColumnName' => 'Last2' }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[2]);
    System.assertEquals(originalRows[1], orderedRows[0]);
    System.assertEquals(originalRows[2], orderedRows[1]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of Date type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleDateOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.DESCENDING;
    queryContext.tableSelection.order.add(order);
    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => Date.today().addYears(-2) },
      new Map<String, Object>{ 'ColumnName' => Date.today() },
      new Map<String, Object>{ 'ColumnName' => Date.today().addYears(-1) }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[2]);
    System.assertEquals(originalRows[1], orderedRows[0]);
    System.assertEquals(originalRows[2], orderedRows[1]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of Datetime type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleDatetimeOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.DESCENDING;
    queryContext.tableSelection.order.add(order);
    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => Datetime.now().addYears(-2) },
      new Map<String, Object>{ 'ColumnName' => Datetime.now() },
      new Map<String, Object>{ 'ColumnName' => Datetime.now().addYears(-1) }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[2]);
    System.assertEquals(originalRows[1], orderedRows[0]);
    System.assertEquals(originalRows[2], orderedRows[1]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of Integer type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleIntegerOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order);

    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => 3 },
      new Map<String, Object>{ 'ColumnName' => 1 },
      new Map<String, Object>{ 'ColumnName' => 2 }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[2]);
    System.assertEquals(originalRows[1], orderedRows[0]);
    System.assertEquals(originalRows[2], orderedRows[1]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of Decimal type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleDecimalOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order);

    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => 1.3 },
      new Map<String, Object>{ 'ColumnName' => 0.2 },
      new Map<String, Object>{ 'ColumnName' => 1.2 }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[2]);
    System.assertEquals(originalRows[1], orderedRows[0]);
    System.assertEquals(originalRows[2], orderedRows[1]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a simple order
   * statement of Boolean type, containing only one sort field
   */
  @IsTest
  static void shouldReturnOrderedRowsBasedOnSimpleBooleanOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order = new DataSource.Order();
    order.columnName = 'ColumnName';
    order.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order);

    List<Map<String, Object>> originalRows = new List<Map<String, Object>>{
      new Map<String, Object>{ 'ColumnName' => true },
      new Map<String, Object>{ 'ColumnName' => true },
      new Map<String, Object>{ 'ColumnName' => false }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(originalRows);

    System.assertEquals(originalRows[0], orderedRows[1]);
    System.assertEquals(originalRows[1], orderedRows[2]);
    System.assertEquals(originalRows[2], orderedRows[0]);
  }

  /**
   * Asserts that the QueryHandler Order function can order a list of data rows with a complex order
   * statement, containing multiple sort fields
   */
  @IsTest
  static void shouldReturnOrderRowsBasedOnComplexOrder() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();
    queryContext.tableSelection.order = new List<DataSource.Order>();
    DataSource.Order order1 = new DataSource.Order();
    order1.columnName = 'ColumnName1';
    order1.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order1);
    DataSource.Order order2 = new DataSource.Order();
    order2.columnName = 'ColumnName2';
    order2.direction = DataSource.OrderDirection.DESCENDING;
    queryContext.tableSelection.order.add(order2);
    DataSource.Order order3 = new DataSource.Order();
    order3.columnName = 'ColumnName3';
    order3.direction = DataSource.OrderDirection.ASCENDING;
    queryContext.tableSelection.order.add(order3);

    List<Map<String, Object>> rows = new List<Map<String, Object>>{
      new Map<String, Object>{
        'ColumnName1' => 'Value3',
        'ColumnName2' => 'Value32',
        'ColumnName3' => 1
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value2',
        'ColumnName2' => 'Value22',
        'ColumnName3' => 2
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value1',
        'ColumnName2' => 'Value11',
        'ColumnName3' => 3
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value3',
        'ColumnName2' => 'Value31',
        'ColumnName3' => 4
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value2',
        'ColumnName2' => 'Value21',
        'ColumnName3' => 5
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value1',
        'ColumnName2' => 'Value11',
        'ColumnName3' => 6
      }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(rows);

    System.assertEquals(rows[0], orderedRows[4]);
    System.assertEquals(rows[1], orderedRows[2]);
    System.assertEquals(rows[2], orderedRows[0]);
    System.assertEquals(rows[3], orderedRows[5]);
    System.assertEquals(rows[4], orderedRows[3]);
    System.assertEquals(rows[5], orderedRows[1]);
  }

  /**
   * Asserts that when rows are processed without an order statement, the order of the rows remain intact
   */
  @IsTest
  static void shouldReturnSameOrderOfRowsWhenMissingOrderStatement() {
    DataSource.QueryContext queryContext = new DataSource.QueryContext();
    queryContext.tableSelection = new DataSource.TableSelection();

    List<Map<String, Object>> rows = new List<Map<String, Object>>{
      new Map<String, Object>{
        'ColumnName1' => 'Value3',
        'ColumnName2' => 'Value32',
        'ColumnName3' => 1
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value2',
        'ColumnName2' => 'Value22',
        'ColumnName3' => 2
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value1',
        'ColumnName2' => 'Value11',
        'ColumnName3' => 3
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value3',
        'ColumnName2' => 'Value31',
        'ColumnName3' => 4
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value2',
        'ColumnName2' => 'Value21',
        'ColumnName3' => 5
      },
      new Map<String, Object>{
        'ColumnName1' => 'Value1',
        'ColumnName2' => 'Value11',
        'ColumnName3' => 6
      }
    };

    C_ExternalObjectQueryHandler handler = new C_ExternalObjectQueryHandler(
      queryContext
    );
    List<Map<String, Object>> orderedRows = handler.orderRows(rows);

    System.assertEquals(
      rows,
      orderedRows,
      'The order was different the original order, should not change if order statement is missing'
    );
  }
}
