/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Class for overriding the default QuickAction when writing Emails
 */
global class FCS_EmailPublisherAction implements QuickAction.QuickActionDefaultsHandler {
  // Empty constructor
  global FCS_EmailPublisherAction() {
  }

  // The main interface method
  global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
    //Set different values to enable Apex tests for when using default email quick action
    String actionName = Test.isRunningTest() ? 'Case.Email' : 'Case.SendEmail';
    String actionType = Test.isRunningTest() ? 'Email' : 'SendEmail';

    QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
    // Check if the quick action is the standard Case Feed send email action
    for (QuickAction.QuickActionDefaults action : defaults) {
      if (
        action instanceof QuickAction.SendEmailQuickActionDefaults &&
        action.getTargetSObject().getSObjectType() ==
        EmailMessage.sObjectType &&
        action.getActionName().equals(actionName) &&
        action.getActionType().equals(actionType)
      ) {
        sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) action;
        break;
      }
    }

    if (sendEmailDefaults != null) {
      Case cse = [
        SELECT
          CaseNumber,
          Type,
          Department__c,
          Team__c,
          IsRedirected__c,
          IsEscalated__c,
          Origin
        FROM Case
        WHERE Id = :sendEmailDefaults.getContextId()
      ];
      EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
      if (
        cse != null &&
        (cse.IsRedirected__c ||
        cse.IsEscalated__c ||
        cse.Origin?.startsWith('Manual') ||
        cse.Origin == 'Internal - New Refund Request Form' ||
        cse.Origin?.contains('Form - ')) &&
        (cse.Department__c != null &&
        cse.Team__c != null)
      ) {
        String lstFromEMails = From_email_based_on_Dept_and_Teams__c.getValues(
            cse.Department__c.substringBefore(' ') +
            '-' +
            cse.Team__c
          )
          ?.From_Email__c;
        if (!String.isEmpty(lstFromEMails) && lstFromEMails != null) {
          emailMessage.ValidatedFromAddress = lstFromEMails;
        } else {
          emailMessage.ValidatedFromAddress = From_email_based_on_Dept_and_Teams__c.getValues(
              'Default From Address'
            )
            ?.From_Email__c;
        }
      }
    }
  }
}
