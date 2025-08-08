public without sharing class Settlements extends ApplicationDomain {
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRatesSel = ExchangeRatesSelector.newInstance();

  public Settlements(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Settlement__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Settlements(records);
    }
  }

  public static Settlements newInstance(List<Settlement__c> sObjectList) {
    return (Settlements) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public List<Settlement__c> instanceRecords;

  public enum RecordType {
    Cheque,
    EBPoints,
    Monetary,
    Voucher
  }

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.Cheque => 'Cheque',
    RecordType.EBPoints => 'EB points',
    RecordType.Monetary => 'Monetary',
    RecordType.Voucher => 'Voucher'
  };

  private static Map<RecordType, Id> recordTypeToId = new Map<RecordType, String>();

  public static Id getRecordTypeId(RecordType rt) {
    Id rtId = recordTypeToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
        .get(recordTypeToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeToId.put(rt, rtId);
    }
    return rtId;
  }

  public static RecordType getRecordType(Id rtId) {
    if (rtId == getRecordTypeId(RecordType.Cheque)) {
      return RecordType.Cheque;
    } else if (rtId == getRecordTypeId(RecordType.EBPoints)) {
      return RecordType.EBPoints;
    } else if (rtId == getRecordTypeId(RecordType.Monetary)) {
      return RecordType.Monetary;
    } else if (rtId == getRecordTypeId(RecordType.Voucher)) {
      return RecordType.Voucher;
    } else {
      return null;
    }
  }

  private static final Map<String, String> voucherTypeToCostAccount = new Map<String, String>{
    '6721 - Denied boarding involuntary voucher' => '6721',
    '6721 - Denied boarding voluntary voucher' => '6721',
    '6722 - Downgrading involuntary voucher' => '6722',
    '6722 - Downgrading voluntary voucher' => '6722',
    '6727 - EU261 voucher' => '6727',
    '6738 - Care voucher' => '6738',
    '6741 - Damaged baggage voucher' => '6741',
    '6742 - Delayed baggage voucher' => '6742',
    '6733 - Goodwill voucher' => '6733',
    '6743 - Pilfered baggage voucher' => '6743'
  };

  public static final Map<String, VoucherIntegrationService.VoucherSubType> VOUCHER_TYPE_STRING_TO_VOUCHER_SUBTYPE = new Map<String, VoucherIntegrationService.VoucherSubType>{
    '6721 - Denied boarding involuntary voucher' => VoucherIntegrationService.VoucherSubType.IDBCOMP,
    '6721 - Denied boarding voluntary voucher' => VoucherIntegrationService.VoucherSubType.VDBCOMP,
    '6722 - Downgrading involuntary voucher' => VoucherIntegrationService.VoucherSubType.IDGCOMP,
    '6722 - Downgrading voluntary voucher' => VoucherIntegrationService.VoucherSubType.VDGCOMP,
    '6727 - EU261 voucher' => VoucherIntegrationService.VoucherSubType.EU261,
    '6738 - Care voucher' => VoucherIntegrationService.VoucherSubType.CARE,
    '6741 - Damaged baggage voucher' => VoucherIntegrationService.VoucherSubType.DAMAGEBAG,
    '6742 - Delayed baggage voucher' => VoucherIntegrationService.VoucherSubType.DELAYEDBAG,
    '6733 - Goodwill voucher' => VoucherIntegrationService.VoucherSubType.GOODWILL,
    '6743 - Pilfered baggage voucher' => VoucherIntegrationService.VoucherSubType.PILFBAG
  };

  public static final Map<String, VoucherOrchestrationService.VoucherType> VOUCHER_TYPE_STRING_TO_VOUCHER_TYPE = new Map<String, VoucherOrchestrationService.VoucherType>{
    '6721 - Denied boarding involuntary voucher' => VoucherOrchestrationService.VoucherType.IDBCOMP,
    '6721 - Denied boarding voluntary voucher' => VoucherOrchestrationService.VoucherType.VDBCOMP,
    '6722 - Downgrading involuntary voucher' => VoucherOrchestrationService.VoucherType.IDGCOMP,
    '6722 - Downgrading voluntary voucher' => VoucherOrchestrationService.VoucherType.VDGCOMP,
    '6727 - EU261 voucher' => VoucherOrchestrationService.VoucherType.EU261,
    '6738 - Care voucher' => VoucherOrchestrationService.VoucherType.CARE,
    '6741 - Damaged baggage voucher' => VoucherOrchestrationService.VoucherType.DAMAGEBAG,
    '6742 - Delayed baggage voucher' => VoucherOrchestrationService.VoucherType.DELAYEDBAG,
    '6733 - Goodwill voucher' => VoucherOrchestrationService.VoucherType.GOODWILL,
    '6743 - Pilfered baggage voucher' => VoucherOrchestrationService.VoucherType.PILFBAG
  };

  public static final String STATUS_IN_PROGRESS = 'In progress';
  public static final String STATUS_WAITING_FOR_APPROVAL = 'Waiting for approval';
  public static final String STATUS_WAITING_FOR_CONTROL = 'Waiting for control';
  public static final String STATUS_DENIED = 'Denied';
  public static final String STATUS_WAITING_FOR_TRANSFER = 'Waiting for transfer';
  public static final String STATUS_SENT_TO_RACER = 'Sent to Racer';
  public static final String STATUS_REJECTED_BY_RACER = 'Rejected by Racer';
  public static final String STATUS_SENT_TO_BANK = 'Sent to bank';
  public static final String STATUS_REJECTED_BY_BANK = 'Rejected by bank';
  public static final String STATUS_DONE = 'Done';
  public static final String STATUS_FAILED = 'Failed';
  public static final String STATUS_FAILED_PROCESSED = 'Failed - Processed';

  private static final Integer INSURANCE_DEDUCTIBLE_BAGGAGE = 1250;
  private static final Integer INSURANCE_DEDUCTIBLE_PERSONAL_INJURY = 0;

  private static final Set<String> COST_ACCOUNTS_BAGGAGE = new Set<String>{
    '6741',
    '6742',
    '6743'
  };

  public static final String COST_ACCOUNT_CREDIT = '1654';
  public static final String COST_ACCOUNT_INSURANCE = '1662';
  public static final String COST_ACCOUNT_LIABILITY_OTHER = '6735';
  public static final String COST_ACCOUNT_EU261_COMPENSATION = '6727';
  public static final String COST_ACCOUNT_EU261_REIMBURSEMENT = '6738';

  private static final Map<SettlementItem.RecordType, String> COST_CENTER_DEBITS = new Map<SettlementItem.RecordType, String>{
    SettlementItem.RecordType.DefaultRecordType => '90801',
    SettlementItem.RecordType.Emergency => '71470'
  };

  public static final Decimal CONVERSION_RATE_EUR_TO_EB_POINTS = 100;
  public static final Decimal CONVERSION_RATE_EUR_TO_VOUCHER_EUR = 2;

  public class CreateException extends Exception {
  }

  public class UpdateException extends Exception {
  }

  public override void onBeforeInsert() {
    normalizeFields();
    sanitizeAddressFields();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    dispatchProcessingEventsForWaitingEBAndVoucher();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    normalizeFields();
    sanitizeAddressFields();
    removeSettlementItemsOnCurrencyChange(
      (Map<Id, Settlement__c>) existingRecords
    );
    getStateOnPostalCodeChange((Map<Id, Settlement__c>) existingRecords);
  }

  public Settlements markAsSentToRacer(
    String paymentFilename,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> settlementIds = new Set<Id>();
    for (Settlement__c s : instanceRecords) {
      s.Payment_File_Name__c = paymentFilename;
      s.Settlement_Status__c = STATUS_SENT_TO_RACER;
      uow.registerDirty(s);
      settlementIds.add(s.Id);
    }

    List<Settlement_Item__c> correspondingSettlements = settlementItemsSel.selectBySettlementIds(
      settlementIds
    );

    SettlementItems.newInstance(correspondingSettlements)
      .markAsPendingL1Confirmation(uow);

    return this;
  }

  public void setDateOfPayment() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    setDateOfPayment(uow);
    uow.commitWork();
  }

  public void setDateOfPayment(fflib_ISObjectUnitOfWork uow) {
    Datetime now = Datetime.now();
    for (Settlement__c s : instanceRecords) {
      s.Date_Of_Payment__c = now;
      uow.registerDirty(s);
    }
  }

  public Settlements markAsReceivedByBank(
    Datetime paymentDate,
    String bankStatus,
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (bankStatus == 'ACCEPTED') {
      Set<Id> acceptedSettlementIds = new Set<Id>();

      for (Settlement__c s : instanceRecords) {
        s.Settlement_Status__c = STATUS_DONE;
        s.Date_of_Payment__c = paymentDate;
        uow.registerDirty(s);
        acceptedSettlementIds.add(s.Id);
      }

      List<Settlement_Item__c> correspondingSettlements = settlementItemsSel.selectBySettlementIds(
        acceptedSettlementIds
      );
      SettlementItems.newInstance(correspondingSettlements)
        .markAsReadyForTransfer(uow);
    } else {
      for (Settlement__c s : instanceRecords) {
        s.Settlement_Status__c = STATUS_REJECTED_BY_BANK;
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Settlements rejected by bank with error: ' + errorMessage,
        null,
        'Settlements',
        null
      );
    }

    return this;
  }

  public Settlements markAsReceivedByRacer(
    String racerStatus,
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (racerStatus == 'PROCESSED') {
      for (Settlement__c s : instanceRecords) {
        s.Settlement_Status__c = STATUS_SENT_TO_BANK;
        uow.registerDirty(s);
      }
    } else {
      for (Settlement__c s : instanceRecords) {
        s.Settlement_Status__c = STATUS_REJECTED_BY_RACER;
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Settlements rejected by Racer: ' + errorMessage,
        null,
        'Settlements',
        null
      );
    }

    return this;
  }

  /**
   * Marks the given settlements as failed due to an L2 failure.
   *
   * If a settlement fails at L2 level, it should not be reprocessed. Instead a
   * new settlement needs to be created.
   *
   * Settlement items should be changed to "Settlement failed" status if they
   * are still in Draft status.
   *
   * Expected to be used when we receive an L2 file from Racer.
   */
  public Settlements markAsFailedPayment(
    Map<Id, String> settlementIdsToErrorMessages,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : instanceRecords) {
      s.Settlement_Status__c = STATUS_FAILED;
      s.Date_of_Payment__c = null;
      s.Error_Message__c = settlementIdsToErrorMessages.get(s.Id);
      uow.registerDirty(s);

      C_Log.log(
        C_Log.Severity.Warning,
        'Settlement ' +
          s.Name +
          ' was rejected by bank with error: ' +
          settlementIdsToErrorMessages.get(s.Id),
        null,
        'Settlements',
        null
      );
    }

    List<Settlement_Item__c> correspondingSettlementItems = settlementItemsSel.selectBySettlementIds(
      settlementIdsToErrorMessages.keySet()
    );

    SettlementItems.newInstance(correspondingSettlementItems)
      .markAsSettlementFailed(uow);

    return this;
  }

  public Settlements markAsDone(
    String reference,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : instanceRecords) {
      if (
        s.Settlement_Status__c != STATUS_FAILED &&
        s.Settlement_Status__c != STATUS_FAILED_PROCESSED
      ) {
        // Failed settlements should never be reprocessed. At least payment
        // acceptance files can be received out of order so that we first
        // receive the L2 failure for a settlement and after that the
        // acceptance file. Even this order should leave the settlements as
        // failed.

        s.Settlement_Status__c = STATUS_DONE;
        s.External_Reference__c = reference;
        uow.registerDirty(s);
      }
    }

    return this;
  }

  public Settlements markAsFailed(
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : instanceRecords) {
      s.Settlement_Status__c = STATUS_FAILED;
      s.Error_Message__c = errorMessage;
      uow.registerDirty(s);
    }
    C_Log.log(
      C_Log.Severity.Error,
      'Settlement denied: ' + errorMessage,
      null,
      'Settlements',
      null
    );

    return this;
  }

  /**
   * Locks a list of settlements.
   *
   * Locks also all settlement items related to this settlement.
   */
  public Settlements lock() {
    List<Settlement_Item__c> settlementItemsForInstanceRecords = settlementItemsSel.selectBySettlementIds(
      (new Map<Id, Settlement__c>(instanceRecords)).keySet()
    );
    Approval.lock(instanceRecords);
    Approval.lock(settlementItemsForInstanceRecords);

    return this;
  }

  /**
   * Unlocks a list of settlements.
   *
   * Unlocks also all settlement items related to this settlement.
   */
  public Settlements unlock() {
    List<Settlement_Item__c> settlementItemsForInstanceRecords = settlementItemsSel.selectBySettlementIds(
      (new Map<Id, Settlement__c>(instanceRecords)).keySet()
    );
    Approval.unlock(instanceRecords);
    Approval.unlock(settlementItemsForInstanceRecords);

    return this;
  }

  public Settlements submitToApproval(fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Id == null) {
        uow.registerNew(settlement);
      } else {
        uow.registerDirty(settlement);
      }

      settlement.Submitter__c = UserInfo.getUserId();
      settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_APPROVAL;
    }

    return this;
  }

  /**
   * Approves the given settlements for transfer. Excepts that the settlements
   * have already been validated.
   *
   * Sets approver and submitter of the settlement to UserInfo.getUserId().
   */
  public Settlements approve(fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Id == null) {
        uow.registerNew(settlement);
      } else {
        uow.registerDirty(settlement);
      }

      settlement.Approver__c = UserInfo.getUserId();
      settlement.Submitter__c = UserInfo.getUserId();
      settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
      settlement.Control_verified__c = true;

      Approval_Request__c approval = new Approval_Request__c(
        OwnerId = UserInfo.getUserId(),
        Status__c = 'Approved',
        Type__c = 'Approval'
      );
      uow.registerNew(approval, Approval_Request__c.Settlement__c, settlement);
    }

    return this;
  }

  /**
   * @param itemsToUpsert Map from Settlement Id to list of SettlementItems for each settlement.
   */
  public Settlements updateSettlementItems(
    Map<Id, List<SettlementItem>> itemsToUpsert,
    fflib_ISObjectUnitOfWork uow
  ) {
    Map<Id, List<Settlement_Item__c>> sObjectsToUpsert = new Map<Id, List<Settlement_Item__c>>();

    for (Id settlementId : itemsToUpsert.keySet()) {
      List<Settlement_Item__c> items = new List<Settlement_Item__c>();

      for (SettlementItem si : itemsToUpsert.get(settlementId)) {
        si.updateSObjectFields();
        items.add(si.underlyingSObject);
      }

      sObjectsToUpsert.put(settlementId, items);
    }

    return updateSettlementItems(sObjectsToUpsert, uow);
  }

  /**
   * Updates the list of settlement items for this settlement. Upserts the
   * given items and removes all settlement items related to the settlement,
   * but not included in the given items.
   *
   * Also updates the settlement total and currency conversion calculations.
   *
   * @param itemsToUpsert Full list of settlement items this settlement should have the operation.
   */
  public Settlements updateSettlementItems(
    Map<Id, List<Settlement_Item__c>> itemsToUpsert,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> parentClaimIds = new Set<Id>();
    for (Settlement__c settlement : instanceRecords) {
      if (
        settlement.RecordTypeId !=
        getRecordTypeId(Settlements.RecordType.EBPoints) &&
        settlement.Currency__c == null
      ) {
        throw new UpdateException(
          'Set currency before trying to update settlement items.'
        );
      }

      Boolean canBeModified =
        settlement.Settlement_Status__c == STATUS_IN_PROGRESS ||
        settlement.Settlement_Status__c == STATUS_DENIED;

      if (!canBeModified) {
        throw new UpdateException(
          'Settlement status must be in progress or denied to update settlement items.'
        );
      }
      parentClaimIds.add(settlement.Claim__c);
    }

    Map<Id, LIA_Claim__c> parentClaimsById = new Map<Id, LIA_Claim__c>(
      ClaimsSelector.newInstance().selectById(parentClaimIds)
    );
    Map<String, Exchange_Rate__c> exchangeRatesToSEK = new Map<String, Exchange_Rate__c>();
    Map<String, Exchange_Rate__c> exchangeRatesFromUSD = new Map<String, Exchange_Rate__c>();

    for (Exchange_Rate__c er : exchangeRatesSel.selectByToCurrency('SEK')) {
      exchangeRatesToSEK.put(er.From_Currency__c, er);
    }

    for (Exchange_Rate__c er : exchangeRatesSel.selectByFromCurrency('USD')) {
      exchangeRatesFromUSD.put(er.To_Currency__c, er);
    }

    markRemovedSettlementItemsForDeletion(itemsToUpsert, uow);

    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Id != null) {
        uow.registerDirty(settlement);
      }

      Decimal sumOfLineItems = 0;

      for (Settlement_Item__c item : itemsToUpsert.get(settlement.Id)) {
        if (item.Id == null) {
          uow.registerNew(item, Settlement_Item__c.Settlement__c, settlement);
        } else {
          uow.registerDirty(item);
        }

        Boolean isEmergencyClaim = settlement.IsEmergencyClaim__c;

        if (isEmergencyClaim) {
          item.Cost_Center__c = COST_CENTER_DEBITS.get(
            SettlementItem.RecordType.Emergency
          );
          item.RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
            SettlementItem.RecordType.Emergency
          );
        } else {
          item.Cost_Center__c = COST_CENTER_DEBITS.get(
            SettlementItem.RecordType.DefaultRecordType
          );
          item.RecordTypeId = SettlementItem.getRecordTypeIdByEnum(
            SettlementItem.RecordType.DefaultRecordType
          );
        }

        item.Currency__c = settlement.Currency__c;
        item.Status__c = SettlementItems.STATUS_DRAFT;

        if (
          settlement.RecordTypeId ==
          getRecordTypeId(Settlements.RecordType.Voucher)
        ) {
          // Voucher cost accounts can be set automatically based on voucher type.
          item.Cost_Account__c = voucherTypeToCostAccount.get(
            settlement.Voucher_Type__c
          );
        }

        sumOfLineItems += item.Amount__c;

        updateSettlementItemTotal(item, settlement, exchangeRatesToSEK);
      }

      updateInsuranceForSettlementItems(
        itemsToUpsert.get(settlement.id),
        settlement,
        parentClaimsById.get(settlement.Claim__c),
        exchangeRatesFromUSD
      );

      updateSettlementTotal(settlement, sumOfLineItems, exchangeRatesToSEK);
    }

    return this;
  }

  /**
   * Creates settlements without settlement items for the given claims.
   *
   * @param claims List of claims for which to create settlements.
   * @param recordTypeForSettlements Which type of settlements should be created. If
   * null, the claims' preferred compensation methods will be used.
   */
  public static Settlements createFromClaim(
    List<LIA_Claim__c> claims,
    RecordType recordTypeForSettlements,
    Boolean createReimbursementSettlement,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<Settlement__c> settlementsToCreate = new List<Settlement__c>();

    for (LIA_Claim__c claim : claims) {
      RecordType recordTypeToCreate = recordTypeForSettlements;

      if (recordTypeToCreate == null) {
        String method = createReimbursementSettlement
          ? claim.Preferred_Reimbursement_Method__c
          : claim.Preferred_Compensation_Method__c;

        switch on method {
          when 'EuroBonus Points' {
            recordTypeToCreate = RecordType.EBPoints;
          }
          when 'Monetary' {
            recordTypeToCreate = RecordType.Monetary;
          }
          when 'Voucher' {
            recordTypeToCreate = RecordType.Voucher;
          }
          when else {
            recordTypeToCreate = RecordType.Monetary;
          }
        }
      }

      // Logic from settlement creation flow
      Settlement__c settlementToCreate = new Settlement__c(
        Address_line_1__c = claim.Address_line_1__c,
        Address_line_2__c = claim.Address_line_2__c,
        City__c = claim.City__c,
        Claim__c = claim.Id,
        Country__c = claim.Country__c,
        Postal_Code__c = claim.Postal_Code__c,
        Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
      );
      switch on recordTypeToCreate {
        when Cheque {
          settlementToCreate.Bank_Country__c = 'United States'; // Cheques are supported only for US.
          settlementToCreate.Country__c = 'United States'; // Cheques are supported only for US.
          settlementToCreate.Currency__c = 'USD'; // Cheques are supported only for USD.
          settlementToCreate.Payee_Name__c = claim.Bank_Account_Holder_Name__c;
          settlementToCreate.Payee_reference__c = claim.Customer_s_Reference__c;
          settlementToCreate.RecordTypeId = Settlements.getRecordTypeId(
            Settlements.RecordType.Cheque
          );
          settlementToCreate.State__c = UsStateUtils.getStateFromPostalCode(
            claim.Postal_Code__c
          );
        }
        when EBPoints {
          settlementToCreate.EuroBonus_Number__c = claim.EuroBonus_Number__c;
          settlementToCreate.Payee_Name__c = claim.Full_Name__c;
          settlementToCreate.RecordTypeId = Settlements.getRecordTypeId(
            Settlements.RecordType.EBPoints
          );
        }
        when Monetary {
          settlementToCreate.BIC_Swift__c = claim.BIC_Swift__c;
          settlementToCreate.Bank_Account_Number__c = claim.Bank_Account_Number__c;
          settlementToCreate.Bank_Country__c = claim.Bank_Country__c;
          settlementToCreate.Bank_Name__c = claim.Bank_Name__c;
          if (claim.Currency__c != null) {
            settlementToCreate.Currency__c = claim.Currency__c;
          } else {
            if (claim.Bank_Country__c == null) {
              throw new CreateException(
                'Cannot determine currency for the settlement.'
              );
            }

            Settlement_Country_Setting__mdt settingsForClaimBankCountry = [
              SELECT Default_Currency__c
              FROM Settlement_Country_Setting__mdt
              WHERE Country_Name__c = :claim.Bank_Country__c
            ];
            settlementToCreate.Currency__c = settingsForClaimBankCountry.Default_Currency__c;
          }
          settlementToCreate.Payee_Name__c = claim.Bank_Account_Holder_Name__c;
          settlementToCreate.Payee_reference__c = claim.Customer_s_Reference__c;
          settlementToCreate.RecordTypeId = Settlements.getRecordTypeId(
            Settlements.RecordType.Monetary
          );
        }
        when Voucher {
          settlementToCreate.Bank_Country__c = 'Not Applicable';
          settlementToCreate.Payee_First_Name__c = claim.Contact_First_Name__c;
          settlementToCreate.Payee_Last_Name__c = claim.Contact_Last_Name__c;
          settlementToCreate.RecordTypeId = Settlements.getRecordTypeId(
            Settlements.RecordType.Voucher
          );
          settlementToCreate.Voucher_Email__c = claim.Contact_Email__c;
          settlementToCreate.Voucher_Type__c = '6727 - EU261 voucher';
          settlementToCreate.Currency__c = 'EUR'; // Usually issued in euros so we default to that.
        }
      }
      uow.registerNew(settlementToCreate);
      settlementsToCreate.add(settlementToCreate);
    }

    return newInstance(settlementsToCreate);
  }

  /**
   * Creates settlements for the given claims using the given compensation
   * cards. Payment details are taken from the claims and the compensation
   * amount from compensation cards.
   *
   * The settlements contains also settlement items and are ready to be
   * approved after they are created.
   *
   * @param cardClaims claims List of claims for which to create settlements.
   * @param compensationCardByClaimId Map from claim.Id to the compensation
   * card for that claim.
   */
  public static Settlements createFromCompensationCard(
    List<LIA_Claim__c> cardClaims,
    Map<Id, Redeemed_Compensation_Card__c> compensationCardByClaimId,
    fflib_ISObjectUnitOfWork uow
  ) {
    Map<Id, Settlement__c> settlementsByClaimId = new Map<Id, Settlement__c>();

    Settlements settlementsToCreate = createFromClaim(
      cardClaims,
      null,
      false,
      uow
    );

    for (Settlement__c s : settlementsToCreate.instanceRecords) {
      settlementsByClaimId.put(s.Claim__c, s);
    }

    for (LIA_Claim__c cl : cardClaims) {
      Redeemed_Compensation_Card__c compensationCardForClaim = compensationCardByClaimId.get(
        cl.Id
      );
      if (
        cl.RecordTypeId !=
        Claim.getRecordTypeIdByEnum(Claim.RecordType.CompensationCard) ||
        compensationCardForClaim == null
      ) {
        throw new CreateException(
          'Not a compensation card claim or missing card information.'
        );
      }

      if (cl.Preferred_Compensation_Method__c == 'Voucher') {
        // There are several different voucher sybtypes issued as compensation
        // cards. The subtype always begins with either IDB, IDG, VDB, or VDG
        // for the different compensation situations. We can map these to the
        // existing voucher cost accounts like this.

        Settlement__c settlementToCreate = settlementsByClaimId.get(cl.Id);

        String voucherSubTypeCategory = String.isBlank(
            compensationCardForClaim.Sub_Type__c
          ) || compensationCardForClaim.Sub_Type__c.length() < 3
          ? ''
          : compensationCardForClaim.Sub_Type__c.substring(0, 3);
        switch on voucherSubTypeCategory {
          when 'IDB' {
            settlementToCreate.Voucher_Type__c = '6721 - Denied boarding involuntary voucher';
          }
          when 'VDB' {
            settlementToCreate.Voucher_Type__c = '6721 - Denied boarding voluntary voucher';
          }
          when 'IDG' {
            settlementToCreate.Voucher_Type__c = '6722 - Downgrading involuntary voucher';
          }
          when 'VDG' {
            settlementToCreate.Voucher_Type__c = '6722 - Downgrading voluntary voucher';
          }
          when else {
            settlementToCreate.Voucher_Type__c = '6721 - Denied boarding involuntary voucher';
          }
        }
      }
    }

    Map<Id, List<Settlement_Item__c>> itemsToCreateBySettlement = new Map<Id, List<Settlement_Item__c>>();

    for (LIA_Claim__c claim : cardClaims) {
      Redeemed_Compensation_Card__c compensationCardForClaim = compensationCardByClaimId.get(
        claim.Id
      );
      Settlement__c settlement = settlementsByClaimId.get(claim.Id);

      Settlement_Item__c itemToCreate = new Settlement_Item__c(
        Comments__c = 'Automatic settlement item for compensation card.',
        Customer_Name__c = claim.Full_Name__c,
        Settlement__c = settlement.Id
      );
      switch on claim.Preferred_Compensation_Method__c {
        when 'EuroBonus Points' {
          itemToCreate.Amount__c =
            CONVERSION_RATE_EUR_TO_EB_POINTS *
            compensationCardForClaim.Amount__c;
          itemToCreate.Cost_Account__c = '';
        }
        when 'Voucher' {
          settlement.Currency__c = compensationCardForClaim.Currency__c;

          itemToCreate.Amount__c =
            CONVERSION_RATE_EUR_TO_VOUCHER_EUR *
            compensationCardForClaim.Amount__c;
        }
        when else {
          String country = claim.Bank_Country__c;

          Settlement_Country_Setting__mdt bankCurrency = [
            SELECT Default_Currency__c
            FROM Settlement_Country_Setting__mdt
            WHERE Country_Name__c = :country
          ];
          settlement.Currency__c = bankCurrency.Default_Currency__c;

          List<Exchange_Rate__c> er = exchangeRatesSel.selectByCurrencies(
            compensationCardForClaim.Currency__c,
            settlement.Currency__c
          );

          if (compensationCardForClaim.Currency__c != settlement.Currency__c) {
            if (er.isEmpty()) {
              throw new CreateException(
                'Exchange rate does not exist ' +
                  compensationCardForClaim.Currency__c +
                  '-' +
                  settlement.Currency__c
              );
            }
            itemToCreate.Amount__c =
              compensationCardForClaim.Amount__c * er[0].Rate__c;
          } else {
            itemToCreate.Amount__c = compensationCardForClaim.Amount__c;
          }

          // There are several different voucher sybtypes issued as compensation
          // cards. The subtype always begins with either IDB, IDG, VDB, or VDG
          // for the different compensation situations. We can map these to the
          // existing voucher cost accounts like this.
          String voucherSubTypeCategory = String.isBlank(
              compensationCardForClaim.Sub_Type__c
            ) || compensationCardForClaim.Sub_Type__c.length() < 3
            ? ''
            : compensationCardForClaim.Sub_Type__c.substring(0, 3);
          switch on voucherSubTypeCategory {
            when 'IDB' {
              itemToCreate.Cost_Account__c = '6721';
            }
            when 'VDB' {
              itemToCreate.Cost_Account__c = '6721';
            }
            when 'IDG' {
              itemToCreate.Cost_Account__c = '6722';
            }
            when 'VDG' {
              itemToCreate.Cost_Account__c = '6722';
            }
            when else {
              itemToCreate.Cost_Account__c = '6721';
            }
          }
        }
      }

      itemToCreate.Amount__c = Math.ceil(itemToCreate.Amount__c);

      itemsToCreateBySettlement.put(
        settlement.Id,
        new List<Settlement_Item__c>{ itemToCreate }
      );
    }

    return settlementsToCreate
      .updateSettlementItems(itemsToCreateBySettlement, uow);
  }

  /**
   * Given a list of new settlement items, marks all settlements items for
   * instance records for deletion if they do not exist in the given
   * itemsToUpsert.
   */
  private void markRemovedSettlementItemsForDeletion(
    Map<Id, List<Settlement_Item__c>> itemsToUpsert,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> settlementIds = new Set<Id>();
    for (Settlement__c s : instanceRecords) {
      if (s.Id != null) {
        settlementIds.add(s.Id);
      }
    }
    if (settlementIds.size() == 0) {
      // Nothing to remove if the settlements don't exist yet.
      return;
    }

    List<Settlement_Item__c> allExistingSettlementItems = settlementItemsSel.selectBySettlementIds(
      settlementIds
    );

    Map<Id, List<Settlement_Item__c>> existingSettlementItemsBySettlement = new Map<Id, List<Settlement_Item__c>>();

    for (Settlement_Item__c si : allExistingSettlementItems) {
      List<Settlement_Item__c> existing = existingSettlementItemsBySettlement.get(
        si.Settlement__c
      );
      if (existing == null) {
        existingSettlementItemsBySettlement.put(
          si.Settlement__c,
          new List<Settlement_Item__c>{ si }
        );
      } else {
        existing.add(si);
      }
    }
    for (Id settlementId : settlementIds) {
      // If we have an existing settlement, we need to check if any of the
      // existing settlements should be deleted and mark them for deletion if
      // so.
      List<Settlement_Item__c> existingItems = settlementItemsSel.selectBySettlementIds(
        new Set<Id>{ settlementId }
      );

      for (Settlement_Item__c existingItem : existingItems) {
        Boolean found = false;
        for (Settlement_Item__c newItem : itemsToUpsert.get(settlementId)) {
          if (newItem.Id == existingItem.Id) {
            found = true;
            break;
          }
        }
        if (!found) {
          uow.registerDeleted(existingItem);
        }
      }
    }
  }

  /**
   * Updates the settlement amount fields for the given settlement based on the
   * given sum of line items. Handles currency conversion calculation to SEK
   * for Settlement_amount_in_SEK__c field.
   */
  private void updateSettlementTotal(
    Settlement__c settlement,
    Decimal sumOfLineItems,
    Map<String, Exchange_Rate__c> exchangeRatesToSEK
  ) {
    if (
      settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.EBPoints)
    ) {
      settlement.EuroBonus_Points__c = sumOfLineItems;
    } else {
      settlement.Amount__c = sumOfLineItems;
      if (settlement.Currency__c == 'SEK') {
        settlement.Settlement_amount_in_SEK__c = sumOfLineItems;
        settlement.Date_of_Exchange_Calculation__c = Date.today();
      } else {
        Exchange_Rate__c exchangeRateToSEK = exchangeRatesToSEK.get(
          settlement.Currency__c
        );

        if (exchangeRateToSEK != null) {
          // There should always be exactly one, but just in case we lose exchange rate data, let's check.
          settlement.Settlement_amount_in_SEK__c =
            sumOfLineItems * exchangeRateToSEK.Rate__c;
          settlement.Date_of_Exchange_Calculation__c = exchangeRateToSEK.Date__c;
        }
      }
    }
  }

  private void updateSettlementItemTotal(
    Settlement_Item__c item,
    Settlement__c settlement,
    Map<String, Exchange_Rate__c> exchangeRatesToSEK
  ) {
    if (
      settlement.RecordTypeId !=
      getRecordTypeId(Settlements.RecordType.EBPoints)
    ) {
      if (item.Currency__c == 'SEK') {
        item.Amount_in_SEK__c = item.Amount__c;
        item.Date_of_Exchange_Calculation__c = Date.today();
        item.Exchange_Rate__c = 1;
      } else {
        Exchange_Rate__c exchangeRateToSEK = exchangeRatesToSEK.get(
          item.Currency__c
        );

        if (exchangeRateToSEK != null) {
          // There should always be exactly one, but just in case we lose exchange rate data, let's check.
          item.Amount_in_SEK__c = item.Amount__c * exchangeRateToSEK.Rate__c;
          item.Exchange_Rate__c = exchangeRateToSEK.Rate__c;
          item.Date_of_Exchange_Calculation__c = exchangeRateToSEK.Date__c;
        }
      }
    }
  }

  public class SettlementValidityException extends Exception {
  }

  /**
   * Validates that the settlement is ready to be submitted to approval
   * TODO: Move the validation logic to a Settlement class.
   * Logic:
   * Monetary:
   * Check that Bank_Account_Number, BIC_Swift, Payee_Name, Currency, Bank_Country, and Amount are not null
   * Check that Amount is larger than 0
   * Check that Bank_Account_Number and BIC_Swift are valid
   *
   * Cheque:
   * Check that Payee_Name, Currency, Bank_Country, Amount, Address_Line_1, City, Postal_Code and Country are not null
   * Check that Amount is larger than 0
   *
   * Voucher:
   * Check that Voucher_Email, Currency, Amount, Payee_First_Name, Payee_Last_Name are not null
   * Check that Amount is larger than 0
   *
   * EB Points:
   * Check that EuroBonus_Number and EuroBonus_Points are not null
   * Check that EuroBonus_Points are larger than 0
   */
  public Settlements validate() {
    List<String> errorsForAllSettlements = new List<String>();

    for (Settlement__c s : instanceRecords) {
      List<String> errorMessages = new List<String>();

      RecordType rt = getRecordType(s.RecordTypeId);

      for (Schema.SObjectField field : getRequiredFieldsForSettlement(rt)) {
        if (s.get(field) == null) {
          errorMessages.add(
            field.getDescribe().getLabel() + ' cannot be empty.'
          );
        }
      }

      switch on rt {
        when EBPoints {
          if (!(s.EuroBonus_Points__c > 0)) {
            errorMessages.add('EuroBonus Points has to be greater than 0.');
          }

          try {
            Accounts.parseIntoEuroBonusNumber(s.EuroBonus_Number__c);
          } catch (Accounts.IncorrectEBNumberException e) {
            errorMessages.add(
              'EuroBonus number is not in correct format (9 digits).'
            );
          }
        }
        when Cheque {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
          if (s.State__c == null) {
            errorMessages.add(
              'State is not populated correctly. Please check the Postal Code.'
            );
          }
        }
        when Voucher {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
        }
        when Monetary {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
          if (errorMessages.size() == 0) {
            Boolean bankAccountNumberIsValid = true;
            try {
              bankAccountNumberIsValid = BankAccountUtils.validateIBAN(
                s.Bank_Account_Number__c,
                s.Bank_Country__c,
                s.BIC_Swift__c
              );
            } catch (Exception e) {
              errorMessages.add(
                'Bank Account Number and the bank country do not match. ' +
                e.getMessage()
              );
            }
            if (!bankAccountNumberIsValid) {
              errorMessages.add('Bank Account Number is invalid.');
            }
            if (!BankAccountUtils.validateBIC(s.BIC_Swift__c)) {
              errorMessages.add(
                'BIC number should be formatted as: XXXXXXYY or XXXXXXYYYYY (X\'s are letters, Y\'s are letters or numbers).'
              );
            }
            if (
              !BankAccountUtils.validateAddress(
                s.Address_line_1__c,
                s.Address_line_2__c
              )
            ) {
              errorMessages.add(
                'Address should not contain special character like (´,´,!,€,+,?)).'
              );
            }
          }
        }
      }
      if (s.Postal_Code__c != null && !s.Postal_Code__c.isAlphanumericSpace()) {
        errorMessages.add('Postal code should not contain special characters');
      }

      if (errorMessages.size() != 0) {
        String errors = '';
        for (String e : errorMessages) {
          errors += e + '\n';
        }
        errorsForAllSettlements.add('Settlement ' + s.Name + ':\n' + errors);
      }
    }

    if (errorsForAllSettlements.size() != 0) {
      String errors = '';
      for (String e : errorsForAllSettlements) {
        errors += e + '\n';
      }
      throw new SettlementValidityException(
        '\nOne or more Settlements are invalid. You need to correct the following:\n' +
          errors +
          'Please correct these fields and resubmit the Settlements.'
      );
    }

    return this;
  }

  /**
   * Validates the instance records and returns the errors as a map from id to
   * errors. If no map entry exists for a given instance record id, the
   * settlement was validated successfully.
   *
   * TODO: Move this to a Settlement class.
   */ 
  public static Map<Id, String> validateWithoutThrowing(
    List<Settlement__c> settlementsToValidate
  ) {
    Map<Id, String> errorsBySettlementId = new Map<Id, String>();

    for (Settlement__c s : settlementsToValidate) {
      List<String> errorMessages = new List<String>();

      RecordType rt = getRecordType(s.RecordTypeId);

      for (Schema.SObjectField field : getRequiredFieldsForSettlement(rt)) {
        if (s.get(field) == null) {
          errorMessages.add(
            field.getDescribe().getLabel() + ' cannot be empty.'
          );
        }
      }

      switch on rt {
        when EBPoints {
          if (!(s.EuroBonus_Points__c > 0)) {
            errorMessages.add('EuroBonus Points has to be greater than 0.');
          }

          try {
            Accounts.parseIntoEuroBonusNumber(s.EuroBonus_Number__c);
          } catch (Accounts.IncorrectEBNumberException e) {
            errorMessages.add(
              'EuroBonus number is not in correct format (9 digits).'
            );
          }
        }
        when Cheque {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
          if (s.State__c == null) {
            errorMessages.add(
              'State is not populated correctly. Please check the Postal Code.'
            );
          }
        }
        when Voucher {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
        }
        when Monetary {
          if (!(s.Amount__c > 0)) {
            errorMessages.add('Amount has to be greater than 0.');
          }
          if (errorMessages.size() == 0) {
            Boolean bankAccountNumberIsValid = true;
            try {
              bankAccountNumberIsValid = BankAccountUtils.validateIBAN(
                s.Bank_Account_Number__c,
                s.Bank_Country__c,
                s.BIC_Swift__c
              );
            } catch (Exception e) {
              errorMessages.add(
                'Bank Account Number and the bank country do not match. ' +
                e.getMessage()
              );
            }
            if (!bankAccountNumberIsValid) {
              errorMessages.add('Bank Account Number is invalid.');
            }
            if (!BankAccountUtils.validateBIC(s.BIC_Swift__c)) {
              errorMessages.add(
                'BIC number should be formatted as: XXXXXXYY or XXXXXXYYYYY (X\'s are letters, Y\'s are letters or numbers).'
              );
            }
            if (
              !BankAccountUtils.validateAddress(
                s.Address_line_1__c,
                s.Address_line_2__c
              )
            ) {
              errorMessages.add(
                'Address should not contain special character like (´,´,!,€,+,?)).'
              );
            }
          }
        }
      }
      if (s.Postal_Code__c != null && !s.Postal_Code__c.isAlphanumericSpace()) {
        errorMessages.add('Postal code should not contain special characters');
      }
      if (errorMessages.size() != 0) {
        String errors = '';
        for (String e : errorMessages) {
          errors += e + '\n';
        }
        errorsBySettlementId.put(s.Id, errors);
      }
    }

    return errorsBySettlementId;
  }

  /**
   * Marks the settlement item as insured and calculates the claimable amount
   * from SAS's insurance company after deductible. Updates the record which
   * was passed in.
   *
   * @return The same list with the updated settlement items.
   */
  private List<Settlement_Item__c> updateInsuranceForSettlementItems(
    List<Settlement_Item__c> items,
    Settlement__c settlement,
    LIA_Claim__c claim,
    Map<String, Exchange_Rate__c> exchangeRatesFromUSD
  ) {
    Boolean isAMonetaryClaim =
      Settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.Cheque) ||
      settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.Monetary);

    Boolean isAnInsuredClaimType = isAMonetaryClaim;
    // Only monetary payments are claimed from insurance.
    if (!isAnInsuredClaimType) {
      return items;
    }

    // We're making an assumption here that there is never a settlement which contains
    // both baggage and personal injure claims.
    Decimal deductible;

    Boolean isPersonalInjuryClaim =
      claim.Customer_Claim_Type__c == 'Personal injury';

    if (isPersonalInjuryClaim) {
      deductible = INSURANCE_DEDUCTIBLE_PERSONAL_INJURY;
    } else {
      deductible = INSURANCE_DEDUCTIBLE_BAGGAGE;
    }

    Map<String, List<Settlement_Item__c>> customerNamesToSettlementItems = new Map<String, List<Settlement_Item__c>>();
    for (Settlement_Item__c item : items) {
      // Group settlement items by customer as deductible is by customer.
      List<Settlement_Item__c> existingItemsForCustomer = customerNamesToSettlementItems.get(
        item.Customer_Name__c
      );
      if (existingItemsForCustomer == null) {
        customerNamesToSettlementItems.put(
          item.Customer_Name__c,
          new List<Settlement_Item__c>{ item }
        );
      } else {
        existingItemsForCustomer.add(item);
      }
    }

    if (settlement.Currency__c != 'USD') {
      // Deductible amounts are defined in USD so we need to convert them to
      // settlement currency if it isn't USD.
      Exchange_Rate__c exchangeRateFromUSD = exchangeRatesFromUSD.get(
        settlement.Currency__c
      );
      if (exchangeRateFromUSD != null) {
        deductible = (deductible * exchangeRateFromUSD.Rate__c).setScale(2);
      } else {
        C_Log.log(
          C_Log.Severity.Error,
          'Failed to fetch exchange rate from: ' +
            settlement.Currency__c +
            ' to USD.',
          null,
          'Settlements',
          null
        );
      }
    }

    for (String c : customerNamesToSettlementItems.keySet()) {
      // Deductible is per customer.
      Decimal totalDeductionForThisCustomer = 0;

      for (Settlement_Item__c item : customerNamesToSettlementItems.get(c)) {
        Boolean isPersonalInjuryClaimAndAccount =
          isPersonalInjuryClaim &&
          item.Cost_Account__c == COST_ACCOUNT_LIABILITY_OTHER;
        Boolean isBaggageAccount = COST_ACCOUNTS_BAGGAGE.contains(
          item.Cost_Account__c
        );
        Boolean isInsured = isBaggageAccount || isPersonalInjuryClaimAndAccount;
        if (isInsured) {
          item.Is_Insured__c = true;

          Decimal maximumDeductionLeft =
            deductible - totalDeductionForThisCustomer;
          Decimal toDeduct = Math.min(maximumDeductionLeft, item.Amount__c);

          item.Net_Amount_After_Deductible__c = item.Amount__c - toDeduct;
          totalDeductionForThisCustomer += toDeduct;
        }
      }
    }

    return items;
  }

  private void dispatchProcessingEventsForWaitingEBAndVoucher() {
    // Dispatch EBVoucherPaymentApproved__e events to process EB and voucher payments
    for (Settlement__c settlement : instanceRecords) {
      Boolean isToBePaidOut =
        settlement.Settlement_Status__c == STATUS_WAITING_FOR_TRANSFER &&
        ((settlement.RecordTypeId ==
        getRecordTypeId(Settlements.RecordType.EBPoints)) ||
        (settlement.RecordTypeId ==
        getRecordTypeId(Settlements.RecordType.Voucher)));

      if (isToBePaidOut) {
        EventBus.publish(
          new EBVoucherPaymentApproved__e(Settlement__c = settlement.id)
        );
      }
    }
  }

  private void normalizeFields() {
    for (Settlement__c settlement : instanceRecords) {
      if (!String.isBlank(settlement.BIC_Swift__c)) {
        settlement.BIC_Swift__c = StringUtils.removeWhitespace(
          settlement.BIC_Swift__c.toUpperCase()
        );
      }
      if (!String.isBlank(settlement.Bank_Account_Number__c)) {
        settlement.Bank_Account_Number__c = StringUtils.removeWhitespace(
          settlement.Bank_Account_Number__c.toUpperCase()
        );
      }
    }
  }

  private void sanitizeAddressFields() {
    for (Settlement__c s : instanceRecords) {
      s.Address_line_1__c = StringUtils.sanitizeWithoutRemovingSpaces(
        s.Address_line_1__c
      );
      s.Address_line_2__c = StringUtils.sanitizeWithoutRemovingSpaces(
        s.Address_line_2__c
      );
      s.City__c = StringUtils.sanitizeWithoutRemovingSpaces(s.City__c);
      s.Payee_First_Name__c = StringUtils.sanitizeWithoutRemovingSpaces(
        s.Payee_First_Name__c
      );
      s.Payee_Last_Name__c = StringUtils.sanitizeWithoutRemovingSpaces(
        s.Payee_Last_Name__c
      );
      s.Payee_Name__c = StringUtils.sanitizeWithoutRemovingSpaces(
        s.Payee_Name__c
      );
    }
  }

  private void removeSettlementItemsOnCurrencyChange(
    Map<Id, Settlement__c> existingRecords
  ) {
    for (Settlement__c settlement : instanceRecords) {
      if (
        settlement.Currency__c != existingRecords.get(Settlement.Id).Currency__c
      ) {
        List<Settlement_Item__c> itemToDelete = settlementItemsSel.selectBySettlementIds(
          new Set<Id>{ Settlement.Id }
        );
        settlement.Amount__c = 0;
        settlement.Settlement_amount_in_SEK__c = 0;
        delete itemToDelete;
      }
    }
  }

  private void getStateOnPostalCodeChange(
    Map<Id, Settlement__c> existingRecords
  ) {
    for (Settlement__c settlement : instanceRecords) {
      if (
        settlement.RecordTypeId ==
        Settlements.getRecordTypeId(Settlements.RecordType.Cheque)
      ) {
        if (
          settlement.Postal_Code__c !=
          existingRecords.get(Settlement.Id).Postal_Code__c
        ) {
          settlement.State__c = UsStateUtils.getStateFromPostalCode(
            settlement.Postal_Code__c
          );
        }
      }
    }
  }

  private static List<Schema.SObjectField> getRequiredFieldsForSettlement(
    RecordType settlementRecordType
  ) {
    Map<RecordType, List<Schema.SObjectField>> recordTypeIdToRequiredFields = new Map<RecordType, List<Schema.SObjectField>>{
      RecordType.Cheque => new List<Schema.SObjectField>{
        Settlement__c.Payee_Name__c,
        Settlement__c.Currency__c,
        Settlement__c.Bank_Country__c,
        Settlement__c.Address_line_1__c,
        Settlement__c.City__c,
        Settlement__c.Postal_Code__c,
        Settlement__c.Country__c
      },
      RecordType.EBPoints => new List<Schema.SObjectField>{
        Settlement__c.EuroBonus_Number__c
      },
      RecordType.Monetary => new List<Schema.SObjectField>{
        Settlement__c.Bank_Account_Number__c,
        Settlement__c.BIC_Swift__c,
        Settlement__c.Payee_Name__c,
        Settlement__c.Currency__c,
        Settlement__c.Bank_Country__c
      },
      RecordType.Voucher => new List<Schema.SObjectField>{
        Settlement__c.Voucher_Email__c,
        Settlement__c.Currency__c,
        Settlement__c.Payee_First_Name__c,
        Settlement__c.Payee_Last_Name__c
      }
    };
    return recordTypeIdToRequiredFields.get(settlementRecordType);
  }
}
