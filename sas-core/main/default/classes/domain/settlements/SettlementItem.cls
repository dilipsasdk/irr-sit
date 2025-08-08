public without sharing class SettlementItem extends AbstractSObjectWrapper {
  public Settlement_Item__c underlyingSObject { get; private set; }
  public RecordType recordType;

  public Id parentSettlementId;
  public String accountingFileName;
  public Decimal amount;
  public Decimal amountInSEK;
  public String comments;
  public CostAccount costAccount;
  public CostCenter costCenter;
  public Money.CurrencyCode itemCurrency;
  public String customerName;
  public Date dateOfExchangeCalculation;
  public Decimal deductibleInsuranceAmount;
  public String errorMessage;
  public Boolean isInsured = false;
  public Decimal netAmountAfterDeductible;
  public Status status;

  public enum CostAccount {
    CA6721,
    CA6722,
    CA6727,
    CA6730,
    CA6731,
    CA6732,
    CA6733,
    CA6734,
    CA6735,
    CA6736,
    CA6737,
    CA6738,
    CA6739,
    CA6740,
    CA6741,
    CA6742,
    CA6743,
    CA6744
  }

  public enum CostCenter {
    CC90801,
    CC71470
  }

  public enum Status {
    Draft,
    PendingL1Confirmation,
    WaitingForTransfer,
    SentToRacer,
    RejectedByRacer,
    Done,
    SettlementFailed
  }

  public enum RecordType {
    Emergency,
    DefaultRecordType
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Accounting_File_Name__c = this.accountingFileName;
    this.underlyingSObject.Amount__c = this.amount;
    this.underlyingSObject.Amount_in_SEK__c = this.amountInSEK;
    this.underlyingSObject.Comments__c = this.comments;
    this.underlyingSObject.Cost_Account__c = COST_ACCOUNT_ENUM_TO_PICKLIST_VALUE.get(
      this.costAccount
    );
    this.underlyingSObject.Cost_Center__c = COST_CENTER_ENUM_TO_PICKLIST_VALUE.get(
      this.costCenter
    );
    this.underlyingSObject.Currency__c = Money.CURRENCY_ENUM_TO_PICKLIST_VALUE.get(
      this.itemCurrency
    );
    this.underlyingSObject.Customer_Name__c = this.customerName;
    this.underlyingSObject.Date_of_Exchange_Calculation__c = this.dateOfExchangeCalculation;
    this.underlyingSObject.Deductible_Insurance_Amount__c = this.deductibleInsuranceAmount;
    this.underlyingSObject.Error_Message__c = this.errorMessage;
    this.underlyingSObject.Is_Insured__c = this.isInsured;
    this.underlyingSObject.Net_Amount_After_Deductible__c = this.netAmountAfterDeductible;
    this.underlyingSObject.Settlement__c = this.parentSettlementId;
    this.underlyingSObject.Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.status
    );
    this.underlyingSObject.RecordTypeId = getRecordTypeIdByEnum(
      this.recordType
    );
  }

  public SettlementItem() {
    this.underlyingSObject = new Settlement_Item__c();
  }

  public SettlementItem(Settlement_Item__c si) {
    this.underlyingSObject = si;
    this.accountingFileName = si.Accounting_File_Name__c;
    this.amount = si.Amount__c;
    this.amountInSEK = si.Amount_in_SEK__c;
    this.comments = si.Comments__c;
    this.costAccount = COST_ACCOUNT_PICKLIST_VALUE_TO_ENUM.get(
      si.Cost_Account__c
    );
    this.costCenter = COST_CENTER_PICKLIST_VALUE_TO_ENUM.get(si.Cost_Center__c);
    this.itemCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
      si.Currency__c
    );
    this.customerName = si.Customer_Name__c;
    this.dateOfExchangeCalculation = si.Date_of_Exchange_Calculation__c;
    this.deductibleInsuranceAmount = si.Deductible_Insurance_Amount__c;
    this.errorMessage = si.Error_Message__c;
    this.isInsured = si.Is_Insured__c;
    this.netAmountAfterDeductible = si.Net_Amount_After_Deductible__c;
    this.parentSettlementId = si.Settlement__c;
    this.status = STATUS_PICKLIST_VALUE_TO_ENUM.get(si.Status__c);
    this.recordType = getRecordTypeEnumById(si.RecordTypeId);
  }

  /**
   * Sets the currency and amount of this item based on the given money instance.
   */
  public void setValue(Money value) {
    this.itemCurrency = value.CurrencyCode;
    this.amount = value.amount;
  }

  private static final Map<String, CostAccount> COST_ACCOUNT_PICKLIST_VALUE_TO_ENUM = new Map<String, CostAccount>{
    '6721' => CostAccount.CA6721,
    '6722' => CostAccount.CA6722,
    '6727' => CostAccount.CA6727,
    '6730' => CostAccount.CA6730,
    '6731' => CostAccount.CA6731,
    '6732' => CostAccount.CA6732,
    '6733' => CostAccount.CA6733,
    '6734' => CostAccount.CA6734,
    '6735' => CostAccount.CA6735,
    '6736' => CostAccount.CA6736,
    '6737' => CostAccount.CA6737,
    '6738' => CostAccount.CA6738,
    '6739' => CostAccount.CA6739,
    '6740' => CostAccount.CA6740,
    '6741' => CostAccount.CA6741,
    '6742' => CostAccount.CA6742,
    '6743' => CostAccount.CA6743,
    '6744' => CostAccount.CA6744
  };

  private static final Map<CostAccount, String> COST_ACCOUNT_ENUM_TO_PICKLIST_VALUE = new Map<CostAccount, String>{
    CostAccount.CA6721 => '6721',
    CostAccount.CA6722 => '6722',
    CostAccount.CA6727 => '6727',
    CostAccount.CA6730 => '6730',
    CostAccount.CA6731 => '6731',
    CostAccount.CA6732 => '6732',
    CostAccount.CA6733 => '6733',
    CostAccount.CA6734 => '6734',
    CostAccount.CA6735 => '6735',
    CostAccount.CA6736 => '6736',
    CostAccount.CA6737 => '6737',
    CostAccount.CA6738 => '6738',
    CostAccount.CA6739 => '6739',
    CostAccount.CA6740 => '6740',
    CostAccount.CA6741 => '6741',
    CostAccount.CA6742 => '6742',
    CostAccount.CA6743 => '6743',
    CostAccount.CA6744 => '6744'
  };

  private static final Map<String, CostCenter> COST_CENTER_PICKLIST_VALUE_TO_ENUM = new Map<String, CostCenter>{
    '90801' => CostCenter.CC90801,
    '71470' => CostCenter.CC71470
  };

  private static final Map<CostCenter, String> COST_CENTER_ENUM_TO_PICKLIST_VALUE = new Map<CostCenter, String>{
    CostCenter.CC90801 => '90801',
    CostCenter.CC71470 => '71470'
  };

  private static final Map<String, Status> STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, Status>{
    'Draft' => Status.Draft,
    'Pending L1 confirmation' => Status.PendingL1Confirmation,
    'Waiting for transfer' => Status.WaitingForTransfer,
    'Sent to Racer' => Status.SentToRacer,
    'Rejected by Racer' => Status.RejectedByRacer,
    'Done' => Status.Done,
    'Settlement failed' => Status.SettlementFailed
  };

  private static final Map<Status, String> STATUS_ENUM_TO_PICKLIST_VALUE = new Map<Status, String>{
    Status.Draft => 'Draft',
    Status.PendingL1Confirmation => 'Pending L1 confirmation',
    Status.WaitingForTransfer => 'Waiting for transfer',
    Status.SentToRacer => 'Sent to Racer',
    Status.RejectedByRacer => 'Rejected by Racer',
    Status.Done => 'Done',
    Status.SettlementFailed => 'Settlement failed'
  };

  private static Map<RecordType, String> recordTypeToEnumToDeveloperName = new Map<RecordType, String>{
    RecordType.Emergency => 'Emergency',
    RecordType.DefaultRecordType => 'Default Record Type'
  };

  private static Map<String, RecordType> recordTypeDeveloperNameToEnum = new Map<String, RecordType>{
    'Emergency' => RecordType.Emergency,
    'Default Record Type' => RecordType.DefaultRecordType
  };
  private static Map<RecordType, Id> recordTypeEnumToId = new Map<RecordType, Id>();
  private static Map<Id, RecordType> recordTypeIdToEnum = new Map<Id, RecordType>();

  public static Id getRecordTypeIdByEnum(RecordType rt) {
    Id rtId = recordTypeEnumToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.Settlement_Item__c.getRecordTypeInfosByName()
        .get(recordTypeToEnumToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeEnumToId.put(rt, rtId);
      recordTypeIdToEnum.put(rtId, rt);
    }
    return rtId;
  }

  private static RecordType getRecordTypeEnumById(Id rtId) {
    if (rtId == null) {
      return null;
    }

    RecordType rt = recordTypeIdToEnum.get(rtId);
    if (rt == null) {
      rt = recordTypeDeveloperNameToEnum.get(
        Schema.SObjectType.Settlement_Item__c.getRecordTypeInfosById()
          .get(rtId)
          .getName()
      );
      recordTypeEnumToId.put(rt, rtId);
      recordTypeIdToEnum.put(rtId, rt);
    }
    return rt;
  }
}
