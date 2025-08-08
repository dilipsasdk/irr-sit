public without sharing class CreateGroupTravelRequest {
  public GroupTravel groupTravel { get; private set; }
  public String origin { get; private set; }

  public class CreateGroupTravelRequestException extends Exception {
  }

  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Group Travel DK',
    'no-no' => 'Form - Group Travel NO',
    'se-sv' => 'Form - Group Travel SE',
    'be-en' => 'Form - Group Travel BE',
    'fi-en' => 'Form - Group Travel FI',
    'fr-fr' => 'Form - Group Travel FR',
    'de-de' => 'Form - Group Travel DE',
    'ie-en' => 'Form - Group Travel IE',
    'it-en' => 'Form - Group Travel IT',
    'nl-en' => 'Form - Group Travel NL',
    'pl-en' => 'Form - Group Travel PL',
    'ru-ru' => 'Form - Group Travel RU',
    'es-es' => 'Form - Group Travel ES',
    'ch-de' => 'Form - Group Travel CH-de',
    'ch-fr' => 'Form - Group Travel CH-fr',
    'gb-en' => 'Form - Group Travel GB',
    'us-en' => 'Form - Group Travel US',
    'lu-en' => 'Form - Group Travel LU',
    'default' => 'Form - Group Travel GB'
  };

  public class GroupTravel {
    public String groupType { get; private set; }
    public String groupCountryOfResedence { get; private set; }
    public String organizationName { get; private set; }
    public String companyCode { get; private set; }
    public CaseFormJSONV2.SportCodeDetails sportCodeDetails { get; private set; }
    public CaseFormJSONV2.TravelDetails travelDetails { get; private set; }
    public CaseFormJSONV2.TravelersDetails travelersDetails { get; private set; }
    public CaseFormJSONV2.ContactDetails contactDetails { get; private set; }
    public CaseFormJSONV2.SpecialRequests specialRequests { get; private set; }
    public CaseFormJSONV2.PaymentDetails paymentDetails { get; private set; }

    public GroupTravel (CaseFormJSONV2.GroupTravelRequest jsonData) {
      groupType = jsonData.groupType;
      groupCountryOfResedence = jsonData.groupCountryOfResedence;
      organizationName = jsonData.organizationName;
      companyCode = jsonData.companyCode;
      sportCodeDetails = jsonData.sportCodeDetails;
      travelDetails = jsonData.travelDetails;
      travelersDetails = jsonData.travelersDetails;
      contactDetails = jsonData.contactDetails;
      specialRequests = jsonData.specialRequests;
      paymentDetails = jsonData.paymentDetails;
    }
  }

  public CreateGroupTravelRequest(CaseFormJSONV2 jsonData) {
    groupTravel = new GroupTravel(jsonData.formData.groupTravel);
    origin = marketToOrigin.get(jsonData.metaData.market);
  }
}
