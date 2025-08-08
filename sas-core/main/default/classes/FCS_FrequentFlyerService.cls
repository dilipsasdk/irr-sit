/**
 * Service class for logic related to external object Frequent Flyer.
 * Primarily parses Frequent Flyer queries, and routes them to
 * CSharkIntegrationService.
 */
public with sharing class FCS_FrequentFlyerService {
  private static final Map<String, CSharkIntegrationService.SearchType> SEARCH_FIELD_TO_C_SHARK_SEARCH_TYPE = new Map<String, CSharkIntegrationService.SearchType>{
    'EuroBonusNumber' => CSharkIntegrationService.SearchType.EB_NUMBER,
    'TravelPassAccountNumber' => CSharkIntegrationService.SearchType.TP_ACCOUNT,
    'ExternalId' => CSharkIntegrationService.SearchType.CODS_ID,
    'HomeE-mail' => CSharkIntegrationService.SearchType.EMAIL,
    'SubscriptionID' => CSharkIntegrationService.SearchType.SUBSCRIPTION_ID,
    'UserName' => CSharkIntegrationService.SearchType.SITE_MEMBER
  };

  /**
   * Contains the valid fields to search for in the C-Shark API. The values correspond with the field
   * named returned in the service and are used as database named on external objects using the service,
   * e.g. Frequent Flyer. The values are used when translating a query to valid Search Terms for the API.
   */
  private static final Set<String> VALID_API_SEARCH_FIELD_NAMES = new Set<String>{
    'EuroBonusNumber',
    'TravelPassAccountNumber',
    'ExternalId',
    'HomeE-mail'
  };

  public class InvalidSearchException extends Exception {
  }

  /**
   * Used to handle a query for Frequent Flyer object. Extracts terms to search for in external system,
   * filters result based on additional filters, orders rows and returns a table with the result.
   *
   * @param queryContext QueryContext object for query
   * @throws APIMIntegrationService.IntegrationException In case of an error when fetching data.
   * @throws InvalidSearchException In case of invalid search queries.
   * @return Result table for query
   */
  public static DataSource.TableResult handleQuery(
    DataSource.QueryContext queryContext
  ) {
    if (queryContext.tableSelection.filter == null) {
      throw new InvalidSearchException(
        'The query must include a valid search term for the C-Shark API'
      );
    }

    C_ExternalObjectQueryHandler queryHandler = new C_ExternalObjectQueryHandler(
      queryContext
    );

    Map<String, Set<Object>> validApiSearchTermsAndValues = queryHandler.getApiSearchTermsAndValues(
      VALID_API_SEARCH_FIELD_NAMES
    );

    if (validApiSearchTermsAndValues.size() == 0) {
      throw new InvalidSearchException(
        'The query must include a valid search term for the C-Shark API'
      );
    }

    // There should be only 1 search term and value.
    String searchTerm = new List<String>(
      validApiSearchTermsAndValues.keySet()
    )[0];
    List<Object> searchValues = new List<Object>(
      validApiSearchTermsAndValues.get(searchTerm)
    );
    if (searchValues.size() > 1) {
      throw new InvalidSearchException(
        'Only one search value per field can be included in the query for this service'
      );
    }

    Object searchValue = searchValues[0];

    CSharkIntegrationService.SearchType searchType = SEARCH_FIELD_TO_C_SHARK_SEARCH_TYPE.get(
      searchTerm
    );

    List<Map<String, Object>> customerRowsFromCShark = CSharkIntegrationService.getCustomer(
      searchType,
      String.valueOf(searchValue)
    );

    List<Map<String, Object>> processedCustomerRows = queryHandler.orderRows(
      queryHandler.filterRows(customerRowsFromCShark)
    );

    if (processedCustomerRows.size() > 1) {
      // We are currently always expecting to get a single result from C-Shark
      // when querying for customer profiles. However, querying with an email
      // address may return several accounts as there are some situations
      // where there are several customer profiles with the same email address.
      // 
      // We have no way for automatically figuring out which account is the
      // one we are looking for, so we simply don't want to return anything.

      return DataSource.TableResult.get(
        queryContext.tableSelection,
        new List<Map<String, Object>>()
      );
    }

    DataSource.TableResult tableResult = Datasource.TableResult.get(
      queryContext.tableSelection,
      processedCustomerRows
    );
    return tableResult;
  }
}
