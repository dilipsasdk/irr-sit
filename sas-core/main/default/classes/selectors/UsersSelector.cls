public inherited sharing class UsersSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      User.AboutMe,
      User.IsActive,
      User.Address,
      User.ReceivesAdminInfoEmails,
      User.Alias,
      User.ForecastEnabled,
      User.CallCenterId,
      User.FCS_ChatName__c,
      User.DigestFrequency,
      User.CompanyName,
      User.ContactId,
      User.FCS_CustomChatName__c,
      User.DefaultGroupNotificationFrequency,
      User.DelegatedApproverId,
      User.Department,
      User.Division,
      User.EmailEncodingKey,
      User.SenderEmail,
      User.SenderName,
      User.Signature,
      User.Extension,
      User.Fax,
      User.IsProfilePhotoActive,
      User.ReceivesInfoEmails,
      User.LanguageLocaleKey,
      User.LocaleSidKey,
      User.ManagerId,
      User.MobilePhone,
      User.FirstName,
      User.LastName,
      User.MiddleName,
      User.Suffix,
      User.CommunityNickname,
      User.OutOfOfficeMessage,
      User.Phone,
      User.ProfileId,
      User.UserRoleId,
      User.FederationIdentifier,
      User.IsExtIndicatorVisible,
      User.FCS_Site__c,
      User.StayInTouchSignature,
      User.StayInTouchSubject,
      User.FCS_SubTeam__c,
      User.FCS_Team__c,
      User.TimeZoneSidKey,
      User.Title,
      User.MediumBannerPhotoUrl,
      User.BannerPhotoUrl,
      User.SmallBannerPhotoUrl,
      User.MediumPhotoUrl,
      User.Username,
      User.FCS_Vendor__c,
      User.FCS_VirtualOrganization__c,
      User.Name
    };
  }

  public Schema.SObjectType getSObjectType() {
    return User.SObjectType;
  }

  public static UsersSelector newInstance() {
    return (UsersSelector) SAS_Service_Application.Selector.newInstance(
      User.SObjectType
    );
  }

  public List<User> selectById(Set<Id> ids) {
    return (List<User>) selectSObjectsById(ids);
  }
}
