/**
    Handler for just in time user creation from a SAML assertion
    The class executes when using single sign on to login to the environment
*/
global class AD_SamlJitHandler implements Auth.SamlJitHandler {
  /**
        Custom exception thrown when errors occurs in the setup process
    */
  private class JitException extends Exception {
  }

  /**
        Permission type API name for type profile
    */
  private static final String PERMISSION_TYPE_PROFILE = 'Profile';
  /**
        Permission type API name for type user permission
    */
  private static final String PERMISSION_TYPE_USER_PERMISSION = 'User Permission';
  /**
        Permission type API name for type permission set
    */
  private static final String PERMISSION_TYPE_PERMISSION_SET = 'Permission Set';
  /**
        Permission type API name for type permission license
    */
  private static final String PERMISSION_TYPE_PERMISSION_LICENSE = 'Permission License';
  /**
        Permission type API name for type role
    */
  private static final String PERMISSION_TYPE_ROLE = 'Role';
  /**
        Permission type API name for type group
    */
  private static final String PERMISSION_TYPE_GROUP = 'Group';
  /**
        Permission type API name for type call center
    */
  private static final String PERMISSION_TYPE_CALL_CENTER = 'Call Center';
  /**
        AD role name associated with resets of permissions
    */
  private static final String AD_ROLE_RESET = 'RESET';
  /**
        AD role name associated with default permissions
    */
  private static final String AD_ROLE_DEFAULT = 'DEFAULT';
  /**
        Namespace of the SAML assertion
    */
  private static final String NS_ASSERTION = 'urn:oasis:names:tc:SAML:2.0:assertion';
  /**
        Permission type API name for Chatter group hello
    */
  private static final String PERMISSION_TYPE_CHATTER_GROUP = 'Collaboration Group';

  /**
        Configures the user details and sets the permission for the user.
        The mehtod work for both create and update of user
        @param userId The id of the user to setup (null in the case of creation)
        @param federationId The federation id of the user used to identify the user
        @param attributes Automatically identified attributes of the user in the SAML assertion
        @param assertion The base 64 encoded SAML assertion body
    */
  private User setupUser(
    Id userId,
    String federationId,
    Map<String, String> attributes,
    String assertion
  ) {
    AdInfo ai = extractADInfo(assertion);
    //Adding default permissions
    ai.addAdRole(AD_ROLE_DEFAULT);
    ai.loadLinkedRoles();
    ai.loadUserConfig();
    Id profileId = ai.loadProfileId();
    if (profileId == null)
      throw new JitException('No profile configured for the user');
    Id roleId = ai.loadRoleId();

    User u = userId != null
      ? [SELECT Id, Email, Alias, CallCenterId FROM User WHERE Id = :userId]
      : new User();
    if (userId == null) {
      u.DigestFrequency = 'N';
      u.DefaultGroupNotificationFrequency = 'N';
      u.LanguageLocaleKey = 'en_US';
      u.LocaleSidKey = 'sv_SE';
      u.TimeZoneSidKey = 'Europe/Berlin';
      u.UserPreferencesHideChatterOnboardingSplash = true;
      u.UserPreferencesHideSecondChatterOnboardingSplash = true;
      u.UserPreferencesHideSfxWelcomeMat = true;
      u.UserPreferencesLightningExperiencePreferred = true;
    }
    String email = attributes.get(
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
    );
    //Ensure email is not reset from sandbox invalid emails
    if (userId == null || u.Email != email + '.invalid')
      u.Email = email;
    u.EmailEncodingKey = 'UTF-8';
    u.EmailPreferencesAutoBcc = false;
    u.FederationIdentifier = federationId;
    u.FirstName = attributes.get(
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'
    );
    u.IsActive = true;
    u.LastName = attributes.get(
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
    );
    u.ProfileId = profileId;
    u.Username = email + getEnvironmentSuffix();
    u.UserRoleId = roleId;
    String sanitizedFirstName = StringUtils.sanitize(u.FirstName);
    String sanitizedLastName = StringUtils.sanitize(u.LastName);
    u.Alias =
      sanitizedFirstName.substring(0, 1) +
      (sanitizedLastName.length() >= 7
        ? sanitizedLastName.substring(0, 7)
        : sanitizedLastName);
    u.CallCenterId = ai.loadCallCenterId(u.CallCenterId);

    ai.setUserDetails(u);
    try {
      if (userId != null)
        update u;
      else
        insert u;
      ai.updateAssignments(u.Id);
    } catch (Exception e) {
      String userName = u.FirstName + u.LastName;
      C_Log.log(
        C_Log.Severity.Error.name(),
        e.getMessage(),
        e.getStackTraceString(),
        userName
      );
    }
    return u;
  }

  /**
        Extracts the roles provided by the AD assertion as an AD info object
        @param assertion The base 64 encoded SAML assertion body
        @return The AD info object
    */
  private static AdInfo extractADInfo(String assertion) {
    Set<String> adRoles = new Set<String>();
    Dom.Document doc = new Dom.Document();
    doc.load(EncodingUtil.base64Decode(assertion).toString());
    Dom.XmlNode root = doc.getRootElement();
    Dom.XmlNode[] attrNodes = root.getChildElement('Assertion', NS_ASSERTION)
      .getChildElement('AttributeStatement', NS_ASSERTION)
      .getChildElements();
    for (Dom.XmlNode attrNode : attrNodes) {
      if (
        attrNode.getName() == 'Attribute' &&
        attrNode.getAttribute('Name', null) ==
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups'
      ) {
        Dom.XmlNode[] attrValNodes = attrNode.getChildElements();
        for (Dom.XmlNode attrValNode : attrValNodes) {
          if (attrValNode.getName() == 'AttributeValue')
            adRoles.add(attrValNode.getText());
        }
      }
    }
    return new AdInfo(adRoles);
  }
  /** 
        Class representing the active directory information
    */
  private class AdInfo {
    /**
            The active directory roles for the user
        */
    Set<String> adRoles;
    /**
            The profile name
        */
    String profileName;
    /**
            The developer name of the role
        */
    String roleDevName;
    /**
            The name of the call center which to assign to the user
        */
    String callCenterName;
    /**
            The permission sets which to assign to the user
        */
    Set<String> inclPS;
    /**
            The permission licenses which to assign to the user
        */
    Set<String> inclPL;
    /** 
            The groups in which to include the user
        */
    Set<String> inclGroups;
    /**
           The Chatter group in which include the user
        */
    Set<String> inclChatterGroups;
    /**
            The permission sets from which to remove from the user
        */
    Set<String> exclPS;
    /**
            The permission licenses from which to remove from the user
        */
    Set<String> exclPL;
    /**
            The groups from which to exclude the user
        */
    Set<String> exclGroups;
    /**
          The Chatter group in whihc remove the user
        */
    Set<String> exclChatterGroups;
    /**
            THe call centers which should automatically be removed from the user
        */
    Set<String> exclCallCenters;
    /**
            User permissions set for the user
        */
    Map<String, Boolean> userPermissions = new Map<String, Boolean>();
    /**
            The user details to set for the user
        */
    Map<String, Object> userDetails;

    /**
            Creates an active directory info base instance
            @param adRoles The active directory roles for the user
        */
    private AdInfo(Set<String> adRoles) {
      this.adRoles = adRoles;
    }

    /**
            Adds an AD role as an included AD role
            @param adRole The name of the AD role to include
        */
    private void addAdRole(String adRole) {
      this.adRoles.add(adRole);
    }

    /**
            Loads all linked roles related to the currently added roles
        */
    private void loadLinkedRoles() {
      Boolean isTest = C_Util.isSandbox();
      AD_RoleLink__mdt[] arlList = [
        SELECT Id, RoleLinked__r.GroupId__c, Role__r.TestOnly__c
        FROM AD_RoleLink__mdt
        WHERE Role__r.GroupId__c IN :adRoles
      ];
      for (AD_RoleLink__mdt arl : arlList) {
        if (isTest || !arl.Role__r.TestOnly__c) {
          if (arl.RoleLinked__r.GroupId__c != null)
            adRoles.add(arl.RoleLinked__r.GroupId__c);
        }
      }
    }

    /**
            Loads the user configuration for the ad roles
        */
    private void loadUserConfig() {
      Boolean isTest = C_Util.isSandbox();
      inclPS = new Set<String>();
      inclPL = new Set<String>();
      inclGroups = new Set<String>();
      inclChatterGroups = new Set<String>();
      exclPS = new Set<String>();
      exclPL = new Set<String>();
      exclGroups = new Set<String>();
      exclChatterGroups = new Set<String>();
      exclCallCenters = new Set<String>();
      userPermissions = new Map<String, Boolean>();
      userDetails = new Map<String, Object>();

      //Loading permissions included under the users current AD role
      AD_Role__mdt[] arList = [
        SELECT
          Id,
          Priority__c,
          GroupId__c,
          TestOnly__c,
          (SELECT Id, MasterLabel, PermissionType__c FROM RolePermissions__r),
          (SELECT Id, MasterLabel, Value__c FROM RoleUserDetails__r)
        FROM AD_Role__mdt
        WHERE GroupId__c IN :adRoles
        ORDER BY Priority__c DESC
      ];
      for (AD_Role__mdt ar : arList) {
        if (isTest || !ar.TestOnly__c) {
          for (AD_RolePermission__mdt adp : ar.RolePermissions__r) {
            if (adp.PermissionType__c == PERMISSION_TYPE_PROFILE) {
              if (profileName == null)
                profileName = adp.MasterLabel;
            } else if (adp.PermissionType__c == PERMISSION_TYPE_ROLE) {
              if (roleDevName == null)
                roleDevName = adp.MasterLabel;
            } else if (
              adp.PermissionType__c == PERMISSION_TYPE_USER_PERMISSION
            ) {
              if (!userPermissions.containsKey(adp.MasterLabel))
                userPermissions.put(adp.MasterLabel, true);
            } else if (
              adp.PermissionType__c == PERMISSION_TYPE_PERMISSION_SET
            ) {
              inclPS.add(adp.MasterLabel);
            } else if (
              adp.PermissionType__c == PERMISSION_TYPE_PERMISSION_LICENSE
            ) {
              inclPL.add(adp.MasterLabel);
            } else if (adp.PermissionType__c == PERMISSION_TYPE_GROUP) {
              inclGroups.add(adp.MasterLabel);
            } else if (adp.PermissionType__c == PERMISSION_TYPE_CHATTER_GROUP) {
              inclChatterGroups.add(adp.MasterLabel);
            } else if (adp.PermissionType__c == PERMISSION_TYPE_CALL_CENTER) {
              if (callCenterName == null)
                callCenterName = adp.MasterLabel;
            }
          }
        }
      }

      //Loading permissions reset if not present under the users current AD role
      AD_Role__mdt arReset = [
        SELECT
          Id,
          GroupId__c,
          (SELECT Id, MasterLabel, PermissionType__c FROM RolePermissions__r)
        FROM AD_Role__mdt
        WHERE GroupId__c = :AD_ROLE_RESET
      ];
      for (AD_RolePermission__mdt adp : arReset.RolePermissions__r) {
        if (adp.PermissionType__c == PERMISSION_TYPE_USER_PERMISSION) {
          if (!userPermissions.containsKey(adp.MasterLabel))
            userPermissions.put(adp.MasterLabel, false);
        } else if (adp.PermissionType__c == PERMISSION_TYPE_PERMISSION_SET) {
          if (!inclPS.contains(adp.MasterLabel))
            exclPS.add(adp.MasterLabel);
        } else if (
          adp.PermissionType__c == PERMISSION_TYPE_PERMISSION_LICENSE
        ) {
          if (!inclPL.contains(adp.MasterLabel))
            exclPL.add(adp.MasterLabel);
        } else if (adp.PermissionType__c == PERMISSION_TYPE_GROUP) {
          if (!inclGroups.contains(adp.MasterLabel))
            exclGroups.add(adp.MasterLabel);
        } else if (adp.PermissionType__c == PERMISSION_TYPE_CHATTER_GROUP) {
          if (!inclChatterGroups.contains(adp.MasterLabel))
            exclChatterGroups.add(adp.MasterLabel);
        } else if (adp.PermissionType__c == PERMISSION_TYPE_CALL_CENTER) {
          if (adp.MasterLabel != callCenterName)
            exclCallCenters.add(adp.MasterLabel);
        }
      }

      //Retireving general user details to set for the user
      for (Integer i = arList.size() - 1; i >= 0; i--) {
        AD_Role__mdt ar = arList[i];
        if (isTest || !ar.TestOnly__c) {
          for (AD_RoleUserDetail__mdt ud : ar.RoleUserDetails__r) {
            if (ud.Value__c == 'false' || ud.Value__c == 'true')
              userDetails.put(ud.MasterLabel, ud.Value__c == 'true');
            else
              userDetails.put(ud.MasterLabel, ud.Value__c);
          }
        }
      }
    }

    /**
            @return The profile id for the user config profile name
        */
    private Id loadProfileId() {
      if (profileName == null)
        return null;
      Profile[] profileRec = [
        SELECT Id, Name
        FROM Profile
        WHERE Name = :profileName
      ];
      if (profileRec.size() == 0)
        throw new JitException(
          'Cannot find a profile with name: ' + profileName
        );
      return profileRec[0].Id;
    }

    /**
            @return The role id for the user config role name
        */
    private Id loadRoleId() {
      if (roleDevName == null)
        return null;
      UserRole[] roleRec = [
        SELECT Id
        FROM UserRole
        WHERE DeveloperName = :roleDevName
      ];
      if (roleRec.size() == 0)
        throw new JitException(
          'Cannot find a role with developer name: ' + roleDevName
        );
      return roleRec[0].Id;
    }

    /**
            Loads the call center id which to assign to the user
            @param currentCallCenterId The id of the user's current call center
            @return The updated call center id of the user
        */
    private Id loadCallCenterId(Id currentCallCenterId) {
      Set<String> allCallCenters = new Set<String>(exclCallCenters);
      if (callCenterName != null)
        allCallCenters.add(callCenterName);
      CallCenter[] ccList = [
        SELECT Id, InternalName
        FROM CallCenter
        WHERE InternalName IN :allCallCenters
      ];
      Id ccId = currentCallCenterId;
      for (CallCenter cc : ccList) {
        if (cc.InternalName == callCenterName)
          ccId = cc.Id;
        else if (ccId == cc.Id)
          ccId = null;
      }
      return ccId;
    }

    /**
            Sets the user details and permissions for the provided user
            @parma u The user record on which to set the detials and permissions
        */
    private void setUserDetails(User u) {
      for (String f : userDetails.keySet()) {
        u.put(f, userDetails.get(f));
      }
      for (String f : userPermissions.keySet()) {
        u.put(f, userPermissions.get(f));
      }
    }

    /**
            Updates the assigned permission sets and groups for the user
            @param userId The id of the user to update
        */
    private void updateAssignments(Id userId) {
      Set<String> allPS = new Set<String>();
      allPS.addAll(inclPS);
      allPS.addAll(exclPS);
      Set<String> allPL = new Set<String>();
      allPL.addAll(inclPL);
      allPL.addAll(exclPL);
      Set<String> allGroups = new Set<String>();
      allGroups.addAll(inclGroups);
      allGroups.addAll(exclGroups);
      List<PermissionSetAssignment> psaAddList = new List<PermissionSetAssignment>();
      List<PermissionSetAssignment> psaDelList = new List<PermissionSetAssignment>();
      List<PermissionSetLicenseAssign> plaAddList = new List<PermissionSetLicenseAssign>();
      List<PermissionSetLicenseAssign> plaDelList = new List<PermissionSetLicenseAssign>();
      List<GroupMember> gmAddList = new List<GroupMember>();
      List<GroupMember> gmDelList = new List<GroupMember>();

      //Get current permission set license assignments
      PermissionSetLicenseAssign[] plaList = [
        SELECT Id, AssigneeId, PermissionSetLicenseId
        FROM PermissionSetLicenseAssign
        WHERE AssigneeId = :userId
      ];
      Map<Id, PermissionSetLicenseAssign> plaMap = new Map<Id, PermissionSetLicenseAssign>();
      for (PermissionSetLicenseAssign pla : plaList) {
        plaMap.put(pla.PermissionSetLicenseId, pla);
      }
      //Get all referenced permission sets
      PermissionSetLicense[] plList = [
        SELECT Id, DeveloperName
        FROM PermissionSetLicense
        WHERE DeveloperName IN :allPL
      ];
      for (PermissionSetLicense pl : plList) {
        PermissionSetLicenseAssign pla = plaMap.get(pl.Id);
        if (inclPL.contains(pl.DeveloperName)) {
          if (pla == null)
            plaAddList.add(
              new PermissionSetLicenseAssign(
                AssigneeId = userId,
                PermissionSetLicenseId = pl.Id
              )
            );
        } else if (exclPL.contains(pl.DeveloperName)) {
          if (pla != null)
            plaDelList.add(pla);
        }
      }

      //Get current permission set and permission set group assignments
      PermissionSetAssignment[] psaList = [
        SELECT Id, AssigneeId, PermissionSetGroupId, PermissionSetId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :userId
      ];
      Map<Id, PermissionSetAssignment> psaMap = new Map<Id, PermissionSetAssignment>();
      for (PermissionSetAssignment psa : psaList) {
        psaMap.put(psa.PermissionSetId, psa);
      }
      //Get all referenced permission sets
      PermissionSet[] psList = [
        SELECT Id, Name, PermissionSetGroupId
        FROM PermissionSet
        WHERE Name IN :allPS
      ];
      for (PermissionSet ps : psList) {
        PermissionSetAssignment psa = psaMap.get(ps.Id);
        if (inclPS.contains(ps.Name)) {
          if (psa == null)
            psaAddList.add(
              new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = ps.Id,
                PermissionSetGroupId = ps.PermissionSetGroupId
              )
            );
        } else if (exclPS.contains(ps.Name)) {
          if (psa != null)
            psaDelList.add(psa);
        }
      }

      //Get current group members of
      GroupMember[] gmList = [
        SELECT Id, UserOrGroupId, GroupId
        FROM GroupMember
        WHERE UserOrGroupId = :userId
      ];
      Map<Id, GroupMember> gmMap = new Map<Id, GroupMember>();
      for (GroupMember gm : gmList) {
        gmMap.put(gm.GroupId, gm);
      }

      //Get all referenced groups
      Group[] groupList = [
        SELECT Id, DeveloperName, Type
        FROM Group
        WHERE DeveloperName IN :allGroups AND Type = 'Regular'
      ];
      for (Group g : groupList) {
        GroupMember gm = gmMap.get(g.Id);
        if (inclGroups.contains(g.DeveloperName)) {
          if (gm == null)
            gmAddList.add(
              new GroupMember(UserOrGroupId = userId, GroupId = g.Id)
            );
        } else if (exclGroups.contains(g.DeveloperName)) {
          if (gm != null)
            gmDelList.add(gm);
        }
      }
      insert plaAddList;
      insert psaAddList;
      insert gmAddList;
      delete gmDelList;
      delete psaDelList;
      delete plaDelList;
      chatGrpAssignment(inclChatterGroups, exclChatterGroups, userId);
    }
  }

  /**
        Retrieves the default environment suffix to use for users
        @return The environment suffix of the user
    */
  private static String getEnvironmentSuffix() {
    if (!C_Util.isSandbox())
      return '';
    //Check if scratch org
    if (UserInfo.getLastName() == 'User' && UserInfo.getFirstName() == 'User')
      return '.' + C_Util.getUUID().substring(0, 6);
    String uname = UserInfo.getUserName();
    return '.' + uname.substring(uname.lastIndexOf('.') + 1);
  }

  /**
        Called by the single sign on configuration when a new user should be created
        @param samlSsoProviderId The ID of the SamlSsoConfig standard object (not used)
        @param communityId The ID of the community of the user (always null since no community users are created)
        @param portalId The ID of the portal of the user (always null since no community users are created)
        @param federationId The federation id of the user used to identify the user
        @param attributes Automatically identified attributes of the user in the SAML assertion
        @param assertion The base 64 encoded SAML assertion body
        @return The created user record
    */
  global User createUser(
    Id samlSsoProviderId,
    Id communityId,
    Id portalId,
    String federationId,
    Map<String, String> attributes,
    String assertion
  ) {
    return setupUser(null, federationId, attributes, assertion);
  }

  /**
        Called by the single sign on configuration when a user is identified and should be updated
        @param samlSsoProviderId The ID of the SamlSsoConfig standard object (not used)
        @param communityId The ID of the community of the user (always null since no community users are created)
        @param portalId The ID of the portal of the user (always null since no community users are created)
        @param federationId The federation id of the user used to identify the user
        @param attributes Automatically identified attributes of the user in the SAML assertion
        @param assertion The base 64 encoded SAML assertion body
    */
  global void updateUser(
    Id userId,
    Id samlSsoProviderId,
    Id communityId,
    Id portalId,
    String federationId,
    Map<String, String> attributes,
    String assertion
  ) {
    setupUser(userId, federationId, attributes, assertion);
  }
  /**
     called by the Update assignment for chatterGroup assignment
     Set up and non Set up object DML operation can't be performed in single transaction
     So future method introduced
     @param inclChatterGroups the set of chatter groups in which login user will be assigned.
     @param inclChatterGroups the set of chatter groups in which login user will be excluded.
     @param Id of the User
    */
  @future
  public static void chatGrpAssignment(
    Set<String> inclChatterGroups,
    set<String> exclChatterGroups,
    Id userId
  ) {
    List<CollaborationGroupMember> cgmAddList = new List<CollaborationGroupMember>();
    List<CollaborationGroupMember> cgmDelList = new List<CollaborationGroupMember>();
    Set<String> allChatterGroups = new Set<String>();
    allChatterGroups.addAll(inclChatterGroups);
    allChatterGroups.addAll(exclChatterGroups);

    // Get current chatter group members of
    CollaborationGroupMember[] cgmList = [
      SELECT CollaborationGroupId, CollaborationRole, Id, MemberId
      FROM CollaborationGroupMember
      WHERE MemberId = :userId
    ];
    Map<Id, CollaborationGroupMember> cgmMap = new Map<Id, CollaborationGroupMember>();
    for (CollaborationGroupMember cgm : cgmList) {
      cgmMap.put(cgm.CollaborationGroupId, cgm);
    }

    //Get all refrenced chatter groups
    CollaborationGroup[] chatgroupList = [
      SELECT Id, Name
      FROM CollaborationGroup
      WHERE Name IN :allChatterGroups
    ];
    for (CollaborationGroup cg : chatgroupList) {
      CollaborationGroupMember cgm = cgmMap.get(cg.Id);
      if (inclChatterGroups.contains(cg.Name)) {
        if (cgm == null)
          cgmAddList.add(
            new CollaborationGroupMember(
              MemberId = userId,
              CollaborationGroupId = cg.Id
            )
          );
      } else if (exclChatterGroups.contains(cg.Name)) {
        if (cgm != null)
          cgmDelList.add(cgm);
      }
    }

    insert cgmAddList;
    delete cgmDelList;
  }
}
