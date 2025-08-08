@isTest
public with sharing class ManageClaimsFromProactivity_Test {

  private static Date today = Date.today();
  private static String flightIdentifier =
    Flight.constructTEDSFlightNumberDate('SK1', today) + '-UME-ARN';

  @TestSetup
  static void setup() {
    Cases.bypassTrigger = true;
    Claims.bypassTrigger = true;

    Proactivity__c normalProactivity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Email__c = 'test@example.com'
    );

    insert normalProactivity;

    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier
    );

    insert flight1;

    Map<Schema.SObjectField, Object> caseFields = new Map<Schema.SObjectField, Object>{
      Case.Proactivity__c => normalProactivity.Id
    };

    Map<Schema.SObjectField, Object> claimFields = new Map<Schema.SObjectField, Object>{
      LIA_Claim__c.Address_line_1__c => 'Frösundaviks allé 1',
      LIA_Claim__c.Bank_Account_Holder_Name__c => 'Test testsson',
      LIA_Claim__c.Bank_Account_Number__c => 'SE7280000810340009783242',
      LIA_Claim__c.Bank_Country__c => 'Sweden',
      LIA_Claim__c.BIC_Swift__c => 'CITIUS33',
      LIA_Claim__c.City__c => 'Solna',
      LIA_Claim__c.Contact_Email__c => 'test@example.com',
      LIA_Claim__c.Contact_First_Name__c => 'Sven',
      LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
      LIA_Claim__c.Country__c => 'Sweden',
      LIA_Claim__c.Currency__c => 'SEK',
      LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
      LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
      LIA_Claim__c.EuroBonus_Number__c => '123456789',
      LIA_Claim__c.Flight_Number__c => Flight.normalizeFlightNumber('SK1'),
      LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
      LIA_Claim__c.Postal_Code__c => '11200',
      LIA_Claim__c.Preferred_Compensation_Method__c => 'Monetary',
      LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      ),
      LIA_Claim__c.Type_of_Customer__c => 'Private customer'
    };

    TestDataFactories.createCasesWithClaims(1, caseFields, claimFields);
  }

  @IsTest
  static void shouldRouteCasesToManualHandling() {
    LIA_Claim__c claimBeforeUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c limit 1];
    List<Id> proactivityIdList = new List<Id> {[SELECT Id FROM Proactivity__c limit 1].Id};

    routeCasesToManualHandling.routeCasesToManualHandling(proactivityIdList);

    LIA_Claim__c claimAfterUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c WHERE Id = :claimBeforeUpdate.Id limit 1];

    System.assertNotEquals(
      claimBeforeUpdate.EU261_Handling_Status__c,
      claimAfterUpdate.EU261_Handling_Status__c,
      'The queue should have been updated.'
    );
  }

  @IsTest
  static void shouldExcludeClaimsFromAutomation() {
    LIA_Claim__c claimBeforeUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c limit 1];
    List<Id> proactivityIdList = new List<Id> {[SELECT Id FROM Proactivity__c limit 1].Id};

    Test.startTest();
    ExcludeClaimsFromAutomation.excludeClaimsFromAutomation(proactivityIdList);
    Test.stopTest();

    LIA_Claim__c claimAfterUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c WHERE Id = :claimBeforeUpdate.Id limit 1];

    System.assertEquals(
      'On Hold',
      claimAfterUpdate.EU261_Handling_Status__c,
      'The claim is now excluded from the automation.'
    );
  }

  @IsTest
  static void shouldReturnClaimsToAutomation() {
    LIA_Claim__c claimBeforeUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c limit 1];
    List<Id> proactivityIdList = new List<Id> {[SELECT Id FROM Proactivity__c limit 1].Id};

    ReturnClaimsToAutomationFromProactivity.returnClaimsToAutomation(proactivityIdList);

    LIA_Claim__c claimAfterUpdate = [SELECT Id, EU261_Handling_Status__c FROM LIA_Claim__c WHERE Id = :claimBeforeUpdate.Id limit 1];

    System.assertEquals(
      'Unhandled',
      claimAfterUpdate.EU261_Handling_Status__c,
      'The claim is now returned back to automation.'
    );
  }
}