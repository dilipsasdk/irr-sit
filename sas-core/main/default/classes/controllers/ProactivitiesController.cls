public without sharing class ProactivitiesController {
  public class Proactivity {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String note;
    @AuraEnabled
    public String matchingReasons;
    @AuraEnabled
    public String type;

    Proactivity(Proactivity__c proactivity, String reason) {
      this.id = proactivity.Id;
      this.note = proactivity.Note__c;
      this.type = proactivity.Type__c;
      this.matchingReasons = reason;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Proactivity> getProactivitiesForRecord(
    String recordId,
    String objectApiName // Case or Settlement__c
  ) {
    String caseId = recordId;
    if (objectApiName == 'Settlement__c') {
      caseId = SettlementsSelector.newInstance()
          .selectByIdWithClaimFields(new Set<Id>{ recordId })[0]
        .Claim__r.Case__c;
    }

    ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
    List<Proactivity> proactivitiesWithMatchingReason = new List<Proactivity>();
    Map<Proactivity__c, String> proactivityToReason = proactivities.selectByCaseIdWithMatchingReasons(
      caseId
    );
    List<Proactivity__c> proactivitiesFound = new List<Proactivity__c>(
      proactivityToReason.keySet()
    );

    for (Proactivity__c p : proactivitiesFound) {
      String reasons = proactivityToReason.get(p);
      proactivitiesWithMatchingReason.add(new Proactivity(p, reasons));
    }

    return proactivitiesWithMatchingReason;
  }

  @AuraEnabled(cacheable=true)
  public static List<Case> getCasesForProactivity(String proactivityId) {
    return CasesSelector.newInstance().selectByProactivityId(proactivityId); // Limit here does not improve performance
  }

  @AuraEnabled(cacheable=true)
  public static List<Proactivity__c> getDuplicateProactivities(
    String recordId
  ) {
    return ProactivitiesSelector.newInstance()
      .getDuplicateProactivities(recordId);
  }
}
