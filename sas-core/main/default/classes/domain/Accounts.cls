public without sharing class Accounts extends ApplicationDomain {
  public Accounts(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Account>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Accounts(records);
    }
  }

  public static Accounts newInstance(List<Account> sObjectList) {
    return (Accounts) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public List<Account> instanceRecords;

  public override void onAfterInsert() {
    if (Records.size() == 1) {
      fetchBookingsFromTEDS();
      fetchTravelPassAccount();
    }
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    if (Records.size() == 1) {
      // If we're updating just one account, refetch bookings if the eb number has changed
      Boolean ebNumberHasChanged =
        existingRecords.size() == 1 &&
        ((Account) existingRecords.values()[0]).FCS_EBNumber__c !=
        ((Account) Records[0]).FCS_EBNumber__c;

      if (ebNumberHasChanged) {
        fetchBookingsFromTEDS();
      }
    }
  }

  /**
   * Given a string, attempts to parse it into a valid EuroBonus number.
   * Drops all whitespace, and picks the first consecutive string of numbers
   * from the input.
   *
   * Valid EuroBonus numbers are 9 digits with no whitespace.
   *
   * @param potentialEBNumber A string to try and parse into a valid EuroBonus number.
   *
   * @throws IncorrectEBNumberException If the given string isn't a valid EuroBonus number.
   */
  public static String parseIntoEuroBonusNumber(String potentialEBNumber) {
    String toReturn;
    if (!String.isBlank(potentialEBNumber)) {
      String ebNumberWithoutWhitespace = StringUtils.removeWhitespace(
        potentialEBNumber
      );
      Pattern onlyNumbersPattern = Pattern.compile('([0-9]+)');
      Matcher matcher = onlyNumbersPattern.matcher(ebNumberWithoutWhitespace);
      try {
        Boolean matches = matcher.find();
        toReturn = matcher.group();
      } catch (Exception e) {
        throw new IncorrectEBNumberException();
      }
    }

    if (String.isBlank(toReturn) || toReturn.length() != 9) {
      throw new IncorrectEBNumberException();
    }

    return toReturn;
  }

  public class IncorrectEBNumberException extends Exception {
  }

  private void fetchBookingsFromTEDS() {
    Account acc = instanceRecords[0];
    if (
      acc.FCS_EBNumber__c != null &&
      !System.isFuture() &&
      !System.isBatch() &&
      !System.isQueueable()
    ) {
      // Guard against nesting futures. FIXME: update logic so that this isn't needed
      // TODO: This should work fine now. Check.
      System.enqueueJob(
        new BookingService.FetchBookingsByEBNumberAsync(acc.FCS_EBNumber__c)
      );
    }
  }

  private void fetchTravelPassAccount() {
    Account acc = instanceRecords[0];
    if (
      acc.FCS_TPAccountNumber__c != null &&
      acc.FCS_CMP__c != null &&
      !System.isFuture() &&
      !System.isBatch() &&
      !System.isQueueable()
    ) {
      // Guard against nesting futures. FIXME: update logic so that this isn't needed
      TravelPassService.fetchTravelPassAccount(
        acc.FCS_TPAccountNumber__c,
        acc.Id
      );
    }
  }
}
