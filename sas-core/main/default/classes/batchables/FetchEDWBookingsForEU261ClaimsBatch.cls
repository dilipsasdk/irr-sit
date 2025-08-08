public with sharing class FetchEDWBookingsForEU261ClaimsBatch implements Database.Batchable<LIA_Claim__c>, Database.AllowsCallouts, Database.Stateful {
  private static final Decimal MAX_RETRIEVE_COUNT = 3.0;
  private Set<Id> caseIdsToManualHandling;
  private Set<String> attemptedPNR;

  public FetchEDWBookingsForEU261ClaimsBatch() {
    this.caseIdsToManualHandling = new Set<Id>();
    this.attemptedPNR = new Set<String>();
  }

  public Iterable<LIA_Claim__c> start(Database.BatchableContext jobId) {
    return ClaimsSelector.newInstance()
      .selectUnhandledEU261ClaimsByDataStatus('In Progress');
  }

  public void execute(
    Database.BatchableContext bc,
    List<LIA_Claim__c> claimsToFetch
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    Set<String> bookingReferences = new Set<String>();
    Set<String> retrievedPNR = new Set<String>();
    for (LIA_Claim__c c : claimsToFetch) {
      if (this.attemptedPNR.contains(c.Liability_PNR__c)) {
        continue;
      }
      bookingReferences.add(c.Liability_PNR__c);
    }

    Bookings bInstance = BookingService.fetchEDWBookingsByBookingReferences(
      bookingReferences
    );
    this.attemptedPNR.addAll(bookingReferences);
    if (bInstance.objects != null) {
      for (Booking b : bInstance.objects) {
        retrievedPNR.add(b.bookingReference);
      }
    }

    for (LIA_Claim__c c : claimsToFetch) {
      Boolean foundBooking = retrievedPNR.contains(c.Liability_PNR__c);
      Decimal newRetrieveCount = c.External_Data_Retrieve_Count__c + 1;
      if (foundBooking) {
        c.External_Data_Status__c = 'Completed';
      } else {
        if (newRetrieveCount > MAX_RETRIEVE_COUNT) {
          c.EU261_Handling_Status__c = 'Unable to handle';
          c.External_Data_Status__c = 'Unavailable';
          caseIdsToManualHandling.add(c.Case__c);
        }
      }
      c.External_Data_Retrieve_Count__c = newRetrieveCount;
      uow.registerDirty(c);
    }
    uow.commitWork();
  }

  public void finish(Database.BatchableContext jobId) {
    if (caseIdsToManualHandling.size() > 0) {
      CaseService.assignPriorityAndRouteToQueue(caseIdsToManualHandling);
    }
  }
}
