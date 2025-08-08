@IsTest
public with sharing class PaymentEntry_Test {
  @IsTest
  public static void genericPaymentMethodsShouldBeSetCorrectly() {
    Settlement__c s1 = new Settlement__c(
      Currency__c = 'USD',
      Bank_Country__c = 'United States'
    );

    PaymentEntry p1 = new PaymentEntry(s1);

    System.assertEquals(
      'NORDEA US DOM EDI',
      p1.data.get('accountData').get('EDIPaymentMethod'),
      'USD payments to US should have NORDEA US DOM EDI as payment method.'
    );

    Settlement__c s2 = new Settlement__c(
      Currency__c = 'USD',
      Bank_Country__c = 'Sweden'
    );

    PaymentEntry p2 = new PaymentEntry(s2);

    System.assertEquals(
      'NORDEA CROSS BORDER EDI',
      p2.data.get('accountData').get('EDIPaymentMethod'),
      'USD payments to outside of US should have NORDEA CROSS BORDER EDI as payment method.'
    );

    Settlement__c s3 = new Settlement__c(
      Currency__c = 'EUR',
      Bank_Country__c = 'United States'
    );

    PaymentEntry p3 = new PaymentEntry(s3);

    System.assertEquals(
      'CROSS BORDER EDI',
      p3.data.get('accountData').get('EDIPaymentMethod'),
      'Non-USD payments to US should have CROSS BORDER EDI as payment method.'
    );

    Settlement__c s4 = new Settlement__c(
      Currency__c = 'USD',
      Bank_Country__c = 'United States',
      RecordTypeId = Settlements.getRecordTypeId(Settlements.RecordType.Cheque)
    );

    PaymentEntry p4 = new PaymentEntry(s4);

    System.assertEquals(
      'NORDEA US DOM CHEQUE',
      p4.data.get('accountData').get('EDIPaymentMethod'),
      'Check payments should have NORDEA US DOM CHEQUE as payment method.'
    );
  }

  @IsTest
  public static void countryExtensionShouldBeSetCorrectly() {
    Settlement__c s1 = new Settlement__c(
      Bank_Country__c = 'Sweden',
      Currency__c = 'SEK'
    );

    PaymentEntry p1 = new PaymentEntry(s1);

    System.assertEquals(
      'SE',
      p1.data.get('supplierSiteData').get('countryExt'),
      'Country should be set to bank country if contact country does not exist.'
    );

    Settlement__c s2 = new Settlement__c(
      Bank_Country__c = 'Sweden',
      Country__c = 'Finland',
      Currency__c = 'SEK'
    );

    PaymentEntry p2 = new PaymentEntry(s2);

    System.assertEquals(
      'FI',
      p2.data.get('supplierSiteData').get('countryExt'),
      'Country should be set to contact country over bank country if both exist.'
    );
  }
}
