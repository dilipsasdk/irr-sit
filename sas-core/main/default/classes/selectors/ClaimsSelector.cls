public inherited sharing class ClaimsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      LIA_Claim__c.Id,
      LIA_Claim__c.Name,
      LIA_Claim__c.CreatedDate,
      LIA_Claim__c.LastModifiedDate,
      LIA_Claim__c.Address_line_1__c,
      LIA_Claim__c.Address_line_2__c,
      LIA_Claim__c.Bank_Account_Holder_Name__c,
      LIA_Claim__c.Bank_Account_Number__c,
      LIA_Claim__c.Bank_Country__c,
      LIA_Claim__c.Bank_Name__c,
      LIA_Claim__c.BIC_Swift__c,
      LIA_Claim__c.Case__c,
      LIA_Claim__c.City__c,
      LIA_Claim__c.Claim_Firm__c,
      LIA_Claim__c.Comment__c,
      LIA_Claim__c.Company_Code__c,
      LIA_Claim__c.Company_Name__c,
      LIA_Claim__c.Compensation_Card_Number__c,
      LIA_Claim__c.Concerns_a_person_with_reduced_mobility__c,
      LIA_Claim__c.Concerns_an_unaccompanied_minor__c,
      LIA_Claim__c.Contact_Email__c,
      LIA_Claim__c.Contact_First_Name__c,
      LIA_Claim__c.Contact_Last_Name__c,
      LIA_Claim__c.Country__c,
      LIA_Claim__c.Currency__c,
      LIA_Claim__c.Customer_Claim_Category__c,
      LIA_Claim__c.Customer_Claim_Type__c,
      LIA_Claim__c.Customer_s_Reference__c,
      LIA_Claim__c.Delay_Length__c,
      LIA_Claim__c.EU261_Handling_Note__c,
      LIA_Claim__c.EU261_Handling_Status__c,
      LIA_Claim__c.External_Data_Status__c,
      LIA_Claim__c.External_Data_Retrieve_Count__c,
      LIA_Claim__c.Full_Name__c,
      LIA_Claim__c.EuroBonus_Number__c,
      LIA_Claim__c.Flight_Date__c,
      LIA_Claim__c.Flight_Number__c,
      LIA_Claim__c.Liability_PNR__c,
      LIA_Claim__c.Phone_Number__c,
      LIA_Claim__c.PIR__c,
      LIA_Claim__c.Postal_Code__c,
      LIA_Claim__c.Preferred_Compensation_Method__c,
      LIA_Claim__c.Preferred_Reimbursement_Method__c,
      LIA_Claim__c.Purchase_Price__c,
      LIA_Claim__c.Purchase_Currency__c,
      LIA_Claim__c.Purchase_Year__c,
      LIA_Claim__c.RecordTypeId,
      LIA_Claim__c.Submitted_Claim_Expenses_in_SEK__c,
      LIA_Claim__c.Ticket_Number__c,
      LIA_Claim__c.Total_delay_to_final_destination__c,
      LIA_Claim__c.Travel_Agent_Booking_Reference__c,
      LIA_Claim__c.Type_of_Customer__c,
      LIA_Claim__c.Latest_Time_Of_EU261_Automation__c,
      LIA_Claim__c.Samsonite_Reference_Id__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return LIA_Claim__c.SObjectType;
  }

  public static ClaimsSelector newInstance() {
    return (ClaimsSelector) SAS_Service_Application.Selector.newInstance(
      LIA_Claim__c.SObjectType
    );
  }

  public static final String UNHANDLED_EU261_STATUS = 'Unhandled';
  public static final String ONHOLD_EU261_STATUS = 'On Hold';
  public static final String COMPLETED_EXTERNAL_DATA_STATUS = 'Completed';
  public static final String CASE_STATUS_CLOSED = Cases.STATUS_CLOSED;

  public static final Set<String> EU261_CLAIM_TYPES = new Set<String>{
    'Flight cancellation - compensation',
    'Flight delay - compensation',
    'Missed connection - compensation',
    'Flight cancellation - expenses',
    'Flight delay - expenses',
    'Missed connection - expenses'
  };
  public static final String SAS_AUTOMATION_QUEUE_OWNER_NAME = 'SAS Automation Queue';

  public List<LIA_Claim__c> selectById(Set<Id> ids) {
    return (List<LIA_Claim__c>) selectSObjectsById(ids);
  }

  public List<LIA_Claim__c> selectByCaseId(Id caseId) {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition('Case__c = :caseId').toSOQL()
    );
  }

  public List<LIA_Claim__c> selectByIdWithCustomers(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory().setCondition('Id IN :ids');
    new CustomersSelector().addQueryFactorySubselect(claimsQF);
    new ClaimExpensesSelector().addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public class InsufficientFlightInfoException extends Exception {
  }

  public class TooManyMatchesException extends Exception {
  }

  public List<LIA_Claim__c> selectDuplicatesById(Id claimId) {
    LIA_Claim__c claim = selectByIdWithCustomers(new Set<Id>{ claimId })[0];

    // This names-solution is not fantastic. It is oversensitive and is likely to collide on some "Svenssons" or "Smiths".
    Set<String> names = new Set<String>{};

    if (claim.Customers__r != null) {
      for (Customer__c customer : claim.Customers__r) {
        if (!String.isBlank(customer.Name)) {
          names.add(customer.Name);
        }
        if (
          !String.isBlank(customer.First_Name__c) &&
          !String.isBlank(customer.Last_Name__c)
        ) {
          names.add(customer.First_Name__c + ' ' + customer.Last_Name__c);
        }
      }
    }

    String bookingReference = claim.Liability_PNR__c;
    Date flightDate = claim.Flight_Date__c;
    String flightNumber = claim.Flight_Number__c;
    String pirNumber = claim.PIR__c;

    String whereQuery = '';

    whereQuery = buildQuery(
      whereQuery,
      'Liability_PNR__c = :bookingReference',
      !String.isBlank(bookingReference)
    );

    whereQuery = buildQuery(
      whereQuery,
      'PIR__c = :pirNumber',
      !String.isBlank(pirNumber)
    );

    if (String.isBlank(flightNumber) == null || flightDate == null) {
      throw new InsufficientFlightInfoException(
        'Claim does not have sufficient information about the flight.'
      );
    }

    // Passenger name and flightId matches
    // Can this be done in one query? Would require two subqueries and comparing one list against another.
    List<Customer__c> allCustomersWithSameNames = CustomersSelector.newInstance()
      .selectByName(names);
    List<Id> claimsWithPassengersWithSameNames = new List<Id>{};
    for (Customer__c c : allCustomersWithSameNames) {
      claimsWithPassengersWithSameNames.add(c.Claim__c);
    }

    whereQuery = buildQuery(
      whereQuery,
      '((Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate) AND (Id IN :claimsWithPassengersWithSameNames))',
      true
    );

    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );
  }

  public List<LIA_Claim__c> selectByBookingReference(
    Set<String> bookingReferences
  ) {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition('Liability_PNR__c IN :bookingReferences')
        .toSOQL()
    );
  }

  public List<LIA_Claim__c> selectByIdWithSettlements(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory().setCondition('Id IN :ids');
    fflib_QueryFactory settlementsQF = new SettlementsSelector()
      .addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public List<LIA_Claim__c> selectByCaseIdWithCustomers(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory()
      .setCondition('Case__c in :ids');
    fflib_QueryFactory customersQF = new CustomersSelector()
      .addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public List<LIA_Claim__c> selectUnhandledEU261ClaimsByDataStatus(
    String externalDataStatus
  ) {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'EU261_Handling_Status__c = :UNHANDLED_EU261_STATUS and Customer_Claim_Type__c IN :EU261_CLAIM_TYPES AND External_Data_Status__c = :externalDataStatus'
        )
        .toSOQL()
    );
  }

  public List<LIA_Claim__c> selectStuckUnhandledEU261ClaimsByDataStatus(
    String externalDataStatus
  ) {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'EU261_Handling_Status__c = :UNHANDLED_EU261_STATUS and Customer_Claim_Type__c IN :EU261_CLAIM_TYPES AND External_Data_Status__c = :externalDataStatus AND Case__r.Owner.Name = :SAS_AUTOMATION_QUEUE_OWNER_NAME AND CreatedDate < LAST_N_DAYS:6'
        )
        .toSOQL()
    );
  }

  /**
   * When a claim is 2 weeks old and not closed it should no longer be waiting in the automation queue
   * as it opens us up to liability if it is not handled in time.
   */
  public List<LIA_Claim__c> selectStuckEU261Claims() {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'EU261_Handling_Status__c != :ONHOLD_EU261_STATUS AND Case__r.Owner.Name = :SAS_AUTOMATION_QUEUE_OWNER_NAME AND Case__r.Status != :CASE_STATUS_CLOSED AND CreatedDate < LAST_N_DAYS:7'
        )
        .toSOQL()
    );
  }

  public List<LIA_Claim__c> selectClaimsInAutomationQueueByBookingReferences(
    Set<String> bookingReferences
  ) {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Case__r.Owner.Name = :SAS_AUTOMATION_QUEUE_OWNER_NAME AND Case__r.Status != :CASE_STATUS_CLOSED AND Liability_PNR__c IN :bookingReferences'
        )
        .toSOQL()
    );
  }

  public List<LIA_Claim__c> selectClaimsReadyForEU261Automation() {
    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'EU261_Handling_Status__c = :UNHANDLED_EU261_STATUS AND External_Data_Status__c = :COMPLETED_EXTERNAL_DATA_STATUS AND Customer_Claim_Type__c IN :EU261_CLAIM_TYPES AND Case__r.Owner.Name = :SAS_AUTOMATION_QUEUE_OWNER_NAME AND CreatedDate < LAST_N_DAYS:4'
        )
        .setLimit(1600)
        .toSOQL()
    );
  }

  /**
		@throws TooManyMatchesException if there are more than or equal to 50000 matches, custom exception as the default one is not catchable
	*/
  public List<LIA_Claim__c> selectByProactivityId(Id proactivityId) {
    Integer lim = 50000;

    ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
    Proactivity__c proactivity = proactivities.selectById(
      new Set<Id>{ proactivityId }
    )[0];

    String flightNumber;
    Date flightDate;

    if (!String.isBlank(proactivity.Flight_Id__c)) {
      flightNumber = proactivity.Flight_Id__c.substringBefore('-');
      flightDate = DateUtils.parseDateFromFlightId(proactivity.Flight_Id__c);
    }

    String bankAccountNumber = proactivity.Bank_Account_Number__c;
    String bookingReference = proactivity.Booking_Reference__c;
    String email = proactivity.Email__c;
    String euroBonusNumber = proactivity.EuroBonus_Number__c;
    String passengerName = proactivity.Passenger_Name__c;
    String phoneNumber = proactivity.Phone_Number__c;
    String pirNumber = proactivity.PIR__c;

    fflib_QueryFactory query = newQueryFactory();
    Map<Schema.SObjectField, String> proactivityFieldToQuery = new Map<Schema.SObjectField, String>{
      Proactivity__c.Bank_Account_Number__c => 'Bank_Account_Number__c = :bankAccountNumber',
      Proactivity__c.Booking_Reference__c => 'Liability_PNR__c = :bookingReference',
      Proactivity__c.Email__c => 'Contact_Email__c = :email',
      Proactivity__c.EuroBonus_Number__c => 'EuroBonus_Number__c = :euroBonusNumber',
      Proactivity__c.Phone_Number__c => 'Phone_Number__c = :phoneNumber',
      Proactivity__c.PIR__c => 'PIR__c = :pirNumber'
    };

    // Check directly linked cases with claims
    Set<Id> directlyLinkedCasesIds = new Set<Id>{};
    CasesSelector cases = CasesSelector.newInstance();
    List<Case> directlyLinkedCases = cases.selectByDirectlyLinkedProactivityId(
      new Set<Id>{ proactivityId }
    );
    for (Case c : directlyLinkedCases) {
      directlyLinkedCasesIds.add(c.Id);
    }

    String whereQuery = '';
    whereQuery = buildQuery(
      whereQuery,
      'Case__c IN :directlyLinkedCasesIds',
      directlyLinkedCasesIds.size() > 0
    );

    for (Schema.SObjectField field : proactivityFieldToQuery.keySet()) {
      whereQuery = buildQuery(
        whereQuery,
        proactivityFieldToQuery.get(field),
        !String.isBlank((String) proactivity.get(field))
      );
    }

    whereQuery = buildQuery(
      whereQuery,
      '(Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate)',
      !String.isBlank(flightNumber) && flightDate != null
    );

    CustomersSelector customers = CustomersSelector.newInstance();
    if (!String.isBlank(passengerName)) {
      List<Customer__c> matchingCustomers = customers.selectByName(
        new Set<String>{ passengerName }
      );
      if (matchingCustomers.size() > 0) {
        Set<Id> claimIdsFromCustomers = new Set<Id>();
        for (Customer__c c : matchingCustomers) {
          claimIdsFromCustomers.add(c.Claim__c);
        }

        whereQuery = buildQuery(
          whereQuery,
          'Id IN :claimIdsFromCustomers',
          true
        );
      }
    }

    List<LIA_Claim__c> flightClaimList = new List<LIA_Claim__c>();

    Boolean matchArriving = proactivity.Match_Flights_Arriving_To_Airport__c;
    Boolean matchDeparting = proactivity.Match_Flights_Departing_Airport__c;
    String airport = proactivity.Airport__c;
    Date fromDate = proactivity.From_Date__c;
    Date toDate = proactivity.To_Date__c;
    if (toDate != null) {
      toDate = toDate.addDays(1); // To handle comparison between Date and Datetime. 22/02/2022 03:00 > 22/02/2022 (00:00) but 22/02/2022 03:00 < 23/02/2022.
    }
    String cancellationCode = proactivity.Cancellation_Code__c;
    List<Id> bookingList = new List<Id>();
    List<Id> flightIdsWithMatchingCancellationCode = new List<Id>();
    List<Segment__c> allSegments = new List<Segment__c>();
    String arrivalQuery = '(Flight__r.Scheduled_Arrival_Time__c >= :fromDate AND Flight__r.Scheduled_Arrival_Time__c <= :toDate AND Flight__r.Arrival_Airport__c = :airport)';
    String departingQuery = '(Flight__r.Scheduled_Departure_Time__c >= :fromDate AND Flight__r.Scheduled_Departure_Time__c <= :toDate AND Flight__r.Departure_Airport__c = :airport)';
    String advancedMatcherQuery = '';

    advancedMatcherQuery = buildQuery(
      advancedMatcherQuery,
      arrivalQuery,
      matchArriving
    );

    advancedMatcherQuery = buildQuery(
      advancedMatcherQuery,
      departingQuery,
      matchDeparting
    );

    if (cancellationCode != null) {
      List<FlightIrregularities__c> irregularityList = [
        SELECT Flight__c
        FROM FlightIrregularities__c
        WHERE Code__c = :cancellationCode
        LIMIT :lim
      ];

      checkIfAtLimit(irregularityList.size());

      for (FlightIrregularities__c fi : irregularityList) {
        flightIdsWithMatchingCancellationCode.add(fi.Flight__c);
      }
      if (advancedMatcherQuery.length() > 0) {
        advancedMatcherQuery = String.format(
          '({0}) AND Flight__r.Id IN :flightIdsWithMatchingCancellationCode',
          new List<String>{ advancedMatcherQuery }
        );
      } else {
        advancedMatcherQuery = 'Flight__r.Id IN :flightIdsWithMatchingCancellationCode';
      }
    }

    if (
      String.isBlank(advancedMatcherQuery) &&
      !String.isBlank(flightNumber) &&
      flightDate != null
    ) {
      // We cannot mix advanced and simple matchers, so if there are no advanced there might be a simple flight matcher
      String tedsLikeMatcher = String.format(
        '{0}-{1}-%',
        new List<String>{
          flightNumber,
          StringUtils.dateToTEDSString(flightDate)
        }
      );
      String tedsQuery = '(Flight__r.TEDS_Identifier__c LIKE :tedsLikeMatcher)';
      advancedMatcherQuery = buildQuery(advancedMatcherQuery, tedsQuery, true);
    }

    if (!String.isBlank(advancedMatcherQuery)) {
      String segmentQuery = String.format(
        'SELECT Booking__r.Id FROM Segment__c WHERE {0} LIMIT {1}',
        new List<Object>{ advancedMatcherQuery, lim }
      );
      allSegments = Database.query(segmentQuery);
      checkIfAtLimit(allSegments.size());
    }

    for (Segment__c s : allSegments) {
      bookingList.add(s.Booking__c);
    }

    flightClaimList = (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition('Case__c IN (SELECT Case__c FROM CaseToBooking__c WHERE Booking__r.Id IN :bookingList)').setLimit(lim).toSOQL()
    );

    if (whereQuery.length() == 0) {
      if (flightClaimList.size() != 0) {
        return flightClaimList;
      }
      return new List<LIA_Claim__c>{};
    }

    checkIfAtLimit(flightClaimList.size());

    if (this.filterClosed) whereQuery = filterClosed(whereQuery);
      
    List<LIA_Claim__c> results = (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).setLimit(lim).toSOQL()
    );

    results.addAll(flightClaimList);
    checkIfAtLimit(results.size());

    return results;
  }

  private void checkIfAtLimit(Integer recordCount) {
    if (recordCount >= 50000) {
      throw new TooManyMatchesException();
    }
  }

  public List<LIA_Claim__c> selectSimilarClaimsByCaseId(Id caseId) {
    List<LIA_Claim__c> claims = selectByCaseIdWithCustomers(
      new Set<Id>{ caseId }
    );
    if (claims == null || claims.size() == 0) {
      return new List<LIA_Claim__c>();
    }

    LIA_Claim__c claim = claims[0];

    String bankAccountNumber = claim.Bank_Account_Number__c;
    String bookingReference = claim.Liability_PNR__c;
    String email = claim.Contact_Email__c;
    String euroBonusNumber = claim.EuroBonus_Number__c;
    //String passengerName = claim.Passenger_Name__c; // TODO: What should this be?
    String phoneNumber = claim.Phone_Number__c;
    String pirNumber = claim.PIR__c;

    String whereQuery = '';

    if (!String.isBlank(bankAccountNumber)) {
      //Exclude bank account number matches from appearing in similar cases if the account belongs
      // to a claim firm not slow down page load when there are a lot of matches
      List<Bank_Account_Info__c> claimFirmBankAccounts = BankAccountInfosSelector.newInstance()
        .selectByBankAccountNumber(new Set<String>{ bankAccountNumber });
      if (claimFirmBankAccounts.size() == 0) {
        if (String.isBlank(whereQuery)) {
          whereQuery += 'Bank_Account_Number__c = :bankAccountNumber';
        } else {
          whereQuery += ' OR Bank_Account_Number__c = :bankAccountNumber';
        }
      }
    }

    if (!String.isBlank(bookingReference)) {
      List<String> excludedPNRs = new List<String>{
        '-----',
        'ABC12',
        'ABC123',
        'ABCDEF',
        'AGENCY',
        'SKCHAR',
        'XXXXX',
        'XXXXXX',
        'YYYYY'
      };
      if (String.isBlank(whereQuery)) {
        whereQuery += '(Liability_PNR__c = :bookingReference AND Liability_PNR__c NOT IN :excludedPNRs)';
      } else {
        whereQuery += ' OR (Liability_PNR__c = :bookingReference AND Liability_PNR__c NOT IN :excludedPNRs)';
      }
    }

    if (
      !String.isBlank(email) && claim.Type_of_Customer__c == 'Private customer'
    ) {
      List<String> excludedEmails = new List<String>{
        'claim@flyhjaelp.dk',
        'claims@danskrejsehjaelp.dk',
        'klient@flyforsinkelse.dk',
        'kontakt@flyforsinkelser.no',
        'kontakt@flygforsening.se',
        'service@flightright.de'
      };
      // Email should be checked only for private customers.
      if (String.isBlank(whereQuery)) {
        whereQuery += '(Contact_Email__c = :email AND Contact_Email__c NOT IN :excludedEmails)';
      } else {
        whereQuery += ' OR (Contact_Email__c = :email AND Contact_Email__c NOT IN :excludedEmails)';
      }
    }

    if (!String.isBlank(euroBonusNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'EuroBonus_Number__c = :euroBonusNumber';
      } else {
        whereQuery += ' OR EuroBonus_Number__c = :euroBonusNumber';
      }
    }

    /*if (!String.isBlank(passengerName)) {
      List<Customer__c> matchingCustomers = customers.selectByName(
        new Set<String>{ passengerName }
      );
      if (matchingCustomers.size() > 0) {
        Set<Id> claimIdsFromCustomers = new Set<Id>();
        for (Customer__c c : matchingCustomers) {
          claimIdsFromCustomers.add(c.Claim__c);
        }
        if (String.isBlank(whereQuery)) {
          whereQuery += 'Id IN :claimIdsFromCustomers';
        } else {
          whereQuery += ' OR Id IN :claimIdsFromCustomers';
        }
      }
    }*/

    if (!String.isBlank(phoneNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Phone_Number__c = :phoneNumber';
      } else {
        whereQuery += ' OR Phone_Number__c = :phoneNumber';
      }
    }

    if (!String.isBlank(pirNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'PIR__c = :pirNumber';
      } else {
        whereQuery += ' OR PIR__c = :pirNumber';
      }
    }

    List<LIA_Claim__c> toReturn = (List<LIA_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition(whereQuery)
        .addOrdering(
          'CreatedDate',
          fflib_QueryFactory.SortOrder.DESCENDING,
          true
        )
        .setLimit(51)
        .toSOQL()
    );

    // Due to the query limit, the original claim might not be included in the result so let's add it
    if (!toReturn.contains(claim)) {
      toReturn.add(claim);
    }

    return toReturn;
  }

  private Boolean filterClosed = false;

  public void setfilterClosed(Boolean value) {
    this.filterClosed = value;
  }

  private static String buildQuery(
    String whereQuery,
    String queryToAdd,
    Boolean shouldBeAdded
  ) {
    if (shouldBeAdded) {
      if (String.isBlank(whereQuery)) {
        whereQuery += queryToAdd;
      } else {
        whereQuery += ' OR ' + queryToAdd;
      }
    }
    return whereQuery;
  }

  private static String filterClosed(String whereQuery) {
    if (String.isBlank(whereQuery)) {
      whereQuery += 'Case__r.IsClosed = FALSE';
    } else {

      if (whereQuery.contains('OR') || whereQuery.contains('AND')) {
        whereQuery = '(' + whereQuery + ') AND Case__r.IsClosed = FALSE';
      } else {
        whereQuery += ' AND Case__r.IsClosed = FALSE';
      }

    }
    return whereQuery;
  }
}
