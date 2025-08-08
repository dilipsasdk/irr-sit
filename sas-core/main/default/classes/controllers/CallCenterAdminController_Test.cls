//Unable to create test data in scratch org, so we skip running these tests there
@isTest(SeeAllData=true)
public class CallCenterAdminController_Test {
  @isTest
  static void testGetContactCenterUsers() {
    if (C_Util.isSandbox()) {
      System.Assert.isTrue(true);
      return;
    }
    System.Test.startTest();
    List<CallCenterAdminDTO> ret = CallCenterAdminController.getContactCenterUsers();
    System.Test.stopTest();

    System.Assert.isTrue(ret.size() > 0);
  }

  @isTest
  static void testGetContactCenterGroups() {
    if (C_Util.isSandbox()) {
      System.Assert.isTrue(true);
      return;
    }
    System.Test.startTest();
    List<Group> ret = CallCenterAdminController.getContactCenterGroups();
    System.Test.stopTest();

    System.Assert.isTrue(ret.size() > 0);
  }

  @isTest
  static void assignUserToContactCenterGroup() {
    if (C_Util.isSandbox()) {
      System.Assert.isTrue(true);
      return;
    }
    List<CallCenterAdminDTO> ccads = CallCenterAdminController.getContactCenterUsers();

    List<CallCenterAdminDTO> res = new List<CallCenterAdminDTO>();

    for (CallCenterAdminDTO ccad : ccads) {
      if (ccad.contactCenterGroupNameId != '' && ccad.userId != '') {
        res.add(ccad);
        break;
      }
    }

    /*CallCenterAdminDTO ccad = new CallCenterAdminDTO();
        ccad.userId = users[0].Id;
        ccad.contactCenterGroupNameId = groups[0].Id;
        res.add(ccad);
        
        ccad = new CallCenterAdminDTO();
        ccad.userId = users[1].Id;
        ccad.contactCenterGroupNameId = groups[1].Id;
        res.add(ccad);
        
        ccad = new CallCenterAdminDTO();
        ccad.userId = users[2].Id;
        ccad.contactCenterGroupNameId = groups[2].Id;
        res.add(ccad);*/

    System.Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new CallCenterAdminController_TestMock()
    );
    CallCenterAdminController.assignUserToContactCenterGroup(res);
    System.Test.stopTest();
  }
}
