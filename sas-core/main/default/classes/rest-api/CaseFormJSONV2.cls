global class CaseFormJSONV2 {
  global FormData formData;
  global MetaData metaData;

  global class Contact {
    global String type; // private, corporate, travel-agency, other-representative, insurance-company
    global String companyName;
    global String companyCode;
    global String firstName;
    global String lastName;
    global String email;
    global String phone;
    global String address;
    global String postalCode;
    global String city;
    global String country;
    global String euroBonusNumber;
  }

  global class Claim {
    global String category; // baggage, flight-disruption, missing-services, in-flight-disruption, airport-disruption, booking, medical
    global String type; // baggage-delayed, baggage-damaged, flight-cancellation, flight-delay, missed-connection, denied-boarding, downgrading, WIFI, missing-food, extra-baggage, prepaid-seat, lounge, cabin-environment, food-poisoning, in-flight-service, airport-assistance, document-control, gate-issues, booking-errors, complaint-about-refund, personal-injury, regression, other
    global String delayLength; // 0-2, 2-3, 3-4, 4+, never-arrived
    global Boolean unaccompaniedMinor;
    global Boolean personWithReducedMobility;

    global String bookingReference;
    global String travelAgentBookingReference;
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global String ticketNumber;
    global String passengerIrregularityReportNumber;
    global String compensationCardNumber;

    global String comment; // free text field

    global String baggageDelayTime; // less-than-21-days, more-than-21-days
    global Decimal baggagePurchasePrice;
    global String baggagePurchaseCurrency;
    global Integer baggagePurchaseYear;
    global String SamsoniteReferenceId;

    global List<Traveler> travelers;
    global List<Expense> expenses;
    global List<Flight> rebookedFlights;
  }

  global class Feedback {
    global String feedbackType;
    global List<String> area;
    global String comment;
    global String email;
  }

  global class Medical {
    global String medicalType;
    global String bookingReference;
    global String email;
    global List<String> contentVersionIds;
    global ContactDetails contactDetails;
    global EquipmentDetails equipmentDetails;
  }

  global class RefundRequest {
    global String refundType;
    global String bookingReference;
    global String bookedViaTravelAgent;
    global String cancelEntireBooking;
    global String cancelAllPassengers;
    global string cancelledRoute;
    global String ticketNumber;
    global String countryOfPurchase;
    global List<Traveler> travelers;
  }

  global class GroupTravelRequest {
    global String groupType;
    global String groupCountryOfResedence;
    global String organizationName;
    global String companyCode;
    global SportCodeDetails sportCodeDetails;
    global TravelDetails travelDetails;
    global TravelersDetails travelersDetails;
    global ContactDetails contactDetails;
    global SpecialRequests specialRequests;
    global PaymentDetails paymentDetails;
  }

  global class SportCodeDetails {
    global String association;
    global String sportsCode;
  }

  global class TravelDetails {
    global String origin;
    global String destination;
    global String alternativeDepartureTime;
    global String alternativeReturnDestination;
    global String alternativeReturnTime;
    global String departureTime;
    global String departureDate;
    global String returnTime;
    global String returnDate;
    global String alternativeDestination1;
    global String alternativeDestination2;
    global String alternativeDepartureDate;
    global String alternativeReturnDate;
    global String travelDetailsComment;
    global String travelClass;
    global String tripType;
    global String returnFrom;
  }

  global class SpecialRequests {
    global String addBags;
    global String specialBaggage;
    global String wheelchairs;
    global String impairments;
    global String specialBaggageDescription;
  }

  global class PaymentDetails {
    global String paymentMethod;
    global String invoiceAgreementNumber;
  }

  global class TravelersDetails {
    global String adults;
    global String youths;
    global String children;
    global String infants;
  }

  global class CompensationDetails {
    global String bankAccountHolderName;
    global String bankAccountNumber;
    global String bankCountry;
    global String bankName;
    global String bankBic;
    global String bankRoutingNumber;

    global String preferredCurrency; // SEK, USD, EUR...
    global String preferredCompensationMethod; // eurobonus, monetary, voucher
    global String preferredReimbursementMethod; // eurobonus, monetary, voucher

    global String referenceNumber;
  }

  global class FormData {
    global String type; // claim, feedback, group travel, SSR, refund request

    global Contact contact;

    global Claim claim; // One of these five must exist. Not more.
    global Feedback feedback; // One of these five must exist. Not more.
    global Medical medical;
    global RefundRequest refund;
    global List<String> contentVersionIds;
    global CompensationDetails compensationDetails;
    global GroupTravelRequest groupTravel;
    global SpecialServiceRequest specialServiceRequest;
  }

  global class MetaData {
    global String market;
  }

  global class Flight {
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global List<String> contentVersionIds;
  }

  global class Traveler {
    global String firstName;
    global String lastName;
    global List<String> contentVersionIds;
    global List<SObject> documents;
    global String uuid;
    global String relationshipToDeceased;
    global String ticketNo;
  }

  global class Expense {
    global String expenseType; // food, transportation, phone-calls, accommodation
    global String expenseCurrency;
    global Decimal amount;
    global List<String> contentVersionIds;
  }

  global class EquipmentDetails {
    global String model;
    global String amount;
    global Boolean isBatteryPowerSupply;
  }

  global class ContactDetails {
    global String firstName;
    global String lastName;
    global String email;
    global String phone;
    global String organizationName;
    global String street;
    global String postalCode;
    global String city;
    global String companyCode;
    global String careOf;
    global String pnr;
  }

  global class SpecialServiceRequest {
    global ContactDetails contactDetails;
    global Boolean sightDisability;
    global Boolean hearingDisability;
    global Boolean mobilityImpairment;
    global String mobilityAsssistanceType;
    global Boolean bringYourOwnWheelchair;
    global String wheelchairType;
    global WheelchairSize wheelchairSize;
    global Boolean cognitiveImpairment;
    global String cognitiveImpairmentType;
    global Boolean serviceAnimal;
    global String serviceAnimalType;
  }

  global class WheelchairSize {
    global String height;
    global String width;
    global String depth;
    global String weight;
  }

  public static CaseFormJSONV2 parse(String json) {
    return (CaseFormJSONV2) System.JSON.deserialize(json, CaseFormJSONV2.class);
  }
}
