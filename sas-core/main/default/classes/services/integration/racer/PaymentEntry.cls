/**
 * This file includes mostly data parameters for creating the payment files.
 *
 * See ConstructPaymentFile more details.
 *
 * Check the class constructor for the building logic.
 */

public class PaymentEntry {
  // Defines the full field lengths in columns for all fields in all records.
  // If field contents are less than this, they're right padded to this length.
  // Field contents must not be longer than this.
  public static final Map<String, Map<String, Integer>> FIELD_LENGTHS = new Map<String, Map<String, Integer>>{
    'controlRecord' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'communicationMethod' => 2,
      'testFlag' => 1,
      'documentId' => 6,
      'documentType' => 5,
      'documentPurposeCode' => 2,
      'documentCode' => 35,
      'translatorCode' => 30,
      'locationCodeExt' => 35,
      'description' => 74,
      'referenceExt1' => 80,
      'referenceExt2' => 80,
      'transactionDate' => 15,
      'runId' => 15,
      'documentStandard' => 10
    },
    'accountData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'transactionHandlingCode' => 25,
      'trxHandlingCodeExt' => 3,
      'checkAmount' => 22,
      'currencyCode' => 15,
      'currencyCodeExt' => 3,
      'EDIPaymentMethod' => 25,
      'EDIPaymentMethodExt' => 3,
      'EDIPaymentFormat' => 25,
      'EDIPaymentFormatExt' => 10,
      'bankBranchType' => 25,
      'bankBranchTypeExt' => 10,
      'bankAccountType' => 25,
      'bankAccountTypeExt' => 10,
      'bankAccountNumber' => 30,
      'bankEDIIDNumber' => 30,
      'vendorBankBranchType' => 25,
      'vendorBankBranchTypeExt' => 10,
      'vendorBankAccountType' => 25,
      'vendorBankAccountTypeExt' => 10,
      'vendorBankAccountNumber' => 35,
      'paymentDate' => 15,
      'accountHolderName' => 15,
      'EFTRequester' => 15
    },
    'paymentData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'bankNumber' => 25,
      'vendorBankNumber' => 25,
      'EDIRemittanceMethod' => 25,
      'EDIRemittanceInstruction' => 80,
      'checkrunName' => 30,
      'checkVoucherNumber' => 22,
      'selectedCheckId' => 15,
      'checkNumber' => 22,
      'customerNumber' => 25,
      'voidFlag' => 1,
      'voidDate' => 15,
      'supplierBankBranchNumber' => 25,
      'supplierBankBranchSWIFTCode' => 12
    },
    'supplierData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'vendorNumber' => 30,
      'vendorNumberExt' => 30,
      'vendorEDIIDNumber' => 30,
      'Segment2' => 30,
      'Segment3' => 30,
      'Segment4' => 30,
      'Segment5' => 30
    },
    'bankData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'bankSiteCode' => 20,
      'bankSiteCodeExt' => 20,
      'bankName' => 60,
      'addressLine1' => 35,
      'addressLine2' => 35,
      'addressLine3' => 35,
      'addressLine4' => 35,
      'city' => 30,
      'postalCode' => 15,
      'country' => 20,
      'countryExt' => 3,
      'state' => 20,
      'stateExt' => 10,
      'province' => 20,
      'provinceExt' => 10
    },
    'supplierSiteData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'vendorSiteCode' => 20,
      'vendorSiteCodeExt' => 20,
      'vendorName' => 60,
      'addressLine1' => 35,
      'addressLine2' => 35,
      'addressLine3' => 35,
      'addressLine4' => 35,
      'city' => 30,
      'postalCode' => 15,
      'country' => 20,
      'countryExt' => 3,
      'state' => 20,
      'stateExt' => 10,
      'province' => 20,
      'provinceExt' => 10
    },
    'invoiceData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'checkrunName' => 30,
      'vendorNumber' => 30,
      'vendorNumberExt' => 20,
      'customerNumber' => 25,
      'invoiceNumber' => 50,
      'invoiceDate' => 15,
      'invoiceDescription' => 50,
      'paymentAmount' => 22,
      'invoiceAmount' => 22,
      'discountAmount' => 22
    },
    'invoiceFlexfields' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'attributeCategory' => 30,
      'attribute1' => 80,
      'attribute2' => 80,
      'attribute3' => 80,
      'attribute4' => 80,
      'attribute5' => 30
    }
  };

  // Defines the order fields should be for a given record.
  public static final Map<String, List<String>> FIELDS_IN_ORDER_BY_RECORD = new Map<String, List<String>>{
    'controlRecord' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'communicationMethod',
      'testFlag',
      'documentId',
      'documentType',
      'documentPurposeCode',
      'documentCode',
      'translatorCode',
      'locationCodeExt',
      'description',
      'referenceExt1',
      'referenceExt2',
      'transactionDate',
      'runId',
      'documentStandard'
    },
    'accountData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'transactionHandlingCode',
      'trxHandlingCodeExt',
      'checkAmount',
      'currencyCode',
      'currencyCodeExt',
      'EDIPaymentMethod',
      'EDIPaymentMethodExt',
      'EDIPaymentFormat',
      'EDIPaymentFormatExt',
      'bankBranchType',
      'bankBranchTypeExt',
      'bankAccountType',
      'bankAccountTypeExt',
      'bankAccountNumber',
      'bankEDIIDNumber',
      'vendorBankBranchType',
      'vendorBankBranchTypeExt',
      'vendorBankAccountType',
      'vendorBankAccountTypeExt',
      'vendorBankAccountNumber',
      'paymentDate',
      'accountHolderName',
      'EFTRequester'
    },
    'paymentData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'bankNumber',
      'vendorBankNumber',
      'EDIRemittanceMethod',
      'EDIRemittanceInstruction',
      'checkrunName',
      'checkVoucherNumber',
      'selectedCheckId',
      'checkNumber',
      'customerNumber',
      'voidFlag',
      'voidDate',
      'supplierBankBranchNumber',
      'supplierBankBranchSWIFTCode'
    },
    'supplierData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'vendorNumber',
      'vendorNumberExt',
      'vendorEDIIDNumber',
      'Segment2',
      'Segment3',
      'Segment4',
      'Segment5'
    },
    'bankData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'bankSiteCode',
      'bankSiteCodeExt',
      'bankName',
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'city',
      'postalCode',
      'country',
      'countryExt',
      'state',
      'stateExt',
      'province',
      'provinceExt'
    },
    'supplierSiteData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'vendorSiteCode',
      'vendorSiteCodeExt',
      'vendorName',
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'city',
      'postalCode',
      'country',
      'countryExt',
      'state',
      'stateExt',
      'province',
      'provinceExt'
    },
    'invoiceData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'checkrunName',
      'vendorNumber',
      'vendorNumberExt',
      'customerNumber',
      'invoiceNumber',
      'invoiceDate',
      'invoiceDescription',
      'paymentAmount',
      'invoiceAmount',
      'discountAmount'
    },
    'invoiceFlexfields' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'attributeCategory',
      'attribute1',
      'attribute2',
      'attribute3',
      'attribute4',
      'attribute5'
    }
  };

  // Constant fields for records across batches and settlements.
  // If a field is an empty string here, it should always be blank.
  public static final Map<String, Map<String, String>> CONSTANT_FIELDS_BY_RECORD = new Map<String, Map<String, String>>{
    'controlRecord' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '0010',
      'recordLayout' => 'CT',
      'recordLayoutQualifier' => 'CTL',
      'communicationMethod' => 'ED',
      'testFlag' => (C_Util.isSandbox() || Test.isRunningTest()) ? 'T' : 'P',
      'documentId' => 'PYO',
      'documentType' => '',
      'documentPurposeCode' => '',
      'locationCodeExt' => '',
      'description' => '',
      'referenceExt1' => '',
      'referenceExt2' => '',
      'documentStandard' => 'EDIFACT'
    },
    'accountData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1000',
      'recordLayout' => 'BK',
      'recordLayoutQualifier' => 'BK1',
      'transactionHandlingCode' => 'D',
      'trxHandlingCodeExt' => '',
      'currencyCodeExt' => '',
      'EDIPaymentMethodExt' => '',
      'EDIPaymentFormat' => '',
      'EDIPaymentFormatExt' => '',
      'bankBranchType' => '',
      'bankBranchTypeExt' => '',
      'bankAccountType' => '',
      'bankAccountTypeExt' => '',
      'vendorBankBranchType' => '',
      'vendorBankBranchTypeExt' => '',
      'vendorBankAccountType' => '',
      'vendorBankAccountTypeExt' => ''
    },
    'paymentData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1010',
      'recordLayout' => 'PY',
      'recordLayoutQualifier' => 'PAY',
      'bankNumber' => '',
      'vendorBankNumber' => '',
      'EDIRemittanceMethod' => 'EDI to payer\'s bank',
      'checkVoucherNumber' => '',
      'customerNumber' => '',
      'voidFlag' => '',
      'voidDate' => '',
      'supplierBankBranchSWIFTCode' => ''
    },
    'supplierData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1020',
      'recordLayout' => 'VN',
      'recordLayoutQualifier' => 'VN1',
      'vendorNumber' => '',
      'vendorNumberExt' => '',
      'vendorEDIIDNumber' => '',
      'Segment2' => '',
      'Segment3' => '',
      'Segment4' => '',
      'Segment5' => ''
    },
    'bankData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1030',
      'recordLayout' => 'AD',
      'recordLayoutQualifier' => 'BK1',
      'bankSiteCodeExt' => '',
      'bankName' => '',
      'countryExt' => '',
      'stateExt' => '',
      'provinceExt' => ''
    },
    'supplierSiteData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1050',
      'recordLayout' => 'AD',
      'recordLayoutQualifier' => 'VS1',
      'vendorSiteCodeExt' => '',
      'addressLine3' => '',
      'addressLine4' => '',
      'country' => '',
      'stateExt' => '',
      'province' => '',
      'provinceExt' => ''
    },
    'invoiceData' => new Map<String, String>{
      'ref3Blank' => '',
      'recordNumber' => '2000',
      'recordLayout' => 'IV',
      'recordLayoutQualifier' => 'INV',
      'vendorNumber' => '',
      'vendorNumberExt' => '',
      'customerNumber' => '',
      'invoiceDescription' => '',
      'discountAmount' => '0'
    },
    'invoiceFlexfields' => new Map<String, String>{
      'ref3Blank' => '',
      'recordNumber' => '2010',
      'recordLayout' => 'A1',
      'recordLayoutQualifier' => 'RE1',
      'attributeCategory' => '',
      'attribute2' => '',
      'attribute3' => '',
      'attribute4' => '',
      'attribute5' => ''
    }
  };

  // Defines the order that the record lines should be in in the payment file.
  public static final List<String> RECORDS_IN_ORDER = new List<String>{
    'controlRecord',
    'accountData',
    'paymentData',
    'supplierData',
    'bankData',
    'supplierSiteData',
    'invoiceData',
    'invoiceFlexfields'
  };

  public Map<String, Map<String, String>> data;
  public String paymentCurrency;

  private static final String TODAYS_DATE = Datetime.now().format('yyyyMMdd');
  private static final Map<String, Settlement_Currency_Setting__mdt> currencyToSettings = Settlement_Currency_Setting__mdt.getAll();
  private static final Map<Id, Settlement_Bank_Setting__mdt> bankToSettings = new Map<Id, Settlement_Bank_Setting__mdt>();
  private static final Map<String, Settlement_Country_Setting__mdt> countryToSettings = new Map<String, Settlement_Country_Setting__mdt>();
  // getAll() returns a map of DeveloperName => Mdt Object. We need to be able to fetch these
  // based on the Id found in Settlement_Currency_Setting__mdt
  static {
    for (
      Settlement_Bank_Setting__mdt sbs : Settlement_Bank_Setting__mdt.getAll()
        .values()
    ) {
      bankToSettings.put(sbs.Id, sbs);
    }
    for (
      Settlement_Country_Setting__mdt scs : Settlement_Country_Setting__mdt.getAll()
        .values()
    ) {
      countryToSettings.put(scs.Country_Name__c, scs);
    }
  }

  public PaymentEntry(Settlement__c s) {
    Settlement_Currency_Setting__mdt currencySettings = currencyToSettings.get(
      s.Currency__c
    );

    Settlement_Bank_Setting__mdt bankSettings = bankToSettings.get(
      currencySettings.Settlement_Bank_Setting__c
    );

    Settlement_Country_Setting__mdt bankCountrySettings = countryToSettings.get(
      s.Bank_Country__c
    );

    String countryShortCode;

    // Country short code should by default be set based on contact's address
    // information, but if it doesn't exist, we can use bank country info.
    // When we receive company information from the form, we don't ask for
    // address information which would include the country.
    if (String.isBlank(s.Country__c)) {
      countryShortCode = bankCountrySettings.Country_Short_Code__c;
    } else {
      Settlement_Country_Setting__mdt contactCountrySettings = countryToSettings.get(
        s.Country__c
      );

      countryShortCode = contactCountrySettings.Country_Short_Code__c;
    }

    String paymentMethod = null;

    Boolean isChequeSettlement =
      Settlements.getRecordTypeId(Settlements.RecordType.Cheque) ==
      s.RecordTypeId;
    Boolean isUSDPaymentToOutsideOfUS =
      s.Currency__c == 'USD' &&
      s.Bank_Country__c != 'United States';
    Boolean isNonUSDPaymentToUS =
      s.Bank_Country__c == 'United States' &&
      s.Currency__c != 'USD';
    Boolean isNonSEKPaymentToSweden =
      s.Currency__c != 'SEK' &&
      s.Bank_Country__c == 'Sweden';

    // Payment details are dependent on bank country
    if (isChequeSettlement) {
      // Cheque payments also have a specific payment type. This is only
      // supported for US domestic cheque payments.
      paymentMethod = 'NORDEA US DOM CHEQUE';
    } else if (isUSDPaymentToOutsideOfUS) {
      paymentMethod = 'NORDEA CROSS BORDER EDI';
    } else if (isNonUSDPaymentToUS) {
      paymentMethod = 'CROSS BORDER EDI';
    } else if (isNonSEKPaymentToSweden) {
      paymentMethod = 'SEPA';
    } else {
      paymentMethod = bankCountrySettings.Payment_Type__c;
    }

    String amount = String.valueOf(s.Amount__c);

    this.paymentCurrency = s.Currency__c;

    Map<String, Map<String, String>> fullPaymentRecord = new Map<String, Map<String, String>>{
      'controlRecord' => new Map<String, String>{
        'transactionDate' => TODAYS_DATE
      },
      'accountData' => new Map<String, String>{
        'checkAmount' => amount,
        'currencyCode' => s.Currency__c,
        'vendorBankAccountNumber' => isChequeSettlement
          ? ''
          : s.Bank_Account_Number__c,
        'EDIPaymentMethod' => paymentMethod,
        'bankAccountNumber' => currencySettings.bankAccountNumber__c,
        'bankEDIIDNumber' => bankSettings.bankEDIIDNumber__c,
        'accountHolderName' => bankSettings.accountHolderName__c,
        'EFTRequester' => bankSettings.EFT_Requester__c,
        'paymentDate' => TODAYS_DATE
      },
      'paymentData' => new Map<String, String>{
        'checkrunName' => s.Currency__c.substring(0, 2) + s.Name,
        'EDIRemittanceInstruction' => currencySettings.EDIRemittanceInstruction__c ==
          null
          ? ''
          : currencySettings.EDIRemittanceInstruction__c,
        'selectedCheckId' => s.Name,
        'supplierBankBranchNumber' => isChequeSettlement ? '' : s.BIC_Swift__c
      },
      'supplierData' => new Map<String, String>(),
      'bankData' => new Map<String, String>{
        'bankSiteCode' => bankSettings.bankSiteCode__c,
        'addressLine1' => bankSettings.addressLine1__c,
        'city' => bankSettings.city__c,
        'postalCode' => bankSettings.postalCode__c,
        'country' => bankSettings.country__c
      },
      'supplierSiteData' => new Map<String, String>{
        'vendorSiteCode' => s.Name,
        'vendorName' => s.Payee_Name__c,
        'addressLine1' => s.Address_line_1__c == null
          ? null
          : s.Address_line_1__c,
        'addressLine2' => s.Address_line_2__c == null
          ? null
          : s.Address_line_2__c,
        'city' => s.City__c,
        'postalCode' => s.Postal_Code__c,
        'state' => (isChequeSettlement && s.State__c != null) ? s.State__c : '',
        'countryExt' => countryShortCode
      },
      'invoiceData' => new Map<String, String>{
        'ref2Invoice' => 'SF REF ' + s.Name,
        'checkrunName' => s.Name,
        'invoiceNumber' => s.Name,
        'paymentAmount' => amount,
        'invoiceAmount' => amount,
        'invoiceDate' => TODAYS_DATE
      },
      'invoiceFlexfields' => new Map<String, String>{
        'ref2Invoice' => 'SF REF ' + s.Name,
        'attribute1' => s.Payee_reference__c == null ? '' : s.Payee_reference__c
      }
    };

    for (Map<String, String> record : fullPaymentRecord.values()) {
      record.put('tradingPartnerCode', bankSettings.tradingPartnerCode__c);
      record.put('translatorCode', bankSettings.translatorCode__c);
    }

    this.data = fullPaymentRecord;
  }
}
