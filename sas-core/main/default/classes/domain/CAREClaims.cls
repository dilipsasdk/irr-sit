public without sharing class CAREClaims extends ApplicationDomain {
  public CAREClaims(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<CARE_Claim__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new CAREClaims(records);
    }
  }

  public static CAREClaims newInstance(List<CARE_Claim__c> sObjectList) {
    return (CAREClaims) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public List<CARE_Claim__c> instanceRecords;

  public override void onApplyDefaults() {
    for (CARE_Claim__c claim : instanceRecords) {
      if (claim.Name == null) {
        claim.Name = claim.Case_Id__c;
      }
    }
  }

  public CAREClaims upsertToDB() {
    // The upsert operation seems to fail due to a race condition between two threads
    // trying to upsert the records simultaneously. One thread succeeds and the other
    // fails with a duplicate value exception. Retrying fixes this because then
    // the records are simply updated.
    try {
      upsert instanceRecords Case_Id__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert instanceRecords Case_Id__c;
      }
    }

    return this;
  }

  public static CAREClaims create(FetchCAREClaimsResponse claimsResponse) {
    if (claimsResponse == null || claimsResponse.response.cases.size() == 0) {
      return null;
    }

    List<CARE_Claim__c> toCreate = new List<CARE_Claim__c>();

    for (FetchCAREClaimsResponse.Cases claim : claimsResponse.response.cases) {
      toCreate.add(parseResponseToSObject(claim));
    }

    return new CAREClaims(toCreate);
  }

  private static CARE_Claim__c parseResponseToSObject(
    FetchCAREClaimsResponse.Cases responseCase
  ) {
    String parsedSettlements = '';
    String parsedNotes = '';
    String parsedDecisions = '';
    String parsedCustomers = '';
    String parsedCategories = '';

    Map<String, String> customerIdToName = new Map<String, String>();
    Map<String, String> dictionary = new Map<String, String>{
      '841' => 'Refund of tickets and ancillary',
      '842' => 'Goodwill Compensation',
      '846' => 'Liability - Other',
      '849' => 'Liability - Care (Meal, Hotel, Transportation)',
      '850' => 'Liability - Downgrading Compensation',
      '851' => 'Liability - EU 261 Compensation',
      '852' => 'Liability - Denied Boarding Compensation',
      '854' => 'Liability - Baggage Pilfered',
      '855' => 'Liability - Baggage Delayed/missing/lost',
      '856' => 'Liability - Baggage Damaged',
      '1066' => 'SEK',
      '1067' => 'DKK',
      '1068' => 'NOK',
      '1069' => 'EUR',
      '1070' => 'AUD',
      '1071' => 'CAD',
      '1072' => 'CZK',
      '1073' => 'HKD',
      '1074' => 'JPY',
      '1075' => 'NZD',
      '1076' => 'PLN',
      '1077' => 'SGD',
      '1078' => 'CHF',
      '1079' => 'GBP',
      '1080' => 'USD',
      '1966' => 'CNY',
      '1967' => 'RUB',
      '1968' => 'THB'
    };

    for (FetchCAREClaimsResponse.Customers customer : responseCase.customers) {
      String name = customer.cusFirstname + ' ' + customer.cusLastname;
      customerIdToName.put(customer.customerId, name);

      parsedCustomers += name + '<br>';
    }

    for (FetchCAREClaimsResponse.Notes note : responseCase.notes) {
      String toAdd =
        '<b>Note ' +
        note.noteSeq +
        ' for ' +
        customerIdToName.get(note.customerId) +
        '</b><br>' +
        note.noteValue +
        '<br><br>';

      parsedNotes += toAdd;
    }

    Set<String> uniqueCategoryNames = new Set<String>();
    for (
      FetchCAREClaimsResponse.Categories category : responseCase.categories
    ) {
      uniqueCategoryNames.add(category.CatName);
    }
    for (String name : uniqueCategoryNames) {
      parsedCategories += name + '<br>';
    }

    for (FetchCAREClaimsResponse.Decisions decision : responseCase.decisions) {
      parsedDecisions += decision.dicName + '<br>';
    }

    for (
      FetchCAREClaimsResponse.Settlements settlement : responseCase.settlements
    ) {
      if (settlement.amount != null) {
        String toAdd = '<b>Settlement</b><br>';
        toAdd +=
          'Total: ' +
          settlement.amount +
          ' ' +
          dictionary.get(settlement.settlementCurrency) +
          '<br>';

        toAdd +=
          'Created: ' +
          settlement.dateCreated +
          '<br>Approved: ' +
          settlement.dateApproved +
          '<br>';

        if (
          settlement.settlementItems != null &&
          !settlement.settlementItems.isEmpty()
        ) {
          toAdd += '<b>Items</b><br>';
          for (
            FetchCAREClaimsResponse.SettlementItems item : settlement.settlementItems
          ) {
            String settlementItem = '* ';
            if (
              item.stiEurobonusPoints != null &&
              item.stiEurobonusPoints > 0
            ) {
              settlementItem +=
                item.stiEurobonusPoints +
                ' points for ' +
                customerIdToName.get(item.stiCusId) +
                '. Comments: ' +
                item.stiComments +
                '<br><br>';
            } else {
              settlementItem +=
                item.stiAmount +
                ' ' +
                dictionary.get(settlement.settlementCurrency) +
                ' for ' +
                customerIdToName.get(item.stiCusId) +
                '. Cost Acc: ' +
                dictionary.get(item.stiCostAcc) +
                '. Comments: ' +
                item.stiComments +
                '<br><br>';
            }
            toAdd += settlementItem;
          }
        }

        toAdd += '<br><br>';

        parsedSettlements += toAdd;
      }
    }

    return new CARE_Claim__c(
      Case_Id__c = responseCase.caseId,
      Booking_Reference__c = responseCase.pnr,
      Customers__c = parsedCustomers,
      Categories__c = parsedCategories,
      Decisions__c = parsedDecisions,
      Departure_Date__c = responseCase.flightDate != null
        ? Date.newInstance(
            responseCase.flightDate.year(),
            responseCase.flightDate.month(),
            responseCase.flightDate.day()
          )
        : null,
      Flight_Number__c = responseCase.flightNumber,
      Name = responseCase.caseId,
      Notes__c = parsedNotes,
      Date_Closed_In_CARE__c = responseCase.dateClosed,
      Date_Created_In_CARE__c = responseCase.dateCreated,
      Last_Modified_In_CARE__c = responseCase.lastModified,
      PIR__c = responseCase.pir,
      Settlements__c = parsedSettlements
    );
  }
}
