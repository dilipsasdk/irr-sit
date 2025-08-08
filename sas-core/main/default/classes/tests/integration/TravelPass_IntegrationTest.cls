@IsTest
public with sharing class TravelPass_IntegrationTest {
  @IsTest
  public static void itShouldBePossibleToRefreshTPProductInfo() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Account newAccount = new Account(
      FCS_TPAccountNumber__c = 'TEST12',
      FCS_CMP__c = 'TEST12',
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      FirstName = 'Test',
      LastName = 'Account'
    );
    insert newAccount;

    TravelPassService.fetchTravelPassAccount('TEST12', newAccount.Id);
    TravelPassService.refreshTravelPassAccount(newAccount.Id);
    Test.stopTest();

    List<Travel_Pass_Product__c> associatedTPProducts = [
      SELECT Id, Account__c
      FROM Travel_Pass_Product__c
      WHERE Account__c = :newAccount.Id
    ];

    System.assert(
      associatedTPProducts.size() == 2,
      'There should be two TP products associated with the account as the mock response contains two products.'
    );
  }
  @IsTest
  public static void updatingTPAccountDataShouldNotCreateDuplicateProducts() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Account newAccount = new Account(
      FCS_TPAccountNumber__c = 'TEST12',
      FCS_CMP__c = 'TEST12',
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      FirstName = 'Test',
      LastName = 'Account'
    );
    insert newAccount;
    TravelPassService.fetchTravelPassAccount('TEST12', newAccount.Id);
    Test.stopTest();

    List<Travel_Pass_Product__c> associatedTPProducts = [
      SELECT Id, Account__c
      FROM Travel_Pass_Product__c
      WHERE Account__c = :newAccount.Id
    ];

    System.assert(
      associatedTPProducts.size() == 2,
      'There should be two TP products associated with the account as the mock response contains two products.'
    );
  }
}
