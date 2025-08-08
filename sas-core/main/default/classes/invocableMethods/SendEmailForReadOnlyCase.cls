public with sharing class SendEmailForReadOnlyCase {
  @InvocableMethod(label='Send template email')
  public static void sendEmail(List<Id> caseIds) {
    List<Case> allCases = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseIds[0] });

    String splitEmailAddress = allCases[0].SuppliedEmail.substringBefore('@');

    List<EmailServicesAddress> emailServiceAddress = [
      SELECT Id, LocalPart
      FROM EmailServicesAddress
      WHERE LocalPart = :splitEmailAddress
    ];

    if (!emailServiceAddress.isEmpty()) {
      return;
    }

    String closedCasePermanentlyTemplate = Cases.allReadOnlyConfigs.get(
      allCases[0].Department__c
    ).Email_Template_Name__c;
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Messaging.SingleEmailMessage msg = EmailMessages.createSingleEmailMessageFromTemplate(
      closedCasePermanentlyTemplate,
      caseIds[0]
    );
    msg.SetReplyTo('no-reply@flysas.com');
    Cases.newInstance(allCases).emailOwner(msg, uow);

    uow.commitWork();
  }
}
