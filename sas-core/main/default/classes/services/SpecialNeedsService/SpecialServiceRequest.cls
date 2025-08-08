public without sharing class SpecialServiceRequest {
  public class SpecialServiceRequestException extends Exception {
  }

  private static String type = '';

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'WCHR' => 'WCHR Ramp',
    'WCHS' => 'WCHS Steps',
    'WCHC' => 'WCHC Carry',
    'WCBD' => 'Dry Battery Wheelchair (WCBD)',
    'WCBW' => 'Wet Battery Wheelchair (WCBW)',
    'WCLB' => 'Lithium Battery Wheelchair (WCLB)',
    'WCMP' => 'Manual Power Wheelchair (WCMP)',
    'downs-syndrome'  => 'Downs syndrome',
    'cerebral-palsy' => 'Cerebral palsy',
    'autism' => 'Autism',
    'tourrettes-syndrome' => 'Tourrette syndrome',
    'NA' => 'Not applicable'
  };

  private static Map<String, String> serviceAnimalType = new Map<String, String>{
    'seeing-eye-dog' => 'Seeing eye dog',
    'service-dog' => 'Service dog for e.g. cognitive impairment',
    'hearing-aid-dog' => 'Hearing aid dog',
    'diabetic-aid-dog' => 'Diabetic aid dog'
  };

  public static String createSpecialService(CreateSpecialServiceRequest request) {
    Special_Service_Request__c specialServiceRequest = createSpecialServiceRequest(request);

    Case newCase = createCaseRecord(request, specialServiceRequest);

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(newCase, dmlOptions);

    Case insertedCase = CasesSelector.newInstance().selectById(new Set<Id>{ newCase.Id })[0];

    return insertedCase.CaseNumber;
  }

  private static Special_Service_Request__c createSpecialServiceRequest(CreateSpecialServiceRequest request) {
    CaseFormJSONV2.ContactDetails contactDetails = request.specialServiceRequest.contactDetails;
    CaseFormJSONV2.WheelchairSize wheelchairSize = request.specialServiceRequest.wheelchairSize;

    String typeOfSpecialAssistance = '';
    String mobilityDimensions = '';

    if (request.specialServiceRequest.mobilityImpairment) {
      type = 'Mobility';

      if (request.specialServiceRequest.bringYourOwnWheelchair == true) {
        mobilityDimensions =
        'Width: ' +
        wheelchairSize.width +
        ' cm, Height: ' +
        wheelchairSize.height +
        ' cm, Depth: ' +
        wheelchairSize.depth +
        ' cm, Weight: ' +
        wheelchairSize.weight +
        ' kg.';
      }

      if (!String.isEmpty(request.specialServiceRequest.mobilityAsssistanceType)) {
        typeOfSpecialAssistance = jsonToPicklist.get(request.specialServiceRequest.mobilityAsssistanceType);
      }
    }

    if (!String.isEmpty(request.specialServiceRequest.serviceAnimalType)) {
      type = 'Service Animal';
    }

    if (request.specialServiceRequest.hearingDisability == true || request.specialServiceRequest.sightDisability) {
      type = 'Special Assistance';

      if (request.specialServiceRequest.hearingDisability == true) {
        typeOfSpecialAssistance = 'Hearing disability';
      } else if (request.specialServiceRequest.sightDisability == true) {
        typeOfSpecialAssistance = 'Sight disability';
      }
    }

    if (request.specialServiceRequest.cognitiveImpairment == true) {
      type = 'Cognitive Impairment';
      typeOfSpecialAssistance = jsonToPicklist.get(request.specialServiceRequest.cognitiveImpairmentType);
    }

    Special_Service_Request__c specialServiceRequest = new Special_Service_Request__c(
      Brings_Own_Mobility_Device__c = request.specialServiceRequest.bringYourOwnWheelchair,
      Email__c = contactDetails.email,
      First_Name__c = contactDetails.firstName,
      Last_Name__c = contactDetails.lastName,
      Mobility_Device_Dimensions__c = mobilityDimensions,
      Mobility_Device_Type__c = jsonToPicklist.get(request.specialServiceRequest.wheelchairType),
      Passenger_Needing_Assistance__c = contactDetails.firstName + ' ' + contactDetails.lastName,
      Phone__c = contactDetails.phone,
      PNR__c = contactDetails.pnr,
      Type__c = type,
      Type_Of_Service_Animal__c = serviceAnimalType.get(request.specialServiceRequest.serviceAnimalType),
      Type_Of_Special_Assistance__c = typeOfSpecialAssistance
    );

    insert specialServiceRequest;
    return specialServiceRequest;
  }

  private static Case createCaseRecord(CreateSpecialServiceRequest request, Special_Service_Request__c specialServiceRequest) {
    Id salesControlQueueId = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Sales_Control_BOM' })[0].Id;

    Case newCase = new Case(
      OwnerId = salesControlQueueId,
      Origin = request.origin,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
      Subject = 'SSR, Type: ' + type + ', PNR:' + request.specialServiceRequest.contactDetails.pnr,
      SuppliedEmail = request.specialServiceRequest.contactDetails.email,
      SuppliedName = request.specialServiceRequest.contactDetails.firstName + ' ' + request.specialServiceRequest.contactDetails.lastName,
      SuppliedPhone = request.specialServiceRequest.contactDetails.phone,
      Special_Service_Request__c = specialServiceRequest.Id,
      SSR_Type_Of_Service_Animal__c = specialServiceRequest.Type_Of_Service_Animal__c
    );

    return newCase;
  }
}