@IsTest
public with sharing class FlightDelayCertificates_IntegrationTest {
  @IsTest
  public static void incomingRequestShouldCreateCaseAndQueueableJob() {
    CaseFormJSONV2 requestBody = CaseFormJSONV2.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "delay-certificate",' +
      '    "contact": {' +
      '      "firstName": "Test",' +
      '      "lastName": "Testsson",' +
      '      "email": "test@example.com"' +
      '    },' +
      '    "claim": {' +
      '      "bookingReference": "DELAY1",' +
      '      "departureDate": "2022-03-02",' +
      '      "flightNumber": "SK0903"' +
      '    }' +
      '  },' +
      '  "metaData": {' +
      '    "market": "en-us"' +
      '  }' +
      '}'
    );

    // Create email templates to use for testing
    // Handling the requests requires certain templates to be present
    // and we ideally do not want these to be stored in version control
    // Runs as thisUser to avoid mixed DML Operation errors
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      BrandTemplate bt = [
        SELECT Id
        FROM BrandTemplate
        WHERE DeveloperName = 'SAS_Logo'
      ];

      EmailTemplate et1 = new EmailTemplate(
        Subject = 'Test',
        HtmlValue = '<html>test</html>',
        Body = 'test',
        Name = 'bookingExists',
        DeveloperName = 'test1',
        BrandTemplateId = bt.Id,
        TemplateStyle = 'freeForm',
        TemplateType = 'html',
        FolderId = UserInfo.getUserId()
      );
      EmailTemplate et2 = new EmailTemplate(
        Subject = 'Test',
        HtmlValue = '<html>test</html>',
        Body = 'test',
        Name = 'bookingDoesNotExist',
        DeveloperName = 'test2',
        BrandTemplateId = bt.Id,
        TemplateStyle = 'freeForm',
        TemplateType = 'html',
        FolderId = UserInfo.getUserId()
      );
      insert new List<EmailTemplate>{ et1, et2 };
    }
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    CaseFormV2.createCase(requestBody);
    Test.stopTest();
    String insertedEmailAddress = 'test@example.com';
    Case c = [
      SELECT Id, Flight_Number__c
      FROM Case
      WHERE SuppliedEmail = :insertedEmailAddress
    ];
    String statusToCheck = 'delayed';

    List<AsyncApexJob> aaj = [
      SELECT Id
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];
    System.assertNotEquals(
      null,
      c,
      'Case should have been created for this request'
    );
    System.assertEquals(
      'SK0903',
      c.Flight_Number__c,
      'Case data should match form data'
    );
    System.assertNotEquals(
      0,
      aaj.size(),
      'Should have created a queueable apex job'
    );
  }

  @IsTest
  public static void createdAttachmentShouldHaveCorrectFileNameAndContentType() {
    Case c = new Case(Flight_Number__c = 'SK0903');
    Flight__c flight1 = new Flight__c(
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'ontime'
    );
    Flight__c flight2 = new Flight__c(
      Operating_Carrier__c = 'AY',
      TEDS_Identifier__c = 'AY1',
      Arrival_Status__c = 'ontime',
      Departure_Status__c = 'ontime'
    );
    Booking__c booking = new Booking__c(
      Booking_Reference__c = 'ABC123',
      TEDS_Identifier__c = 'ABC123'
    );
    insert new List<SObject>{ c, booking, flight1, flight2 };

    Segment__c seg1 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = booking.Id,
      Flight__c = flight2.Id
    );

    Flight_Delay_Certificate_Request__c req = new Flight_Delay_Certificate_Request__c(
      Booking_Reference__c = 'ABC123',
      Contact_First_Name__c = 'Test',
      Contact_Last_Name__c = 'Testsson',
      Flight_Number__c = 'SK1234',
      Case__c = c.Id
    );
    insert new List<SObject>{ seg1, seg2, req };
    Booking__c bookingToTest = [
      SELECT Id, Booking_Reference__c, (SELECT Id, Flight__c FROM Segments__r)
      FROM Booking__c
      WHERE Id = :booking.Id
    ];

    FlightDelayCertificateRequests requests = FlightDelayCertificateRequests.newInstance(
      FlightDelayCertificateRequestsSelector.newInstance()
        .selectByIdFull(new Set<Id>{ req.Id })
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Blob pdf = requests.generateFlightDelayCertificate(bookingToTest.Id);
    Messaging.EmailFileAttachment createdAttachment = EmailMessages.createEmailAttachmentFromBlob(
      pdf,
      requests.instanceRecords[0].Contact_Full_Name__c +
      '_' +
      requests.instanceRecords[0].Booking_Reference__c,
      'application/pdf'
    );
    Test.stopTest();
    System.assertEquals(
      'Test Testsson_ABC123',
      createdAttachment.getFilename(),
      'Filename should be [passengerName].pdf'
    );
    System.assertEquals(
      'application/pdf',
      createdAttachment.getContentType(),
      'Content-Type for the created attachment should be application/pdf'
    );
  }
}
