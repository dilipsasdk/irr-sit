/**
 * @author Anton Norell
 * @date 2019-10-01
 * @description Controller for component used to identify a customer from a Salesforce record. Includes methods
 * to retrieve data and create data.
 */
public without sharing class FCS_IdentifyCustomerController {
  /**
   * Used to handle request to find a customer from the component. A list of frequent flyer record is fetched by
   * a query, and then the first record in the list is synced to a corresponding account record in Salesforce.
   * If the account already exists it is updated, otherwise created.
   * @param searchField Field on Frequent Flyer object to use as filter to retrieve customer, e.g. EBNumber__c
   * @param searchValue Value for the search field, e.g. a EuroBonus number
   * @return If an account is found it is returned, otherwise null,
   */
  @AuraEnabled
  public static Account findCustomer(String searchField, String searchValue) {
    // We should not search for EB accounts for SAS internal email addresses.
    // Several test accounts in production data have internal users' email
    // addresses as their profile email, and we don't want to surface those
    // in Salesforce.
    // 
    // We also don't want to search for accounts with empty search values
    // (the method can be called outside of the component)

    List<String> excludedEmailDomains = new List<String>{
      '@sas.dk',
      '@sas.no',
      '@sas.se'
    };

    if (searchField == null || searchValue == null || searchValue == '' || excludedEmailDomains.contains(searchValue)) {
      return null;
    }
    
    Account createdAccount;
    String query =
      'SELECT Id, ExternalId, AddressLine1__c, AddressLine2__c, AddressLine3__c, BirthDate__c, ' +
      'City__c, ConsentTelemarketing__c, ConsentEB0__c, ConsentSMS__c, ConsentEB__c, ConsentEmail__c, ' +
      'CountryCode__c, CountyState__c, EmailPersonal__c, EBBalance__c, EBLevel__c, EBNumber__c, CMP__c, ' +
      'FirstName__c, LastName__c, Gender__c, EBMemberSinceDate__c, Mobile__c, Name__c, Phone__c, ' +
      'EBMbrshipLvlStatusStartDate__c, EBMbrshipLvlStatusEndDate__c, EBReachesNextLevelPoints__c, ' +
      'SubscriptionId__c, TPAccountNumber__c, ZipCode__c, CompanyName__c, Title__c, MiddleName__c, Salutation__c ' +
      'FROM FCS_FrequentFlyer__x ' +
      'WHERE ' +
      searchField +
      ' = \'' +
      searchValue +
      '\'';
    try {
      List<FCS_FrequentFlyer__x> externalData = Database.query(query);
      createdAccount = createAccountRecordBasedOnFrequentFlyers(externalData);

      //Necessary to do a query for the account after upsert to retrieve the PersonContactId
      if (createdAccount != null) {
        return [
          SELECT
            Id,
            PersonContactId,
            FCS_EBNumber__c,
            FCS_EBLevel__c,
            FCS_TPAccountNumber__c,
            FCS_CODSId__c,
            FCS_LastRetrievedFromSource__c
          FROM Account
          WHERE Id = :createdAccount.Id
        ];
      }
    } catch (Exception excp) {
      String msg = excp.getMessage() + searchField + ':' + searchValue;
      C_Log.log(
        C_Log.Severity.Error,
        msg,
        excp.getStackTraceString(),
        'c-shark',
        null
      );
    }

    return null;
  }

  /**
   * Used to create an account based on a Frequent Flyer record. If additional fields are added in the mapping
   * below, they also have to be added to the query retrieving the frequent flyer record.
   * @param frequentFlyers List of Frequent Flyer record to generate accounts for
   * @return List of account generated
   */
  @TestVisible
  private static Account createAccountRecordBasedOnFrequentFlyers(
    List<FCS_FrequentFlyer__x> frequentFlyers
  ) {
    List<Account> accounts = new List<Account>();
    // TODO: Add checks here.
    for (FCS_FrequentFlyer__x ff : frequentFlyers) {
      Account newAccount = new Account(
        RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
        FCS_CODSId__c = ff.ExternalId,
        FCS_FrequentFlyer__c = ff.ExternalId,
        PersonMailingStreet = ff.AddressLine1__c,
        PersonMailingCity = ff.City__c,
        PersonMailingPostalCode = ff.ZipCode__c,
        PersonMailingCountry = ff.CountryCode__c,
        PersonMailingState = ff.CountyState__c,
        FCS_ConsentEmail__c = ff.ConsentEmail__c,
        FCS_ConsentEuroBonus__c = ff.ConsentEB__c,
        FCS_ConsentSMS__c = ff.ConsentSMS__c,
        FCS_ConsentSiteProfile__c = ff.ConsentEB0__c,
        FCS_ConsentTelemarketing__c = ff.ConsentTelemarketing__c,
        FCS_EBLevel__c = ff.EBLevel__c,
        FCS_EBNumber__c = ff.EBNumber__c,
        FirstName = ff.FirstName__c,
        FCS_Gender__c = ff.Gender__c,
        LastName = ff.LastName__c,
        FCS_EBMemberSinceDate__c = ff.EBMemberSinceDate__c != null
          ? Date.valueOf(ff.EBMemberSinceDate__c)
          : null,
        PersonMobilePhone = ff.Mobile__c,
        PersonHomePhone = ff.Phone__c,
        FCS_SubscriptionId__c = ff.SubscriptionId__c,
        FCS_TPAccountNumber__c = ff.TPAccountNumber__c,
        FCS_CompanyName__c = ff.CompanyName__c,
        FCS_CMP__c = ff.CMP__c,
        PersonTitle = ff.Title__c,
        Salutation = ff.Salutation__c,
        MiddleName = ff.MiddleName__c,
        FCS_LastRetrievedFromSource__c = Datetime.now()
      );
      if (ff.BirthDate__c != null) {
        // Date accepts values which aren't accepted by SF DB so we need a check.
        // Principal difference is that DB accepts only dates between years
        // 1700 and 4000.
        Date birthDate = Date.valueOf(ff.BirthDate__c);
        Integer year = birthDate.year();
        if (year > 1700 && year < 4000) {
          newAccount.PersonBirthdate = birthDate;
        } else {
          C_Log.log(
            C_Log.Severity.Warning,
            'Invalid birthdate: ' +
            ff.BirthDate__c +
            '. For EB user: ' +
            ff.EBNumber__c,
            null,
            'CODS-data',
            null
          );
        }
      }

      if (
        ff.EmailPersonal__c != null &&
        !StringUtils.isEmailAddress(ff.EmailPersonal__c)
      ) {
        C_Log.log(
          C_Log.Severity.Warning,
          'Invalid email address: ' +
          ff.EmailPersonal__c +
          '. For EB user: ' +
          ff.EBNumber__c,
          null,
          'CODS-data',
          null
        );
      } else if (
        /**
           The email with domain @sas.dk, @sas.se and @sas.no are Salesforce internal users,
           for Salesforce internal users automatic association of the Case and EB Account is not needed, 
           so not assigning the email address for those Salesforce Internal Users.
         */
        ff.EmailPersonal__c != null &&
        !(ff.EmailPersonal__c.contains('@sas.dk') ||
        ff.EmailPersonal__c.contains('@sas.se') ||
        ff.EmailPersonal__c.contains('@sas.no'))
      ) {
        newAccount.PersonEmail = ff.EmailPersonal__c;
      }
      accounts.add(newAccount);
    }
    if (!accounts.isEmpty()) {
      upsert accounts[0] FCS_CODSId__c;
      return accounts[0];
    }
    return null;
  }

  /**
   * Used to retrieve data for the record that the controller is called from.
   * @param recordId Record id for the record where the component is called from.
   * @return Abstract interpretation of object in context, containing record data.
   */
  @AuraEnabled
  public static ComponentRecordData getRecordData(Id recordId) {
    SObjectType sObjectType = recordId.getSobjectType();
    if (sObjectType == Case.getSObjectType()) {
      return new ComponentRecordData(
        [
          SELECT
            Id,
            FCS_EBNumber__c,
            FCS_EBLevel__c,
            FCS_TPAccountNumber__c,
            AccountId,
            Account.FCS_FrequentFlyer__c,
            Account.FCS_LastRetrievedFromSource__c,
            Account.PersonContactId
          FROM Case
          WHERE Id = :recordId
        ]
      );
    } else if (sObjectType == LiveChatTranscript.getSObjectType()) {
      return new ComponentRecordData(
        [
          SELECT
            Id,
            FCS_EBNumber__c,
            FCS_CODSId__c,
            Account.PersonContactId,
            Account.FCS_FrequentFlyer__c,
            CaseId,
            Account.FCS_LastRetrievedFromSource__c
          FROM LiveChatTranscript
          WHERE Id = :recordId
        ]
      );
    } else if (sObjectType == MessagingSession.getSObjectType()) {
      return new ComponentRecordData(
        [
          SELECT
            Id,
            EndUserAccountId,
            EndUserContactId,
            EndUserAccount.FCS_LastRetrievedFromSource__c,
            CaseId
          FROM MessagingSession
          WHERE Id = :recordId
        ]
      );
    } else {
      throw new IdentifyCustomerComponentException(
        'This object is not supported. Modify component controller to support object'
      );
    }
  }

  /**
   * Class used as an abstract interpretation of multiple SObject types. The class is used to communicate data
   * between the controlled and the Lightning Web Component, as well as performing actions on records encapsuled
   * by this wrapper. To support new SObject types, add a new constructor and a corresponding block in the update method.
   */
  public class ComponentRecordData {
    @AuraEnabled
    public Id recordId { get; private set; }
    @AuraEnabled
    public Id accountId { get; private set; }
    @AuraEnabled
    public Id personContactId { get; private set; }
    @AuraEnabled
    public Id caseId { get; private set; }
    @AuraEnabled
    public String euroBonusNumber { get; private set; }
    @AuraEnabled
    public String euroBonusLevel { get; private set; }
    @AuraEnabled
    public String tpAccountNumber { get; private set; }
    @AuraEnabled
    public String codsId { get; private set; }
    @AuraEnabled
    public Datetime lastRetrievedFromSource { get; private set; }
    /**
     * Indicates that this SObjectType supports UI API. This enables transactions in JavaScript without
     * utilizing APEX to perform DML.
     */
    @AuraEnabled
    public Boolean supportsUIApi { get; private set; }

    /**
     * Constructor for class
     * @param cse Case record used to populate class params
     */
    public ComponentRecordData(Case cse) {
      recordId = cse.Id;
      accountId = cse.AccountId;
      personContactId = cse.Account.PersonContactId;
      euroBonusNumber = cse.FCS_EBNumber__c;
      euroBonusLevel = cse.FCS_EBLevel__c;
      tpAccountNumber = cse.FCS_TPAccountNumber__c;
      codsId = cse.Account.FCS_FrequentFlyer__c;
      caseId = cse.Id;
      lastRetrievedFromSource = cse.Account.FCS_LastRetrievedFromSource__c;
      supportsUIApi = true;
    }

    /**
     * Constructor for class
     * @param transcript LiveChatTranscript record used to populate class params
     */
    public ComponentRecordData(LiveChatTranscript transcript) {
      recordId = transcript.Id;
      accountId = transcript.AccountId;
      personContactId = transcript.Account.PersonContactId;
      euroBonusNumber = transcript.FCS_EBNumber__c;
      codsId = transcript.FCS_CODSId__c;
      caseId = transcript.CaseId;
      lastRetrievedFromSource = transcript.Account.FCS_LastRetrievedFromSource__c;
      supportsUIApi = false;
    }

    /**
     * Constructor for class
     * @param transcript LiveChatTranscript record used to populate class params
     */
    public ComponentRecordData(MessagingSession session) {
      recordId = session.Id;
      accountId = session.EndUserAccountId;
      personContactId = session.EndUserContactId;
      caseId = session.CaseId;
      lastRetrievedFromSource = session.EndUserAccount.FCS_LastRetrievedFromSource__c;
      supportsUIApi = false;
    }

    /**
     * Used to perform an update with dynamic selection of SObject type based on type derived from record id.
     */
    public void updateUnderlyingRecord() {
      SObject[] recordsToUpdate = new List<SObject>{};
      if (recordId.getSobjectType() == LiveChatTranscript.getSObjectType()) {
        recordsToUpdate.add(generateSObjectRecord(recordId));
        if (caseId != null) {
          recordsToUpdate.add(generateSObjectRecord(caseId));
        }
      } else if (recordId.getSobjectType() == Case.getSObjectType()) {
        recordsToUpdate.add(generateSObjectRecord(recordId));
        for (LiveChatTranscript transcript : [
          SELECT Id
          FROM LiveChatTranscript
          WHERE CaseId = :recordId
        ]) {
          recordsToUpdate.add(generateSObjectRecord(transcript.Id));
        }
      } else if (
        recordId.getSobjectType() == MessagingSession.getSObjectType()
      ) {
        MessagingSession session = [
          SELECT Id, MessagingEndUserId
          FROM MessagingSession
          WHERE Id = :recordId
        ];
        recordsToUpdate.add(generateSObjectRecord(session.MessagingEndUserId));
        if (caseId != null) {
          recordsToUpdate.add(generateSObjectRecord(caseId));
        }
      }
      update recordsToUpdate;
    }

    /**
     * Used to populate a new SObject record based on values in ComponentRecordData.
     * @param recordId Id of record to create. Possible to set to enable creation of records based on related Ids.
     * @return A new SObject record.
     */
    private SObject generateSObjectRecord(Id recordId) {
      SObject returnRecord;
      if (recordId.getSobjectType() == Case.SObjectType) {
        returnRecord = new Case(
          Id = recordId,
          AccountId = accountId,
          FCS_TPAccountNumber__c = tpAccountNumber,
          FCS_CODSId__c = codsId,
          FCS_EBNumber__c = euroBonusNumber,
          FCS_EBLevel__c = euroBonusLevel,
          ContactId = personContactId
        );
      } else if (recordId.getSobjectType() == LiveChatTranscript.SObjectType) {
        returnRecord = new LiveChatTranscript(
          Id = recordId,
          AccountId = accountId,
          FCS_EBNumber__c = euroBonusNumber,
          FCS_CODSId__c = codsId,
          ContactId = personContactId
        );
      } else if (recordId.getSobjectType() == MessagingEndUser.SObjectType) {
        returnRecord = new MessagingEndUser(
          Id = recordId,
          AccountId = accountId,
          ContactId = personContactId
        );
      }
      return returnRecord;
    }
  }

  /**
   * Used to perform an update from a Lightning Web Component with apex, when UI API is not supported.
   * @param jsonData JSON structure corresponding to the ComponentRecordData class.
   */
  @AuraEnabled
  public static void updateRecordDataWithApex(String jsonData) {
    ComponentRecordData recordData = (ComponentRecordData) JSON.deserialize(
      jsonData,
      ComponentRecordData.class
    );
    recordData.updateUnderlyingRecord();
  }

  /**
   * @author Anton Norell
   * @date 2020-01-14
   * @description Custom exception class used to throw exception for cases not covered by standard exceptions.
   */
  @TestVisible
  private class IdentifyCustomerComponentException extends Exception {
  }
}
