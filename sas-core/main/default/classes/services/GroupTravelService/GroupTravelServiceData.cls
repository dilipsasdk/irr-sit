public without sharing class GroupTravelServiceData {
  public class GroupTravelServiceException extends Exception {
  }

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'any-time' => 'Any Time',
    'morning' => 'Morning',
    'midmorning' => 'Midmorning',
    'afternoon' => 'Afternoon',
    'evening' => 'Evening',
    'credit-card' => 'Credit Card',
    'Invoice' => 'SAS Invoice',
    'regular' => 'Regular',
    'youth' => 'Youth',
    'sport' => 'Sports',
    'one-way' => 'One Way',
    'round-trip' => 'Round Trip',
    'return-from-other-destination' => 'Return From Another City',
    'go' => 'SAS Go',
    'plus' => 'SAS Plus',
    'business' => 'SAS Business'
  };

  public static String createGroupTravel(CreateGroupTravelRequest request) {
    Group_Travel_Request__c groupTravelRequest = createGroupTravelRequest(request);

    Case newCase = createCaseRecord(request, groupTravelRequest.Id);

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(newCase, dmlOptions);

    Case insertedCase = CasesSelector.newInstance().selectById(new Set<Id>{ newCase.Id })[0];

    return insertedCase.CaseNumber;
  }

  private static Group_Travel_Request__c createGroupTravelRequest(CreateGroupTravelRequest request) {
    CaseFormJSONV2.ContactDetails contactDetails = request.groupTravel.contactDetails;
    CaseFormJSONV2.travelersDetails travelersDetails = request.groupTravel.travelersDetails;
    CaseFormJSONV2.TravelDetails travelDetails = request.groupTravel.travelDetails;
    CaseFormJSONV2.SpecialRequests specialRequests = request.groupTravel.specialRequests;
    CaseFormJSONV2.sportCodeDetails sportsCodeDetails = request.groupTravel.sportCodeDetails;

    Group_Travel_Request__c groupTravelRequest = new Group_Travel_Request__c(
      Address__c = contactDetails.street != null ? contactDetails.street : '',
      Alternate_Departure_date__c = !String.isEmpty(travelDetails.alternativeDepartureDate) ? Date.valueOf(travelDetails.alternativeDepartureDate) : null,
      Alternate_Departure_time__c = !String.isEmpty(travelDetails.alternativeDepartureTime) ? jsonToPicklist.get(travelDetails.alternativeDepartureTime) : null,
      Alternate_Return_date__c = !String.isEmpty(travelDetails.alternativeReturnDate) ? Date.valueOf(travelDetails.alternativeReturnDate) : null,
      Alternate_Return_time__c = !String.isEmpty(travelDetails.alternativeReturnTime) ? jsonToPicklist.get(travelDetails.alternativeReturnTime) : null,
      Alternative_Dates__c = !String.isEmpty(travelDetails.alternativeReturnDate) || !String.isEmpty(travelDetails.alternativeDepartureDate) ? true : false,
      Association__c = !String.isEmpty(sportsCodeDetails.association) ? sportsCodeDetails.association : null,
      City__c = contactDetails.city,
      C_o_Address__c = !String.isEmpty(contactDetails.careOf) ? contactDetails.careOf : null,
      Comments_From_Customer__c = !String.isEmpty(travelDetails.travelDetailsComment) ? travelDetails.travelDetailsComment.trim() : null,
      Company_Code__c = !String.isEmpty(request.groupTravel.companyCode) ? request.groupTravel.companyCode : null,
      Country__c = request.groupTravel.groupCountryOfResedence,
      Departure_date__c = Date.valueOf(travelDetails.departureDate),
      Departure_time__c = jsonToPicklist.get(travelDetails.departureTime),
      Different_Return_City_Airport__c = travelDetails.returnFrom,
      Email__c = contactDetails.email,
      Extra_Bags__c = Integer.ValueOf(specialRequests.addBags) > 0 ? true : false,
      First_Name__c = contactDetails.firstName,
      Form_of_payment__c = jsonToPicklist.get(request.groupTravel.paymentDetails.paymentMethod),
      From_Airport__c = travelDetails.origin,
      Group_Type__c = jsonToPicklist.get(request.groupTravel.groupType),
      Have_Company_Code__c = request.groupTravel.companyCode != null ? true : false,
      Invoice_Agreement_With_SAS__c = !String.isEmpty(request.groupTravel.paymentDetails.invoiceAgreementNumber) ? true : false,
      Invoice_Agreement_Number__c = !String.isEmpty(request.groupTravel.paymentDetails.invoiceAgreementNumber) ? request.groupTravel.paymentDetails.invoiceAgreementNumber : null,
      Last_Name__c = contactDetails.lastName,
      Name = request.groupTravel.organizationName,
      Number_Of_Adults__c = Integer.ValueOf(travelersDetails.adults),
      Number_Of_Children__c = Integer.ValueOf(travelersDetails.children),
      Number_Of_Extra_Bags__c = Integer.ValueOf(specialRequests.addBags),
      Number_Of_Infants__c = Integer.ValueOf(travelersDetails.infants),
      Number_Of_Special_Assistance_Travellers__c = Integer.ValueOf(specialRequests.wheelchairs) + Integer.ValueOf(specialRequests.impairments),
      Number_Of_Special_Baggage__c = Integer.ValueOf(specialRequests.specialBaggage),
      Number_Of_Youths__c = Integer.ValueOf(travelersDetails.youths),
      Number_Of_Wheelchairs__c = Integer.ValueOf(specialRequests.wheelchairs),
      Other_Destinations_Of_Interest__c = !String.isEmpty(travelDetails.alternativeDestination1) || !String.isEmpty(travelDetails.alternativeDestination2)
        ? (travelDetails.alternativeDestination1 + '\r\n' + travelDetails.alternativeDestination2).trim()
        : '',
      Phone__c = contactDetails.phone,
      Postal_Code__c = contactDetails.postalCode,
      Return_date__c = !String.isEmpty(travelDetails.returnDate) ? Date.valueOf(travelDetails.returnDate) : null,
      Return_time__c = jsonToPicklist.get(travelDetails.returnTime),
      Special_Baggage__c = Integer.ValueOf(specialRequests.specialBaggage) > 0 ? true : false,
      Special_Baggage_Note__c = !String.isEmpty(specialRequests.specialBaggageDescription) ? specialRequests.specialBaggageDescription.trim() : null,
      Sport_Code__c = !String.isEmpty(sportsCodeDetails.sportsCode) ? sportsCodeDetails.sportsCode : null,
      To_Airport__c = travelDetails.destination,
      Travel_Class__c = jsonToPicklist.get(travelDetails.travelClass),
      Trip_Type__c = jsonToPicklist.get(travelDetails.tripType),
      Visual_or_hearing_assistance__c = Integer.ValueOf(specialRequests.impairments) > 0 ? true : false,
      Wheelchairs__c = Integer.ValueOf(specialRequests.wheelchairs) > 0 ? true : false
    );

    insert groupTravelRequest;
    return groupTravelRequest;
  }

  private static Case createCaseRecord(CreateGroupTravelRequest request, Id groupTravelId) {
    Id groupSalesQueueId = GroupsSelector.newInstance()
      .selectQueuesByDepartment(new Set<String>{ 'Group_Sales' })[0].Id;

    Case newCase = new Case(
      OwnerId = groupSalesQueueId,
      Group_Travel_Request__c = groupTravelId,
      Origin = request.origin,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
      Subject = 'Group Travel Request: ' + request.groupTravel.organizationName,
      SuppliedEmail = request.groupTravel.contactDetails.email,
      SuppliedName = request.groupTravel.contactDetails.firstName + ' ' + request.groupTravel.contactDetails.lastName,
      SuppliedPhone = request.groupTravel.contactDetails.phone,
      SuppliedFirstname__c = request.groupTravel.contactDetails.firstName,
      SuppliedLastname__c = request.groupTravel.contactDetails.lastName
    );

    return newCase;
  }
}
