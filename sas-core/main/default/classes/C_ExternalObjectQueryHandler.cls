/**
 * @author Anton Norell
 * @date 2019-11-30
 * @description This class contains tools for parsing a query for an external object and performing operations
 * connected to the query, e.g. retrieving filter values or applying filters in query on a list of data rows
 * from an external system.
 * The class needs to be instantiated and can be used for any external object.
 */
public with sharing class C_ExternalObjectQueryHandler {
  /**
   * TableSelection variable for QueryContext supplied in constructor. Filter and Order variables
   * used in this class are references through the this variable.
   */
  private DataSource.TableSelection tableSelection;

  /**
   * Holds extracted, valid API search terms from a query when is is iterated. Only used within the class.
   */
  private Map<String, Set<Object>> validApiSearchTermsAndValues;

  /**
   * Variable used to store the list of order clauses for a query when the ordering function is called.
   */
  private static List<DataSource.Order> orderList;

  /**
   * Constructor for class. Extracts values from the QueryContext needed by methods in the class to class variables.
   * @param queryContext QueryContext object for the query for an external object.
   */
  public C_ExternalObjectQueryHandler(DataSource.QueryContext queryContext) {
    tableSelection = queryContext.tableSelection;
  }

  /**
   * Used to filter supplied rows based on the query supplied for class instance.
   * @param rows List of rows to be filtered.
   * @return List of filtered rows.
   */
  public List<Map<String, Object>> filterRows(List<Map<String, Object>> rows) {
    List<Map<String, Object>> validRows = new List<Map<String, Object>>();
    for (Map<String, Object> row : rows) {
      QueryRowHandler queryIterator = new QueryRowHandler(row);
      Boolean filterResult = queryIterator.filterRow(tableSelection.filter);
      if (filterResult)
        validRows.add(row);
    }
    return validRows;
  }

  /**
   * Used to order supplied rows based on the query supplied for class instance.
   * @param rows List of rows to be ordered.
   * @return Ordered list with rows. If no order clause exists, the original list is returned.
   */
  public List<Map<String, Object>> orderRows(List<Map<String, Object>> rows) {
    if (tableSelection.order != null && tableSelection.order.size() != 0) {
      orderList = tableSelection.order;
      List<DataRowSortWrapper> wrappers = new List<DataRowSortWrapper>();
      for (Map<String, Object> row : rows) {
        wrappers.add(new DataRowSortWrapper(row));
      }
      wrappers.sort();
      List<Map<String, Object>> orderedRows = new List<Map<String, Object>>();
      for (DataRowSortWrapper wrapper : wrappers) {
        orderedRows.add(wrapper.dataRow);
      }
      return orderedRows;
    }
    return rows;
  }

  /**
   * Used to retrieve terms and values to use in API call from query based on a supplied set of valid terms.
   * This method is exposed externally and calls an internal method to iterate over query filter.
   * @param validApiSearchTerms Set of valid search terms for the integration used to retrieve data.
   * @return Map with valid search terms as key and set of values to search for as value
   */
  public Map<String, Set<Object>> getApiSearchTermsAndValues(
    Set<String> validApiSearchTerms
  ) {
    validApiSearchTermsAndValues = new Map<String, Set<Object>>();
    extractValidApiSearchTermsAndValues(
      tableSelection.filter,
      validApiSearchTerms
    );
    return this.validApiSearchTermsAndValues;
  }

  /**
   * Internal method used to iterate over a query filter and extract terms and values that can be used to search
   * for data in an external system. The method runs recursively for each sub filter in the query.
   * The extracted terms and values are stored in a class variable during execution.
   * @param filter Filter to iterate over and extract terms
   * @param validApiSearchTerms Set of valid search terms to
   */
  @TestVisible
  private void extractValidApiSearchTermsAndValues(
    DataSource.Filter filter,
    Set<String> validApiSearchTerms
  ) {
    if (filter.subfilters != null) {
      for (DataSource.Filter subFilter : filter.subfilters) {
        extractValidApiSearchTermsAndValues(subFilter, validApiSearchTerms);
      }
    } else {
      if (validApiSearchTerms.contains(filter.columnName)) {
        if (validApiSearchTermsAndValues.get(filter.columnName) == null) {
          validApiSearchTermsAndValues.put(
            filter.columnName,
            new Set<Object>{ filter.columnValue }
          );
        } else {
          validApiSearchTermsAndValues.get(filter.columnName)
            .add(filter.columnValue);
        }
      }
    }
  }

  /**
   * @author Anton Norell
   * @date 2019-11-30
   * @description Internal class used to handle operations connected to an individual row
   * returned after an outbound call to an external system
   */
  @TestVisible
  private class QueryRowHandler {
    /**
     * Individual row to iterate. Supplied in constructor.
     */
    private Map<String, Object> row;

    /**
     * Constructor for class
     * @param row Individual row to iterate
     */
    public QueryRowHandler(Map<String, Object> row) {
      this.row = row;
    }

    /**
     * Used to apply a filter from a query on an individual data row returned from an external system.
     * The method runs recursively for all sub filters in query
     * @param filter
     * @return
     */
    @TestVisible
    private Boolean filterRow(DataSource.Filter filter) {
      Integer filtersTrue = 0;
      Integer numberOfSubFilters = filter.subfilters != null
        ? filter.subfilters.size()
        : 0;
      if (filter.subfilters != null) {
        for (DataSource.Filter subFilter : filter.subfilters) {
          if (filterRow(subFilter) == true)
            filtersTrue++;
        }
      } else {
        if (evaluateFilter(filter))
          filtersTrue++;
      }
      if (filter.type == DataSource.FilterType.AND_) {
        if (filtersTrue == numberOfSubFilters) {
          return true;
        }
      } else if (filtersTrue >= 1) {
        return true;
      }
      return false;
    }

    /**
     * Helper method used to evaluate an individual filter for a row during execution.
     * The method contains comparisons for expression supported in a query for external objects.
     * @param filter
     * @return
     */
    private Boolean evaluateFilter(DataSource.Filter filter) {
      Object filterValue = filter.columnValue;
      Object actualValue = row.get(filter.columnName);

      if (filter.type == DataSource.FilterType.EQUALS) {
        if (filterValue == actualValue)
          return true;
      } else if (filter.type == DataSource.FilterType.NOT_EQUALS) {
        if (filterValue != actualValue)
          return true;
      } else if (filter.type == DataSource.FilterType.LIKE_) {
        throw new QueryException(
          'LIKE is not a valid expression for this object'
        );
      } else if (filter.type == DataSource.FilterType.GREATER_THAN) {
        if (filterValue instanceof Integer) {
          if (Integer.valueOf(filterValue) < Integer.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof String) {
          if (String.valueOf(filterValue) < String.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Boolean) {
          if (
            Boolean.valueOf(filterValue) == false &&
            Boolean.valueOf(actualValue) == true
          )
            return true;
        } else if (filterValue instanceof Date) {
          if (Date.valueOf(filterValue) < Date.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Datetime) {
          if (Datetime.valueOf(filterValue) < Datetime.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Decimal) {
          if (Double.valueOf(filterValue) < Double.valueOf(actualValue))
            return true;
        }
      } else if (
        filter.type == DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO
      ) {
        if (filterValue instanceof Integer) {
          if (Integer.valueOf(filterValue) <= Integer.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof String) {
          if (String.valueOf(filterValue) <= String.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Boolean) {
          return true;
        } else if (filterValue instanceof Date) {
          if (Date.valueOf(filterValue) <= Date.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Datetime) {
          if (Datetime.valueOf(filterValue) <= Datetime.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Decimal) {
          if (Double.valueOf(filterValue) <= Double.valueOf(actualValue))
            return true;
        }
      } else if (filter.type == DataSource.FilterType.LESS_THAN) {
        if (filterValue instanceof Integer) {
          if (Integer.valueOf(filterValue) > Integer.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof String) {
          if (String.valueOf(filterValue) > String.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Boolean) {
          if (
            Boolean.valueOf(filterValue) == true &&
            Boolean.valueOf(actualValue) == false
          )
            return true;
        } else if (filterValue instanceof Date) {
          if (Date.valueOf(filterValue) > Date.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Datetime) {
          if (Datetime.valueOf(filterValue) > Datetime.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Decimal) {
          if (Double.valueOf(filterValue) > Double.valueOf(actualValue))
            return true;
        }
      } else if (filter.type == DataSource.FilterType.LESS_THAN_OR_EQUAL_TO) {
        if (filterValue instanceof Integer) {
          if (Integer.valueOf(filterValue) >= Integer.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof String) {
          if (String.valueOf(filterValue) >= String.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Boolean) {
          return true;
        } else if (filterValue instanceof Date) {
          if (Date.valueOf(filterValue) >= Date.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Datetime) {
          if (Datetime.valueOf(filterValue) >= Datetime.valueOf(actualValue))
            return true;
        } else if (filterValue instanceof Decimal) {
          if (Double.valueOf(filterValue) >= Double.valueOf(actualValue))
            return true;
        }
      }
      return false;
    }
  }

  /**
   * @author Anton Norell
   * @date 2019-12-06
   * @description Wrapper class to enable ordering of a list of data rows. Each data row is wrapped and the comparable
   * interface is implemented for the wrapper to support sorting of the wrapper records.
   */
  private class DataRowSortWrapper implements Comparable {
    /**
     * Holds the wrapped row which values should be used to sort a list
     */
    private Map<String, Object> dataRow;

    /**
     * Constructor for class that wraps the provided data row
     * @param row
     */
    public DataRowSortWrapper(Map<String, Object> dataRow) {
      this.dataRow = dataRow;
    }

    /**
     * Implementation of comparable interface, allowing standard sorting of a customer object. Iterates
     * over a map with values to order rows by
     * @param compareToObject Object to compare the contextual object to
     * @return Returns an integer representing the objects relative position in the list
     */
    public Integer compareTo(Object compareToObject) {
      DataRowSortWrapper compareToWrapper = (DataRowSortWrapper) compareToObject;
      for (DataSource.Order order : orderList) {
        Integer res = 0;
        res = compareField(
          this.dataRow.get(order.columnName),
          compareToWrapper.dataRow.get(order.columnName),
          order.direction
        );
        if (res != 0)
          return res;
      }
      return 0;
    }

    /**
     * Helper method used to handle the fact that the values of rows for External Objects are always
     * returned as objects. This method casts the object to its intended data type, allowing a comparison to be made.
     * @param o1 The first object to compare
     * @param o2 The second object to compare
     * @param orderAscending If the order should be in ascending direction
     * @return Returns object o1s relative position to object o2
     */
    private Integer compareField(
      Object o1,
      Object o2,
      DataSource.OrderDirection orderDirection
    ) {
      Integer res = 0;
      if (o1 instanceof Integer) {
        Integer value1 = (Integer) o1;
        Integer value2 = (Integer) o2;
        if (value1 < value2)
          res = 1;
        else if (value1 > value2)
          res = -1;
      } else if (o1 instanceof String) {
        String value1 = (String) o1;
        String value2 = (String) o2;
        if (value1 < value2)
          res = 1;
        else if (value1 > value2)
          res = -1;
      } else if (o1 instanceof Boolean) {
        Boolean value1 = (Boolean) o1;
        Boolean value2 = (Boolean) o2;
        if (value1 == false && value2 == true)
          res = 1;
        else if (value1 == true && value2 == false)
          res = -1;
      } else if (o1 instanceof Date) {
        Date value1 = (Date) o1;
        Date value2 = (Date) o2;
        if (value1 < value2)
          res = 1;
        else if (value1 > value2)
          res = -1;
      } else if (o1 instanceof Datetime) {
        Datetime value1 = (Datetime) o1;
        Datetime value2 = (Datetime) o2;
        if (value1 < value2)
          res = 1;
        else if (value1 > value2)
          res = -1;
      } else if (o1 instanceof Decimal) {
        Decimal value1 = (Decimal) o1;
        Decimal value2 = (Decimal) o2;
        if (value1 < value2)
          res = 1;
        else if (value1 > value2)
          res = -1;
      }
      if (res != 0 && orderDirection == DataSource.OrderDirection.ASCENDING) {
        res = res * -1;
      }
      return res;
    }
  }

  public class QueryException extends Exception {
  }
}
