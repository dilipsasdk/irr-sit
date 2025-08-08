/**
 * fflib factory configuration for SAS Service. See also IRR_Application.
 */

public class SAS_Service_Application {
  public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
    new Map<SObjectType, Type>{
      Account.SObjectType => AccountsSelector.class,
      Booking__c.SObjectType => BookingsSelector.class,
      Bank_Account_Info__c.SObjectType => BankAccountInfosSelector.class,
      CARE_Claim__c.SObjectType => CAREClaimsSelector.class,
      Case.SObjectType => CasesSelector.class,
      CaseToBooking__c.SObjectType => CaseToBookingsSelector.class,
      Claim_Expense__c.SObjectType => ClaimExpensesSelector.class,
      ContentVersion.SObjectType => ContentVersionsSelector.class,
      Customer__c.SObjectType => CustomersSelector.class,
      Contact.SObjectType => ContactsSelector.class,
      EmailMessage.SObjectType => EmailMessagesSelector.class,
      EmailTemplate.SObjectType => EmailTemplatesSelector.class,
      Exchange_Rate__c.SObjectType => ExchangeRatesSelector.class,
      Flight__c.SObjectType => FlightsSelector.class,
      Airport__c.SObjectType => AirportsSelector.class,
      Flight_Delay_Certificate_Request__c.SObjectType => FlightDelayCertificateRequestsSelector.class,
      FlightIrregularities__c.SObjectType => FlightIrregularitiesSelector.class,
      User.SObjectType => UsersSelector.class,
      Group.SObjectType => GroupsSelector.class,
      LIA_Claim__c.SObjectType => ClaimsSelector.class,
      LiveChatTranscript.SObjectType => ChatTranscriptsSelector.class,
      MessagingSession.SObjectType => MessagingSessionsSelector.class,
      OrgWideEmailAddress.SObjectType => OrgWideEmailAddressesSelector.class,
      Passenger__c.SObjectType => PassengersSelector.class,
      Proactivity__c.SObjectType => ProactivitiesSelector.class,
      Racer_Integration_Counter__c.SObjectType => RacerIntegrationCountersSelector.class,
      Redeemed_Compensation_Card__c.SObjectType => RedeemedCompensationCardsSelector.class,
      Refund_Request__c.SObjectType => Refund_RequestsSelector.class,
      Segment__c.SObjectType => SegmentsSelector.class,
      Segment_Event__c.SObjectType => SegmentEventsSelector.class,
      Settlement__c.SObjectType => SettlementsSelector.class,
      Settlement_Item__c.SObjectType => SettlementItemsSelector.class,
      SocialPost.SObjectType => SocialPostsSelector.class,
      Travel_Pass_Product__c.SObjectType => TravelPassProductsSelector.class
    }
  );

  public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
    SAS_Service_Application.Selector,
    new Map<SObjectType, Type>{
      Account.SObjectType => Accounts.Constructor.class,
      Booking__c.SObjectType => Bookings.Constructor.class,
      ContentVersion.SObjectType => ContentVersions.Constructor.class,
      Case.SObjectType => Cases.Constructor.class,
      CARE_Claim__c.SObjectType => CAREClaims.Constructor.class,
      Customer__c.SObjectType => Customers.Constructor.class,
      EmailMessage.SObjectType => EmailMessages.Constructor.class,
      Exchange_Rate__c.SObjectType => ExchangeRates.Constructor.class,
      Flight__c.SObjectType => Flights.Constructor.class,
      Airport__c.SObjectType => Airports.Constructor.class,
      Flight_Delay_Certificate_Request__c.SObjectType => FlightDelayCertificateRequests.Constructor.class,
      FlightIrregularities__c.SObjectType => FlightIrregularities.Constructor.class,
      LIA_Claim__c.SObjectType => Claims.Constructor.class,
      Claim_Expense__c.SObjectType => ClaimExpenses.Constructor.class,
      LiveChatTranscript.SObjectType => LiveChatTranscripts.Constructor.class,
      MessagingSession.SObjectType => MessagingSessions.Constructor.class,
      Passenger__c.SObjectType => Passengers.Constructor.class,
      Redeemed_Compensation_Card__c.SObjectType => RedeemedCompensationCards.Constructor.class,
      Refund_Request__c.SObjectType => Refund_Requests.Constructor.class,
      Segment__c.SObjectType => Segments.Constructor.class,
      Segment_Event__c.SObjectType => SegmentEvents.Constructor.class,
      Settlement__c.SObjectType => Settlements.Constructor.class,
      Settlement_Item__c.SObjectType => SettlementItems.Constructor.class,
      SocialPost.SObjectType => SocialPosts.Constructor.class,
      EBVoucherPaymentApproved__e.SObjectType => EBVoucherPaymentApproved.Constructor.class,
      Knowledge__kav.SObjectType => Knowledges.Constructor.class
    }
  );

  public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
    new Map<Type, Type>{
      BookingService.class => BookingService.class,
      ClaimService.class => ClaimService.class,
      ClaimsIntegrationService.class => ClaimsIntegrationService.class,
      CLMIntegrationService.class => CLMIntegrationService.class,
      EU261Service.class => EU261Service.class,
      FlightService.class => FlightService.class,
      AirportService.class => AirportService.class,
      SettlementService.class => SettlementService.class,
      TEDSIntegrationService.class => TEDSIntegrationService.class,
      VoucherIntegrationService.class => VoucherIntegrationService.class,
      KnowledgeService.class => KnowledgeService.class,
      VoucherOrchestrationService.class => VoucherOrchestrationService.class
    }
  );

  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Account.SObjectType,
      Booking__c.SObjectType,
      CaseToBooking__c.SObjectType,
      Redeemed_Compensation_Card__c.SObjectType,
      ContentDocumentLink.SObjectType,
      ContentVersion.SObjectType,
      EmailMessage.SObjectType,
      Exchange_Rate__c.SObjectType,
      FeedItem.SObjectType,
      Flight__c.SObjectType,
      FlightIrregularities__c.SObjectType,
      User.SObjectType,
      Airport__c.SObjectType,
      LIA_Claim__c.SObjectType,
      Claim_Expense__c.SObjectType,
      Passenger__c.SObjectType,
      Segment__c.SObjectType,
      Segment_Event__c.SObjectType,
      Case.SobjectType,
      Refund_Request__c.SobjectType,
      Group_Travel_Request__c.SobjectType,
      Racer_Integration_Counter__c.SObjectType,
      Settlement__c.SObjectType,
      Settlement_Item__c.SObjectType,
      Approval_Request__c.SObjectType,
      Case_Status_Change__c.SObjectType
    }
  );
}
