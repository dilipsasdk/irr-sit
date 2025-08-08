public without sharing class Passengers extends ApplicationDomain {
  public Passengers(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Passenger__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Passengers(records);
    }
  }

  public List<Passenger__c> instanceRecords;

  public static Passengers newInstance(List<Passenger__c> sObjectList) {
    return (Passengers) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public override void onApplyDefaults() {
    for (Passenger__c passenger : (List<Passenger__c>) Records) {
      if (passenger.Name == null) {
        passenger.Name = passenger.Last_Name__c;
      }
    }
  }

  public override void onBeforeInsert() {
    associateWithExistingEBAccountsNoUpdate();
  }

  /**
   * Associates a passenger record with an EB account if one already exists
   * in Salesforce. Doesn't try to fetch EB account data from outside of SF
   * if it doesn't already exist in there.
   */
  public void associateWithExistingEBAccounts() {
    associateWithExistingEBAccountsNoUpdate();
    upsert Records;
  }

  private void associateWithExistingEBAccountsNoUpdate() {
    AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
      Account.SObjectType
    );

    Set<String> euroBonusNumbers = new Set<String>();

    for (Passenger__c passenger : (List<Passenger__c>) Records) {
      if (passenger.EuroBonus_Number__c != null) {
        euroBonusNumbers.add(passenger.EuroBonus_Number__c);
      }
    }

    List<Account> accountsFromSF = accounts.selectByEuroBonusNumber(
      euroBonusNumbers
    );

    for (Passenger__c passenger : (List<Passenger__c>) Records) {
      if (passenger.EuroBonus_Number__c != null) {
        for (Account account : accountsFromSF) {
          if (account.FCS_EBNumber__c == passenger.EuroBonus_Number__c) {
            passenger.Account__c = account.Id;
          }
        }
      }
    }
  }
}
