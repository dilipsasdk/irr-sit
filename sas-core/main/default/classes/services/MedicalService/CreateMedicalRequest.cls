public without sharing class CreateMedicalRequest {
  public Medical medical { get; private set; }

  public class InvalidDataException extends Exception {
  }

  public class Medical {
    public String medicalType { get; private set; }
    public String bookingReference { get; private set; }
    public String email { get; private set; }
    public Set<Id> contentVersionIds { get; private set; }
    public CaseFormJSONV2.ContactDetails contactDetails { get; private set; }
    public CaseFormJSONV2.EquipmentDetails equipmentDetails { get; private set; }

    public Medical(CaseFormJSONV2.medical jsonData) {
      medicalType = jsonData.medicalType;
      bookingReference = jsonData.bookingReference;
      email = jsonData.email;

      if (jsonData.medicalType == 'medical-approval') {
        Set<Id> contentVersionIdsToCreate = new Set<Id>();
        for (String i : jsonData.contentVersionIds) {
          contentVersionIdsToCreate.add(Id.valueOf(i));
        }
        contentVersionIds = contentVersionIdsToCreate;
      } else if (jsonData.medicalType == 'oxygen-registration') {
        contactDetails = jsonData.contactDetails;
        equipmentDetails = jsonData.equipmentDetails;
      }
    }
  }

  public CreateMedicalRequest(CaseFormJSONV2 jsonData) {
    medical = new Medical(jsonData.formData.medical);
  }
}
