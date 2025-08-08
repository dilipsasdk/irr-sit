@IsTest
public with sharing class Accounts_IntegrationTest {
  @IsTest
  public static void insertingAnEBAccountFetchesBookings() {
    // Given
    Account newAccount = FCS_TestDataFactory.createFrequentFlyers(1)[0];
    newAccount.FCS_EBNumber__c = APIMMock.EB_NUMBER_WITH_BOOKINGS;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    // When
    insert newAccount;
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = BookingsSelector.newInstance()
      .selectByAccountId(new Set<Id>{ newAccount.Id });
    System.assert(
      bookingsFromDB.size() > 0,
      'There should be a new booking related to the account'
    );
  }

  @IsTest
  public static void insertingAnAccountShouldFetchTPProducts() {
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
