public without sharing class CustomerCardController {
  /**
   * @return a list of all the bookings for the given booking reference.
   */
  @AuraEnabled
  public static List<Booking__c> addBookingToCase(
    ID caseId,
    String bookingReference
  ) {
    if (!Booking.isValidBookingReference(bookingReference)) {
      throw new AuraHandledException(
        'Booking reference should be 5 or 6 characters.'
      );
    }

    Bookings b = BookingService.addBookingToCase(caseId, bookingReference);
    if (b == null) {
      return null;
    }

    return b.instanceRecords;
  }

  @AuraEnabled(cacheable=true)
  public static List<BookingJSON> getBookingsForCase(String caseId) {
    List<Booking__c> bookingsFromDB = BookingsSelector.newInstance()
      .selectByCaseId(new Set<Id>{ caseId });
    List<BookingJSON> toReturn = new List<BookingJSON>();
    Map<String, List<IRR_CommunicationLog__c>> logsByBookingReference = new Map<String, List<IRR_CommunicationLog__c>>();
    Map<String, Booking__c> bookingsByBookingReference = new Map<String, Booking__c>();
    for (Booking__c b : bookingsFromDB) {
      bookingsByBookingReference.put(b.Booking_Reference__c, b);
      logsByBookingReference.put(
        b.Booking_Reference__c,
        new List<IRR_CommunicationLog__c>()
      );
    }

    // Get related logs for bookings
    List<IRR_CommunicationLog__c> logsFromDB = IRR_SEL_CommunicationLogsSelector.newInstance() // TODO: Move this to top of this class.
      .getCommunicationLogsByBookingReference(
        bookingsByBookingReference.keySet()
      );
    for (IRR_CommunicationLog__c log : logsFromDB) {
      List<IRR_CommunicationLog__c> element = logsByBookingReference.get(
        log.IRR_BookingReference__c
      );

      if (element == null) {
        element = new List<IRR_CommunicationLog__c>();
      }

      element.add(log);
      logsByBookingReference.put(log.IRR_BookingReference__c, element);
    }

    // Construct final JSON
    for (String key : bookingsByBookingReference.keySet()) {
      Booking__c b = bookingsByBookingReference.get(key);
      List<Case> relatedCases = CasesSelector.newInstance()
        .selectByBookingReference(new Set<String>{ b.Booking_Reference__c });
      List<IRR_CommunicationLog__c> logs = logsByBookingReference.get(key);

      toReturn.add(new BookingJSON(b, relatedCases, logs));
    }
    toReturn.sort();

    return toReturn;
  }

  @AuraEnabled
  public static void refetchBookingData(String bookingIdentifier) {
    BookingService.fetchBookingByBookingIdentifier(bookingIdentifier);
  }

  @AuraEnabled
  public static void refetchTPProducts(String accountId) {
    TravelPassService.refreshTravelPassAccount(Id.valueOf(accountId));
  }

  @AuraEnabled
  public static void removeBookingFromCase(ID caseId, String pnr) {
    BookingService.removeBookingFromCase(caseId, pnr);
  }

  @AuraEnabled
  public static void removeBookingFromCaseIdentifier(
    ID caseId,
    String bookingIdentifier
  ) {
    BookingService.removeBookingFromCaseIdentifier(caseId, bookingIdentifier);
  }

  @AuraEnabled(cacheable=true)
  public static List<Account> getAccountData(String accountId) {
    return AccountsSelector.newInstance().selectById(new Set<Id>{ accountId });
  }

  @AuraEnabled(cacheable=true)
  public static List<BookingJSON> getBookingData(String accountId) {
    List<Booking__c> bookingsForCustomer = BookingsSelector.newInstance()
      .selectByAccountId(new Set<Id>{ accountId });
    List<BookingJSON> toReturn = new List<BookingJSON>();
    for (Booking__c b : bookingsForCustomer) {
      toReturn.add(
        new BookingJSON(
          b,
          new List<Case>(),
          new List<IRR_CommunicationLog__c>()
        )
      );
    }
    toReturn.sort();

    return toReturn;
  }

  @AuraEnabled(cacheable=true)
  public static List<Travel_Pass_Product__c> getTPProductsForAccount(
    String accountId
  ) {
    return TravelPassProductsSelector.newInstance()
      .selectByAccountId(new Set<Id>{ accountId });
  }

  @AuraEnabled(cacheable=true)
  public static List<Case> getCaseData(String accountId) {
    return CasesSelector.newInstance()
      .selectByAccountId(new Set<Id>{ accountId });
  }

  @AuraEnabled(cacheable=true)
  public static List<BookingJSON.CommunicationLog> getAllCommunicationData(
    String euroBonusNumber
  ) {
    List<IRR_CommunicationLog__c> logs = IRR_SEL_CommunicationLogsSelector.newInstance()
      .getCommunicationLogsByEBAccount(new Set<String>{ euroBonusNumber });

    List<BookingJSON.CommunicationLog> toReturn = new List<BookingJSON.CommunicationLog>();
    for (IRR_CommunicationLog__c log : logs) {
      toReturn.add(new BookingJSON.CommunicationLog(log));
    }

    return toReturn;
  }
}
