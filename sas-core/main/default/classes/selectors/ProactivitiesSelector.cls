public inherited sharing class ProactivitiesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Proactivity__c.Id,
      Proactivity__c.Name,
      Proactivity__c.Bank_Account_Number__c,
      Proactivity__c.Booking_Reference__c,
      Proactivity__c.Email__c,
      Proactivity__c.EuroBonus_Number__c,
      Proactivity__c.Flight_Id__c,
      Proactivity__c.Claim_Firm__c,
      Proactivity__c.Note__c,
      Proactivity__c.Passenger_Name__c,
      Proactivity__c.Phone_Number__c,
      Proactivity__c.Claims_On_Hold__c,
      Proactivity__c.PIR__c,
      Proactivity__c.Type__c,
      Proactivity__c.Airport__c,
      Proactivity__c.Match_Flights_Arriving_To_Airport__c,
      Proactivity__c.Match_Flights_Departing_Airport__c,
      Proactivity__c.From_Date__c,
      Proactivity__c.To_Date__c,
      Proactivity__c.Cancellation_Code__c,
      Proactivity__c.EU261_Eligibility__c,
      Proactivity__c.Automate_Matching_Claims__c,
      Proactivity__c.Eligibility_Explanation__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Proactivity__c.SObjectType;
  }

  public static ProactivitiesSelector newInstance() {
    return (ProactivitiesSelector) SAS_Service_Application.Selector.newInstance(
      Proactivity__c.SObjectType
    );
  }

  public List<Proactivity__c> selectById(Set<Id> ids) {
    return (List<Proactivity__c>) selectSObjectsById(ids);
  }

  /**
   * Gets proactivities which match on the same criteria as the proactivity with the given id
   */
  public List<Proactivity__c> getDuplicateProactivities(String recordId) {
    List<Proactivity__c> proactivities = selectById(new Set<Id>{ recordId });
    if (proactivities.size() == 0) {
      return new List<Proactivity__c>{};
    }
    Proactivity__c p = proactivities[0];
    Set<String> queryParts = new Set<String>();
    String bankAccountNumber = p.Bank_Account_Number__c;
    String bookingReference = p.Booking_Reference__c;
    String email = p.Email__c;
    String euroBonusNumber = p.EuroBonus_Number__c;
    String flightId = p.Flight_Id__c;
    String claimFirm = p.Claim_Firm__c;
    String passengerName = p.Passenger_Name__c;
    String phoneNumber = p.Phone_Number__c;
    String pir = p.PIR__c;

    if (!String.isBlank(bankAccountNumber))
      queryParts.add('Bank_Account_Number__c = :bankAccountNumber');
    if (!String.isBlank(bookingReference))
      queryParts.add('Booking_Reference__c = :bookingReference');
    if (!String.isBlank(email))
      queryParts.add('Email__c = :email');
    if (!String.isBlank(euroBonusNumber))
      queryParts.add('EuroBonus_Number__c = :euroBonusNumber');
    if (!String.isBlank(flightId))
      queryParts.add('Flight_Id__c = :flightId');
    if (!String.isBlank(claimFirm))
      queryParts.add('Claim_Firm__c = :claimFirm');
    if (!String.isBlank(passengerName))
      queryParts.add('Passenger_Name__c = :passengerName');
    if (!String.isBlank(phoneNumber))
      queryParts.add('Phone_Number__c = :phoneNumber');
    if (!String.isBlank(pir))
      queryParts.add('PIR__c = :pir');

    if (queryParts.isEmpty()) {
      // Handle case where no fields are set, if necessary
      return new List<Proactivity__c>{};
    }

    String query = buildQuery(queryParts);
    query = String.format(
      '({0}) AND Id != :recordId',
      new List<String>{ query }
    );

    return (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(query).toSOQL()
    );
  }

  public List<Proactivity__c> selectByCaseId(Id caseId) {
    Map<Proactivity__c, String> reasonToProactivites = selectByCaseIdWithMatchingReasons(
      caseId
    );
    return new List<Proactivity__c>(reasonToProactivites.keySet());
  }

  public Map<Proactivity__c, String> selectByCaseIdWithMatchingReasons(
    Id caseId
  ) {
    LIA_Claim__c claim;
    ClaimsSelector claims = ClaimsSelector.newInstance();
    CasesSelector cases = CasesSelector.newInstance();

    Id directlyLinkedProactivityId;
    try {
      directlyLinkedProactivityId = cases.selectById(new Set<Id>{ caseId })[0]
        .Proactivity__c;
    } catch (Exception e) {
      // The case does not exist (should not happen)
    }

    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};
    List<Proactivity__c> proactivites = new List<Proactivity__c>{};
    if (directlyLinkedProactivityId != null) {
      // Not amazing to double query, but it is irregular and cleans up the code significantly
      proactivites = (List<Proactivity__c>) Database.query(
        newQueryFactory()
          .setCondition('Id = :directlyLinkedProactivityId')
          .toSOQL()
      );

      if (proactivites.size() != 0) {
        proactivityToReason.put(proactivites[0], 'Directly linked');
      }
    }

    try {
      claim = claims.selectByCaseIdWithCustomers(new Set<Id>{ caseId })[0];
    } catch (Exception e) {
      return proactivityToReason;
    }

    proactivityToReason.putAll(
      selectProactivitiesByClaimsWithMatchingReasons(
          new List<LIA_Claim__c>{ claim }
        )
        .proactivityToReason
    );

    return proactivityToReason;
  }

  public ProactivityQueryResult selectProactivitiesByClaimsWithMatchingReasons(
    List<LIA_Claim__c> claims
  ) {
    Set<String> queryParts = new Set<String>{};

    // Get the query and associated variables for proactivities connected to the claim
    FullClaimQuery fullClaimQuery = getFullClaimQuery(claims);
    Set<String> bankAccountNumbers = new Set<String>(
      fullClaimQuery.bankAccountNumbers
    );
    Set<String> bookingReferences = new Set<String>(
      fullClaimQuery.bookingReferences
    );
    Set<String> emails = new Set<String>(fullClaimQuery.emails);
    Set<String> euroBonusNumbers = new Set<String>(
      fullClaimQuery.euroBonusNumbers
    );
    Set<String> phoneNumbers = new Set<String>(fullClaimQuery.phoneNumbers);
    Set<String> pirNumbers = new Set<String>(fullClaimQuery.pirNumbers);
    Set<String> passengerNames = new Set<String>(fullClaimQuery.passengerNames);
    Set<Id> firms = new Set<Id>(fullClaimQuery.firms);
    queryParts.addAll(fullClaimQuery.getQueryParts());

    // Get the query and associated variables for proactivities connected to the claim flight
    Set<String> stringFlightIds = new Set<String>{};
    Set<FullFlightQuery> fullFlightQueries = new Set<FullFlightQuery>{};
    for (LIA_Claim__c claim : claims) {
      FullFlightQuery fullFlightQuery = getFullFlightQuery(claim);
      stringFlightIds.addAll(fullFlightQuery.stringFlightIds);
      queryParts.addAll(fullFlightQuery.getQueryParts());
      fullFlightQueries.add(fullFlightQuery);
    }

    String whereQuery = buildQuery(queryParts);

    List<Proactivity__c> proactivities = (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );

    // Match claims with proactivities and get the reasons for the matches
    return constructProactivityQueryResult(
      claims,
      proactivities,
      passengerNames,
      fullFlightQueries
    );
  }

  private ProactivityQueryResult constructProactivityQueryResult(
    List<LIA_Claim__c> claims,
    List<Proactivity__c> proactivities,
    Set<String> passengerNames,
    Set<FullFlightQuery> fullFlightQueries
  ) {
    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};
    Map<Id, Set<Proactivity__c>> claimIdToProactivities = new Map<Id, Set<Proactivity__c>>{};
    for (LIA_Claim__c claim : claims) {
      Map<Proactivity__c, String> claimSpecificProactivityToReason = getClaimMatchingReasons(
        claim,
        proactivities,
        passengerNames,
        null
      );
      // Add the proactivities which have reasons to the claimIdToProactivities
      for (Proactivity__c p : claimSpecificProactivityToReason.keySet()) {
        if (claimSpecificProactivityToReason.get(p) != '') {
          if (!claimIdToProactivities.containsKey(claim.Id)) {
            claimIdToProactivities.put(claim.Id, new Set<Proactivity__c>{});
          }
          claimIdToProactivities.get(claim.Id).add(p);
        }
      }

      // Do the same for the proactivityToReason
      for (Proactivity__c p : claimSpecificProactivityToReason.keySet()) {
        if (claimSpecificProactivityToReason.get(p) != '') {
          proactivityToReason.put(p, claimSpecificProactivityToReason.get(p));
        }
      }
    }

    // Match individual flights with proactivities and get the reasons for the matches
    String multiReasonTemplate = '{0}, {1}';
    Map<Id, Set<Proactivity__c>> flightIdToProactivities = new Map<Id, Set<Proactivity__c>>{};
    for (FullFlightQuery ffq : fullFlightQueries) {
      for (FlightQuery fq : ffq.flightQueriesMetaData) {
        Set<String> flightIds = ffq.flightIdToSimpleFlightIds.get(fq.flight.Id);
        if (flightIds == null) {
          flightIds = new Set<String>{};
        }
        Map<Proactivity__c, String> flightSpecificProactivityToReason = getFlightMatchingReasons(
          proactivities,
          fq,
          flightIds
        );

        flightIdToProactivities.put(
          fq.flight.Id,
          flightSpecificProactivityToReason.keySet()
        );

        // We can't use putAll as one proactivity might have several flights
        for (Proactivity__c p : flightSpecificProactivityToReason.keySet()) {
          String currentReason = proactivityToReason.get(p);

          if (currentReason == null) {
            proactivityToReason.put(
              p,
              flightSpecificProactivityToReason.get(p)
            );
          } else {
            String combinedReason = String.format(
              multiReasonTemplate,
              new List<String>{
                currentReason,
                flightSpecificProactivityToReason.get(p)
              }
            );

            proactivityToReason.put(p, combinedReason);
          }
        }
      }
    }

    return new ProactivityQueryResult(
      claimIdToProactivities,
      flightIdToProactivities,
      proactivityToReason
    );
  }

  public ProactivityQueryResult selectProactivitiesByClaimsFlightsAndIrregularitiesWithMatchingReasons(
    List<LIA_Claim__c> claims,
    Set<Flight__c> connectedFlights,
    Map<Id, List<FlightIrregularity>> flightIdToIrregularities,
    Boolean onlySelectAutomationProactivities
  ) {
    Map<Id, List<FlightIrregularities__c>> flightIdToSObjectIrregularities = new Map<Id, List<FlightIrregularities__c>>{};
    for (Id flightId : flightIdToIrregularities.keySet()) {
      List<FlightIrregularity> irrs = flightIdToIrregularities.get(flightId);
      List<FlightIrregularities__c> flightIrrs = new List<FlightIrregularities__c>{};
      for (FlightIrregularity irr : irrs) {
        flightIrrs.add(irr.underlyingSObject);
      }
      flightIdToSObjectIrregularities.put(flightId, flightIrrs);
    }

    return selectProactivitiesByClaimsFlightsAndIrregularitiesWithMatchingReasons(
      claims,
      connectedFlights,
      flightIdToSObjectIrregularities,
      onlySelectAutomationProactivities
    );
  }

  public ProactivityQueryResult selectProactivitiesByClaimsFlightsAndIrregularitiesWithMatchingReasons(
    List<LIA_Claim__c> claims,
    Set<Flight__c> connectedFlights,
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities,
    Boolean onlySelectAutomationProactivities
  ) {
    Set<String> queryParts = new Set<String>{};

    // Get the query and associated variables for proactivities connected to the claim
    FullClaimQuery fullClaimQuery = getFullClaimQuery(claims);
    Set<String> bankAccountNumbers = new Set<String>(
      fullClaimQuery.bankAccountNumbers
    );
    Set<String> bookingReferences = new Set<String>(
      fullClaimQuery.bookingReferences
    );
    Set<String> emails = new Set<String>(fullClaimQuery.emails);
    Set<String> euroBonusNumbers = new Set<String>(
      fullClaimQuery.euroBonusNumbers
    );
    Set<String> phoneNumbers = new Set<String>(fullClaimQuery.phoneNumbers);
    Set<String> pirNumbers = new Set<String>(fullClaimQuery.pirNumbers);
    Set<String> passengerNames = new Set<String>(fullClaimQuery.passengerNames);
    Set<Id> firms = new Set<Id>(fullClaimQuery.firms);
    queryParts.addAll(fullClaimQuery.getQueryParts());

    // Get the query and associated variables for proactivities connected to the claim flight
    Set<String> stringFlightIds = new Set<String>{};
    Set<FullFlightQuery> fullFlightQueries = new Set<FullFlightQuery>{};

    for (LIA_Claim__c claim : claims) {
      FullFlightQuery fullFlightQuery = getFullFlightQuery(
        claim,
        new Set<Flight__c>(),
        new Map<Id, List<FlightIrregularities__c>>(),
        false
      );
      stringFlightIds.addAll(fullFlightQuery.stringFlightIds);
      queryParts.addAll(fullFlightQuery.getQueryParts());
      fullFlightQueries.add(fullFlightQuery);
    }

    // Not fantastic, get the query and associated variables for proactivities connected to the connected flights
    if (connectedFlights != null) {
      FullFlightQuery fullFlightQuery = getFullFlightQuery(
        claims[0],
        connectedFlights,
        flightIdToIrregularities,
        false
      );
      stringFlightIds.addAll(fullFlightQuery.stringFlightIds);
      queryParts.addAll(fullFlightQuery.getQueryParts());
      fullFlightQueries.add(fullFlightQuery);
    }

    String whereQuery = buildQuery(queryParts);

    if (onlySelectAutomationProactivities) {
      whereQuery = 'Automate_Matching_Claims__c = TRUE AND (QUERY)'
        .replace('QUERY', whereQuery);
    }

    List<Proactivity__c> proactivities = (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );

    // Match claims with proactivities and get the reasons for the matches
    return constructProactivityQueryResult(
      claims,
      proactivities,
      passengerNames,
      fullFlightQueries
    );
  }

  public class ProactivityQueryResult {
    public Map<Id, Set<Proactivity__c>> claimIdToProactivities;
    public Map<Id, Set<Proactivity__c>> flightIdToProactivities;
    public Map<Proactivity__c, String> proactivityToReason;

    public ProactivityQueryResult() {
      this.claimIdToProactivities = new Map<Id, Set<Proactivity__c>>();
      this.flightIdToProactivities = new Map<Id, Set<Proactivity__c>>();
      this.proactivityToReason = new Map<Proactivity__c, String>();
    }

    public ProactivityQueryResult(
      Map<Id, Set<Proactivity__c>> claimIdToProactivities,
      Map<Id, Set<Proactivity__c>> flightIdToProactivities,
      Map<Proactivity__c, String> proactivityToReason
    ) {
      this.claimIdToProactivities = claimIdToProactivities;
      this.flightIdToProactivities = flightIdToProactivities;
      this.proactivityToReason = proactivityToReason;
    }
  }

  /**
   * Holds the query and all variables connected to that query
   * for one or more claims
   */
  private class FullClaimQuery {
    List<String> bankAccountNumbers;
    List<String> bookingReferences;
    List<String> emails;
    List<String> euroBonusNumbers;
    List<Id> firms;
    List<String> phoneNumbers;
    List<String> pirNumbers;
    List<String> passengerNames;

    public FullClaimQuery(
      List<String> bankAccountNumbers,
      List<String> bookingReferences,
      List<String> emails,
      List<String> euroBonusNumbers,
      List<Id> firms,
      List<String> phoneNumbers,
      List<String> pirNumbers,
      List<String> passengerNames
    ) {
      this.bankAccountNumbers = bankAccountNumbers;
      this.bookingReferences = bookingReferences;
      this.emails = emails;
      this.euroBonusNumbers = euroBonusNumbers;
      this.firms = firms;
      this.phoneNumbers = phoneNumbers;
      this.pirNumbers = pirNumbers;
      this.passengerNames = passengerNames;
    }

    public Set<String> getQueryParts() {
      Map<String, List<Object>> queryToObjects = new Map<String, List<Object>>{
        'Bank_Account_Number__c IN :bankAccountNumbers' => bankAccountNumbers,
        'Booking_Reference__c IN :bookingReferences' => bookingReferences,
        'Email__c IN :emails' => emails,
        'EuroBonus_Number__c IN :euroBonusNumbers' => euroBonusNumbers,
        'Phone_Number__c IN :phoneNumbers' => phoneNumbers,
        'PIR__c IN :pirNumbers' => pirNumbers
      };

      Set<String> queryParts = new Set<String>();
      for (String query : queryToObjects.keySet()) {
        if (queryToObjects.get(query).size() > 0) {
          queryParts.add(query);
        }
      }

      if (passengerNames.size() > 0) {
        queryParts.add('Passenger_Name__c IN :passengerNames');
      }

      if (firms.size() > 0) {
        queryParts.add('Claim_Firm__c IN :firms');
      }

      return queryParts;
    }
  }

  /**
   * Holds all flightqueries for one db-query and the associated flight ids
   * which are used to match the proactivities with the flights after the query
   * and to match flights with the "FlightId" proactivity field.
   */
  private class FullFlightQuery {
    List<FlightQuery> flightQueriesMetaData;
    Set<String> stringFlightIds;
    Map<Id, Set<String>> flightIdToSimpleFlightIds;

    public FullFlightQuery(
      List<FlightQuery> flightQueriesMetaData,
      Set<String> stringFlightIds,
      Map<Id, Set<String>> flightIdToSimpleFlightIds
    ) {
      this.flightQueriesMetaData = flightQueriesMetaData;
      this.stringFlightIds = stringFlightIds;
      this.flightIdToSimpleFlightIds = flightIdToSimpleFlightIds;
    }

    public Set<String> getQueryParts() {
      Set<String> queryParts = new Set<String>{};
      for (FlightQuery fq : flightQueriesMetaData) {
        if (!String.isBlank(fq.query)) {
          queryParts.add(fq.query);
        }
      }

      queryParts.add('Flight_Id__c IN :stringFlightIds');

      return queryParts;
    }
  }

  /**
   * Holds a flight specific query and the associated flight to make it
   * possible to match the flight with connected proactivities after the query
   * has been executed
   */
  private class FlightQuery {
    public String query;
    public Flight__c flight;
    public List<String> cancellationCodes;

    public FlightQuery(String q, Flight__c f, List<String> ccs) {
      this.query = q;
      this.flight = f;
      this.cancellationCodes = ccs;
    }
  }

  /**
   * Get the query and associated variables for proactivities connected to the claim
   * The variables need to be passed as they need to be in the scope when the query is executed
   *
   * @param claims The claims to get the query for
   * @return The query and associated variables
   */
  private static FullClaimQuery getFullClaimQuery(List<LIA_Claim__c> claims) {
    List<String> bankAccountNumbers = new List<String>();
    List<String> bookingReferences = new List<String>();
    List<String> emails = new List<String>();
    List<String> euroBonusNumbers = new List<String>();
    List<String> phoneNumbers = new List<String>();
    List<String> pirNumbers = new List<String>();
    List<String> passengerNames = new List<String>();
    List<Id> firms = new List<Id>();
    // Loop through all claims and get the query parameters
    for (LIA_Claim__c claim : claims) {
      if (claim.Customers__r != null) {
        for (Customer__c customer : claim.Customers__r) {
          if (customer.Name != null) {
            passengerNames.add(customer.Name);
          }
        }
      }

      // Get query parameters related to claim
      if (!String.IsBlank(claim.Bank_Account_Number__c)) {
        bankAccountNumbers.add(claim.Bank_Account_Number__c);
      }
      if (!String.IsBlank(claim.Liability_PNR__c)) {
        bookingReferences.add(claim.Liability_PNR__c);
      }
      if (!String.IsBlank(claim.Contact_Email__c)) {
        emails.add(claim.Contact_Email__c);
      }
      if (!String.IsBlank(claim.EuroBonus_Number__c)) {
        euroBonusNumbers.add(claim.EuroBonus_Number__c);
      }
      if (!String.IsBlank(claim.Phone_Number__c)) {
        phoneNumbers.add(claim.Phone_Number__c);
      }
      if (!String.IsBlank(claim.PIR__c)) {
        pirNumbers.add(claim.PIR__c);
      }
      if (!String.IsBlank(claim.Claim_Firm__c)) {
        firms.add(claim.Claim_Firm__c);
      }
    }

    return new FullClaimQuery(
      bankAccountNumbers,
      bookingReferences,
      emails,
      euroBonusNumbers,
      firms,
      phoneNumbers,
      pirNumbers,
      passengerNames
    );
  }

  private static FullFlightQuery getFullFlightQuery(LIA_Claim__c claim) {
    List<Flight__c> connectedFlights = new List<Flight__c>{};

    if (claim.Liability_PNR__c != null) {
      connectedFlights = FlightsSelector.newInstance()
        .selectByBookingReference(new Set<String>{ claim.Liability_PNR__c });
    }

    return getFullFlightQuery(
      claim,
      new Set<Flight__c>(connectedFlights),
      null,
      true
    );
  }

  /**
   * Get the query and associated variables for proactivities connected to the claim flight
   * and the flights connected to the booking which the claim is connected to
   */
  private static FullFlightQuery getFullFlightQuery(
    LIA_Claim__c claim,
    Set<Flight__c> connectedFlights,
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities,
    Boolean searchForClaimFlight
  ) {
    // Match on claim flight (Two flight ids to handle different input formats):
    Flight__c claimFlight;
    // Match on any flight in the booking:
    String flightId1 = null;
    String flightId2 = null;
    String claimFlightNumber;
    if (Flight.canNormalizeFlightNumber(claim.Flight_Number__c)) {
      claimFlightNumber = Flight.normalizeFlightNumber(claim.Flight_Number__c);
      flightId1 = claimFlightNumber != null &&
        claim.Flight_Date__c != null
        ? claimFlightNumber +
          '-' +
          String.valueOf(claim.Flight_Date__c).remove('-')
        : null;
      flightId2 = claimFlightNumber != null &&
        claim.Flight_Date__c != null
        ? claimFlightNumber + '-' + String.valueOf(claim.Flight_Date__c)
        : null;
    }

    Set<Id> flightIds = new Set<Id>{};
    Set<String> stringFlightIds = new Set<String>{};
    Map<Id, Set<String>> flightIdToSimpleFlightIds = new Map<Id, Set<String>>{};
    for (Flight__c f : connectedFlights) {
      Set<String> simpleFlightIds = new Set<String>(
        Flight.TEDSIdToSimpleFlightIds(f.TEDS_Identifier__c)
      );
      stringFlightIds.addAll(simpleFlightIds);
      flightIdToSimpleFlightIds.put(f.Id, simpleFlightIds);
      if (simpleFlightIds.contains(flightId1)) {
        claimFlight = f;
      }
      flightIds.add(f.Id);
    }

    if (flightId1 != null) {
      stringFlightIds.add(flightId1);
    }
    if (flightId2 != null) {
      stringFlightIds.add(flightId2);
    }

    if (
      claimFlight == null &&
      claimFlightNumber != null &&
      claim.Flight_Date__c != null &&
      searchForClaimFlight
    ) {
      FlightsSelector flights = FlightsSelector.newInstance();
      try {
        claimFlight = flights.selectByFlightNumberAndDate(
          claimFlightNumber,
          claim.Flight_Date__c
        )[0];
        connectedFlights.add(claimFlight);
        flightIds.add(claimFlight.Id);

        Set<String> simpleFlightIds = new Set<String>(
          Flight.TEDSIdToSimpleFlightIds(claimFlight.TEDS_Identifier__c)
        );
        stringFlightIds.addAll(simpleFlightIds);
        flightIdToSimpleFlightIds.put(claimFlight.Id, simpleFlightIds);
      } catch (Exception e) {
        // No flight matches the claim
      }
    }

    // If the flightIdToIrregularities was not passed in, get it from the db
    if (flightIdToIrregularities == null && connectedFlights.size() > 0) {
      List<FlightIrregularities__c> irregularities = FlightIrregularitiesSelector.newInstance()
        .selectByFlightId(flightIds);

      FlightIrregularities irregs = new FlightIrregularities(irregularities);
      flightIdToIrregularities = irregs.getFlightIdToIrregularities();
    }

    List<FlightQuery> flightQueriesMetaData = new List<FlightQuery>{};
    for (Flight__c f : connectedFlights) {
      FlightQuery flightQ = getFlightQuery(
        f,
        flightIdToIrregularities.get(f.Id)
      );

      if (!String.isBlank(flightQ.query)) {
        flightQueriesMetaData.add(flightQ);
      }
    }

    return new FullFlightQuery(
      flightQueriesMetaData,
      stringFlightIds,
      flightIdToSimpleFlightIds
    );
  }

  /**
   * Get the query and associated variables for proactivities connected to the claim flight
   * The variables need to be passed as they need to be in the scope when the query is executed
   *
   * @param flight The flight to get the query for
   * @param flightIrregularities The irregularities connected to the flight
   * @return The query and associated variables
   */
  private static FlightQuery getFlightQuery(
    Flight__c flight,
    List<FlightIrregularities__c> flightIrregularities
  ) {
    String airportQuery = '';
    List<String> cancellationCodes = new List<String>{};

    if (flight != null) {
      String arrivalTime;
      String departureTime;

      // Not perfect null handling but sufficient for most proactivities
      if (flight.Scheduled_Arrival_Time__c != null) {
        arrivalTime = String.valueOf(flight.Scheduled_Arrival_Time__c.date());
      } else {
        arrivalTime = String.valueOf(
          StringUtils.extractDateFromTEDSId(flight.TEDS_Identifier__c)
        );
      }

      if (flight.Scheduled_Departure_Time__c != null) {
        departureTime = String.valueOf(
          flight.Scheduled_Departure_Time__c.date()
        );
      } else {
        departureTime = String.valueOf(
          StringUtils.extractDateFromTEDSId(flight.TEDS_Identifier__c)
        );
      }

      String fromAirport = flight.Departure_Airport__c;
      String toAirport = flight.Arrival_Airport__c;
      String departingTemplate = '(From_Date__c <= {0} AND To_Date__c >= {0} AND Match_Flights_Departing_Airport__c = TRUE AND Airport__c = \'\'{1}\'\')';
      String departingQuery = String.format(
        departingTemplate,
        new List<String>{ departureTime, fromAirport }
      );
      String arrivingTemplate = '(From_Date__c <= {0} AND To_Date__c >= {0} AND Match_Flights_Arriving_To_Airport__c = TRUE AND Airport__c = \'\'{1}\'\')';
      String arrivingQuery = String.format(
        arrivingTemplate,
        new List<String>{ arrivalTime, toAirport }
      );

      if (flightIrregularities != null) {
        for (FlightIrregularities__c irregularity : flightIrregularities) {
          if (irregularity.Code__c != null) {
            cancellationCodes.add(irregularity.Code__c);
          }
        }
      }

      if (!String.isBlank(fromAirport)) {
        airportQuery = departingQuery;
      }

      if (!String.isBlank(toAirport)) {
        if (airportQuery == '') {
          airportQuery = arrivingQuery;
        } else {
          airportQuery += ' OR ' + arrivingQuery;
        }
      }

      String cancellationCodeRow = '';
      for (String cc : cancellationCodes) {
        cancellationCodeRow = buildReasons(
          cancellationCodeRow,
          '\'' +
          cc +
          '\''
        );
      }

      String cancellationTemplate = '((From_Date__c <= {0} AND To_Date__c >= {1}) AND Cancellation_Code__c IN ({2}))';
      String cancellationCodeQuery = String.format(
        cancellationTemplate,
        new List<String>{ arrivalTime, departureTime, cancellationCodeRow }
      );

      // If a proactivity has both airport and cancellation code matcher both of them must match
      if (cancellationCodes.size() != 0) {
        String airportQueryTemplate = '(({0}) AND {1}) OR (({1}) AND Match_Flights_Departing_Airport__c != TRUE AND Match_Flights_Arriving_To_Airport__c != TRUE) OR (({0}) AND Cancellation_Code__c = \'\'\'\')';
        airportQuery = String.format(
          airportQueryTemplate,
          new List<String>{ airportQuery, cancellationCodeQuery }
        );
      } else {
        String smallAirportQueryTemplate = '(({0}) AND Cancellation_Code__c = \'\'\'\')';
        airportQuery = String.format(
          smallAirportQueryTemplate,
          new List<String>{ airportQuery }
        );
      }
    }

    return new FlightQuery(airportQuery, flight, cancellationCodes);
  }

  private static String buildQuery(Set<String> queryParts) {
    return String.join(new List<String>(queryParts), ' OR ');
  }

  /**
   * Build a string of reasons for why a proactivity matches a claim
   */
  private static Map<Proactivity__c, String> getClaimMatchingReasons(
    LIA_Claim__c claim,
    List<Proactivity__c> proactivites,
    Set<String> passengerNames,
    Id directlyLinkedProactivityId
  ) {
    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};
    for (Proactivity__c p : proactivites) {
      Set<String> reasons = new Set<String>{};
      if (
        !String.isBlank(p.Bank_Account_Number__c) &&
        p.Bank_Account_Number__c == claim.Bank_Account_Number__c
      ) {
        reasons.add('Bank');
      }
      if (
        !String.isBlank(p.Booking_Reference__c) &&
        p.Booking_Reference__c == claim.Liability_PNR__c
      ) {
        reasons.add('PNR');
      }
      if (!String.isBlank(p.Email__c) && p.Email__c == claim.Contact_Email__c) {
        reasons.add('Email');
      }
      if (
        !String.isBlank(p.EuroBonus_Number__c) &&
        p.EuroBonus_Number__c == claim.EuroBonus_Number__c
      ) {
        reasons.add('EB');
      }
      if (
        !String.isBlank(p.Passenger_Name__c) &&
        passengerNames.contains(p.Passenger_Name__c)
      ) {
        reasons.add('Name');
      }
      if (
        !String.isBlank(p.Phone_Number__c) &&
        p.Phone_Number__c == claim.Phone_Number__c
      ) {
        reasons.add('Phone');
      }
      if (!String.isBlank(p.PIR__c) && p.PIR__c == claim.PIR__c) {
        reasons.add('PIR');
      }
      if (p.Claim_Firm__c != null && p.Claim_Firm__c == claim.Claim_Firm__c) {
        reasons.add('Firm');
      }
      if (p.Id != null && p.Id == directlyLinkedProactivityId) {
        reasons.add('Directly linked');
      }

      String reasonsExplanation = '';
      for (String reason : reasons) {
        reasonsExplanation = buildReasons(reasonsExplanation, reason);
      }

      proactivityToReason.put(p, reasonsExplanation);
    }

    return proactivityToReason;
  }

  /**
   * Build a string of reasons for why proactivities match individual flights
   */
  private static Map<Proactivity__c, String> getFlightMatchingReasons(
    List<Proactivity__c> proactivites,
    FlightQuery fq,
    Set<String> stringFlightIds
  ) {
    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};
    String flightMatchTemplate = 'Flight ({0})';

    for (Proactivity__c p : proactivites) {
      Set<String> reasons = new Set<String>{};

      for (String flightId : stringFlightIds) {
        if (!String.isBlank(p.Flight_Id__c) && (p.Flight_Id__c == flightId)) {
          String flightMatch = String.format(
            flightMatchTemplate,
            new List<String>{ flightId }
          );
          reasons.add(flightMatch);
        }
      }

      String matchReasons = getFlightMatchReason(fq, p);
      if (!String.isBlank(matchReasons)) {
        reasons.add(matchReasons);
      }

      if (reasons.size() == 0) {
        continue;
      }

      String reasonsExplanation = '';
      for (String reason : reasons) {
        reasonsExplanation = buildReasons(reasonsExplanation, reason);
      }

      proactivityToReason.put(p, reasonsExplanation);
    }

    return proactivityToReason;
  }

  /**
   * Build a string of reasons for why a proactivity matches a single flight
   */
  private static String getFlightMatchReason(FlightQuery fq, Proactivity__c p) {
    Flight__c flight = fq.flight;
    List<String> cancellationCodes = fq.cancellationCodes;
    String reasons = '';

    // This is much less complex than it looks. If it were not for nullchecks this could be done in 4 lines.
    if (!String.isBlank(p.Airport__c) && flight != null) {
      Boolean matchesActualDepartureTime = false;
      Boolean matchesScheduledDepartureTime = false;
      if (
        flight.Actual_Departure_Time__c != null &&
        flight.Actual_Arrival_Time__c != null
      ) {
        matchesActualDepartureTime = (flight.Actual_Departure_Time__c.date() >=
        p.From_Date__c &&
        flight.Actual_Departure_Time__c.date() <= p.To_Date__c);
      }
      if (
        flight.Scheduled_Departure_Time__c != null &&
        flight.Scheduled_Arrival_Time__c != null
      ) {
        matchesScheduledDepartureTime = (flight.Scheduled_Departure_Time__c.date() >=
        p.From_Date__c &&
        flight.Scheduled_Departure_Time__c.date() <= p.To_Date__c);
      }

      Boolean matchesActualArrivalTime = false;
      Boolean matchesScheduledArrivalTime = false;
      if (
        flight.Actual_Arrival_Time__c != null &&
        flight.Actual_Arrival_Time__c != null
      ) {
        matchesActualArrivalTime = (flight.Actual_Arrival_Time__c.date() >=
        p.From_Date__c &&
        flight.Actual_Arrival_Time__c.date() <= p.To_Date__c);
      }
      if (
        flight.Scheduled_Arrival_Time__c != null &&
        flight.Scheduled_Arrival_Time__c != null
      ) {
        matchesScheduledArrivalTime = (flight.Scheduled_Arrival_Time__c.date() >=
        p.From_Date__c &&
        flight.Scheduled_Arrival_Time__c.date() <= p.To_Date__c);
      }

      if (
        p.Airport__c == flight.Departure_Airport__c &&
        (matchesActualDepartureTime || matchesScheduledDepartureTime) &&
        p.Match_Flights_Departing_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Departure airport');
      }

      if (
        p.Airport__c == flight.Arrival_Airport__c &&
        (matchesActualArrivalTime || matchesScheduledArrivalTime) &&
        p.Match_Flights_Arriving_To_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Arrival airport');
      }
    }
    for (String cancellationCode : cancellationCodes) {
      if (cancellationCode == p.Cancellation_Code__c) {
        reasons = buildReasons(reasons, 'Code "' + cancellationCode + '"');
        break; // A proactivity can only have one code
      }
    }

    if (!String.IsBlank(p.Cancellation_Code__c) && !reasons.contains('Code')) {
      return ''; // If we only match on airport and not code we should not match
    } else if (!String.isBlank(p.Airport__c) && !reasons.contains('airport')) {
      return ''; // If we only match on code and not airport we should not match
    }

    if (!String.isBlank(reasons)) {
      String reasonTemplate = '{0}: ({1})';
      reasons = String.format(
        reasonTemplate,
        new List<String>{
          flight.TEDS_Identifier__c.substringBefore('-'),
          reasons
        }
      );
    }
    return reasons;
  }

  private static String buildReasons(String reasons, String reason) {
    String reasonTemplate = '{0}, {1}';
    if (!String.isBlank(reasons)) {
      return String.format(reasonTemplate, new List<String>{ reasons, reason });
    } else {
      return reason;
    }
  }
}
