public without sharing class CallCenterAdminController {
  @AuraEnabled(cacheable=true)
  public static List<CallCenterAdminDTO> getContactCenterUsers() {
    List<CallCenterAdminDTO> result = new List<CallCenterAdminDTO>();

    List<GroupMember> l_groupMember = [
      SELECT Id, GroupId, Group.Name, UserOrGroupId
      FROM GroupMember
      WHERE group.type = 'contactcentergroup'
    ];
    Map<ID, GroupMember> m_groupMember = new Map<ID, GroupMember>();

    for (GroupMember gm : l_groupMember) {
      m_groupMember.put(gm.UserOrGroupId, gm);
    }

    List<PermissionSetLicenseAssign> l_permSetLicAssign = [
      SELECT AssigneeId, Assignee.Name
      FROM PermissionSetLicenseAssign
      WHERE
        PermissionSetLicense.PermissionSetLicenseKey = 'ServiceCloudVoicePsl'
        AND Assignee.IsActive = TRUE
    ];

    for (PermissionSetLicenseAssign psla : l_permSetLicAssign) {
      CallCenterAdminDTO ccad = new CallCenterAdminDTO();

      ccad.userName = psla.Assignee.Name;
      ccad.userId = psla.AssigneeId;
      if (m_groupMember.containsKey(psla.AssigneeId)) {
        ccad.contactCenterGroupName = m_groupMember.get(psla.AssigneeId)
          .Group.Name;
        ccad.contactCenterGroupNameId = m_groupMember.get(psla.AssigneeId)
          .GroupId;
      } else {
        ccad.contactCenterGroupName = '';
        ccad.contactCenterGroupNameId = '';
      }

      result.add(ccad);
    }

    return result;
  }

  @AuraEnabled
  public static void assignUserToContactCenterGroup(
    List<CallCenterAdminDTO> callCenterAdminDTO
  ) {
    List<Id> groupMembersToDelete = new List<Id>();
    List<Id> preloadMap = new List<Id>();

    for (CallCenterAdminDTO ccad : callCenterAdminDTO) {
      groupMembersToDelete.add(ccad.userId);
      preloadMap.add(ccad.contactCenterGroupNameId);
    }

    List<GroupMember> gmToDelete = [
      SELECT id, UserOrGroupId
      FROM groupmember
      WHERE
        UserOrGroupId IN :groupMembersToDelete
        AND group.type = 'ContactCenterGroup'
    ];

    // look for the callmappings
    preloadMap.addall(groupMembersToDelete);

    List<CallCenterRoutingMap> callCenterRoutingMap = [
      SELECT externalId, ReferenceRecordId
      FROM CallCenterRoutingMap
      WHERE ReferenceRecordId IN :preloadMap
    ];

    Map<String, String> m_callCenterRoutingMap = new Map<String, String>();
    for (CallCenterRoutingMap ccrm : callCenterRoutingMap) {
      m_callCenterRoutingMap.put(ccrm.ReferenceRecordId, ccrm.ExternalId);
    }

    String raw_request = '[';

    for (CallCenterAdminDTO ccad : callCenterAdminDTO) {
      String awsGroupId = m_callCenterRoutingMap.get(
          ccad.contactCenterGroupNameId
        )
        .substring(104);
      String awsUserId = m_callCenterRoutingMap.get(ccad.userId).substring(94);
      raw_request += '{"routingProfileId": "' + awsGroupId + '",';
      raw_request += '"userId": "' + awsUserId + '"},';
      m_callCenterRoutingMap.put(awsGroupId, ccad.contactCenterGroupNameId);
      m_callCenterRoutingMap.put(awsUserId, ccad.userId);
    }

    raw_request = raw_request.substring(0, raw_request.length() - 1);
    raw_request += ']';

    String API_PATH = 'callout:AWS_LAMBDA';
    HttpRequest req = new HttpRequest();
    req.setEndpoint(API_PATH);
    req.setMethod('POST');
    req.setBody(raw_request);
    Http http = new Http();
    HTTPResponse res = http.send(req);

    List<AwsLambdaResponse> result = AwsLambdaResponse.parse(res.getBody());

    Map<Id, Boolean> m_awsLambdaResponse = new Map<Id, Boolean>();
    for (AwsLambdaResponse aws : result) {
      m_awsLambdaResponse.put(
        m_callCenterRoutingMap.get(aws.userId),
        aws.success
      );
    }

    List<GroupMember> toAdd = new List<GroupMember>();
    for (CallCenterAdminDTO ccad : callCenterAdminDTO) {
      if (m_awsLambdaResponse.get(ccad.userId) == true) {
        GroupMember gm = new GroupMember();
        gm.GroupId = ccad.contactCenterGroupNameId;
        gm.UserOrGroupId = ccad.userId;
        toAdd.add(gm);
      }
    }

    insert toAdd;

    List<GroupMember> realToDelete = new List<GroupMember>();
    for (GroupMember toDel : gmToDelete) {
      if (m_awsLambdaResponse.get(toDel.UserOrGroupId) == true) {
        realToDelete.add(toDel);
      }
    }

    delete realToDelete;
  }

  @AuraEnabled(cacheable=true)
  public static List<Group> getContactCenterGroups() {
    return [
      SELECT Id, Name, DeveloperName
      FROM Group
      WHERE Type = 'ContactCenterGroup'
    ];
  }
}
