/**
 * Service for making requests to the voucher API.
 */
public without sharing class VoucherIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM_VOUCHER/vouchers/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Voucher_Subscription_Key');

  public static VoucherIntegrationService newInstance() {
    return (VoucherIntegrationService) SAS_Service_Application.Service.newInstance(
      VoucherIntegrationService.class
    );
  }

  public class InvalidVoucherException extends Exception {
  }

  public enum VoucherType {
    GIFTCARD,
    COMP
  }

  public enum VoucherSubType {
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
  public VoucherCreateResponse createVoucher(
    VoucherCreateRequest voucherToCreate
  ) {
    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      '',
      JSON.serialize(voucherToCreate).replace('voucherCurrency', 'currency')
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return VoucherCreateResponse.parse(response.getBody());
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
  public VoucherValidateResponse validateVoucher(
    String voucherId,
    String bookingReference
  ) {
    if (voucherId == null || bookingReference == null) {
      throw new APIMIntegrationService.IntegrationException(
        'Missing parameter: ' +
        (voucherId == null ? 'voucherId' : 'bookingReference')
      );
    }

    String path = 'validate/vouchers/' + voucherId + '/' + bookingReference;

    HttpResponse response = makeRequest(HttpUtils.HTTP_METHOD.GET, path, null);

    if (response.getStatusCode() == 404) {
      throw new InvalidVoucherException();
    }

    return VoucherValidateResponse.parse(response.getBody());
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

    String fullPath = API_PATH + path;

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'api-version' => '1',
      'Content-Type' => 'application/json',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      method,
      fullPath,
      body,
      extraRequestHeaders
    );
  }
}
