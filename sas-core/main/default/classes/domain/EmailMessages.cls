public without sharing class EmailMessages extends ApplicationDomain {
  public EmailMessages(List<SObject> records) {
    super(records);
  }

  public static final String STATUS_NEW = '0';
  public static final String STATUS_READ = '1';
  public static final String STATUS_REPLIED = '2';
  public static final String STATUS_SENT = '3';
  public static final String STATUS_FORWARDED = '4';
  public static final String STATUS_DRAFT = '5';

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new EmailMessages(records);
    }
  }
  /**
   * Stores value for how long an EmailMessage HTML body can be on incoming messages before it's truncated
   */
  @TestVisible
  private static final Integer ACCEPTED_HTML_LENGTH = Test.isRunningTest()
    ? 10
    : 100000;

  /**
   * Message placed in bottom of email HTML body when truncated
   */
  @TestVisible
  private static final String TRUNCATION_MESSAGE =
    '<p style="background-color: #ff0000"><b>----- Email truncated due to character limit exceeded. ' +
    'For full history, see the email feed on the case. -----</b></p>';

  public class EmailTemplateNameException extends Exception {
  }

  /**
   * Used to call the trigger in the before insert context
   */
  public override void onBeforeInsert() {
    handleEmailHTMLBodyLength();
  }

  /**
   * Truncates incoming email if the HTML body exceeds the accepted length, and removes
   * truncation message on outgoing emails.
   */
  private void handleEmailHTMLBodyLength() {
    for (EmailMessage msg : (List<EmailMessage>) Records) {
      if (msg.Incoming && msg.HtmlBody != null) {
        Integer bodyLength = msg.HtmlBody.length();
        if (bodyLength > ACCEPTED_HTML_LENGTH) {
          msg.HtmlBody = msg.HtmlBody.substring(0, ACCEPTED_HTML_LENGTH);
          msg.HtmlBody = TRUNCATION_MESSAGE + msg.HtmlBody;
        }
      } else if (!msg.Incoming && msg.HtmlBody != null) {
        msg.HtmlBody = msg.HtmlBody.remove(TRUNCATION_MESSAGE);
      }
    }
  }

  public static Messaging.EmailFileAttachment createEmailAttachmentFromBlob(
    Blob content,
    String fileName,
    String contentType
  ) {
    Messaging.EmailFileAttachment newAttachment = new Messaging.EmailFileAttachment();
    newAttachment.setContentType(contentType);
    newAttachment.setFileName(fileName);
    newAttachment.setInline(false);
    newAttachment.setBody(content);
    return newAttachment;
  }

  /**
   * Create an EmailMessage record from a template with the given name.
   *
   * The created email can be inserted and stored to be sent later.
   *
   * @param templateName Name of the email template. There must exist only one template with this name.
   * @param parentCaseId The case to which this email is linked to.
   * @throws EmailTemplateNameException if no templates are found with the name, or if more than one template is found.
   */
  public static EmailMessage createEmailMessageFromTemplate(
    String templateName,
    Id parentCaseId
  ) {
    List<EmailTemplate> templates = EmailTemplatesSelector.newInstance()
      .selectByName(new Set<String>{ templateName });

    if (templates.size() != 1) {
      throw new EmailTemplateNameException();
    }

    return new EmailMessage(
      HtmlBody = templates[0].HtmlValue,
      ParentId = parentCaseId,
      Subject = templates[0].Subject +
        ' ' +
        System.EmailMessages.getFormattedThreadingToken(parentCaseId),
      TextBody = templates[0].Body,
      Status = STATUS_DRAFT
    );
  }

  /**
   * Create a Messaging.SingleEmailMessage from a template with the given name.
   *
   * The created email will be queued for sending immediately after it is
   * inserted.
   *
   * @param templateName Name of the email template. There must exist only one template with this name.
   * @param parentCaseId The case to which this email is linked to.
   * @throws EmailTemplateNameException if no templates are found with the name, or if more than one template is found.
   */
  public static Messaging.SingleEmailMessage createSingleEmailMessageFromTemplate(
    String templateName,
    Id parentCaseId
  ) {
    List<EmailTemplate> templates = EmailTemplatesSelector.newInstance()
      .selectByName(new Set<String>{ templateName });

    if (templates.size() != 1) {
      throw new EmailTemplateNameException(templateName);
    }

    EmailTemplate emailTemplate = templates[0];
    // Set whoId to null to not prepopulate the recipients
    Messaging.SingleEmailMessage emailToSend = Messaging.renderStoredEmailTemplate(
      emailTemplate.Id,
      null,
      parentCaseId
    );
    emailToSend.setSubject(
      emailToSend.getSubject() +
        ' ' +
        System.EmailMessages.getFormattedThreadingToken(parentCaseId)
    );

    String messageId = System.Cases.generateThreadingMessageId(parentCaseId);
    emailToSend.setReferences(messageId);

    return emailToSend;
  }

  public static Messaging.SingleEmailMessage createSingleEmailMessageFromEmailMessage(
    EmailMessage sourceEmail
  ) {
    Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
    singleEmailMessage.setSenderDisplayName(sourceEmail.FromAddress);

    singleEmailMessage.setToAddresses(sourceEmail.ToAddress.split(';'));
    singleEmailMessage.setReplyTo(sourceEmail.FromAddress);

    if (sourceEmail.CcAddress != null) {
      singleEmailMessage.setCcAddresses(sourceEmail.CcAddress.split(';'));
    }
    if (sourceEmail.BccAddress != null) {
      singleEmailMessage.setBccAddresses(sourceEmail.BccAddress.split(';'));
    }

    singleEmailMessage.setSubject(sourceEmail.Subject);
    singleEmailMessage.setHtmlBody(sourceEmail.HtmlBody);
    singleEmailMessage.setPlainTextBody(sourceEmail.TextBody);
    singleEmailMessage.setSaveAsActivity(true);

    return singleEmailMessage;
  }
}
