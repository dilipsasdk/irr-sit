/**
 * Service for making requests to the voucher API.
 */
public without sharing class ClaimsIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM/claim/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public static ClaimsIntegrationService newInstance() {
    return (ClaimsIntegrationService) SAS_Service_Application.Service.newInstance(
      ClaimsIntegrationService.class
    );
  }

  /** Checks whether a claim exists in CARE data in EDW for the given booking
   * reference. Returns true if one was found, false otherwise.
   *
   * @param bookingReference Booking reference to search for.
   *
   * @return Whether claims exist in EDW for the given booking reference.
   */
  public static Boolean checkIfClaimsExistForBookingReference(
    String bookingReference
  ) {
    FetchCAREClaimsQuery query = new FetchCAREClaimsQuery();
    query.pnr = bookingReference;

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.GET,
      'claim',
      query
    );

    if (response.getStatusCode() == 404) {
      return false;
    }

    return ClaimsCheckCAREResponse.parse(response.getBody()).claimsfound;
  }

  public class FetchCAREClaimsQuery extends APIMIntegrationService.BaseQuery {
    public String pnr { get; set; }
    public String caseId { get; set; }
    public String pir { get; set; }

    public override String toQueryParamString() {
      String queryParamString = '';

      queryParamString = addFieldToQueryParams(queryParamString, 'pnr', pnr);
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'caseId',
        caseId
      );
      queryParamString = addFieldToQueryParams(queryParamString, 'pir', pir);

      return queryParamString;
    }
  }

  public static FetchCAREClaimsResponse fetchClaimsByQuery(
    FetchCAREClaimsQuery query
  ) {
    if (
      !String.isBlank(query.pnr) && !Booking.isValidBookingReference(query.pnr)
    ) {
      throw new APIMIntegrationService.IllegalArgumentsException(
        'Booking reference must be 5 or 6 characters'
      );
    }

    // Request path is /claim/claimdetails/{pnr}/{pir}/{caseId}
    // Any unused ones should be replaced with '-'.

    String path = 'claimdetails';

    path += String.isBlank(query.pnr) ? '/-' : '/' + query.pnr;
    path += String.isBlank(query.pir) ? '/-' : '/' + query.pir;
    path += String.isBlank(query.caseId) ? '/-' : '/' + query.caseId;

    HttpResponse response = makeRequest(HttpUtils.HTTP_METHOD.GET, path, null);

    if (response.getStatusCode() == 404) {
      return null;
    }

    return FetchCAREClaimsResponse.parse(response.getBody());
  }

  /**
   * Constructs and fires a request to the Claims API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    APIMIntegrationService.BaseQuery query
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    if (query != null) {
      fullPath += query.toQueryParamString();
    }

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'api-version' => 'v1',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      method,
      fullPath,
      null,
      extraRequestHeaders
    );
  }
}
