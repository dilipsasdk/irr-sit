/**
 * @author Philip Ossler
 * @date 2020-04-22
 * @description Test class for FCS_SocialPostController class, Visualforce Pages (FCS_SocialPostRemoveOwnershipButton, FCS_SocialPostTakeOwnershipButton) and Process Builder
 */
@isTest
private class FCS_SocialPostControllerTest {
  @testSetup
  static void testSetup() {
    Profile p = [SELECT id FROM Profile WHERE Name = 'Vendor'];
    Group g = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
      LIMIT 1
    ];

    User u = new User(
      Alias = 'test',
      Email = 'test@test.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'test',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'sv_SE',
      ProfileId = p.Id,
      TimeZoneSidKey = 'Europe/Paris',
      UserName = 'test@test.com.flysas'
    );
    insert u;

    SocialPost sp1 = new SocialPost(Name = 'Test1', OwnerId = g.Id);
    insert sp1;

    SocialPost sp2 = new SocialPost(Name = 'Test2', OwnerId = g.Id);
    insert sp2;
  }

  /**
   * Test for Take Ownership button in Social Post listviews
   */
  @isTest
  static void takeOwnershipTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User u = [SELECT Id FROM User WHERE Alias = 'test'];
    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'SocialMediaUser'
    ];
    Group g = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
      LIMIT 1
    ];
    List<SocialPost> spList = [
      SELECT Id, Name, OwnerId, FCS_PreviousQueue__c
      FROM SocialPost
    ];

    System.runAs(thisUser) {
      PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = u.id,
        PermissionSetId = ps.Id
      );
      insert psa;
    }

    System.runAs(u) {
      Test.startTest();
      ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(
        spList
      );
      setCon.setSelected(spList);
      FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
      ext.takeOwnership();
      Test.stopTest();
    }

    List<SocialPost> spListUpdated = [
      SELECT Id, Name, OwnerId, FCS_PreviousQueue__c
      FROM SocialPost
    ];

    //Assert to check if Owner has been assigned to running user
    System.assertEquals(u.Id, spListUpdated[0].OwnerId);
    System.assertEquals(u.Id, spListUpdated[1].OwnerId);

    //Assert of Social Post Process Builder to set PreviousQueue
    System.assertEquals(g.Id, spList[0].FCS_PreviousQueue__c);
    System.assertEquals(g.Id, spList[1].FCS_PreviousQueue__c);
  }

  /**
   * Test for Remove Ownership button in Social Post listviews
   */
  @isTest
  static void removeOwnershipTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User u = [SELECT Id FROM User WHERE Alias = 'test'];
    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'SocialMediaUser'
    ];
    Group g = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
      LIMIT 1
    ];
    List<SocialPost> spList = [SELECT Id, Name, OwnerId FROM SocialPost];

    System.runAs(thisUser) {
      PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = u.id,
        PermissionSetId = ps.Id
      );
      insert psa;

      for (SocialPost sp : spList) {
        sp.OwnerId = u.Id;
        sp.FCS_PreviousQueue__c = g.Id;
      }
      update spList;
    }

    System.runAs(u) {
      Test.startTest();
      ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(
        spList
      );
      setCon.setSelected(spList);
      FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
      ext.removeOwnership();
      Test.stopTest();
    }

    List<SocialPost> spListUpdated = [
      SELECT Id, Name, OwnerId, FCS_PreviousQueue__c
      FROM SocialPost
    ];

    //Assert to check if Owners has been removed and assigned back to PreviousQueue
    System.assertEquals(g.Id, spListUpdated[0].OwnerId);
    System.assertEquals(g.Id, spListUpdated[1].OwnerId);
  }

  /**
   * Test for no selected records in listview
   */
  @isTest
  static void noSelectedRecordsTest() {
    User u = [SELECT Id FROM User WHERE Alias = 'test'];
    List<SocialPost> spList = new List<SocialPost>();

    System.runAs(u) {
      Test.startTest();
      ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(
        spList
      );
      FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
      ext.takeOwnership();
      ext.removeOwnership();
      Test.stopTest();

      System.assert(setCon.getSelected().isEmpty(), 'No selected records');
    }
  }
}
