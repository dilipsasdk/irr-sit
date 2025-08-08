/**
@author Thippeswamy Aravinda
@date June-10-2021
@description : invoked from mass redirection flow 
*/

public class FCS_MassRedirection {
  @InvocableMethod(label='Get redirection Cases')
  public static List<Responsecase> getRedirectionCases(
    List<Requestcase> requestCases
  ) {
    List<Case> lstCses = [
      SELECT
        Id,
        Department__c,
        Team__c,
        IsRedirected__c,
        RecordTypeId,
        OwnerId,
        Status,
        CaseNumber
      FROM Case
      WHERE Id = :requestCases[0].caseIds
    ];

    Responsecase resCase = new Responsecase();
    resCase.lstCases = lstCses;
    List<Responsecase> lstresCases = new List<Responsecase>();
    lstresCases.add(resCase);
    return lstresCases;
  }

  public class Requestcase {
    @InvocableVariable
    public List<Id> caseIds;
  }

  public class Responsecase {
    @InvocableVariable
    public List<Case> lstCases;
  }
}
