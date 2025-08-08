@IsTest
private class Customers_Test {
  @IsTest
  static void customerNameShouldBeEqualToFirstLast() {
    LIA_Claim__c cl = new LIA_Claim__c();
    insert cl;

    Customer__c c = new Customer__c(
      First_Name__c = 'Test',
      Last_Name__c = 'Testsson',
      Claim__c = cl.Id
    );

    insert c;

    Customer__c customerAfterInsert = [
      SELECT Id, Name
      FROM Customer__c
      WHERE Id = :c.Id
    ];

    System.assertEquals(
      'Test Testsson',
      customerAfterInsert.Name,
      'Customer Name should set as first name followed by last name.'
    );
  }
}
