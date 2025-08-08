@isTest
global class APIMMock implements HttpCalloutMock {
  public static final String INVALID_BOOKING_REFERENCE = 'AAAAAA';
  public static final String EB_NUMBER_WITH_BOOKINGS = '123456789';
  public static final String BOOKING_REFERENCE_WITH_DELAY = 'DELAY1';
  public static final String EB_NUMBER_WITHOUT_BOOKINGS = 'TEST654321';
  public static final String CLM_TRANSACTION_ID = '0000000001';
  public static final String EB_NUMBER_NOT_IN_CLM = '987654321';
  public static final String EB_NUMBER_RETURN_500 = '777777777';
  public static final String VOUCHER_INVALID_EMAIL = 'invalidemail@invalidemail.invalidemail';
  public static final String VOUCHER_VALID_CARD_ID = '1234567890';
  public static final String VOUCHER_VALID_PNR = 'ABC123';
  public static final String PNR_FOR_WHICH_CLAIMS_EXIST = '987654';
  public static final String PIR_FOR_WHICH_CLAIMS_EXIST = 'MIASK10139';
  public static final String PNR_FOR_WHICH_CLAIMS_DO_NOT_EXIST = '000000';
  public static final String DEFAULT_VALID_TEDS_PNR = 'TEST21';
  public static final String DEFAULT_VALID_TEDS_BOOKING_DATE = '20201126';
  public static final String DEFAULT_VALID_TEDS_TICKET_NUMBER = '117-1234567890';
  public static final String DELAYED_FLIGHT_ID_1 = 'SK0903-20210410-ARN-EWR';
  public static final String DELAYED_FLIGHT_ID_2 = 'WF0075-20220531-TRD-OSL';
  public static final String CANCELLED_FLIGHT_ID = 'LH2434-20220531-MUC-BLL';
  public static final String FLIGHT_WITH_LONG_REASON = 'SK0909-20200410-ARN-CPH';
  public static final String EDW_SINGLE_PNR = 'UUWBU6';
  public static final String EDW_OTHER_PNR = 'AABBC3';
  public static final String EDW_BOOKING_DATE = '20220114';
  public static final String VALID_VO_VOUCHER_NUMBER = '8821852672';
  public static final String VALID_VO_VOUCHER_ACCESS_CODE = 'ABC123';

  public static final String DEFAULT_VALID_TEDS_IDENTIFIER =
    DEFAULT_VALID_TEDS_PNR +
    '-' +
    DEFAULT_VALID_TEDS_BOOKING_DATE;
  public static final String EDW_IDENTIFIER =
    EDW_SINGLE_PNR +
    '-' +
    EDW_BOOKING_DATE;

  private String endpoint;

  global HttpResponse respond(HttpRequest req) {
    endpoint = req.getEndpoint();
    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);
    if (endpoint.contains('teds-flight')) {
      res.setHeader('Content-Type', 'application/json');
      if (
        endpoint.contains(DELAYED_FLIGHT_ID_1) ||
        endpoint.contains(DELAYED_FLIGHT_ID_2)
      ) {
        res.setBody(APIMMockResponses.DELAYED_FLIGHT_RESPONSE_BODY);
      } else if (endpoint.contains(CANCELLED_FLIGHT_ID)) {
        res.setBody(APIMMockResponses.CANCELLED_FLIGHT_RESPONSE_BODY);
      } else if (endpoint.contains(FLIGHT_WITH_LONG_REASON)) {
        res.setBody(APIMMockResponses.FLIGHT_WITH_LONG_REASON_BODY);
      } else {
        res.setBody(APIMMockResponses.FLIGHT_RESPONSE_BODY);
      }
    } else if (endpoint.contains('/teds-booking/bookings/')) {
      res.setHeader('Content-Type', 'application/json');
      // Single booking
      String reference = endpoint.substring(
        endpoint.length() - 6,
        endpoint.length()
      );
      if (reference == INVALID_BOOKING_REFERENCE) {
        res.setStatusCode(404);
        res.setHeader('Content-Type', 'text/plain');
        res.setBody('Not found');
      } else {
        res.setBody(
          APIMMockResponses.SINGLE_BOOKING_RESPONSE_BODY.replace(
              '{bookingReference}',
              reference
            )
            .replace('{bookingDate}', DEFAULT_VALID_TEDS_BOOKING_DATE)
        );
      }
    } else if (endpoint.contains('/teds-booking/bookings?')) {
      String reference = getQueryParam('reference');
      String euroBonusNumber = getQueryParam('euroBonusNumber');
      if (
        reference == INVALID_BOOKING_REFERENCE ||
        euroBonusNumber == EB_NUMBER_WITHOUT_BOOKINGS
      ) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[]');
      } else if (reference == BOOKING_REFERENCE_WITH_DELAY) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
          APIMMockResponses.DELAYED_BOOKING_RESPONSE_BODY.replace(
              '{bookingReference}',
              reference
            )
            .replace('{bookingDate}', DEFAULT_VALID_TEDS_BOOKING_DATE)
        );
      } else {
        // Bookings query
        res.setHeader('Content-Type', 'application/json');
        if (String.isBlank(euroBonusNumber)) {
          euroBonusNumber = 'TEST987654';
        }
        if (String.isBlank(reference)) {
          reference = DEFAULT_VALID_TEDS_PNR;
        }

        res.setBody(
          APIMMockResponses.BOOKINGS_QUERY_RESPONSE_BODY.replace(
              '{bookingReference}',
              reference
            )
            .replace('{euroBonusNumber}', euroBonusNumber)
            .replace('{bookingDate}', DEFAULT_VALID_TEDS_BOOKING_DATE)
        );
      }
    } else if (endpoint.contains('/teds-airport/airports?')) {
      res.setHeader('Content-Type', 'application/json');
      String ids = getQueryParam('ids');
      if (ids == 'RUN') {
        res.setBody(APIMMockResponses.AIRPORT_RESPONSE_BODY_SPECIAL_TERRITORY);
      } else if (ids.contains('ITM')) {
        res.setBody(APIMMockResponses.AIRPORT_RESPONSE_BODY_MULTIPLE);
      } else {
        res.setBody(APIMMockResponses.AIRPORT_RESPONSE_BODY_MULTIPLE);
      }
    } else if (endpoint.contains('csharkservice')) {
      if (
        req.getHeader('SOAPAction') ==
        CSharkIntegrationService.SOAP_ACTION_HEADER_BASE +
        String.valueOf(
          CSharkIntegrationService.OperationName.TPAccountGetTicketless
        )
      ) {
        res.setHeader('Content-Type', 'text/xml');
        res.setBody(APIMMockResponses.TP_ACCOUNT_RESPONSE_BODY);
      } else {
        res.setStatusCode(404);
      }
    } else if (
      endpoint.contains('vouchers') && !endpoint.contains('orchestration')
    ) {
      if (endpoint.contains('validate')) {
        // VoucherIntegrationService.validateVoucher
        if (
          endpoint.contains(VOUCHER_VALID_CARD_ID) &&
          endpoint.contains(VOUCHER_VALID_PNR)
        ) {
          // Valid voucher
          res.setHeader('Content-Type', 'application/json');
          res.setBody(
            '{"departureTime": "","lastName": "Testsson","ticketNumber": 11712345678,"amount": 400,"flightDate": "2022-05-12","serviceClass": "a","type": "a","flightNumber": "SK1","firstName": "Test","phone": "0000000000","pnr": "abc123","subType": "a","currency": "EUR","email": "test@example.com"}'
          );
        } else {
          // Invalid voucher
          res.setStatusCode(404);
        }
      } else if (req.getBody().contains(VOUCHER_INVALID_EMAIL)) {
        // VoucherIntegrationService.createVoucher
        res.setStatusCode(400);
      } else {
        // VoucherIntegrationService.createVoucher
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"link":"test.sas.se", "caseId": "12345678"}');
      }
    } else if (endpoint.contains('voucher-orchestration')) {
      if (endpoint.contains('vouchers/create')) {
        if (req.getBody().contains(VOUCHER_INVALID_EMAIL)) {
          res.setStatusCode(400);
        } else {
          res.setHeader('Content-Type', 'application/json');
          res.setBody(
            '{"vouchers":[{"id":"49079ce0-c81c-5898-b829-5c10a41c06cd","number":"1400010063760352"}],"expiry":"2024-06-25T11:21:51+00:00"}'
          );
        }
      } else if (endpoint.contains('compensation/validate')) {
        res.setHeader('Content-Type', 'application/json');
        if (
          !req.getBody().contains(VALID_VO_VOUCHER_ACCESS_CODE) &&
          !req.getBody().contains(VALID_VO_VOUCHER_NUMBER)
        ) {
          res.setStatusCode(404);
        } else {
          res.setBody(
            APIMMockResponses.VOUCHER_COMPENSATION_VALIDATE_RESPONSE_BODY
          );
        }
      } else {
        res.setStatusCode(404);
      }
    } else if (endpoint.contains('claim/claimdetails')) {
      if (
        endpoint.contains(PNR_FOR_WHICH_CLAIMS_EXIST) ||
        endpoint.contains(PIR_FOR_WHICH_CLAIMS_EXIST)
      ) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.CARE_CLAIM_DETAILS_FOUND);
      } else if (endpoint.contains(PNR_FOR_WHICH_CLAIMS_DO_NOT_EXIST)) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.CARE_CLAIM_DETAILS_NOT_FOUND);
      } else {
        res.setStatusCode(404);
      }
    } else if (endpoint.contains('claim/claim')) {
      if (endpoint.contains(PNR_FOR_WHICH_CLAIMS_EXIST)) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.CARE_CLAIM_FOUND);
      } else {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.CARE_CLAIM_NOT_FOUND);
      }
    } else if (endpoint.contains('claim/bookingdetails')) {
      if (endpoint.contains(EDW_SINGLE_PNR)) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.EDW_BOOKING_DATA_SINGLE_BOOKING_RETURN);
      } else if (endpoint.contains(EDW_OTHER_PNR)) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.EDW_BOOKING_DATA_OTHER);
      } else {
        res.setStatusCode(404);
      }
    } else if (endpoint.contains('customercare')) {
      res.setStatusCode(200);
    } else if (endpoint.contains('/clm/callcenter/addPoints')) {
      if (req.getBody().contains(EB_NUMBER_NOT_IN_CLM)) {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(APIMMockResponses.CLM_ADD_POINTS_FAILURE_BODY);
        res.setStatusCode(400);
      } else if (req.getBody().contains(EB_NUMBER_RETURN_500)) {
        res.setStatusCode(500);
      } else {
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
          APIMMockResponses.CLM_ADD_POINTS_SUCCESS_BODY.replace(
            '{clmTransactionId}',
            CLM_TRANSACTION_ID
          )
        );
      }
    } else if (endpoint.contains('SSIAdapter')) {
      res.setBody(APIMMockResponses.CONTENTFUL_DATA);
    } else {
      res.setStatusCode(404);
    }
    return res;
  }

  /**
   * Returns the value for the given query parameter for this request.
   *
   * Naive implementation and breaks down with nested special characters, but
   * should be good enough for testing.
   */
  private String getQueryParam(String paramName) {
    String toReturn = endpoint.substringBetween(paramName + '=', '&');
    if (toReturn == null) {
      // Nothing found between param name and a following ampersand. Let's
      // check if it is the last param.
      toReturn = endpoint.substringAfter(paramName + '=');
    }
    return toReturn;
  }
}
