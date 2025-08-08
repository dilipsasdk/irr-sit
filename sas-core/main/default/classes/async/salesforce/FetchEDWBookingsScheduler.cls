public with sharing class FetchEDWBookingsScheduler implements Schedulable {
  public static final Integer BOOKINGS_BATCH_SIZE = 2;
  public void execute(SchedulableContext jobId) {
    Database.executeBatch(
      new FetchEDWBookingsForEU261ClaimsBatch(),
      BOOKINGS_BATCH_SIZE
    );
  }
}
