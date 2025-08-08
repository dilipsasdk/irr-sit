/**
 * @author Anton Norell
 * @date 2020-04-07
 * @description Test class for Email Message trigger handler.
 */
@IsTest
private class EmailMessages_Test {
  /**
   * Asserts that an incoming email message exceeding the HTML character limit is truncated, and that
   * a string is inserted at the end of the email.
   */
  @IsTest
  static void shouldTruncateIncomingEmail() {
    Case[] c = FCS_TestDataFactory.createCases(1, null, null, null);
    insert c;

    insert new EmailMessage(
      HtmlBody = 'SSSSSSSSSSS',
      ToAddress = 'test@sas.se',
      TextBody = '',
      Incoming = true,
      ParentId = c[0].Id
    );

    EmailMessage message = [
      SELECT Id, HtmlBody, TextBody, Incoming
      FROM EmailMessage
      LIMIT 1
    ];
    System.assert(message.HtmlBody.contains(EmailMessages.TRUNCATION_MESSAGE));
    System.assertEquals(
      10 + EmailMessages.TRUNCATION_MESSAGE.length(),
      message.HtmlBody.length()
    );
  }

  /**
   * Asserts that the message inserted into a truncated, incoming email is removed from outgoing emails.
   */
  @IsTest
  static void shouldRemoveTruncationMessageFromOutgoingEmail() {
    Case[] c = FCS_TestDataFactory.createCases(1, null, null, null);
    insert c;

    insert new EmailMessage(
      HtmlBody = 'S' + EmailMessages.TRUNCATION_MESSAGE,
      ToAddress = 'test@sas.se',
      TextBody = '',
      Incoming = false,
      ParentId = c[0].Id
    );

    System.assertEquals(
      'S',
      [SELECT Id, HtmlBody, TextBody, Incoming FROM EmailMessage LIMIT 1]
      .HtmlBody
    );
  }

  @IsTest
  public static void createdSingleEmailShouldHaveABodyButNoRecipients() {
    String testTemplateName = 'createEmailFromTemplateApexTest';
    Case[] c = FCS_TestDataFactory.createCases(1, null, null, null);
    insert c;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      BrandTemplate bt = [
        SELECT Id
        FROM BrandTemplate
        WHERE DeveloperName = 'SAS_Logo'
      ];
      EmailTemplate et = new EmailTemplate(
        Subject = 'Test',
        HtmlValue = '<html>test</html>',
        Body = 'test',
        BrandTemplateId = bt.Id,
        Name = testTemplateName,
        DeveloperName = 'createEmailFromTemplateApexTest1',
        TemplateStyle = 'freeForm',
        TemplateType = 'html',
        FolderId = UserInfo.getUserId()
      );
      insert et;
    }
    Messaging.SingleEmailMessage newEmail = EmailMessages.createSingleEmailMessageFromTemplate(
      testTemplateName,
      c[0].Id
    );
    System.assertEquals(
      'test',
      newEmail.getPlainTextBody(),
      'Email body should match template body'
    );
    System.assertEquals(
      null,
      newEmail.getToAddresses(),
      'Created Email should not have a recipient'
    );
  }
}
