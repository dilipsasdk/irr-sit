public without sharing class SettlementItems extends ApplicationDomain {
  public SettlementItems(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Settlement_Item__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new SettlementItems(records);
    }
  }

  public static SettlementItems newInstance(
    List<Settlement_Item__c> sObjectList
  ) {
    return (SettlementItems) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  private List<Settlement_Item__c> instanceRecords;

  public static final String STATUS_DRAFT = 'Draft';
  public static final String STATUS_SETTLEMENT_FAILED = 'Settlement failed';
  public static final String STATUS_PENDING_L1_CONFIRMATION = 'Pending L1 confirmation';
  public static final String STATUS_WAITING_FOR_TRANSFER = 'Waiting for transfer';
  public static final String STATUS_SENT_TO_RACER = 'Sent to Racer';
  public static final String STATUS_REJECTED_BY_RACER = 'Rejected by Racer';
  public static final String STATUS_DONE = 'Done';

  public enum RecordType {
    Emergency,
    DefaultRecordType
  }

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.Emergency => 'Emergency',
    RecordType.DefaultRecordType => 'Default Record Type'
  };
  private static Map<RecordType, Id> recordTypeToId = new Map<RecordType, String>();

  public static Id getRecordTypeId(RecordType rt) {
    Id rtId = recordTypeToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.Settlement_Item__c.getRecordTypeInfosByName()
        .get(recordTypeToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeToId.put(rt, rtId);
    }
    return rtId;
  }

  public void markAsReceivedByRacer(
    String accountingStatus,
    String errorMessage,
    Datetime dateOfAccounting
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReceivedByRacer(
      accountingStatus,
      errorMessage,
      dateOfAccounting,
      uow
    );
    uow.commitWork();
  }

  public SettlementItems markAsDone() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsDone(uow);
    uow.commitWork();
    return this;
  }

  public SettlementItems markAsDone(fflib_ISObjectUnitOfWork uow) {
    for (Settlement_Item__c s : instanceRecords) {
      s.Status__c = STATUS_DONE;
      uow.registerDirty(s);
    }
    return this;
  }

  public void setDateOfAccounting(Datetime theDate) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    setDateOfAccounting(uow, theDate);
    uow.commitWork();
  }

  public void setDateOfAccounting(
    fflib_ISObjectUnitOfWork uow,
    Datetime theDate
  ) {
    for (Settlement_Item__c s : instanceRecords) {
      s.Date_Of_Accounting__c = theDate;
      uow.registerDirty(s);
    }
  }

  public void markAsPendingL1Confirmation() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsPendingL1Confirmation(uow);
    uow.commitWork();
  }

  public void markAsPendingL1Confirmation(fflib_ISObjectUnitOfWork uow) {
    for (Settlement_Item__c s : instanceRecords) {
      s.Status__c = STATUS_PENDING_L1_CONFIRMATION;
      uow.registerDirty(s);
    }
  }

  public void markAsReceivedByRacer(
    String accountingStatus,
    String errorMessage,
    Datetime dateOfAccounting,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (accountingStatus == 'PROCESSED') {
      for (Settlement_Item__c s : instanceRecords) {
        s.Status__c = STATUS_DONE;
        uow.registerDirty(s);
      }
      setDateOfAccounting(uow, dateOfAccounting);
    } else {
      for (Settlement_Item__c s : instanceRecords) {
        s.Status__c = STATUS_REJECTED_BY_RACER;
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Accounting entries rejected by Racer with error: ' + errorMessage,
        null,
        'RACER',
        null
      );
    }
  }

  public void markAsReadyForTransfer() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReadyForTransfer(uow);
    uow.commitWork();
  }

  public void markAsReadyForTransfer(fflib_ISObjectUnitOfWork uow) {
    for (Settlement_Item__c s : instanceRecords) {
      s.Status__c = STATUS_WAITING_FOR_TRANSFER;
      uow.registerDirty(s);
    }
  }

  public void markAsSentToRacer(String accountingFilename) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsSentToRacer(accountingFilename, uow);
    uow.commitWork();
  }

  public void markAsSentToRacer(
    String accountingFilename,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement_Item__c s : instanceRecords) {
      s.Accounting_File_Name__c = accountingFilename;
      s.Status__c = STATUS_SENT_TO_RACER;
      uow.registerDirty(s);
    }
  }

  public void markAsSettlementFailed() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsSettlementFailed(uow);
    uow.commitWork();
  }

  /**
   * Marks the given list of settlement items as failed when the parent
   * settlement has failed. Only settlement items which have status 'Draft' or
   * 'Pending L1 confirmation' can be marked as failed, as other items in other
   * statuses have already been sent to accounting.
   */
  public void markAsSettlementFailed(fflib_ISObjectUnitOfWork uow) {
    for (Settlement_Item__c s : instanceRecords) {
      if (
        s.Status__c == STATUS_DRAFT ||
        s.Status__c == STATUS_PENDING_L1_CONFIRMATION
      ) {
        s.Status__c = STATUS_SETTLEMENT_FAILED;
        uow.registerDirty(s);
      }
    }
  }
}
