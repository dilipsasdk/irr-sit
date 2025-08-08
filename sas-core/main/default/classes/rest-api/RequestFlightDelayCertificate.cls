@RestResource(urlMapping='/RequestFlightDelayCertificate/*')
global with sharing class RequestFlightDelayCertificate {
  public class APIException extends Exception {
  }

  @HttpPost
  global static String sendFlightDelayCertificate(
    FlightDelayCertificateFormJSON2Apex form
  ) {
    try {
      return FlightDelayCertificateService.processFlightDelayCertificateRequest(
        form
      );
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'FlightDelayCertificateFormAPI',
        null
      );
      throw new APIException();
    }
  }
}
