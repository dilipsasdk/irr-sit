/**
 * Service for making requests to the EDW Flight Data API.
 */
public without sharing class EDWIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM/claim/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public static EDWIntegrationService newInstance() {
    return (EDWIntegrationService) SAS_Service_Application.Service.newInstance(
      EDWIntegrationService.class
    );
  }

  public class FetchEDWBookingsQuery extends APIMIntegrationService.BaseQuery {
    public String pnr { get; set; }

    public override String toQueryParamString() {
      String queryParamString = '';
      queryParamString = addFieldToQueryParams(queryParamString, 'pnr', pnr);
      return queryParamString;
    }
  }

  public static FetchEDWBookingResponse fetchEDWBookingsByQuery(
    FetchEDWBookingsQuery query
  ) {
    if (
      !String.isBlank(query.pnr) && !Booking.isValidBookingReference(query.pnr)
    ) {
      throw new APIMIntegrationService.IllegalArgumentsException(
        'Booking reference must be 5 or 6 characters'
      );
    }

    // Request path is /claim/claimdetails/{pnr}

    String path = 'bookingdetails';

    path += String.isBlank(query.pnr) ? '/-' : '/' + query.pnr;

    HttpResponse response = makeRequest(HttpUtils.HTTP_METHOD.GET, path, null);

    if (response.getStatusCode() == 404) {
      return null;
    }

    return FetchEDWBookingResponse.parse(response.getBody());
  }

  /**
   * Constructs and fires a request to the EDW API.
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
