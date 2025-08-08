@IsTest
public with sharing class TestDataFactories {
  /**
   * Create test bookings. Inserts all objects into DB.
   */
  public static List<Booking__c> createBookings(
    Integer amount,
    String bookingReference
  ) {
    List<Booking__c> newBookings = new List<Booking__c>();
    List<SObject> toInsert = new List<SObject>();

    Flight__c f = new Flight__c(TEDS_Identifier__c = C_Util.generateUUID());
    insert f;

    for (Integer i = 0; i < amount; i++) {
      Booking__c b = new Booking__c(
        Booking_Reference__c = bookingReference,
        TEDS_Identifier__c = bookingReference + String.valueOf(i)
      );
      newBookings.add(b);
    }
    insert newBookings;

    for (Integer i = 0; i < amount; i++) {
      Segment__c s = new Segment__c(
        Flight__c = f.Id,
        Booking__c = newBookings[i].Id,
        Identifier__c = String.valueOf(i)
      );
      toInsert.add(s);

      Passenger__c p = new Passenger__c(
        Booking__c = newBookings[i].Id,
        Identifier__c = String.valueOf(i)
      );
      toInsert.add(p);
    }
    insert toInsert;

    return newBookings;
  }

  public static List<IRR_MOD_TedsBooking> createParsedBookingData(
    String bookingReference,
    String euroBonusNumber
  ) {
    String ebNumber = '1234567890';
    if (euroBonusNumber != null) {
      ebNumber = euroBonusNumber;
    }

    String template = '{"id": "VKQLKR-20201126","reference": "{bookingReference}","type": "RoundTrip","isCancelled": false,"codsId": "000364992","travelAdmin": {"codsId": ""},"audit": {"created": {"officeId": "STOSK08RV","at": "2020-11-26T04:15:00Z"},"updated": {"officeId": "NCESK0553","at": "2021-02-19T22:25:00Z"}},"passengers": [{"id": "PT2","title": "MR","firstName": "GUSTAF","lastName": "DOUGLAS","contact": {"phone": [{"type": "APH","number": "+33492943368"},{"type": "APM","number": "+33492943368"},{"type": "APU","number": "+33492943368"},{"type": "APH","number": "+3312345879"},{"type": "APM","number": "+334647681157"},{"type": "APU","number": "+33123456897"}],"email": [{"type": "APE","address": "NO-REPLY_RECEIPT@AMADEUS.COM"},{"type": "APE","address": "NO-REPLY@AMADEUS.COM"}]},"frequentTraveler": {"euroBonus": [{"segmentIds": [],"carrier": "SK","tier": "EBB","number": "{euroBonusNumber}"}],"other": []},"specialServiceRequests": [],"segments": [{"segmentId": "ST1","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "OSERSM"}},{"segmentId": "ST2","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "TSERSM"}}]}],"trips": [{"type": "Outbound","segments": [{"id": "ST1","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK2569-20210410-ARN-CPH","operatingId": "SK2569-20210410-ARN-CPH","operatingCarrier": "SK","operatingFlightNumber": "2569","marketingCarrier": "SK","marketingFlightNumber": "2569","departure": {"station": "ARN","scheduledTime": {"utc": "2021-04-10T07:00:00Z","local": "2021-04-10T09:00:00"},"terminal": "5"},"arrival": {"station": "CPH","scheduledTime": {"utc": "2021-04-10T08:20:00Z","local": "2021-04-10T10:20:00"},"terminal": "3"}},"bookingClass": "O","serviceClass": "M"}]},{"type": "Inbound","segments": [{"id": "ST2","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK0402-20210420-CPH-ARN","operatingId": "SK0402-20210420-CPH-ARN","operatingCarrier": "SK","operatingFlightNumber": "0402","marketingCarrier": "SK","marketingFlightNumber": "0402","departure": {"station": "CPH","scheduledTime": {"utc": "2021-04-20T05:15:00Z","local": "2021-04-20T07:15:00"},"terminal": "3"},"arrival": {"station": "ARN","scheduledTime": {"utc": "2021-04-20T06:30:00Z","local": "2021-04-20T08:30:00"},"terminal": "5"}},"bookingClass": "T","serviceClass": "M"}]}]}';

    List<IRR_MOD_TedsBooking> toReturn = new List<IRR_MOD_TedsBooking>();
    toReturn.add(
      IRR_MOD_TedsBooking.parse(
        template.replace('{bookingReference}', bookingReference)
          .replace('{euroBonusNumber}', ebNumber)
      )
    );
    return toReturn;
  }

  public class CasesClaims {
    public List<Case> cases { get; set; }
    public List<LIA_Claim__c> claims { get; set; }

    CasesClaims(List<Case> cases, List<LIA_Claim__c> claims) {
      this.cases = cases;
      this.claims = claims;
    }
  }

  /**
   * Creates a collection of case and claim pairs and inserts them to the DB.
   *
   * @param count Number of case-claim pairs to create.
   * @param fieldsForCases Map of field to field value for fields to set for all created cases.
   * @param fieldsForClaims Map of field to field value for fields to set for all created claims.
   */
  public static CasesClaims createCasesWithClaims(
    Integer count,
    Map<Schema.SObjectField, Object> fieldsForCases,
    Map<Schema.SObjectField, Object> fieldsForClaims
  ) {
    List<Case> casesToCreate = new List<Case>();
    List<LIA_Claim__c> claimsToCreate = new List<LIA_Claim__c>();

    for (Integer i = 0; i < count; i++) {
      Case c = new Case(
        Origin = 'Form - Claims SE',
        RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
        Status = Cases.STATUS_NEW,
        SuppliedEmail = 'test@example.com',
        SuppliedFirstname__c = 'Test',
        SuppliedLastname__c = 'Testsson'
      );
      LIA_Claim__c cl = new LIA_Claim__c(
        Customer_Claim_Category__c = 'Flight disruptions',
        Liability_PNR__c = 'ABC123',
        PIR__c = 'ARNSK12345',
        RecordTypeId = Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        )
      );

      if (fieldsForCases != null) {
        for (Schema.SObjectField field : fieldsForCases.keySet()) {
          c.put(field, fieldsForCases.get(field));
        }
      }

      if (fieldsForClaims != null) {
        for (Schema.SObjectField field : fieldsForClaims.keySet()) {
          cl.put(field, fieldsForClaims.get(field));
        }
      }
      casesToCreate.add(c);
      claimsToCreate.add(cl);
    }
    List<SObject> allToCreate = new List<SObject>();
    allToCreate.addAll((List<SObject>) casesToCreate);
    allToCreate.addAll((List<SObject>) claimsToCreate);
    insert allToCreate;

    for (Integer i = 0; i < count; i++) {
      Case c = casesToCreate[i];
      LIA_Claim__c cl = claimsToCreate[i];
      c.LIA_Claim__c = cl.Id;
      cl.Case__c = c.Id;
    }

    update allToCreate;

    return new CasesClaims(casesToCreate, claimsToCreate);
  }

  public enum TemplateType {
    BLANK,
    AUTOMATION_APPROVED,
    AUTOMATION_REJECTED
  }

  public static final Map<TestDataFactories.TemplateType, String> EMAIL_TEMPLATE_TYPE_TO_HTML_VALUE = new Map<TestDataFactories.TemplateType, String>{
    TemplateType.BLANK => '<html>test</html>',
    TemplateType.AUTOMATION_APPROVED => '<html>|||compensationTextPlaceholder|||, |||flightNumber|||, |||departureAirport|||, |||arrivalAirport|||, |||cancellationDate|||, |||flightPlan|||, |||flightDistanceKm|||, |||minutesDelayed|||</html>',
    TemplateType.AUTOMATION_REJECTED => '<html>|||flightPlan|||, |||flightNumber|||, |||flightDistanceKm|||, |||flightDate|||, |||departureAirport|||, |||departureTime|||, |||arrivalAirport|||, |||cancellationDate|||, |||cancellationTime|||, |||cancellationType|||, |||cancellationReason|||, |||daysBetweenInformedAndDeparture|||, |||timeFrame|||, |||monthLimit|||, |||tripDestinationArrivalType|||, |||minutesDelayed|||, |||minutesEarly|||</html>'
  };

  public static void insertEmailTemplates(Set<String> templateNamesToCreate) {
    Map<String, TemplateType> templateNamesToType = new Map<String, Templatetype>();

    for (String name : templateNamesToCreate) {
      templateNamesToType.put(name, TemplateType.BLANK);
    }

    insertEmailTemplates(templateNamesToType);
  }

  public static void insertEmailTemplates(
    Map<String, TemplateType> templateNamesToType
  ) {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      BrandTemplate bt = [
        SELECT Id
        FROM BrandTemplate
        WHERE DeveloperName = 'SAS_Logo'
      ];

      List<EmailTemplate> toInsert = new List<EmailTemplate>();

      List<EmailTemplate> existingTemplates = EmailTemplatesSelector.newInstance()
        .selectByName(templateNamesToType.keySet());
      List<String> existingTemplateNames = new List<String>();
      for (EmailTemplate t : existingTemplates) {
        existingTemplateNames.add(t.Name);
      }

      for (String templateName : templateNamesToType.keySet()) {
        if (!existingTemplateNames.contains(templateName)) {
          String htmlValue = EMAIL_TEMPLATE_TYPE_TO_HTML_VALUE.get(
            templateNamesToType.get(templateName)
          );
          // Insert only templates which don't exist yet.
          EmailTemplate template = new EmailTemplate(
            Subject = 'Test',
            HtmlValue = '<html>test</html>',
            Body = 'test',
            Name = templateName,
            DeveloperName = templateName,
            BrandTemplateId = bt.Id,
            TemplateStyle = 'freeForm',
            TemplateType = 'html',
            FolderId = UserInfo.getUserId()
          );
          toInsert.add(template);
        }
      }

      insert toInsert;
    }
  }
}
