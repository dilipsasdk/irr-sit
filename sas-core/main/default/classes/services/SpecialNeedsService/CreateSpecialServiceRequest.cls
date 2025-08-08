public without sharing class CreateSpecialServiceRequest {
  public SpecialServiceRequest specialServiceRequest { get; private set; }
  public String origin { get; private set; }

  public class CreateSpecialServiceRequestException extends Exception {
  }

  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - SSR DK',
    'no-no' => 'Form - SSR NO',
    'se-sv' => 'Form - SSR SE',
    'default' => 'Form - SSR International'
  };

  public class SpecialServiceRequest {
    public CaseFormJSONV2.ContactDetails contactDetails { get; private set; }
    public Boolean sightDisability { get; private set; }
    public Boolean hearingDisability { get; private set; }
    public Boolean mobilityImpairment { get; private set; }
    public String mobilityAsssistanceType { get; private set; }
    public Boolean bringYourOwnWheelchair { get; private set; }
    public String wheelchairType { get; private set; }
    public CaseFormJSONV2.WheelchairSize wheelchairSize { get; private set; }
    public Boolean cognitiveImpairment { get; private set; }
    public String cognitiveImpairmentType { get; private set; }
    public Boolean serviceAnimal { get; private set; }
    public String serviceAnimalType { get; private set; }

    public SpecialServiceRequest(CaseFormJSONV2.SpecialServiceRequest jsonData) {
      contactDetails = jsonData.contactDetails;
      sightDisability = jsonData.sightDisability;
      hearingDisability = jsonData.hearingDisability;
      mobilityImpairment = jsonData.mobilityImpairment;
      mobilityAsssistanceType = jsonData.mobilityAsssistanceType;
      bringYourOwnWheelchair = jsonData.bringYourOwnWheelchair;
      wheelchairType = jsonData.wheelchairType;
      wheelchairSize = jsonData.wheelchairSize;
      cognitiveImpairment = jsonData.cognitiveImpairment;
      cognitiveImpairmentType = jsonData.cognitiveImpairmentType;
      serviceAnimal = jsonData.serviceAnimal;
      serviceAnimalType = jsonData.serviceAnimalType;
    }
  }

  public CreateSpecialServiceRequest(CaseFormJSONV2 jsonData) {
    String getOrigin = marketToOrigin.get(jsonData.metaData.market);

    specialServiceRequest = new SpecialServiceRequest(jsonData.formData.specialServiceRequest);
    origin = !String.isEmpty(getOrigin) ? getOrigin : 'Form - SSR International';
  }
}
