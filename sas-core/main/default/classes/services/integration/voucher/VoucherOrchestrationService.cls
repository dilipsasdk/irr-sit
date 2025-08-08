/**
 * Service for making requests to the voucher API.
 */
public without sharing class VoucherOrchestrationService {
  private static final String API_PATH = 'callout:SAS_VO/voucher-orchestration';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('CLM').get('CLM_APIM_Subscription_Key');

  public static VoucherOrchestrationService newInstance() {
    return (VoucherOrchestrationService) SAS_Service_Application.Service.newInstance(
      VoucherOrchestrationService.class
    );
  }

  public class InvalidVoucherException extends Exception {
  }

  public enum VoucherType {
    EU261,
    CARE,
    GOODWILL,
    DAMAGEBAG,
    DELAYEDBAG,
    PILFBAG,
    VDBCOMP, // voluntary denied boarding
    IDBCOMP, // involuntary denied boarding
    VDGCOMP, // voluntary downgrading comp
    IDGCOMP, // involuntary downgrading comp
    GRNDTRNS, // ground transport
    SLBKSEAT, // sell back seat
    COVID19,
    RTCREDIT,
    NRTBONUS,
    EBPAAMEX
  }

  public enum VoucherCurrency {
    SEK,
    EUR
  }

  /** Attempts to create a voucher with the given information.
   *
   * @param voucherToCreate Details for the voucher.
   *
   * @return The parsed response data as VoucherCreateResponse on success.
   */
  public VoucherCreateResponseV2 createVoucher(
    VoucherCreateRequestV2 voucherToCreate
  ) {
    String fullPath = API_PATH + '/vouchers/create';

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      fullPath,
      JSON.serialize(voucherToCreate).replace('voucherCurrency', 'currency')
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return VoucherCreateResponseV2.parse(response.getBody());
  }

  /** Attempts to validate a voucher with the given information. Validation
   * checks whether a voucher with this id and booking reference combination
   * exists. Returns the full details for the voucher if a valid one was found
   * for the given details. Throws if one cannot be found.
   *
   * @param voucherId Unique identifier of the voucher to validate
   * @param bookingReference PNR of the voucher to validate.
   *
   * @return The parsed response data as VoucherValidateResponse on success or null on failure.
   */
  public VoucherValidateResponseV2 validateVoucher(
    String voucherNumber,
    String accessCode
  ) {
    if (voucherNumber == null || accessCode == null) {
      throw new APIMIntegrationService.IntegrationException(
        'Missing parameter: ' +
        (voucherNumber == null ? 'voucherNumber' : 'accessCode')
      );
    }

    String requestBody = JSON.serialize(
      new Map<String, String>{
        'voucherNumber' => voucherNumber,
        'accessCode' => accessCode
      }
    );

    String path = API_PATH + '/compensation/validate';

    HttpResponse response;

    try {
      response = makeRequest(
        HttpUtils.HTTP_METHOD.POST,
        path,
        requestBody
      );
    } catch (APIMIntegrationService.IntegrationException e) {
      throw new InvalidVoucherException();
    }

    if (response.getStatusCode() == 404) {
      throw new InvalidVoucherException();
    }

    return VoucherValidateResponseV2.parse(response.getBody());
  }

  /**
   * Constructs and fires a request to the Voucher API.
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
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body
  ) {
    HttpRequest request = new HttpRequest();

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      method,
      path,
      body,
      extraRequestHeaders
    );
  }
}
