/**
 * A class for creating accounting files from AccountingEntries.
 *
 * These are sent further to RACER to be passed along to accounting.
 *
 * See Confluence for more details.
 */
public class AccountingFileBuilder {
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

  private static final Id ACCOUNTING_FOLDER_ID = [
        SELECT Id
        FROM ContentFolder
        WHERE Name = 'racer-outgoing-accounting'
      ]
      .isEmpty()
    ? null
    : [SELECT Id FROM ContentFolder WHERE Name = 'racer-outgoing-accounting'][0]
      .Id;

  public enum PaymentCurrency {
    SEK,
    DKK,
    NOK,
    OTH
  }

  public static Id create(
    List<AccountingEntry> accountingEntries,
    PaymentCurrency fileCurrency,
    Decimal verificationNumber
  ) {
    if (fileCurrency == null || accountingEntries == null) {
      throw new CreateFileException(
        'AccountingFileBuilder.create# Missing parameters'
      );
    }

    List<String> fileContents = new List<String>();
    Long sumOfDebitEntries = 0;
    try {
      // Create one debit line per accounting entry.
      for (AccountingEntry entry : accountingEntries) {
        for (String field : AccountingEntry.FIELDS_IN_ORDER) {
          if (field == 'Amount') {
            // A special case. Padded with to left zeroes and added up to a total line.
            String amountAsText = entry.data.get(field);
            fileContents.add(
              amountAsText.leftPad(
                AccountingEntry.FIELD_LENGTHS.get(field),
                '0'
              )
            );
            if (entry.type == AccountingEntry.EntryType.DEBIT) {
              sumOfDebitEntries += entry.amount;
            }
          } else if (field == 'VerificationNumber') {
            fileContents.add(
              String.valueOf(verificationNumber)
                .rightPad(AccountingEntry.FIELD_LENGTHS.get(field))
            );
          } else {
            // Check if this is a constant field.
            String fieldContents = AccountingEntry.CONSTANT_FIELDS.get(field);

            // If yes, we should add that value. If not, we should get the value
            // from the accounting entry.
            String textToAdd = fieldContents == null
              ? entry.data.get(field)
              : fieldContents;

            // Pad text to full field length as the file format is column based.
            fileContents.add(
              textToAdd.rightPad(AccountingEntry.FIELD_LENGTHS.get(field))
            );
          }
        }
        fileContents.add('\n');
      }

      fileContents.add(createTotalLine(sumOfDebitEntries, verificationNumber));

      String dayOfYear = String.valueOf(Date.today().dayOfYear())
        .leftPad(3, '0');

      String todaysDate = Datetime.now().format('yyyyMMdd');
      // Format is a5{AUN}{dayOfYear}{RunningCount}
      String fileName =
        'a501' +
        dayOfYear +
        '0' +
        todaysDate +
        String.valueOf(verificationNumber) +
        '.sf' +
        fileCurrency.name().toLowerCase();

      ContentVersion accountingFile = new ContentVersion(
        ContentLocation = 'S',
        PathOnClient = fileName + '.txt',
        Title = fileName,
        VersionData = Blob.valueOf(String.join(fileContents, ''))
      );

      insert accountingFile;

      // Insert generated file to a folder visible to admins
      ContentVersion accountingFileAfterInsert = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :accountingFile.Id
      ];

      ContentVersions file = ContentVersions.newInstance(
        new List<ContentVersion>{ accountingFileAfterInsert }
      );
      if (RACER_FILES_CONTENT_WORKSPACE_ID != null) {
        file.moveToWorkspace(RACER_FILES_CONTENT_WORKSPACE_ID);
      }
      if (ACCOUNTING_FOLDER_ID != null) {
        file.moveToFolder(ACCOUNTING_FOLDER_ID);
      }

      return accountingFile.Id;
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'Accounting File Creation',
        null
      );
      throw new CreateFileException();
    }
  }

  private static String createTotalLine(
    Long sumOfDebitEntries,
    Decimal verificationNumber
  ) {
    List<String> totalLine = new List<String>();
    totalLine.add('RAT01');
    totalLine.add(String.valueOf(verificationNumber).rightPad(60));
    totalLine.add(String.valueOf(sumOfDebitEntries).leftPad(17, '0'));
    totalLine.add(
      ''.rightPad(AccountingEntry.FIELD_LENGTHS.get('Description'))
    );
    totalLine.add(
      AccountingEntry.CONSTANT_FIELDS.get('CompanyCode')
        .rightPad(AccountingEntry.FIELD_LENGTHS.get('CompanyCode'))
    );
    totalLine.add(
      AccountingEntry.CONSTANT_FIELDS.get('Period')
        .rightPad(AccountingEntry.FIELD_LENGTHS.get('Period'))
    );
    totalLine.add(
      AccountingEntry.CONSTANT_FIELDS.get('FeederName')
        .rightPad(AccountingEntry.FIELD_LENGTHS.get('FeederName'))
    );
    totalLine.add(
      AccountingEntry.CONSTANT_FIELDS.get('DeliveryNumber')
        .rightPad(AccountingEntry.FIELD_LENGTHS.get('DeliveryNumber'))
    );

    return String.join(totalLine, '');
  }
}
