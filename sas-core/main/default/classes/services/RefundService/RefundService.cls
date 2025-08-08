public without sharing class RefundService {
  public class RefundException extends Exception {
  }

  public static String createRefund(CreateRefundRequest request) {
    try {
      Refund_Request__c refund = createRefundRecord(request);
      insert refund;

      Case newCase = createCaseRecord(request, refund.id);

      // Auto-response emails are not triggered by default for cases created
      // through Apex. Setting the triggerAutoResponseEmail header forces
      // them to be sent.
      Database.DMLOptions dmlOptions = new Database.DMLOptions();
      dmlOptions.EmailHeader.triggerAutoResponseEmail = true;

      database.insert(newCase, dmlOptions);

      Case insertedCase = CasesSelector.newInstance().selectById(new Set<Id>{ newCase.Id })[0];

      Map<Id, SObject> fileIdsToObjects = new Map<Id, SObject>();
      for (Id contentId : request.filesToLink) {
        fileIdsToObjects.put(contentId, refund);
      }
      insert constructContentLinks(fileIdsToObjects, insertedCase.id);

      return insertedCase.CaseNumber;
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() + ': ' + e.getMessage(),
        e.getStackTraceString(),
        'CaseFormV2 - Refund',
        null
      );
      throw new RefundException();
    }
  }

  private static Refund_Request__c createRefundRecord(CreateRefundRequest request) {
    Refund_Request__c refund = new Refund_Request__c(
      First_Name__c = request.contact.firstName,
      Last_Name__c = request.contact.lastName,
      Email__c = request.contact.email,
      Phone__c = request.contact.phone != null ? request.contact.phone : '',
      PNR__c = request.refund.bookingReference,
      Note__c = request.refund.notes,
      Cancel_Entire_Booking__c = request.refund.cancelEntireBooking != null ? request.refund.cancelEntireBooking.capitalize() : '',
      Cancel_All_Passengers__c = request.refund.cancelAllPassengers != null ? request.refund.cancelAllPassengers.capitalize() : '',
      Cancel_Direction__c = request.refund.cancelDirection != null ? request.refund.cancelDirection : '',
      Ticket_Numbers__c = request.refund.ticketNumber != null ? request.refund.ticketNumber : '',
      Country_of_Purchase__c = request.refund.countryOfPurchase != null ? request.refund.countryOfPurchase : ''
    );

    if (request.refund.refundType == 'travel-agent') {
      refund.Request_Type__c = 'Travel Agent Tickets';
      refund.Request_Type_Sub_Category__c = 'Webform Request';
      refund.Refund_Not_Claimed_Elsewhere__c = true;
    }

    return refund;
  }

  private static Case createCaseRecord(CreateRefundRequest request, Id refundId) {
    String subject = '';

    switch on request.refund.refundType {
      when 'death-certificate' {
        subject = 'Waiver request due to death in family, PNR: ' + request.refund.bookingReference;
      }
      when 'mmb' {
        subject = 'Refund Customer Webform, ' + request.market.replace('-', ' ').toUpperCase() + ' PNR: ' + request.refund.bookingReference;
      }
      when 'travel-agent' {
        subject = 'Refund Travel Agent Webform, ' + request.market.replace('-', ' ').toUpperCase() + ' PNR: ' + request.refund.bookingReference;
      }
      when 'visa-rejection' {
        subject = 'Waiver request due to visa rejection, PNR: ' + request.refund.bookingReference;
      }
    }

    Id refundsQueueId = GroupsSelector.newInstance()
      .selectQueuesByDepartment(new Set<String>{ 'Refunds' })[0].Id;

    Case newCase = new Case(
      OwnerId = refundsQueueId,
      Initially_Provided_PNR__c = request.refund.bookingReference,
      SuppliedEmail = request.contact.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
      Origin = request.origin,
      Subject = subject,
      Refund_Request__c = refundId,
      SuppliedName = request.contact.firstName + ' ' + request.contact.lastName,
      SuppliedFirstname__c = request.contact.firstName,
      SuppliedLastname__c = request.contact.lastName,
      Refund_Notes__c = request.refund.notes
    );

    return newCase;
  }

  private static List<ContentDocumentLink> constructContentLinks(Map<Id, SObject> fileIdsToObjects, Id caseId) {
    List<ContentDocumentLink> listOfFiles = new List<ContentDocumentLink>();
    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance().selectById(fileIdsToObjects.keySet());

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
}
