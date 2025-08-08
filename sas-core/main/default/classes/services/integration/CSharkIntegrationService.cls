/**
 * Exposes C-Shark endpoints as an internal service. C-Shark provides
 * connectivity to various system, e.g. CODS, for fetching retrieving customer
 * data. Connection to C-Shark goes through SAS APIM.
 *
 * The service handles querying for the service through APIMIntegrationService
 * and parsing of the results using CSharkResponseParser.
 *
 * See Confluence for more details.
 */
public with sharing class CSharkIntegrationService {
  /**
   * Supported operation names for C-Shark services
   */
  public enum OperationName {
    CustomerGet,
    CustomersGet,
    TPAccountGetTicketless
  }

  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public static final String SOAP_ACTION_HEADER_BASE = 'http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1/ICSharkCustomerManagementTicketless/';
  private static final String API_PATH = 'callout:SAS_APIM/csharkservice';

  /**
   * Supported parameters to base search for customer on. The format of these search types
   * correspond with valid search terms in the C-Shark service.
   */
  public enum SearchType {
    EB_NUMBER,
    CODS_ID,
    TP_ACCOUNT,
    EMAIL,
    SITE_MEMBER,
    SUBSCRIPTION_ID
  }

  /**
   * Queries C-Shark for customer info based on given SearchType and search string. Returns a list of customers
   * matching the search query. Can query both CustomerGet and CustomersGet SOAPActions from C-Shark depending
   * on search type.
   *
   * @param searchEngagementType Type of identifier for customer to search with.
   * @param engagementSearchKey Value to search for, based on search type, e.g. a EuroBonus number
   * @throws APIMIntegrationError In case of an error when fetching data.
   * @return List of customer data
   */
  public static List<Map<String, Object>> getCustomer(
    SearchType searchEngagementType,
    String engagementSearchKey
  ) {
    Map<SearchType, String> searchTypeToTerm = new Map<SearchType, String>{
      SearchType.EB_NUMBER => 'EuroBonus',
      SearchType.CODS_ID => 'Default',
      SearchType.TP_ACCOUNT => 'TP',
      SearchType.EMAIL => 'Email',
      SearchType.SITE_MEMBER => 'SiteMember',
      SearchType.SUBSCRIPTION_ID => 'Subscription'
    };
    String engagementSearchType = searchTypeToTerm.get(searchEngagementType);

    DOM.Document requestBody;

    Boolean isCustomersGet = searchEngagementType == SearchType.EMAIL;

    if (isCustomersGet) {
      Map<String, String> requestData = new Map<String, String>{
        'SearchType' => engagementSearchType,
        'SearchKey' => engagementSearchKey,
        'FirstName' => ''
      };
      requestBody = constructSoapRequestBody(
        OperationName.CustomersGet,
        requestData
      );
    } else {
      Map<String, String> requestData = new Map<String, String>{
        'searchEngagementType' => engagementSearchType,
        'engagementSearchKey' => engagementSearchKey
      };
      requestBody = constructSoapRequestBody(
        OperationName.CustomerGet,
        requestData
      );
    }

    HttpResponse response = makeRequest(
      isCustomersGet ? OperationName.CustomersGet : OperationName.CustomerGet,
      requestBody
    );

    return isCustomersGet
      ? CSharkResponseParser.parseCustomersGetResponse(response.getBody())
      : CSharkResponseParser.parseCustomerGetResponse(response.getBody());
  }

  /**
   * Fetches travel pass account based on the travel pass account number
   * from C-Shark.
   *
   * @param TPAccountNumber Travel Pass account number to search with.
   * @throws APIMIntegrationError In case of an error when fetching data.
   * @return Parsed response as a TPAccount
   */
  public static TpAccount getTPAccount(String TPAccountNumber) {
    Map<String, String> requestData = new Map<String, String>{
      'travelPassAccountNumber' => TPAccountNumber,
      'optIn' => 'ProductCategoryAll' // What to include in C-Shark response. Must have a value.
    };
    DOM.Document requestBody = constructSoapRequestBody(
      OperationName.TPAccountGetTicketless,
      requestData
    );

    HttpResponse response = makeRequest(
      OperationName.TPAccountGetTicketless,
      requestBody
    );

    return CSharkResponseParser.parseTPAccountGetTicketlessResponse(
      response.getBody()
    );
  }

  /**
   * Constructs the SOAP request body in a format expected by C-Shark.
   *
   * @param operationName The name of the SOAP operation included in the body.
   * @param requestDataNodes A map of XML node names to XML node text contents which should be included in the request.
   */
  @TestVisible
  private static DOM.Document constructSoapRequestBody(
    OperationName operationName,
    Map<String, String> requestDataNodes
  ) {
    String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
    String cSharkNS = 'http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1';

    DOM.Document doc = new DOM.Document();
    DOM.XmlNode envelope = doc.createRootElement('Envelope', soapNS, '');

    DOM.XmlNode body = envelope.addChildElement('Body', soapNS, '');

    DOM.XmlNode operation = body.addChildElement(
      String.valueOf(operationName),
      cSharkNS,
      ''
    );
    operation.setAttribute('xsi', 'http://www.w3.org/2001/XMLSchema-instance');

    for (String key : requestDataNodes.keySet()) {
      operation.addChildElement(key, null, null)
        .addTextNode(requestDataNodes.get(key));
    }

    return doc;
  }

  private static HttpResponse makeRequest(
    OperationName operation,
    DOM.Document requestBody
  ) {
    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Content-Type' => 'text/xml',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY,
      'SOAPAction' => SOAP_ACTION_HEADER_BASE + String.valueOf(operation)
    };

    return APIMIntegrationService.makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      API_PATH,
      requestBody.toXmlString(),
      extraRequestHeaders
    );
  }
}
