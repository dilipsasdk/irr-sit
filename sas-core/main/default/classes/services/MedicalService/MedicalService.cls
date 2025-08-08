public without sharing class MedicalService {
  public class MedicalException extends Exception {
  }

  private static final List<String> SOS_MEDICAL_EMAILS = C_Util.isSandbox()
    ? new List<String>{
        'vedran.sola@sas.se',
        'michael.uvnaes@sas.se'
      }
    : new List<String>{ 'medaut@sos.eu' };

  public static String sendMedicalEmail(CreateMedicalRequest request) {
    switch on request.medical.medicalType {
      when 'medical-approval' {
        sendMedicalApprovalEmail(request);
      }
      when 'oxygen-registration' {
        sendOxygenRegistrationEmail(request);
      }
    }

    return '1';
  }

  private static void sendMedicalApprovalEmail(CreateMedicalRequest request) {
    Case newCase = createCaseRecord(request);

    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.EmailHeader.triggerAutoResponseEmail = true;
    database.insert(newCase, dmlOptions);

    Case insertedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ newCase.Id })[0];

    Map<Id, SObject> fileIdsToObjects = new Map<Id, SObject>();
    for (Id contentId : request.medical.contentVersionIds) {
      fileIdsToObjects.put(contentId, insertedCase);
    }

    List<ContentDocumentLink> files = constructContentLinks(
      fileIdsToObjects,
      insertedCase.Id
    );

    sendMedicalApprovalEmailToSos(files[0].ContentDocumentId, request);
    delete insertedCase;
  }

  private static void sendMedicalApprovalEmailToSos(
    Id documentId,
    CreateMedicalRequest request
  ) {
    List<String> body = new List<String>();
    body.add('PNR: ' + request.medical.bookingReference);
    body.add('email: ' + request.medical.email);

    sendEmail(
      SOS_MEDICAL_EMAILS,
      string.join(body, '<br>'),
      'SAS Medical',
      documentId
    );
  }

  private static void sendOxygenRegistrationEmail(
    CreateMedicalRequest request
  ) {
    CaseFormJSONV2.ContactDetails contactDetails = request.medical.contactDetails;
    CaseFormJSONV2.EquipmentDetails equipmentDetails = request.medical.equipmentDetails;

    sendOxygenRegistrationEmailToSos(request, contactDetails, equipmentDetails);
    sendOxygenRegistrationEmailToCustomer(
      request,
      contactDetails,
      equipmentDetails
    );
  }

  private static void sendOxygenRegistrationEmailToSos(
    CreateMedicalRequest request,
    CaseFormJSONV2.ContactDetails contactDetails,
    CaseFormJSONV2.EquipmentDetails equipmentDetails
  ) {
    String body = constructBody(request, contactDetails, equipmentDetails);

    sendEmail(
      SOS_MEDICAL_EMAILS,
      body,
      'New oxygen registration',
      null
    );
  }

  private static void sendOxygenRegistrationEmailToCustomer(
    CreateMedicalRequest request,
    CaseFormJSONV2.ContactDetails contactDetails,
    CaseFormJSONV2.EquipmentDetails equipmentDetails
  ) {
    List<String> topBody = new List<String>();
    topBody.add(
      'Thank you for your request. We will contact you as soon as possible, usually within 1 working day.' +
      '<br>'
    );
    topBody.add('Here is a summary of your request.' + '<br>');

    String mainBody = constructBody(request, contactDetails, equipmentDetails);

    List<String> body = new List<String>();
    body.add(string.join(topBody, '<br>'));
    body.add(mainBody);

    sendEmail(
      new List<String>{ contactDetails.email },
      string.join(body, '<br>'),
      'Your oxygen registration was received',
      null
    );
  }

  private static String constructBody(
    CreateMedicalRequest request,
    CaseFormJSONV2.ContactDetails contactDetails,
    CaseFormJSONV2.EquipmentDetails equipmentDetails
  ) {
    List<String> body = new List<String>();
    body.add('PNR: ' + request.medical.bookingReference + '<br>');
    body.add('Contact Details: ');
    body.add('First name: ' + contactDetails.firstName);
    body.add('Last name: ' + contactDetails.lastName);
    body.add('E-mail: ' + contactDetails.email);
    body.add('Phone: ' + contactDetails.phone + '<br>');
    body.add('Equipment Details: ');
    body.add('Model/name of oxygen concentrator: ' + equipmentDetails.model);
    body.add('Number of oxygen tanks: ' + equipmentDetails.amount);
    body.add(
      'Equipment is battery powered: ' +
      (equipmentDetails.isBatteryPowerSupply ? 'Yes' : 'No')
    );

    return string.join(body, '<br>');
  }

  private static void sendEmail(
    List<String> toAddresses,
    String body,
    String subject,
    Id documentId
  ) {
    Id organisationWideEmailId = OrgWideEmailAddressesSelector.newInstance()
      .selectByAddress(new Set<String>{ 'no-reply@flysas.com' })[0].Id;

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(toAddresses);
    mail.setOrgWideEmailAddressId(organisationWideEmailId);
    mail.setSubject(subject);
    mail.setBccSender(false);
    mail.setHtmlBody(body);
    mail.setPlainTextBody(body);
    mail.setSaveAsActivity(false);

    if (documentId != null) {
      mail.setFileAttachments(
        new List<Messaging.EmailFileAttachment>{ createAttachment(documentId) }
      );
    }

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
  }

  private static Case createCaseRecord(CreateMedicalRequest request) {
    Id vendorManagementQueueId = GroupsSelector.newInstance()
      .selectQueuesByDepartment(new Set<String>{ 'Vendor_Management' })[0].Id;

    Case newCase = new Case(
      OwnerId = vendorManagementQueueId,
      Origin = 'Form - Medical Approval EN',
      SuppliedEmail = request.medical.email,
      FCS_PNR__c = request.medical.bookingReference,
      Initially_Provided_PNR__c = request.medical.bookingReference,
      Subject = 'Medical Approval EN',
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel)
    );

    return newCase;
  }

  private static List<ContentDocumentLink> constructContentLinks(
    Map<Id, SObject> fileIdsToObjects,
    Id caseId
  ) {
    List<ContentDocumentLink> listOfFiles = new List<ContentDocumentLink>();
    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(fileIdsToObjects.keySet());

    for (ContentVersion content : contentToLink) {
      listOfFiles.add(
        new ContentDocumentLink(
          ContentDocumentId = content.ContentDocumentId,
          LinkedEntityId = caseId
        )
      );
    }

    return listOfFiles;
  }

  private static Messaging.EmailFileAttachment createAttachment(
    Id documentId
  ) {
    ContentVersion contentVersion = ContentVersionsSelector.newInstance()
      .selectByContentDocumentId(documentId)[0];

    Blob fileData = contentVersion.VersionData;
    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFilename(contentVersion.Title);
    attachment.setBody(fileData);

    return attachment;
  }
}
