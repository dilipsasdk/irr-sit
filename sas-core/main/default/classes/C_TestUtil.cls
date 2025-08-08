/**
 * @author Anton Norell
 * @date 2019-12-09
 * @description Utility methods to be used by test classes.
 */
public with sharing class C_TestUtil {
    /**
     * Helper method used to generate a filter for use in QueryIterator class
     * @param type Filter type, Enum from DataSource.FilterType
     * @param columnName Name of columns to filter
     * @param columnValue Value to filter column by
     * @return Generated filter based on input values
     */
    public static DataSource.Filter generateFilter(DataSource.FilterType type, String columnName, Object columnValue){
        DataSource.Filter filter = new DataSource.Filter();
        filter.type = type;
        filter.columnName = columnName;
        filter.columnValue = columnValue;
        return filter;
    }
}