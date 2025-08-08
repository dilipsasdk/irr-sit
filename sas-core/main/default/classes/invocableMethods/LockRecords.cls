public without sharing class LockRecords {
  /**
   * Method for locking a list of records.
   *
   * For settlements call the settlement specific locking functionality.
   */
  @InvocableMethod(label='Lock records')
  public static void LockRecord(List<String> recordIds) {
    List<String> uniqueRecordIdsAsList = new List<String>(
      new Set<String>(recordIds)
    );

    Set<Id> settlementIds = new Set<Id>();
    List<String> otherRecordIds = new List<String>();

    for (String recordId : uniqueRecordIdsAsList) {
      if (
        Id.valueOf(recordId).getSObjectType().getDescribe().getName() ==
        'Settlement__c'
      ) {
        settlementIds.add(Id.valueOf(recordId));
      } else {
        otherRecordIds.add(recordId);
      }
    }

    if (!settlementIds.isEmpty()) {
      (new Settlements(
          SettlementsSelector.newInstance().selectById(settlementIds)
        ))
        .lock();
    }

    if (!otherRecordIds.isEmpty()) {
      Approval.lock(uniqueRecordIdsAsList);
    }
  }
}
