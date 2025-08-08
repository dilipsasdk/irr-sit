/**
 * The AccountingEntry class denotes a single entry in a double-entry
 * bookkeeping system. These entries are used to generate the files sent to
 * Racer for accounting. The entries are created from settlement items in
 * settlements.
 *
 * Each settlement item has two or three AccountingEntry records. If the
 * settlement item is not insured, one debit and one credit entry should be
 * created for the item. If the item is insured, there should be one credit
 * entry and two debit entries: one for the normal cost account of the item
 * which contains the part of the amount which is not covered by insurance
 * (i.e. it falls within the deductible), and one for the insurance cost
 * account which contains the amount which falls above the deductible and
 * can be claimed from insurance.
 */
public class AccountingEntry {
  private static final String TODAYS_DATE = Datetime.now().format('yyyyMMdd');
  private static final String TODAYS_PERIOD = Datetime.now().format('yyMM');

  public enum EntryType {
    CREDIT,
    DEBIT
  }

  // Defines the field lengths in columns for all fields in all records.
  public static final Map<String, Integer> FIELD_LENGTHS = new Map<String, Integer>{
    'RecordIdentifier' => 3,
    'AUN' => 2,
    'VerificationNumber' => 6,
    'ConversionDate' => 8,
    'NaturalAccount' => 4,
    'CostCenter' => 5,
    'ReconciliationReference' => 10,
    'Product' => 6,
    'Counterpart' => 7,
    'Misc1' => 6,
    'Misc2' => 6,
    'Currency' => 3,
    'DebitOrCredit' => 1,
    'Amount' => 15,
    'Description' => 24,
    'CompanyCode' => 3,
    'Period' => 4,
    'FeederName' => 5,
    'DeliveryNumber' => 2
  };

  public static final Map<String, String> CONSTANT_FIELDS = new Map<String, String>{
    'RecordIdentifier' => 'RAC',
    'AUN' => '01',
    'CompanyCode' => 'SK',
    'Period' => TODAYS_PERIOD,
    'FeederName' => 'SF',
    'DeliveryNumber' => '01'
  };

  public static final Map<String, String> CREDIT_COST_CENTERS_BY_CURRENCY = new Map<String, String>{
    'DKK' => '90802',
    'NOK' => '69851',
    'SEK' => '90801',
    'OTH' => '90890'
  };

  public static final List<String> FIELDS_IN_ORDER = new List<String>{
    'RecordIdentifier',
    'AUN',
    'VerificationNumber',
    'ConversionDate',
    'NaturalAccount',
    'CostCenter',
    'ReconciliationReference',
    'Product',
    'Counterpart',
    'Misc1',
    'Misc2',
    'Currency',
    'DebitOrCredit',
    'Amount',
    'Description',
    'CompanyCode',
    'Period',
    'FeederName',
    'DeliveryNumber'
  };

  public Map<String, String> data;
  public Integer amount;
  public EntryType type;

  /**
   * Constructs an AccountingEntry for the given settlement item.
   *
   * Instances of the class should not be created directly with the constructor
   * from outside of the class. Use the provided createFromSettlementItems
   * method instead.
   *
   * @param settlementItem The settlement item for which this is an accounting entry
   * @param entryType Whether this is a credit or a debit entry for the settlement item
   * @param isInsuranceAccountEntry Whether this debit entry is the insurance account entry for this settlement item. N/A for credit entries.
   */
  public AccountingEntry(
    Settlement_Item__c settlementItem,
    EntryType entryType,
    Boolean isInsuranceAccountEntry
  ) {
    String costAccount;
    String costCenter;
    Decimal amountToSet;
    String debitOrCredit;
    String description = '';
    String reconciliationReference;

    if (
      settlementItem.Amount__c == null ||
      settlementItem.Currency__c == null ||
      settlementItem.Cost_Account__c == null
    ) {
      String errorMessage =
        'Missing data from settlement item when creating accounting entry: ' +
        settlementItem.Id +
        ' | Amount: ' +
        settlementItem.Amount__c +
        ' | Currency: ' +
        settlementItem.Currency__c +
        ' | Cost Account: ' +
        settlementItem.Cost_Account__c;

      C_Log.log(C_Log.Severity.Error, errorMessage, null, 'Racer', null);

      throw new IllegalArgumentException(errorMessage);
    }

    switch on entryType {
      when CREDIT {
        amountToSet = settlementItem.Amount__c;
        costAccount = Settlements.COST_ACCOUNT_CREDIT;
        debitOrCredit = 'C';
        reconciliationReference = 'CARE' + TODAYS_PERIOD;
        description = 'Balance post for debits';

        String creditCostCenter = CREDIT_COST_CENTERS_BY_CURRENCY.get(
          settlementItem.Currency__c
        );
        if (creditCostCenter == null) {
          creditCostCenter = CREDIT_COST_CENTERS_BY_CURRENCY.get('OTH');
        }
        costCenter = creditCostCenter;
      }
      when DEBIT {
        debitOrCredit = 'D';
        costCenter = settlementItem.Cost_Center__c;
        if (settlementItem.Name.length() == 15) {
          reconciliationReference = settlementItem.Name.substring(5, 15);
        } else {
          if (settlementItem.Name.length() > 10) {
            throw new IllegalArgumentException(
              'Settlement item name is too long: ' + settlementItem.Name
            );
          }

          reconciliationReference = settlementItem.Name;
        }
        if (settlementItem.Is_Insured__c) {
          if (isInsuranceAccountEntry) {
            // For insured items, we should debit everything above the
            // deductible to the insurance cost account.
            costAccount = Settlements.COST_ACCOUNT_INSURANCE;
            amountToSet = settlementItem.Net_Amount_After_Deductible__c;
            description = 'SAS Insurance';
          } else {
            // For insured items, we should debit up to the deductible to the
            // normal cost account.
            costAccount = settlementItem.Cost_Account__c;
            Decimal deductible =
              settlementItem.Amount__c -
              settlementItem.Net_Amount_After_Deductible__c;
            amountToSet = deductible;
          }
        } else {
          costAccount = settlementItem.Cost_Account__c;
          amountToSet = settlementItem.Amount__c;
        }
      }
    }
    Integer amountInCents;
    if (settlementItem.Currency__c == 'JPY') {
      amountInCents = amountToSet.intValue();
    } else {
      amountInCents = (amountToSet * 100).intValue();
    }

    this.type = entryType;
    this.amount = amountInCents;
    this.data = new Map<String, String>{
      'ConversionDate' => (Datetime.newInstanceGmt(
          settlementItem.Settlement__r.Date_of_Exchange_Calculation__c,
          Time.newInstance(0, 0, 0, 0)
        ))
        .format('yyyyMMdd'),
      'CostCenter' => costCenter,
      'NaturalAccount' => costAccount,
      'ReconciliationReference' => reconciliationReference,
      'Product' => '',
      'Counterpart' => '',
      'Misc1' => '',
      'Misc2' => '',
      'Currency' => settlementItem.Currency__c,
      'DebitOrCredit' => debitOrCredit,
      'Amount' => String.valueOf(amountInCents),
      'Description' => description
    };
  }

  /**
   * Creates a list of accounting entries from the given settlement items.
   * These entries can then be used to generate the accounting files for RACER.
   *
   * The returned list includes entries in the same order as the input list,
   * with all debit entries first, followed by the credit entries.
   *
   * @param settlementItems
   * @return A full list of accounting entries including both
   */
  public static List<AccountingEntry> createFromSettlementItems(
    List<Settlement_Item__c> settlementItems
  ) {
    /**
     * The accounting files for RACER are in double entry format so we need to
     * create both debits and credits for each settlement item.
     *
     * For insured settlement items, we need to separately create the entry
     * for the part of the settlement that falls under the deductible, and the
     * part which we can claim from insurance.
     */
    List<AccountingEntry> accountingEntries = new List<AccountingEntry>();
    List<AccountingEntry> creditEntries = new List<AccountingEntry>();

    for (Settlement_Item__c s : settlementItems) {
      if (s.Is_Insured__c) {
        // If insured, and net amount == amount, we don't create the normal line at all.
        // For insured settlement items, we need to create two entires: One for
        // the non-deducted cost and one for what we claim
        Boolean hasDeductiblePart =
          s.Amount__c != s.Net_Amount_After_Deductible__c;
        if (hasDeductiblePart) {
          // If net amount is equal to settlements amount, we don't need to
          // create an entry for the baggage cost account at all, because all
          // will be debited to the insurance account.
          accountingEntries.add(new AccountingEntry(s, EntryType.DEBIT, false));
        }
        Boolean hasInsuredPart = s.Net_Amount_After_Deductible__c > 0;
        if (hasInsuredPart) {
          accountingEntries.add(new AccountingEntry(s, EntryType.DEBIT, true));
        }
      } else {
        accountingEntries.add(new AccountingEntry(s, EntryType.DEBIT, false));
      }
      // Storing Credit entries separately to preserve the file structure
      creditEntries.add(new AccountingEntry(s, EntryType.CREDIT, false));
    }
    // The Credit entries should be placed after the Debit entries
    accountingEntries.addAll(creditEntries);
    return accountingEntries;
  }
}
