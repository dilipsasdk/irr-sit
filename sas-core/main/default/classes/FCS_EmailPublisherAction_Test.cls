/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Test class for FCS_EmailPublisherAction class
 */
@isTest
private class FCS_EmailPublisherAction_Test {
  // default address for redirected Cases
  @isTest
  static void defaultFromAddressforRedirctedCase() {
    From_email_based_on_Dept_and_Teams__c CSFromEmail = new From_email_based_on_Dept_and_Teams__c();
    CSFromEmail.Name = 'Group-ACE';
    CSFromEmail.From_Email__c = 'groupsalestest@sas.se';

    insert CSFromEmail;

    List<Case> Cases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      C_RecordTypeHelper.CASE_CHANNEL
    );
    cases[0].origin = 'Email - EuroBonus Name Change';
    cases[0].SuppliedFirstname__c = 'Test';
    cases[0].SuppliedLastname__c = 'Testsson';

    insert Cases;

    // redirect the cases
    cases[0].IsRedirected__c = true;
    cases[0].Department__c = 'Group Sales';
    cases[0].Team__c = 'ACE';
    update cases;

    EmailMessage email = new EmailMessage();
    email.ToAddress = 'groupsalestest@sas.se';
    email.ParentId = cases[0].Id;
    insert email;

    //create QuickActionDefaults
    List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
      new Map<String, Object>{
        'targetSObject' => new EmailMessage(),
        'contextId' => cases[0].Id,
        'actionType' => 'Email',
        'actionName' => 'Case.Email',
        'fromAddressList' => new List<String>{ email.ToAddress }
      }
    };

    List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
      JSON.serialize(defaultSettingAsObject),
      List<QuickAction.SendEmailQuickActionDefaults>.class
    );
    Test.startTest();
    (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
    Test.stopTest();

    System.assertEquals(
      CSFromEmail.From_Email__c,
      ((EmailMessage) defaultsSettings[0].getTargetSObject())
        .ValidatedFromAddress
    );
  }
  // user to default the from address if more than email-to-case present for escalated cases
  @isTest
  static void defaultFromAddressEscalatedCase() {
    From_email_based_on_Dept_and_Teams__c CSFromEmail = new From_email_based_on_Dept_and_Teams__c();
    CSFromEmail.Name = 'Corporate-Support International';
    CSFromEmail.From_Email__c = 'coporateinternationtest@sas.se';
    insert CSFromEmail;

    List<Case> Cases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      C_RecordTypeHelper.CASE_CHANNEL
    );
    cases[0].origin = 'Email - Pandion DK';
    cases[0].SuppliedFirstname__c = 'Test';
    cases[0].SuppliedLastname__c = 'Testsson';

    insert Cases;

    // Escalate the cases
    cases[0].IsEscalated__c = true;
    cases[0].status = 'Escalated';
    cases[0].Department__c = 'Corporate';
    cases[0].Team__c = 'Support International';
    update cases;

    EmailMessage email = new EmailMessage();
    email.ToAddress = 'coporateinternationtest@sas.se';
    email.ParentId = cases[0].Id;
    insert email;

    //create QuickActionDefaults
    List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
      new Map<String, Object>{
        'targetSObject' => new EmailMessage(),
        'contextId' => cases[0].Id,
        'actionType' => 'Email',
        'actionName' => 'Case.Email',
        'fromAddressList' => new List<String>{ email.ToAddress }
      }
    };

    List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
      JSON.serialize(defaultSettingAsObject),
      List<QuickAction.SendEmailQuickActionDefaults>.class
    );
    Test.startTest();
    (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
    Test.stopTest();

    System.assertEquals(
      CSFromEmail.From_Email__c,
      ((EmailMessage) defaultsSettings[0].getTargetSObject())
        .ValidatedFromAddress
    );
  }
}
