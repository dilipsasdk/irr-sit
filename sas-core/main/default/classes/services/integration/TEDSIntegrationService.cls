/**
 * Service for fetching booking and flight data from the TEDS API.
 *
 * For the time being this duplicates some functionality from the IRR TEDS integration code.
 * This is intentional to not couple the teams' workflows. Let's look into a way to merge
 * these in future.
 *
 * For more information see:
 *   https://sas-digital.atlassian.net/wiki/spaces/CSSolutions/pages/2342289428/Planned%2BTEDS%2BAPI
 */
public without sharing class TEDSIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM_TEDS_FCS';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_TEDS_Subscription_Key');

  public static TEDSIntegrationService newInstance() {
    return (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );
  }

  /**
   * Query definition for searching bookings. Any fields can be set and query
   * will be combined with AND logic.
   */
  public class BookingsQuery extends APIMIntegrationService.BaseQuery {
    // return bookings that have a flight arriving to the station.
    public String arrivalStation { get; set; }
    // return bookings with the specified print status for boarding pass. NRP = needs print
    public String boardingPassPrintStatus { get; set; }
    // the CMP (Company) of the bookings to return
    public String cmp { get; set; }
    // format - date-time (as date-time in RFC3339). The earliest creation time in UTC.
    public String createdFromTimeUTC { get; set; }
    // format - date-time (as date-time in RFC3339). The latest creation time in UTC.
    public String createdToTimeUTC { get; set; }
    // list with the office ids that have created the bookings that should be returned
    public Set<String> creationOffices { get; set; }
    // the cods ID of the bookings to return
    public String codsId { get; set; }
    // return bookings that have a flight departing from the station
    public String departureStation { get; set; }
    // the eurobonus number of the bookings to return
    public String euroBonusNumber { get; set; }
    // the flight ID of the bookings to return
    public String flightId { get; set; }
    // format - date-time (as date-time in RFC3339). return bookings that have a flight departing or arriving from that time in UTC
    public String fromTimeUTC { get; set; }
    // return bookings that are Cancelled
    public String isCancelled { get; set; }
    // the phone number contained in the booking to return
    public String phoneNumber { get; set; }
    // the booking reference of the bookings to return
    public String reference { get; set; }
    // return bookings that are Active or Passed
    public String status { get; set; }
    // the ticket number of the bookings to return
    public String ticketNumber { get; set; }
    // the travel admin cods ID of the bookings to return
    public String travelAdminCodsId { get; set; }
    // format - date-time (as date-time in RFC3339). return bookings that have a flight departing or arriving to that time in UTC
    public String toTimeUTC { get; set; }

    public override String toQueryParamString() {
      String queryParamString = '';

      queryParamString = addFieldToQueryParams(
        queryParamString,
        'arrivalStation',
        arrivalStation
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'boardingPassPrintStatus',
        boardingPassPrintStatus
      );
      queryParamString = addFieldToQueryParams(queryParamString, 'cmp', cmp);
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'createdFromTimeUTC',
        createdFromTimeUTC
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'createdToTimeUTC',
        createdToTimeUTC
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'codsId',
        codsId
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'departureStation',
        departureStation
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'euroBonusNumber',
        euroBonusNumber
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'flightId',
        flightId
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'fromTimeUTC',
        fromTimeUTC
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'isCancelled',
        isCancelled
      );
      if (reference != null) {
        if (!Booking.isValidBookingReference(reference)) {
          throw new APIMIntegrationService.IllegalArgumentsException(
            'Booking reference must be 5 or 6 alphanumeric characters'
          );
        }
        queryParamString = addFieldToQueryParams(
          queryParamString,
          'reference',
          reference
        );
      }
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'phone',
        phoneNumber
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'status',
        status
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'ticketNumber',
        ticketNumber
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'travelAdminCodsId',
        travelAdminCodsId
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'toTimeUTC',
        toTimeUTC
      );
      if (creationOffices != null && !creationOffices.isEmpty()) {
        queryParamString = addFieldToQueryParams(
          queryParamString,
          'creationOffices',
          String.join(new List<String>(creationOffices), ',')
        );
      }
      return queryParamString;
    }
  }

  public class FlightsQuery extends APIMIntegrationService.BaseQuery {
    public String aircraftRegistration { get; set; }
    public String arrivalStation { get; set; }
    public String callSign { get; set; }
    public String departureDate { get; set; }
    public String departureStation { get; set; }
    public String flightNumber { get; set; }
    public Set<String> ids { get; set; }

    public override String toQueryParamString() {
      String queryParamString = '';

      queryParamString = addFieldToQueryParams(
        queryParamString,
        'aircraftRegistration',
        aircraftRegistration
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'arrivalStation',
        arrivalStation
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'callSign',
        callSign
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'departureDate',
        departureDate
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'departureStation',
        departureStation
      );
      queryParamString = addFieldToQueryParams(
        queryParamString,
        'flightNumber',
        flightNumber
      );
      if (ids != null && !ids.isEmpty()) {
        if (ids.size() > 10) {
          throw new APIMIntegrationService.IllegalArgumentsException(
            'We can only search for maximum of 10 flights at a time.'
          );
        }
        queryParamString = addFieldToQueryParams(
          queryParamString,
          'ids',
          String.join(new List<String>(ids), ',')
        );
      }

      if (queryParamString.length() == 0) {
        throw new APIMIntegrationService.IllegalArgumentsException(
          'Cannot query flights with an empty query.'
        );
      }

      return queryParamString;
    }
  }

  public class AirportsQuery extends APIMIntegrationService.BaseQuery {
    public Set<String> ids { get; set; }

    public override String toQueryParamString() {
      String queryParamString = '';

      if (ids != null && !ids.isEmpty()) {
        if (ids.size() > 10) {
          throw new APIMIntegrationService.IllegalArgumentsException(
            'We can only search for maximum of 10 airports at a time.'
          );
        }
        queryParamString = addFieldToQueryParams(
          queryParamString,
          'ids',
          String.join(new List<String>(ids), ',')
        );
      }

      if (queryParamString.length() == 0) {
        throw new APIMIntegrationService.IllegalArgumentsException(
          'Cannot query airports with an empty query.'
        );
      }

      return queryParamString;
    }
  }

  /** Fetches a single booking from TEDS based on the booking identifier.
   *
   * @param bookingIdentifier Full booking identifier in format {PNR}-{creationDate}. E.g. ABC123-20220506
   *
   * @return The parsed booking data as IRR_MOD_TedsBooking if one was found, null otherwise.
   */
  public IRR_MOD_TedsBooking fetchBookingByBookingIdentifier(
    String bookingIdentifier
  ) {
    HttpResponse response = makeRequest(
      '/teds-booking/bookings/' + bookingIdentifier,
      null
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return IRR_MOD_TedsBooking.parse(response.getBody());
  }

  /** Fetches all bookings from TEDS which match the provided query.
   *
   * @param query Query to execute.
   *
   * @return List of the found bookings, or an empty list of none were found.
   */
  public List<IRR_MOD_TedsBooking> fetchBookingsByQuery(BookingsQuery query) {
    HttpResponse response = makeRequest('/teds-booking/bookings', query);

    return (List<IRR_MOD_TedsBooking>) JSON.deserialize(
      response.getBody().replace('"number"', '"number_x"'),
      List<IRR_MOD_TedsBooking>.class
    );
  }

  /** Fetches all flights from TEDS which match the provided query.
   *
   * @param query Query to execute.
   *
   * @return List of the found flights, or an empty list of none were found.
   */
  public List<TEDSFlight> fetchFlightsByQuery(FlightsQuery query) {
    // TODO: Map<String, String>
    HttpResponse response = makeRequest('/teds-flight/flights', query);

    return TEDSFlight.parseArray(response.getBody());
  }

  /** Fetches all airports from TEDS which match the provided query.
   *
   * @param query Query to execute.
   *
   * @return List of the found airports, or an empty list of none were found.
   */
  public List<TEDSAirport> fetchAirportsByQuery(AirportsQuery query) {
    // TODO: Map<String, String>
    HttpResponse response = makeRequest('/teds-airport/airports', query);
    return TEDSAirport.parseArray(response.getBody());
  }

  /**
   * Constructs and fires a request to the TEDS API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private HttpResponse makeRequest(
    String path,
    APIMIntegrationService.BaseQuery query
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    if (query != null) {
      fullPath += query.toQueryParamString();
    }

    System.debug(fullPath);

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'api-version' => 'v2',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      HttpUtils.HTTP_METHOD.GET,
      fullPath,
      null,
      extraRequestHeaders
    );
  }
}
