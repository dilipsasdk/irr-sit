public without sharing class CreateClaimRequest {
  public Claim.Category category { get; private set; }
  public Claim.Type type { get; private set; }
  public Claim.RecordType recordType { get; private set; }
  public Contact contact { get; private set; }
  public Set<Id> filesToLink { get; private set; }
  public List<Traveler> travelers { get; private set; }
  public List<RebookedFlight> rebookedFlights { get; private set; }
  public List<Expense> expenses { get; private set; }
  public CompensationDetails compensationDetails { get; private set; }

  public String origin { get; private set; }
  public String comment { get; private set; }

  public String bookingReference { get; private set; }
  public String travelAgentBookingReference { get; private set; }
  public String passengerIrregularityReportNumber { get; private set; }
  public String flightNumber { get; private set; }
  public Date departureDate { get; private set; }
  public String ticketNumber { get; private set; }

  public Claim.DelayLength delayLength { get; private set; }
  public Claim.BaggageDelayLength baggageDelayLength { get; private set; }

  public Integer baggagePurchaseYear { get; private set; }
  public Decimal baggagePurchasePrice { get; private set; }
  public String baggagePurchaseCurrency { get; private set; }
  public String SamsoniteReferenceId { get; private set; }

  public Boolean personWithReducedMobility { get; private set; }
  public Boolean unaccompaniedMinor { get; private set; }

  public String compensationCardNumber { get; private set; }

  public class InvalidDataException extends Exception {
  }
  public class CurrencyCountryMismatchException extends Exception {
  }

  private static final Map<String, Claim.RecordType> JSON_TO_RECORD_TYPE = new Map<String, Claim.RecordType>{
    'claim' => Claim.RecordType.CustomerClaim
  };

  private static final Map<String, ClaimExpense.Type> JSON_TO_EXPENSE_TYPE = new Map<String, ClaimExpense.Type>{
    'accommodation' => ClaimExpense.Type.Accommodation,
    'food' => ClaimExpense.Type.Food,
    'phone-calls' => ClaimExpense.Type.PhoneCalls,
    'transportation' => ClaimExpense.Type.Transportation
  };

  private static final Map<String, Claim.CompensationType> JSON_TO_COMPENSATION_TYPE = new Map<String, Claim.CompensationType>{
    'eurobonus' => Claim.CompensationType.EBPoints,
    'monetary' => Claim.CompensationType.Monetary,
    'voucher' => Claim.CompensationType.Voucher
  };

  private static final Map<String, Claim.DelayLength> JSON_TO_DELAY_LENGTH = new Map<String, Claim.DelayLength>{
    '0-2' => Claim.DelayLength.ZeroToTwo,
    '2-3' => Claim.DelayLength.TwoToThree,
    '3-4' => Claim.DelayLength.ThreeToFour,
    '4+' => Claim.DelayLength.MoreThanFour,
    'never-arrived' => Claim.DelayLength.NeverArrived
  };

  private static final Map<String, Claim.BaggageDelayLength> JSON_TO_BAGGAGE_DELAY_LENGTH = new Map<String, Claim.BaggageDelayLength>{
    'less-than-21-days' => Claim.BaggageDelayLength.LessThan21Days,
    'more-than-21-days' => Claim.BaggageDelayLength.MoreThan21Days
  };

  private static final Map<String, Claim.Category> JSON_TO_CLAIM_CATEGORY = new Map<String, Claim.Category>{
    'accident-and-injury' => Claim.Category.AccidentAndInjury,
    'airport-experience' => Claim.Category.AirportExperience,
    'baggage' => Claim.Category.Baggage,
    'booking' => Claim.Category.Booking,
    'flight-disruptions' => Claim.Category.FlightDisruptions,
    'flight-experience' => Claim.Category.FlightExperience,
    'other' => Claim.Category.Other,
    'travel-extras-bought-not-rendered' => Claim.Category.TravelExtras
  };

  private static final Map<String, Claim.Type> JSON_TO_CLAIM_TYPE = new Map<String, Claim.Type>{
    'damaged-baggage' => Claim.Type.BaggageDamaged,
    'baggage-delayed' => Claim.Type.BaggageDelayedLost,
    'booking-error' => Claim.Type.BookingError,
    'cabin-environment' => Claim.Type.CabinEnvironment,
    'complaint-about-refund' => Claim.Type.ComplaintAboutRefund,
    'denied-boarding' => Claim.Type.DeniedBoarding,
    'downgrading' => Claim.Type.Downgrading,
    'extra-baggage' => Claim.Type.ExtraBaggage,
    'flight-cancellation' => Claim.Type.FlightCancellation,
    'flight-cancellation-compensation' => Claim.Type.FlightCancellationCompensation,
    'flight-cancellation-expenses' => Claim.Type.FlightCancellationExpenses,
    'flight-delay' => Claim.Type.FlightDelay,
    'flight-delay-compensation' => Claim.Type.FlightDelayCompensation,
    'flight-delay-expenses' => Claim.Type.FlightDelayExpenses,
    'gate-issues' => Claim.Type.GateIssues,
    'in-flight-meal' => Claim.Type.InFlightMeal,
    'in-flight-service' => Claim.Type.InFlightService,
    'less-than-21-days' => Claim.Type.LessThan21Days,
    'lounge' => Claim.Type.Lounge,
    'meals-drinks' => Claim.Type.MealsDrinks,
    'missed-connection' => Claim.Type.MissedConnection,
    'missed-connection-compensation' => Claim.Type.MissedConnectionCompensation,
    'missed-connection-expenses' => Claim.Type.MissedConnectionExpenses,
    'items-missing' => Claim.Type.MissingItemsFromBaggage,
    'more-than-21-days' => Claim.Type.MoreThan21Days,
    'other' => Claim.Type.Other,
    'personal-injury' => Claim.Type.PersonalInjury,
    'prepaid-seat' => Claim.Type.PrepaidSeat,
    'special-assistance' => Claim.Type.SpecialAssistance,
    'travel-document-control' => Claim.Type.TravelDocumentControl,
    'wifi' => Claim.Type.WiFi
  };

  private static final Map<String, Claim.ContactType> JSON_TO_CUSTOMER_TYPE = new Map<String, Claim.ContactType>{
    'private' => Claim.ContactType.PrivateCustomer,
    'claims-management-company' => Claim.ContactType.ClaimFirm,
    'other-representative' => Claim.ContactType.OtherRepresentative,
    'insurance-company' => Claim.ContactType.InsuranceCompany
  };

  private static final Map<String, String> MARKET_TO_ORIGIN = new Map<String, String>{
    'dk-da' => 'Form - Claims DK',
    'no-no' => 'Form - Claims NO',
    'se-sv' => 'Form - Claims SE',
    'default' => 'Form - Claims International'
  };

  public class Contact {
    public Claim.ContactType type { get; private set; }
    public String companyName { get; private set; }
    public String companyCode { get; private set; }
    public String firstName { get; private set; }
    public String lastName { get; private set; }
    public String email { get; private set; }
    public String phone { get; private set; }
    public String addressLine1 { get; private set; }
    public String addressLine2 { get; private set; }
    public String postalCode { get; private set; }
    public String city { get; private set; }
    public String country { get; private set; }
    public String euroBonusNumber { get; private set; }

    public Contact(CaseFormJSONV2.Contact jsonData) {
      type = JSON_TO_CUSTOMER_TYPE.get(jsonData.type);
      if (jsonData.address != null && jsonData.address.length() > 35) {
        // Racer supports maximum length of 35 characters for address lines.
        // We have two address lines so we'll just split the given address
        // across those. Can't handle more than 70 because of the Racer limit.
        if (jsonData.address.length() > 70) {
          throw new InvalidDataException(
            'Address too long. Length: ' + jsonData.address.length()
          );
        }
        addressLine1 = jsonData.address.substring(0, 35);
        addressLine2 = jsonData.address.substring(35);
      } else {
        addressLine1 = jsonData.address;
      }
      city = jsonData.city;
      companyCode = jsonData.companyCode;
      companyName = jsonData.companyName;
      firstName = jsonData.firstName;
      lastName = jsonData.lastName;
      postalCode = jsonData.postalCode;
      email = jsonData.email;
      phone = jsonData.phone;

      if (!String.isBlank(jsonData.country)) {
        country = CountryUtils.getCountryNameByShortCode(jsonData.country);
      }

      try {
        if (!String.isBlank(jsonData.euroBonusNumber)) {
          euroBonusNumber = Accounts.parseIntoEuroBonusNumber(
            jsonData.euroBonusNumber
          );
        } else {
          euroBonusNumber = '';
        }
      } catch (Exception e) {
        euroBonusNumber = '';
      }
    }
  }

  public class Traveler {
    public String firstName { get; private set; }
    public String lastName { get; private set; }
    public Set<Id> contentVersionIds { get; private set; }

    public Traveler(CaseFormJSONV2.Traveler jsonData) {
      firstName = jsonData.firstName == null ? ' ' : jsonData.firstName;
      lastName = jsonData.lastName == null ? ' ' : jsonData.lastName;

      Set<Id> contentVersionIdsToCreate = new Set<Id>();
      if (jsonData.contentVersionIds != null) {
        for (String i : jsonData.contentVersionIds) {
          contentVersionIdsToCreate.add(Id.valueOf(i));
        }
      }
      contentVersionIds = contentVersionIdsToCreate;
    }

    public override String toString() {
      return this.firstName + ' ' + this.lastName;
    }
  }

  public class Expense {
    public ClaimExpense.Type type { get; private set; }
    public Money.CurrencyCode expenseCurrency { get; private set; }
    public Decimal amount { get; private set; }
    public Set<Id> contentVersionIds { get; private set; }

    public Expense(CaseFormJSONV2.Expense expenseData) {
      if (expenseData.expenseType == null) {
        throw new InvalidDataException('Missing expense type.');
      } else if (expenseData.expenseCurrency == null) {
        throw new InvalidDataException('Missing expense currency.');
      }

      type = JSON_TO_EXPENSE_TYPE.get(expenseData.expenseType);

      if (this.type == null) {
        throw new InvalidDataException(
          'Invalid expense type: ' + expenseData.expenseType
        );
      }

      amount = expenseData.amount == null ? 0 : expenseData.amount;
      expenseCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
        expenseData.expenseCurrency.toUpperCase()
      );

      Set<Id> contentVersionIdsToCreate = new Set<Id>();
      if (expenseData.contentVersionIds != null) {
        for (String i : expenseData.contentVersionIds) {
          contentVersionIdsToCreate.add(Id.valueOf(i));
        }
      }
      contentVersionIds = contentVersionIdsToCreate;
    }

    public override String toString() {
      return ClaimExpense.TYPE_ENUM_TO_PICKLIST_VALUE.get(this.type) +
        ': ' +
        this.amount +
        ' ' +
        this.expenseCurrency.name();
    }
  }

  public class RebookedFlight {
    public Date departureDate { get; private set; } // 2022-02-20
    public String flightNumber { get; private set; } // SK1234
    public Set<Id> contentVersionIds { get; private set; }

    public RebookedFlight(CaseFormJSONV2.Flight flightData) {
      try {
        departureDate = Date.valueOf(flightData.departureDate);
      } catch (Exception e) {
        throw new InvalidDataException(
          'Invalid rebooked departure date: ' + flightData.departureDate
        );
      }

      try {
        flightNumber = Flight.normalizeFlightNumber(flightData.flightNumber);
      } catch (Exception e) {
        throw new InvalidDataException(
          'Invalid rebooked flight number: ' + flightData.flightNumber
        );
      }

      Set<Id> contentVersionIdsToCreate = new Set<Id>();
      if (flightData.contentVersionIds != null) {
        for (String i : flightData.contentVersionIds) {
          contentVersionIdsToCreate.add(Id.valueOf(i));
        }
      }
      contentVersionIds = contentVersionIdsToCreate;
    }

    public override String toString() {
      return this.flightNumber + ' ' + this.departureDate;
    }
  }

  public class CompensationDetails {
    public String bankAccountHolderName;
    public String bankAccountNumber;
    public String bankCountry;
    public String bankName;
    public String bankBic;

    public Money.CurrencyCode preferredCurrency;
    public Claim.CompensationType preferredCompensationMethod;
    public Claim.CompensationType preferredReimbursementMethod;

    public String referenceNumber;

    public CompensationDetails(CaseFormJSONV2.CompensationDetails jsonData) {
      this.bankAccountHolderName = jsonData.bankAccountHolderName;
      this.bankName = jsonData.bankName;
      this.bankBic = jsonData.bankBic;
      this.preferredCurrency = String.isBlank(jsonData.preferredCurrency)
        ? null
        : Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
            jsonData.preferredCurrency.toUpperCase()
          );
      this.preferredCompensationMethod = JSON_TO_COMPENSATION_TYPE.get(
        jsonData.preferredCompensationMethod
      );
      this.preferredReimbursementMethod = JSON_TO_COMPENSATION_TYPE.get(
        jsonData.preferredReimbursementMethod
      );

      this.referenceNumber = jsonData.referenceNumber;

      if (!String.isBlank(jsonData.bankCountry)) {
        this.bankCountry = CountryUtils.getCountryNameByShortCode(
          jsonData.bankCountry
        );
      }

      if (!String.isBlank(jsonData.bankAccountNumber)) {
        if (!String.isBlank(jsonData.bankRoutingNumber)) {
          // US bank account numbers should be sent to Racer as {accountNumber}ABA{routingNumber}
          // Other countries have only an account number.
          this.bankAccountNumber =
            StringUtils.removeWhitespace(jsonData.bankAccountNumber) +
            'ABA' +
            StringUtils.removeWhitespace(jsonData.bankRoutingNumber);
        } else {
          this.bankAccountNumber = jsonData.bankAccountNumber.replace(' ', '');
        }
      }
    }
  }

  private Boolean homeCountryAndCurrencyMismatches(
    Contact contact,
    CompensationDetails compensationDetails
  ) {
    return contact.country != null &&
      compensationDetails.preferredCurrency != null &&
      !CountryUtils.countryAndCurrencyMatches(
        contact.country,
        compensationDetails.preferredCurrency.name()
      );
  }

  public CreateClaimRequest(CaseFormJSONV2 jsonData) {
    if (!String.isBlank(jsonData.formData.claim.compensationCardNumber)) {
      String origin = MARKET_TO_ORIGIN.get(jsonData.metaData.market);
      this.origin = origin != null ? origin : MARKET_TO_ORIGIN.get('default');

      contact = new Contact(jsonData.formData.contact);
      compensationDetails = new CompensationDetails(
        jsonData.formData.compensationDetails
      );
      if (homeCountryAndCurrencyMismatches(contact, compensationDetails)) {
        throw new CurrencyCountryMismatchException(
          'Home country and currency mismatch'
        );
      }

      if (
        !Booking.isValidBookingReference(
          jsonData.formData.claim.bookingReference
        )
      ) {
        throw new InvalidDataException(
          'Invalid booking reference: ' +
          jsonData.formData.claim.bookingReference
        );
      }

      bookingReference = jsonData.formData.claim.bookingReference;
      compensationCardNumber = jsonData.formData.claim.compensationCardNumber;
    } else {
      switch on JSON_TO_RECORD_TYPE.get(jsonData.formData.type) {
        when CustomerClaim {
          this.recordType = Claim.RecordType.CustomerClaim;
          this.category = JSON_TO_CLAIM_CATEGORY.get(
            jsonData.formData.claim.category
          );
          this.type = JSON_TO_CLAIM_TYPE.get(jsonData.formdata.claim.type);
          String origin = MARKET_TO_ORIGIN.get(jsonData.metaData.market);
          this.origin = origin != null
            ? origin
            : MARKET_TO_ORIGIN.get('default');
        }
        when else {
          throw new InvalidDataException(
            'Invalid case type for claim creation.'
          );
        }
      }

      contact = new Contact(jsonData.formData.contact);
      compensationDetails = new CompensationDetails(
        jsonData.formData.compensationDetails
      );
      if (homeCountryAndCurrencyMismatches(contact, compensationDetails)) {
        throw new CurrencyCountryMismatchException(
          'Home country and currency mismatch'
        );
      }

      List<Expense> expensesToCreate = new List<Expense>();
      if (jsonData.formData.claim.expenses != null) {
        for (
          CaseFormJSONV2.Expense expense : jsonData.formData.claim.expenses
        ) {
          expensesToCreate.add(new Expense(expense));
        }
      }
      expenses = expensesToCreate;

      List<RebookedFlight> rebookedFlightsToCreate = new List<RebookedFlight>();
      if (jsonData.formData.claim.rebookedFlights != null) {
        for (
          CaseFormJSONV2.Flight rebookedFlight : jsonData.formData.claim.rebookedFlights
        ) {
          rebookedFlightsToCreate.add(new RebookedFlight(rebookedFlight));
        }
      }
      rebookedFlights = rebookedFlightsToCreate;

      List<Traveler> travelersToCreate = new List<Traveler>();
      if (jsonData.formData.claim.travelers != null) {
        for (CaseFormJSONV2.Traveler t : jsonData.formData.claim.travelers) {
          travelersToCreate.add(new Traveler(t));
        }
      }
      travelers = travelersToCreate;

      if (
        jsonData.formData.claim.bookingReference != null &&
        !Booking.isValidBookingReference(
          jsonData.formData.claim.bookingReference
        )
      ) {
        throw new InvalidDataException(
          'Invalid booking reference: ' +
          jsonData.formData.claim.bookingReference
        );
      }

      try {
        flightNumber = Flight.normalizeFlightNumber(
          jsonData.formData.claim.flightNumber
        );
      } catch (Exception e) {
        throw new InvalidDataException(
          'Invalid flight number: ' + jsonData.formData.claim.flightNumber
        );
      }

      Set<Id> fileIds = new Set<Id>();
      if (jsonData.formData.contentVersionIds != null) {
        for (String s : jsonData.formData.contentVersionIds) {
          fileIds.add(Id.valueOf(s));
        }
      }
      filesToLink = fileIds;

      bookingReference = jsonData.formData.claim.bookingReference;
      travelAgentBookingReference = jsonData.formData.claim.travelAgentBookingReference;
      passengerIrregularityReportNumber = jsonData.formData.claim.passengerIrregularityReportNumber;
      ticketNumber = jsonData.formData.claim.ticketNumber;
      baggagePurchaseYear = jsonData.formData.claim.baggagePurchaseYear;
      baggagePurchasePrice = jsonData.formData.claim.baggagePurchasePrice;
      baggagePurchaseCurrency = jsonData.formData.claim.baggagePurchaseCurrency;
      comment = jsonData.formData.claim.comment;
      SamsoniteReferenceId = jsonData.formData.claim.SamsoniteReferenceId;

      delayLength = JSON_TO_DELAY_LENGTH.get(
        jsonData.formData.claim.delayLength
      );
      baggageDelayLength = JSON_TO_BAGGAGE_DELAY_LENGTH.get(
        jsonData.formData.claim.baggageDelayTime
      );

      departureDate = String.isBlank(jsonData.formData.claim.departureDate)
        ? null
        : Date.valueOf(jsonData.formData.claim.departureDate);

      unaccompaniedMinor = jsonData.formData.claim.unaccompaniedMinor == null
        ? false
        : jsonData.formData.claim.unaccompaniedMinor;

      personWithReducedMobility = jsonData.formData.claim.personWithReducedMobility ==
        null
        ? false
        : jsonData.formData.claim.personWithReducedMobility;
    }
  }
}
