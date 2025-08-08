public without sharing class SimilarCasesController {
  @AuraEnabled(cacheable=true)
  public static List<SimilarCasesJSON> getSimilarCasesForCase(String caseId) {
    List<SimilarCasesJSON> similarCases = new List<SimilarCasesJSON>();

    for (Case c : CasesSelector.newInstance().selectSimilarCasesById(caseId)) {
      similarCases.add(new SimilarCasesJSON(c));
    }
    for (
      CARE_Claim__c c : CAREClaimsSelector.newInstance()
        .selectSimilarCasesById(caseId)
    ) {
      similarCases.add(new SimilarCasesJSON(c));
    }

    return similarCases;
  }

  public class SimilarCasesJSON {
    @AuraEnabled
    public String type; // 'Case' | 'CARE_Claim__c'
    @AuraEnabled
    public Case caseData;
    @AuraEnabled
    public CARE_Claim__c claimData;

    SimilarCasesJSON(Case caseToCreateFrom) {
      this.type = 'Case';
      this.caseData = caseToCreateFrom;
    }

    SimilarCasesJSON(CARE_Claim__c careClaimToCreateFrom) {
      this.type = 'CARE_Claim__c';
      this.claimData = careClaimToCreateFrom;
    }
  }
}
