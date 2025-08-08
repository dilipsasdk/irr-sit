public without sharing class Claims extends ApplicationDomain {
  public Claims(List<SObject> records) {
    super(records);

    this.instanceRecords = (List<LIA_Claim__c>) Records;

    List<Claim> claimObjects = new List<Claim>();
    for (LIA_Claim__c c : this.instanceRecords) {
      claimObjects.add(new Claim(c));
    }

    this.objects = claimObjects;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Claims(records);
    }
  }

  public static Claims newInstance(List<Claim> claimList) {
    List<LIA_Claim__c> sObjectList = new List<LIA_Claim__c>();

    for (Claim c : claimList) {
      c.updateSObjectFields();
      sObjectList.add(c.underlyingSObject);
    }

    return newInstance(sObjectList);
  }

  public static Claims newInstance(List<LIA_Claim__c> sObjectList) {
    return (Claims) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public List<Claim> objects;

  public List<LIA_Claim__c> instanceRecords;

   // Can be used to bypass all trigger handling when testing. E.g. when inserting test setup data.
   @TestVisible
   private static Boolean bypassTrigger = false;

  public override void onAfterInsert() {
    if (bypassTrigger) {
      return;
    }
    fetchCAREClaims();
    updateParentCaseBookings();

    makeDecisionOnClaimExclusionFromAutomation();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    if (bypassTrigger) {
      return;
    }
    fetchCAREClaims((Map<Id, LIA_Claim__c>) existingRecords);
    updateParentCaseBookings((Map<Id, LIA_Claim__c>) existingRecords);

    makeDecisionOnClaimExclusionFromAutomation((Map<Id, LIA_Claim__c>) existingRecords);
    // TODO: We should also update EB accounts correctly. Requires fixing of the entire EB accounts fetching flow.
  }

  public override void onBeforeInsert() {
    if (bypassTrigger) {
      return;
    }
    normalizeFields();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    if (bypassTrigger) {
      return;
    }
    normalizeFields();
  }

  /**
   * A claim can be prorated if it is a baggage claim and has at least one
   * leg with an operating carrier which is not a part of Star Alliance. It
   * must also have at least one paid out settlement.
   *
   * Proration of a claim is splitting costs related to a baggage claim between
   * the airlines in the booking the claims is about. See Confluence for more
   * details.
   *
   * @return A map from claim id to whether that claim can be prorated.
   */
  public Map<Id, Boolean> canBeProrated() {
    Set<Id> parentCaseIds = new Set<Id>();
    for (Claim cl : objects) {
      Boolean isABaggageCaseWithSettlements =
        cl.category == Claim.Category.Baggage &&
        !cl.underlyingSObject.Settlements__r.isEmpty();

      if (isABaggageCaseWithSettlements) {
        parentCaseIds.add(cl.parentCaseId);
      }
    }
    List<Booking> bookingsForInstanceClaims = new List<Booking>();

    if (parentCaseIds.size() > 0) {
      bookingsForInstanceClaims = Booking.createFromList(
        BookingsSelector.newInstance().selectByCaseId(parentCaseIds)
      );
    }

    Map<Id, Boolean> claimIdsToProrationStatus = new Map<Id, Boolean>();

    for (Claim cl : objects) {
      // Claim can potentially be prorated if the booking is is about has an
      // operating carrier which is not a part of Star Alliance.
      claimIdsToProrationStatus.put(cl.underlyingSObject.Id, false);
      if (cl.category == Claim.Category.Baggage) {
        for (Booking b : bookingsForInstanceClaims) {
          if (b.bookingReference == cl.bookingReference) {
            claimIdsToProrationStatus.put(
              cl.id,
              b.hasNonStarAllianceOperatingCarriers()
            );
            break;
          }
        }
      }
    }

    return claimIdsToProrationStatus;
  }

  /**
   * Settles the given instance claims. The claims will be approved
   * automatically and skip control.
   *
   * Settlements must already exist for the claims for this to succeed.
   *
   * If settling fails, sets the settlements as failed and keeps the case in
   * progress.
   */
  public Claims settle(fflib_ISObjectUnitOfWork uow) {
    Settlements.newInstance(
        SettlementsSelector.newInstance().selectByClaimId(this.ids)
      )
      .validate()
      .approve(uow)
      .lock();

    return this;
  }

  public static Claims createFromClaims(List<Claim> listOfClaims) {
    List<LIA_Claim__c> claimsToCreate = new List<LIA_Claim__c>();

    for (Claim cl : listOfClaims) {
      cl.updateSObjectFields();
      claimsToCreate.add(cl.underlyingSObject);
    }

    return newInstance(claimsToCreate);
  }

  public Claims upsertToDB() {
    for (Claim obj : this.objects) {
      obj.updateSObjectFields();
    }
    upsert this.Records;

    List<Claim> claimObjects = new List<Claim>();
    for (LIA_Claim__c c : this.instanceRecords) {
      claimObjects.add(new Claim(c));
    }
    this.objects = claimObjects;

    return this;
  }

  public Claims upsertToDB(fflib_ISObjectUnitOfWork uow) {
    for (Claim obj : this.objects) {
      obj.updateSObjectFields();
    }

    for (LIA_Claim__c c : this.instanceRecords) {
      if (c.Id == null) {
        uow.registerNew(c);
      } else {
        uow.registerDirty(c);
      }
    }

    return this;
  }

  private void updateParentCaseBookings() {
    if (objects.size() == 1) {
      Claim cl = objects[0];
      // TODO: Fix this when we can support several bookings at once
      if (
        cl.bookingReference != null &&
        cl.recordType != Claim.RecordType.CompensationCard &&
        cl.recordType != null &&
        cl.parentCaseId != null
      ) {
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            cl.parentCaseId,
            cl.bookingReference
          )
        );
      }
    }
  }

  private void updateParentCaseBookings(Map<Id, LIA_Claim__c> existingRecords) {
    if (objects.size() == 1) {
      Claim cl = objects[0];
      Claim oldRecord = new Claim(existingRecords.get(cl.id));
      // TODO: Fix this when we can support several bookings at once
      if (
        cl.bookingReference != null &&
        oldRecord.bookingReference != cl.bookingReference &&
        cl.recordType != Claim.RecordType.CompensationCard &&
        cl.recordType != null
      ) {
        BookingService.removeBookingFromCase(
          cl.parentCaseId,
          oldRecord.bookingReference
        );
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            cl.parentCaseId,
            cl.bookingReference
          )
        );
      }
    }
  }

  private void normalizeFields() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (!String.isBlank(claim.Liability_PNR__c)) {
        claim.Liability_PNR__c = StringUtils.removeWhitespace(
          claim.Liability_PNR__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.BIC_Swift__c)) {
        claim.BIC_Swift__c = StringUtils.removeWhitespace(
          claim.BIC_Swift__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.Bank_Account_Number__c)) {
        claim.Bank_Account_Number__c = StringUtils.removeWhitespace(
          claim.Bank_Account_Number__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.Flight_Number__c)) {
        try {
          claim.Flight_Number__c = Flight.normalizeFlightNumber(
            StringUtils.removeWhitespace(claim.Flight_Number__c.toUpperCase())
          );
        } catch (Flight.FlightException e) {
          // Should avoid empty catch blocks
          // but in this case, we can ignore the exception
        }
      }
    }
  }

  private void fetchCAREClaims(Map<Id, LIA_Claim__c> existingRecords) {
    if (objects.size() == 1) {
      Claim newRecord = objects[0];
      Claim oldRecord = new Claim(existingRecords.get(newRecord.id));

      Boolean hasChangedPNROrPIR =
        oldRecord.bookingReference != newRecord.bookingReference ||
        oldRecord.pir != newRecord.pir;

      if (hasChangedPNROrPIR) {
        fetchCAREClaims();
      }
    }
  }

  private void fetchCAREClaims() {
    if (objects.size() == 1) {
      System.enqueueJob(
        new ClaimService.FetchCAREClaimsFromEDWAsync(
          objects[0].bookingReference,
          objects[0].pir,
          null
        )
      );
    }
  }

  public Claims updateExternalDataStatus(
    Claim.ExternalDataStatus newStatus,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Claim cl : objects) {
      cl.externalDataStatus = newStatus;
      cl.updateSObjectFields();
      uow.registerDirty(cl.underlyingSObject);
    }
    return this;
  }

  public void updateCasesAndClaimsStatuses(Claim.EU261HandlingStatus claimStatus, String caseStatus, fflib_ISObjectUnitOfWork uow) {
    updateEU261HandlingStatus(claimStatus, uow);
    Cases.newInstance(CasesSelector.newInstance().selectByClaims(this.instanceRecords)).updateStatusBecauseOfProactivity(uow, caseStatus);
  }

  public Claims updateEU261HandlingStatus(
    Claim.EU261HandlingStatus newStatus,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Claim c : this.objects) {
      c.eu261HandlingStatus = newStatus;
      c.updateSObjectFields();
      uow.registerDirty(c.underlyingSObject);
    }
    return this;
  }

  public void lockCasesAndClaims() {
    lock();
    Cases.newInstance(CasesSelector.newInstance().selectByClaims(this.instanceRecords)).lock();
  }

  public void unlockCasesAndClaims() {
    unlock();
    Cases.newInstance(CasesSelector.newInstance().selectByClaims(this.instanceRecords)).unlock();
  }

  public Claims lock() {
    Approval.lock(this.instanceRecords);
    return this;
  }

  public Claims unlock() {
    Approval.unlock(this.instanceRecords);
    return this;
  }

  public Claims prepareForManualHandling(fflib_ISObjectUnitOfWork uow) {
    for (Claim c : objects) {
      if (c.eu261HandlingStatus != Claim.EU261HandlingStatus.UnableToHandle) {
        c.eu261HandlingStatus = Claim.EU261HandlingStatus.WillNotHandle;
      }

      c.latestTimeOfEU261Automation = DateTime.now();
      c.updateSObjectFields();
      uow.registerDirty(c.underlyingSObject);
    }
    return this;
  }

  private void makeDecisionOnClaimExclusionFromAutomation() {
    ClaimService.makeDecisionOnClaimExclusionFromAutomation(this, null);
  }

  private void makeDecisionOnClaimExclusionFromAutomation(Map<Id, LIA_Claim__c> existingRecords) {
    ClaimService.makeDecisionOnClaimExclusionFromAutomation(this, existingRecords);
  }
}