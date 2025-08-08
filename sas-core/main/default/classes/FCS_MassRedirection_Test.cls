/**
 Test class for class FCS_MassRedirection
*/

@isTest(seeAllData=false)
public class FCS_MassRedirection_Test {
  @IsTest
  static void testMassRedirection() {
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);
    insert newCases;

    List<Id> lseCaseIds = new List<Id>();
    lseCaseIds.add(newCases[0].Id);

    FCS_MassRedirection.Requestcase requestcase = new FCS_MassRedirection.Requestcase();
    requestcase.caseIds = lseCaseIds;
    List<FCS_MassRedirection.Requestcase> lstRequestCases = new List<FCS_MassRedirection.Requestcase>();
    lstRequestCases.add(requestcase);
    Test.startTest();
    List<FCS_MassRedirection.Responsecase> lstResponseCase = FCS_MassRedirection.getRedirectionCases(
      lstRequestCases
    );
    Test.stopTest();
    System.assertEquals(newCases.size(), lstResponseCase[0].lstCases.size());
  }
}
