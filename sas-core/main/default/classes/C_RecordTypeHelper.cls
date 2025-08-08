/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description  Helper class to simplify retrieval and usage of record types in apex. (New record types still need to be correctly conigured in this class to be supported)
    The class can be used directly as it is lazy initialized upon use by a static block.
    Example of use: C_RecordTypeHelper.CASE_INFORMATION
 */
public with sharing class C_RecordTypeHelper {
  /**
    Static variables to store id of record types on case object
    */

  @TestVisible
  public static final Id CASE_INTERNAL_BACKOFFICE;
  @TestVisible
  public static final Id CASE_CHANNEL;
  @TestVisible
  public static final Id CASE_CHAT;

  /**
    Static variables to store id of record types on account object
    */
  @TestVisible
  public static final Id ACCOUNT_PERSON_EBCUSTOMER;
  @TestVisible
  public static final Id ACCOUNT_PERSON_ANONYMOUS;

  /**
   * Static variables to store id of record types on contact object
   */
  @TestVisible
  public static final Id CONTACT_EMAILCONTACT;

  static {
    RecordType[] rtList = [
      SELECT Id, SobjectType, DeveloperName
      FROM RecordType
      WHERE SobjectType IN ('Case', 'Account', 'Contact')
    ];
    for (Integer i = 0, sz = rtList.size(); i < sz; i++) {
      RecordType rt = rtList[i];
      if (rt.SobjectType == 'Case') {
        if (rt.DeveloperName == 'Internal_Backoffice')
          CASE_INTERNAL_BACKOFFICE = rt.Id;
        if (rt.DeveloperName == 'Channel')
          CASE_CHANNEL = rt.Id;
       if (rt.DeveloperName == 'chat')
          CASE_CHAT = rt.Id;
      } else if (rt.SobjectType == 'Account') {
        if (rt.DeveloperName == 'EBCustomer')
          ACCOUNT_PERSON_EBCUSTOMER = rt.Id;
        if (rt.DeveloperName == 'AnonymousCustomer')
          ACCOUNT_PERSON_ANONYMOUS = rt.Id;
      } else if (rt.SobjectType == 'Contact') {
        if (rt.DeveloperName == 'EmailContact')
          CONTACT_EMAILCONTACT = rt.Id;
      }
    }
  }
}