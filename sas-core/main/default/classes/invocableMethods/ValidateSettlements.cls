public without sharing class ValidateSettlements {
  /*
   * Helper class to handle errors in flows
   */
  public class ValidationStatus {
    @InvocableVariable
    public Boolean isValid = true;
    @InvocableVariable
    public String errorMessage = '';

    public ValidationStatus() {
    }

    public ValidationStatus(String message) {
      this.isValid = false;
      this.errorMessage = message;
    }
  }
  /*
   * Checks if the settlement(s) are valid and ready to be submitted to approval.
   * If it is not valid it throws an error with a message of what has to be corrected.
   * @param settlementsToValidate a list with a list of settlements to be validated.
   */
  @InvocableMethod(label='Validate Settlements')
  public static List<ValidationStatus> validate(
    List<List<Settlement__c>> settlementsToValidate
  ) {
    Map<Id, Settlement__c> idsToSettlements = new Map<Id, Settlement__c>(
      settlementsToValidate[0]
    );
    Set<Id> keys = idsToSettlements.keySet();
    try {
      (new Settlements(SettlementsSelector.newInstance().selectById(keys)))
        .validate();
    } catch (Exception e) {
      return new List<ValidationStatus>{ new ValidationStatus(e.getMessage()) };
    }

    return new List<ValidationStatus>{ new ValidationStatus() };
  }
}