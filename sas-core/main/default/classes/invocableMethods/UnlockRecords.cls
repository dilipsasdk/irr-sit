public without sharing class UnlockRecords {
  /**
   * Method for unlocking a list of records.
   *
   * For settlements call the settlement specific unlocking functionality.
   */
  @InvocableMethod(label='Unlock records')
  public static void UnlockRecord(List<String> recordIds) {
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
        .unlock();
    }

    if (!otherRecordIds.isEmpty()) {
      Approval.unlock(uniqueRecordIdsAsList);
    }
  }
}
