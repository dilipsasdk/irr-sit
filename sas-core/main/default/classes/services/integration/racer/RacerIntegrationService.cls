/**
 * Service for sending files to Racer through SEIP and APIM.
 */
public without sharing class RacerIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM/customercare/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public enum FILE_TYPE {
    PAYMENT,
    ACCOUNTING
  }

  private static final Map<FILE_TYPE, String> FILE_TYPE_TO_ENDPOINT = new Map<FILE_TYPE, String>{
    FILE_TYPE.PAYMENT => 'postpaymentfile',
    FILE_TYPE.ACCOUNTING => 'postaccountingfile'
  };

  static ContentVersionsSelector contentVersions = (ContentVersionsSelector) SAS_Service_Application.Selector.newInstance(
    ContentVersion.SObjectType
  );

  public class IntegrationException extends Exception {
  }

  /** Attempts to send the given file to Racer.
   * These files will be passed on asynchronously by SEIP to Racer. OK from
   * this call means only that the file was received succesfully by SEIP.
   * A separate return file will be sent to Salesforce to indicate that the
   * file was successfully received and parsed by Racer.
   *
   * See Confluence for more details.
   *
   * @param fileType Whether this is an accounting or a payment file. See FILE_TYPE. Cannot be null.
   * @param fileId Name of the file to be sent. Should include file extension. Cannot be null.
   *
   * @return The parsed response data on success.
   *
   * @throws IntegrationException On any issues.
   */
  public static String sendFile(FILE_TYPE fileType, Id fileId) {
    if (fileType == null || fileId == null) {
      throw new IntegrationException(
        'RacerIntegrationService.sendFile# arguments cannot be null.'
      );
    }

    List<ContentVersion> files = contentVersions.selectById(
      new Set<Id>{ fileId },
      true
    );

    if (files.size() != 1) {
      throw new IntegrationException(
        'RacerIntegrationService.sendFile# no file found for given id.'
      );
    }

    String fileName = files[0].PathOnClient;
    if (fileType == FILE_TYPE.ACCOUNTING) {
      // Remove .txt part which shouldn't be there for accounting files, but is required for SF to correctly store the file.
      fileName = fileName.removeEnd('.txt');
    }

    // HTTP logic inlined to minimise heap allocations caused by potentially
    // very large files.

    HttpRequest request = new HttpRequest();

    request.setEndpoint(API_PATH + FILE_TYPE_TO_ENDPOINT.get(fileType));
    request.setMethod(String.valueOf(HttpUtils.HTTP_METHOD.POST));

    request.setHeader('sas-system-name', 'Salesforce');
    request.setHeader('Sas-Tracking-Id', C_Util.generateUUID());
    request.setHeader('Ocp-Apim-Subscription-Key', SUBSCRIPTION_KEY);
    request.setHeader('api-version', 'v1');
    request.setHeader('Content-Type', 'application/xml');
    request.setHeader('Filename', fileName);

    request.setBody(EncodingUtil.base64Encode(files[0].VersionData));

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 400 && response.getStatusCode() != 404) {
      // Log and throw again. Typically can't be resolved.
      String message =
        'APIM query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus();

      C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
      C_Log.log(C_Log.Severity.Error, message, null, 'APIM', httpDataLog);

      throw new IntegrationException(
        'APIM query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus()
      );
    }

    if (response.getStatusCode() == 404) {
      return null;
    }

    return response.getBody();
  }
}
