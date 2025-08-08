/**
 * This file defines methods for creating payment files, given a list of
 * PaymentEntries made from Settlement objects. The created files are
 * sent further to RACER to execute the payments. See Confluence for more
 * details.
 *
 * There are 8 records for every payment:
 * 1. Control record
 * 2. Account data
 * 3. Payment data
 * 4. Supplier data
 * 5. Bank data
 * 6. Supplier site data
 * 7. Invoice data
 * 8. Invoice flex fields
 *
 * Each of these records is it's own row in the text file. This means that
 * there are in total eight lines per settlement in the final file.
 *
 * We have also four sources for the different fields in the records:
 * 1. The settlement itself
 * 2. Constant values defined in the PaymentEntry class.
 * 3. Currency and country specific values defined in Settlement_Currency_Setting__mdt,
 *    Settlement_Bank_Setting__mdt and Settlement_Country_Setting__mdt records.
 * 4. Batch counters coming from Racer_Integration_Counter__c
 *
 * A given field should never appear in more than one source, so we simply
 * merge all of the fields together to create a full data source for a given
 * payment.
 *
 * The full list of all fields and their lengths in columns are given in
 * the PaymentEntry class.
 */
public class PaymentFileBuilder {
  public class CreateFileException extends Exception {
  }

  private static final Id RACER_FILES_CONTENT_WORKSPACE_ID = [
        SELECT Id
        FROM ContentWorkspace
        WHERE Name = 'Racer Files'
      ]
      .isEmpty()
    ? null
    : [SELECT Id FROM ContentWorkspace WHERE Name = 'Racer Files'][0].Id;

  private static final Id PAYMENT_FOLDER_ID = [
        SELECT Id
        FROM ContentFolder
        WHERE Name = 'racer-outgoing-payment'
      ]
      .isEmpty()
    ? null
    : [SELECT Id FROM ContentFolder WHERE Name = 'racer-outgoing-payment'][0]
      .Id;

  private static final String TODAYS_DATE = Datetime.now().format('yyyyMMdd');

  public enum PaymentCurrency {
    SEK,
    DKK,
    USD,
    NOK,
    OTH
  }

  /**
   * Creates a payment file based on the given PaymentEntries.
   * The file is created as a ContentVersion object.
   *
   * @param paymentEntries List of PaymentEntries created from Settlements to include in this file.
   * @param fileCurrency The currency of this file as PaymentCurrency.
   * @param runId A unique runId for this file from Racer_Integration_Counter__c
   *
   * @return Id of the created a file.
   */
  public static Id create(
    List<PaymentEntry> paymentEntries,
    PaymentCurrency fileCurrency,
    Decimal runId
  ) {
    if (fileCurrency == null || paymentEntries == null) {
      throw new CreateFileException(
        'PaymentFileBuilder.create# Missing parameters'
      );
    }
    try {
      Settlement_Bank_Setting__mdt bankSettings = Settlement_Bank_Setting__mdt.getAll()
        .get(fileCurrency.name());

      List<String> fileContents = new List<String>();

      // Each settlement in a file has a unique batch reference. The starting
      // number for the batch reference depends on the file's currency.
      Integer batchReference = Integer.valueOf(bankSettings.ref1Batch__c);

      for (PaymentEntry entry : paymentEntries) {
        Map<String, Map<String, String>> mergedRecord = new Map<String, Map<String, String>>();
        // Merge all four data sources into a single map
        for (String key : PaymentEntry.RECORDS_IN_ORDER) {
          mergedRecord.put(key, entry.data.get(key));
          mergedRecord.get(key)
            .putAll(PaymentEntry.CONSTANT_FIELDS_BY_RECORD.get(key));
        }

        for (String recordName : PaymentEntry.RECORDS_IN_ORDER) {
          for (
            String fieldName : PaymentEntry.FIELDS_IN_ORDER_BY_RECORD.get(
              recordName
            )
          ) {
            List<String> textToAdd = new List<String>();

            switch on fieldName {
              when 'ref1Batch', 'documentCode', 'checkNumber' {
                textToAdd.add(String.valueOf(batchReference));
              }
              when 'runId' {
                textToAdd.add(String.valueOf(runId));
              }
              when else {
                String fieldData = mergedRecord.get(recordName)
                    .get(fieldName) != null
                  ? mergedRecord.get(recordName).get(fieldName)
                  : '';
                textToAdd.add(fieldData);
              }
            }

            // Pad field to full field length.
            fileContents.add(
              String.join(textToAdd, '')
                .rightPad(
                  PaymentEntry.FIELD_LENGTHS.get(recordName).get(fieldName)
                )
            );
          }
          // Each record is a single line so we'll add a linebreak at the end.
          fileContents.add('\n');
        }
        // Each settlement has it's own batch reference.
        batchReference++;
      }

      String fileName =
        'SF' +
        '_' +
        bankSettings.Bank__c +
        '_' +
        fileCurrency.name() +
        '_' +
        TODAYS_DATE +
        String.valueOf(runId); // TODO: This isn't the same as the files we have.

      ContentVersion paymentFile = new ContentVersion(
        ContentLocation = 'S',
        PathOnClient = fileName + '.txt',
        Title = fileName,
        VersionData = Blob.valueOf(String.join(fileContents, ''))
      );
      insert paymentFile;

      // Insert generated file to a folder visible to admins
      ContentVersion paymentFileAfterInsert = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :paymentFile.Id
      ];

      ContentVersions file = new ContentVersions(
        new List<ContentVersion>{ paymentFileAfterInsert }
      );
      if (RACER_FILES_CONTENT_WORKSPACE_ID != null) {
        file.moveToWorkspace(RACER_FILES_CONTENT_WORKSPACE_ID);
      }
      if (PAYMENT_FOLDER_ID != null) {
        file.moveToFolder(PAYMENT_FOLDER_ID);
      }

      return paymentFile.Id;
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'Payment File Creation',
        null
      );
      throw new CreateFileException();
    }
  }
}
