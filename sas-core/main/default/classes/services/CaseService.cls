public without sharing class CaseService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'death-certificate-dk-da' => 'Form - Death Certificate DK',
    'death-certificate-no-no' => 'Form - Death Certificate NO',
    'death-certificate-se-sv' => 'Form - Death Certificate SE',
    'death-certificate-default' => 'Form - Death Certificate International',
    'visa-rejection-dk-da' => 'Form - Visa Rejection DK',
    'visa-rejection-no-no' => 'Form - Visa Rejection NO',
    'visa-rejection-se-sv' => 'Form - Visa Rejection SE',
    'visa-rejection-default' => 'Form - Visa Rejection International',
    'feedback-dk-da' => 'Form - Feedback DK',
    'feedback-no-no' => 'Form - Feedback NO',
    'feedback-se-sv' => 'Form - Feedback SE',
    'feedback-default' => 'Form - Feedback International'
  };

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'airport-experience' => 'Airport experience',
    'baggage' => 'Baggage',
    'baggage-damaged' => 'Baggage damaged',
    'baggage-delayed' => 'Baggage delayed/lost',
    'booking' => 'Booking',
    'booking-error' => 'Booking error',
    'cabin-environment' => 'Cabin environment',
    'denied-boarding' => 'Denied boarding',
    'downgrading' => 'Downgrading',
    'extra-baggage' => 'Extra baggage',
    'flight-cancellation' => 'Flight cancellation',
    'flight-delay' => 'Flight delay',
    'flight-disruptions' => 'Flight disruptions',
    'flight-experience' => 'Flight experience',
    'gate-issues' => 'Gate issues',
    'general' => 'General',
    'in-flight-meal' => 'In-flight meal',
    'in-flight-service' => 'In-flight service',
    'lounge' => 'Lounge',
    'meals-drinks' => 'Meals/Drinks',
    'missed-connection' => 'Missed connection',
    'other' => 'Other',
    'prepaid-seat' => 'Prepaid seat',
    'refund' => 'Refund',
    'regression' => 'Regression',
    'special-assistance' => 'Special assistance',
    'travel-document-control' => 'Travel document control',
    'travel-extras' => 'Travel extras',
    'wifi' => 'WiFi'
  };

  private static Group refundsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Refunds'
  ];

  private static Group feedbackQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Customer_Claim'
  ];

  /**
   * Creates a support case for the given case.
   *
   * @param department To which department the case should be created to.
   * @param team To which team within the department the case should be created to.
   * @param caseToCreate The case object which is to be created. No fields need to be set by default.
   * @param parentCaseId Id of the case for which this support case is created.
   * @param uow Unit of work instance with which the case should be created.
   */
  public static void createSupportCase(
    String department,
    String team,
    Case caseToCreate,
    Id parentCaseId,
    fflib_ISObjectUnitOfWork uow
  ) {
    caseToCreate.Department__c = department;
    caseToCreate.Team__c = team;
    caseToCreate.Origin = 'Internal - Support';
    caseToCreate.ParentId = parentCaseId;
    caseToCreate.OwnerId = GroupsSelector.newInstance()
        .selectQueuesByDepartment(new Set<String>{ department })[0]
      .Id;
    if (caseToCreate.RecordTypeId == null) {
      // If no record type is set, default to department's default record type.
      caseToCreate.RecordTypeId = Cases.getRecordTypeId(
        Cases.defaultRecordTypeForDepartment.get(department)
      );
    }

    uow.registerNew(caseToCreate);

    Case parentCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ parentCaseId })[0];

    parentCase.Created_Support_Case__c = true;
    uow.registerDirty(parentCase);
  }

  public class AssignPriorityAndRouteToQueueAsync implements Queueable, Database.AllowsCallouts {
    private Set<Id> caseIds;
    public AssignPriorityAndRouteToQueueAsync(Set<Id> caseIds) {
      this.caseIds = caseIds;
    }
    public void execute(QueueableContext ctx) {
      assignPriorityAndRouteToQueue(this.caseIds);
    }
  }

  public static void assignPriorityAndRouteToQueue(Set<Id> caseIds) {
    List<Case> casesToSortThrough = CasesSelector.newInstance()
      .selectById(caseIds);
    assignPriorityAndRouteToQueue(casesToSortThrough);
  }

  /**
   * Cases with Customers with Diamond and Gold EB-level should have "high" priority.
   * Cases get routeAndPrioritized to a queue depending on their claim type.
   *
   * Special cases:
   * 1. Pandion customers have their own queue.
   * 2. Claims with high care costs have a special queue as we quickly want to
   *    compensate customers who might have been put in a difficult economical situation.
   */
  public static void assignPriorityAndRouteToQueue(
    List<Case> casesToSortThrough
  ) {
    Map<Id, Case> claimIdToCase = new Map<Id, Case>{};
    for (Case c : casesToSortThrough) {
      if (c.LIA_Claim__c != null) {
        claimIdToCase.put(c.LIA_Claim__c, c);
      } else {
        return;
      }
    }

    List<LIA_Claim__c> caseClaims = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(claimIdToCase.keySet());

    List<Case> casesToRoute = new List<Case>{};
    for (LIA_Claim__c cl : caseClaims) {
      Case c = claimIdToCase.get(cl.Id); // Do we want to route compensationcards this way? @Jesús
      if (
        (cl.RecordTypeId ==
        Claim.getRecordTypeIdByEnum(Claim.RecordType.CustomerClaim) &&
        String.valueOf(c.OwnerId).substring(0, 3) == '00G') ||
        cl.RecordTypeId ==
        Claim.getRecordTypeIdByEnum(Claim.RecordType.CompensationCard)
      ) {
        casesToRoute.add(c);
      }
    }

    // Remove duplicate cases (we still need a list for below)
    casesToRoute = new List<Case>(new Set<Case>(casesToRoute));

    if (casesToRoute.size() == 0) {
      return;
    }

    Set<String> groupNames = new Set<String>{
      'Claims - EU261',
      'Claims - Care Expenses',
      'Claims - High Priority',
      'Claims - High Care Costs',
      'Claims - Flight Disruptions',
      'Claims - Flight Disruptions Expenses',
      'Claims - Compensation Card',
      'Claims - Baggage',
      'Claims - Other',
      'Claims - Sensitive Topics',
      'Claims - Travel Extra Refunds',
      'Claims - High Tier',
      'SAS Automation Queue'
    };

    List<Group> queues = GroupsSelector.newInstance()
      .selectGroupsByName(groupNames);

    Integer casesRemaining = casesToRoute.size();
    while (casesRemaining > 0) {
      if (casesRemaining > 250) {
        List<Case> notAllCases = new List<Case>{};
        for (Integer i = 0; i < 250; i++) {
          notAllCases.add(casesToRoute[0]);
          casesToRoute.remove(0);
        }
        casesRemaining = casesToRoute.size();
        routeCases(notAllCases, queues);
      } else {
        routeCases(casesToRoute, queues);
        casesRemaining = 0;
      }
    }
  }

  public static void makeDecisionOnClaimExclusionFromAutomation(Cases casesInstance, Map<Id, Case> existingRecords) {
    Map<Id, Case> proactivityIdToCase = getNewlyLinkedProactivityToCase(casesInstance, existingRecords);
    Set<Id> claimIds = getClaimsToPutOnHold(proactivityIdToCase);

    if (claimIds.size() > 0) {
      List<LIA_Claim__c> claimsToExclude = ClaimsSelector.newInstance().selectbyId(claimIds);
      ClaimService.putOnHold(claimsToExclude);
    }
  }

  public static void captureStatusTime(Cases casesInstance, Map<Id, Case> existingRecords) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    List<Case_Status_Change__c> statusChanges = createStatusChanges(casesInstance, existingRecords, uow);
    
    if (!statusChanges.isEmpty()) {
      updateExistingStatusChanges(statusChanges, uow);
    }

    uow.commitWork();
  }

  private static List<Case_Status_Change__c> createStatusChanges(
    Cases casesInstance, 
    Map<Id, Case> existingRecords, 
    fflib_ISObjectUnitOfWork uow
  ) {
    List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();

    for (Case c: casesInstance.instanceRecords) {
      Case_Status_Change__c statusChange = null;
      
      // only create "Case Status Change" record if Case was just created or the status has changed
      if (existingRecords != null) {
        Case oldCase = existingRecords.get(c.Id);
        if (c.Status != oldCase.Status) {
          statusChange = new Case_Status_Change__c();
          statusChange.Status_From__c = oldCase.Status;
          statusChange.Name = existingRecords.get(c.Id).CaseNumber + ' from ' + oldCase.Status + ' to ' + c.Status;
        }
      } else {
        statusChange = new Case_Status_Change__c();
        statusChange.Name = c.CaseNumber + ' status: ' + c.Status;
      }

      if (statusChange != null) {
        statusChange.Case__c = c.Id;
        statusChange.Status_Name__c = c.Status;
        statusChange.Current_Case_Owner__c = c.Case_Owner_Name__c;
        statusChange.Set_Time__c = Datetime.now();
        statusChanges.add(statusChange);
      }
    }
    
    uow.registerNew(statusChanges);
    return statusChanges;
  }

  private static void updateExistingStatusChanges(
    List<Case_Status_Change__c> statusChanges,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<String> oldStatuses = new List<String>();
    List<Id> caseIds = new List<Id>();

    for (Case_Status_Change__c statusChange: statusChanges) {     
      oldStatuses.add(statusChange.Status_From__c);
      caseIds.add(statusChange.Case__c);            
    }
    
    if (!caseIds.isEmpty() && !oldStatuses.isEmpty()) {
      List<Case_Status_Change__c> existingStatusChanges = [
        SELECT Id, Set_Time__c 
        FROM Case_Status_Change__c 
        WHERE Case__c IN :caseIds 
        AND Status_Name__c IN :oldStatuses
        AND Change_Time__c = null
      ];
      
      BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
      
      for (Case_Status_Change__c existingStatusChange : existingStatusChanges) {
        existingStatusChange.Change_Time__c = Datetime.now();
        Double milliseconds = BusinessHours.diff(bh.Id, existingStatusChange.Set_Time__c, existingStatusChange.Change_Time__c);                 
        existingStatusChange.Status_Time__c = (Decimal.valueOf(milliseconds)).Divide((60 * 60 * 1000), 2);
        existingStatusChange.Age__c = getAge(milliseconds);
      }
      
      uow.registerDirty(existingStatusChanges);
    }
  }

  private static String getAge(Double milliseconds) {
    Double duration = milliseconds;
    Double d = Math.floor(duration/86400000); //Get whole days
    duration -= d*86400000;
    Double h = Math.floor(duration/3600000); //Get whole hours
    duration -= h*3600000;
    Double m = Math.floor(duration/60000);
    duration -= m*60000;
    Double s = Math.floor(duration/1000);

    return d.format() + ' days ' + h.format() + ' hours ' + m.format() + ' minutes ' + s.format() + ' seconds';
  }

  private static Map<Id, Case> getNewlyLinkedProactivityToCase(Cases casesInstance, Map<Id, Case> existingRecords) {
    Map<Id, Case> proactivityIdToCase = new Map<Id, Case>();

    for (Case c: casesInstance.instanceRecords) {
      Case existingRecord = existingRecords != null ? existingRecords.get(c.Id) : null;
      if (existingRecord == null || c.Proactivity__c != existingRecord.Proactivity__c) {
        proactivityIdToCase.put(c.Proactivity__c, c);
      }
    }
    return proactivityIdToCase;
}

  private static Set<Id> getClaimsToPutOnHold(Map<Id, Case> proactivityIdToCase) {
    Set<Id> claimsToPutOnHold = new Set<Id>();

    for (Proactivity__c proactivity : ProactivitiesSelector.newInstance().selectById(proactivityIdToCase.keySet())) {
      if (proactivity.Claims_On_Hold__c) {
        claimsToPutOnHold.add(proactivityIdToCase.get(proactivity.Id).LIA_Claim__c);
      }
    }
    return claimsToPutOnHold;
  }

  private static void routeCases(List<Case> casesToRoute, List<Group> queues) {
    Map<String, List<SObject>> params = new Map<String, List<SObject>>{
      'Cases' => casesToRoute,
      'Groups' => queues
    };
    Flow.Interview.CASE_Route_And_Set_Priority routeAndPrioritize = new Flow.Interview.CASE_Route_And_Set_Priority(
      params
    );
    routeAndPrioritize.start();
  }
  public static void createChatterPost(
    List<Case> casesToPost,
    String feedItemBody,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<FeedItem> toCreate = new List<FeedItem>();
    for (Case c : casesToPost) {
      FeedItem fi = new FeedItem(
        ParentId = c.Id,
        Body = feedItemBody,
        Type = 'TextPost'
      );
      toCreate.add(fi);
    }
    uow.registerNew(toCreate);
  }
}
