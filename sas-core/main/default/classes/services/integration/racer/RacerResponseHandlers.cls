/**
 * A class for handling response files from RACER.
 *
 * See Confluence for more details on the formats and purposes of each of these
 * files.
 */
public class RacerResponseHandlers {
  private static ContentVersionsSelector contentVersionsSel = ContentVersionsSelector.newInstance();
  private static SettlementsSelector settlementsSel = SettlementsSelector.newInstance();
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();

  private static final Id INTEGRATION_USER_ID = [
      SELECT Id
      FROM User
      WHERE Email = 'seip@sas.se'
    ]
    .size() > 0
    ? [SELECT Id FROM User WHERE Email = 'seip@sas.se'][0].Id
    : null;

  private static final String RACER_FILES_CONTENT_WORKSPACE_NAME = 'Racer Files';
  private static final String PAYMUL_FOLDER_NAME = 'racer-incoming-paymul';
  private static final String L1_FOLDER_NAME = 'racer-incoming-l1';
  private static final String L2_FOLDER_NAME = 'racer-incoming-l2';
  private static final String GL_FOLDER_NAME = 'racer-incoming-gl';

  /**
   * Returns true if the file appears to be a file from RACER based on the
   * filename.
   */
  public static Boolean isARacerFile(String fileName, Id fileOwnerId) {
    // A simple solution for ensuring that accidentally similarly named files are disregarded.
    Boolean isRunningTestOrFileOwnerIsIntegrationUser =
      (C_Util.isSandbox() || Test.isRunningTest()) ||
      (fileOwnerId == INTEGRATION_USER_ID);
    return isRunningTestOrFileOwnerIsIntegrationUser &&
      (fileName.startsWith('SF_PAYMUL_') ||
      fileName.startsWith('SF_PAINL1_') ||
      fileName.startsWith('SF_PAINL2_') ||
      fileName.startsWith('SF_RACERGL_'));
  }

  /**
   * Attempts to read and process the given ContentVersion objects as RACER
   * acceptance files.
   *
   * @param contentVersionIds
   */
  public static Void handle(List<Id> contentVersionIds) {
    List<ContentVersion> cvs = contentVersionsSel.selectById(
      new Set<Id>(contentVersionIds),
      true
    );

    for (ContentVersion cv : cvs) {
      if (cv.Title.startsWith('SF_PAYMUL_')) {
        processPaymulStatusReport(cv);
      } else if (cv.Title.startsWith('SF_PAINL1_')) {
        processL1StatusReport(cv);
      } else if (cv.Title.startsWith('SF_PAINL2_')) {
        processL2StatusReport(cv);
      } else if (cv.Title.startsWith('SF_RACERGL_')) {
        processAccountingStatusReport(cv);
      }
    }
  }

  /**
   * Paymul status report is a confirmation file from Racer that the they have
   * received and processed the payment file correctly.
   */
  private static Void processPaymulStatusReport(ContentVersion cv) {
    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      List<String> dataFields = line.split('[|]');
      /**
       * dataFields contents by index:
       *  0 - processed date
       *  1 - file name
       *  2 - document type
       *  3 - payment count
       *  4 - document status: PROCESSED | FAILED
       *  5 - error detail
       *  6 - racer document id
       */
      
      String paymentFileName = dataFields[1];
      String documentStatus = dataFields[4];
      String errorDetail = dataFields[5];

      List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
        paymentFileName
      );

      Settlements.newInstance(correspondingSettlements)
        .markAsReceivedByRacer(documentStatus, errorDetail, uow);
      uow.commitWork();
    }
    moveToFolder(cv, PAYMUL_FOLDER_NAME);
  }

  /**
   * L1 status report is a confirmation file from banks that the payment file
   * has been received and processed successfully by them.
   */
  private static Void processL1StatusReport(ContentVersion cv) {
    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    for (String line : lines) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      List<String> dataFields = line.split('[|]');
      /**
       * dataFields contents by index:
       *  0 - L1 received date
       *  1 - related file name
       *  2 - document type
       *  3 - payment count
       *  4 - document status: ACCEPTED | REJECTED
       *  5 - error detail
       *  6 - racer document id
       */

      String paymentDate = dataFields[0];
      String paymentFileName = dataFields[1];
      String documentStatus = dataFields[4];
      String errorDetail = dataFields[5];

      List<Settlement__c> correspondingSettlements = settlementsSel.selectByPaymentFileName(
        paymentFileName
      );
      // Formatting payment date String from mm/dd/yyyy to yyyy-mm-dd. Because yyyy-mm-dd is required to convert Date/Time From String.
      Datetime dateOfPayment;
      try {
        dateOfPayment = DateUtils.convertRACERDateToDatetime(paymentDate);
      } catch (Exception e) {
        System.debug('Exception' + e.getMessage());
      }

      Settlements.newInstance(correspondingSettlements)
        .markAsReceivedByBank(dateOfPayment, documentStatus, errorDetail, uow);
      uow.commitWork();
    }
    moveToFolder(cv, L1_FOLDER_NAME);
  }

  /**
   * L2 status report includes information about payment which have failed due
   * to user error. This could be, e.g., an invalid bank number given by
   * customer to us.
   */
  private static Void processL2StatusReport(ContentVersion cv) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    String fileContents = cv.VersionData.toString();
    List<String> lines = fileContents.split('\n');

    Set<String> failedSettlementNames = new Set<String>();
    Map<String, String> settlementNamesToErrorMessages = new Map<String, String>();

    for (String line : lines) {
      List<String> dataFields = line.split('[|]');
      /**
       * dataFields contents by index:
       *  0 - L2 received date
       *  1 - related file name
       *  2 - document type
       *  3 - payment instruction id
       *  4 - payment number
       *  5 - payment reference number
       *  6 - debtor account number
       *  7 - account holder name
       *  8 - payment method
       *  9 - payment status
       *  10 - payment status code
       *  11 - payment status info
       *  12 - amount
       *  13 - currency
       *  14 - payment date
       *  15 - paid to
       *  16 - trx status
       *  17 - trx code
       *  18 - trx info
       */

      String paymentInstructionId = dataFields[3].trim();
      String documentStatus = dataFields[4];
      String errorDetail = dataFields[17];

      // Payment instruction id is of format {racerId}/{twoLetterCountryCode}{settlementName}
      // We can find the corresponding settlement from Salesforce with the last part.

      String settlementIdentifier = paymentInstructionId.split('/')[1];

      Pattern onlyNumbersPattern = Pattern.compile('([0-9]+)');
      Matcher matcher = onlyNumbersPattern.matcher(settlementIdentifier);

      Boolean matches = matcher.find();
      String settlementName = matcher.group();

      failedSettlementNames.add(settlementName);
      settlementNamesToErrorMessages.put(settlementName, errorDetail);
    }

    List<Settlement__c> failedSettlements = settlementsSel.selectByName(
      failedSettlementNames
    );

    Map<Id, String> settlementIdsToErrorMessages = new Map<Id, String>();

    for (Settlement__c s : failedSettlements) {
      settlementIdsToErrorMessages.put(
        s.Id,
        settlementNamesToErrorMessages.get(s.Name)
      );
    }

    Settlements.newInstance(failedSettlements)
      .markAsFailedPayment(settlementIdsToErrorMessages, uow);

    uow.commitWork();
    moveToFolder(cv, L2_FOLDER_NAME);
  }

  /**
   * The accounting status report is a confirmation file from the Racer team
   * that the accounting application has successfully received and processed
   * the accounting files.
   */
  private static Void processAccountingStatusReport(ContentVersion cv) {
    String fileContents = cv.VersionData.toString();
    // There should be only a single line.
    List<String> dataFields = fileContents.split('[|]');
    /**
     * dataFields contents by index:
     *  0 - processed date
     *  1 - file name
     *  2 - document type
     *  3 - transaction count
     *  4 - document status
     *  5 - error detail
     *  6 - document verification number
     */

    String processedDate = dataFields[0];
    String accountingFileName = dataFields[1];
    String documentStatus = dataFields[4];
    String errorDetail = dataFields[5];

    Datetime cleanDatetime = DateUtils.convertRACERDateToDatetime(
      processedDate
    );

    List<Settlement_Item__c> correspondingSettlementItems = settlementItemsSel.selectByAccountingFileName(
      accountingFileName
    );
    SettlementItems.newInstance(correspondingSettlementItems)
      .markAsReceivedByRacer(documentStatus, errorDetail, cleanDatetime);
    moveToFolder(cv, GL_FOLDER_NAME);
  }

  /**
   * Moves the given file to the folder with the given name.
   *
   * Used to make the files visible to admins after creation.
   */
  private static void moveToFolder(ContentVersion cv, String folderName) {
    List<ContentWorkspace> workspace = [
      SELECT Id
      FROM ContentWorkspace
      WHERE Name = :RACER_FILES_CONTENT_WORKSPACE_NAME
    ];

    List<ContentFolder> folder = [
      SELECT Id
      FROM ContentFolder
      WHERE Name = :folderName
    ];

    ContentVersions file = ContentVersions.newInstance(
      new List<ContentVersion>{ cv }
    );
    if (!workspace.isEmpty()) {
      file.moveToWorkspace(workspace[0].Id);
    }
    if (!folder.isEmpty()) {
      file.moveToFolder(folder[0].Id);
    }
  }
  public class HandleRacerResponseQueueable implements Queueable {
    private List<Id> contentVersionIds;

    public HandleRacerResponseQueueable(List<Id> contentVersionIds) {
      this.contentVersionIds = contentVersionIds;
    }

    public void execute(QueueableContext ctx) {
      handle(this.contentVersionIds);
    }
  }
}
