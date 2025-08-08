/**
 * @author Anton Norell
 * @date 2019-12-03
 * @description Test class for C_TestUtil.
 */
@IsTest
private class C_TestUtil_Test {
    @IsTest
    static void shouldReturnGeneratedExternalObjectQueryFilter(){
        DataSource.Filter filter = C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Column', 'Value');

        System.assertEquals('Column', filter.columnName, 'Filter generator did not set the correct column name');
        System.assertEquals('Value', filter.columnValue, 'Filter generator did not set the correct column value');
    }
}