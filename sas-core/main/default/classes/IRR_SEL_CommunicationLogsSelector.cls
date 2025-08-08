/**
 * @author Ludvig Wälimaa, Deloitte
 * @date 2020
 *
 */

public class IRR_SEL_CommunicationLogsSelector extends fflib_SObjectSelector implements IRR_SEL_ICommunicationLogsSelector {
  public static IRR_SEL_ICommunicationLogsSelector newInstance() {
    return (IRR_SEL_ICommunicationLogsSelector) IRR_Application.Selector.newInstance(
      IRR_CommunicationLog__c.SObjectType
    );
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      IRR_CommunicationLog__c.Id,
      IRR_CommunicationLog__c.CreatedDate,
      IRR_CommunicationLog__c.IRR_BookingReference__c,
      IRR_CommunicationLog__c.IRR_ContactKey__c,
      IRR_CommunicationLog__c.IRR_LastResponseDate__c,
      IRR_CommunicationLog__c.IRR_Recipient__c,
      IRR_CommunicationLog__c.IRR_Response__c,
      IRR_CommunicationLog__c.IRR_MessageContent__c,
      IRR_CommunicationLog__c.IRR_Channel__c,
      IRR_CommunicationLog__c.IRR_FlightId__c,
      IRR_CommunicationLog__c.IRR_BoardingSequence__c

    };
  }

  public Schema.SObjectType getSObjectType() {
    return IRR_CommunicationLog__c.SObjectType;
  }

  public Map<String, IRR_CommunicationLog__c> getLatestResponseMessageByRecipients(
    Set<String> recipients
  ) {
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setCondition(
        'IRR_Recipient__c IN :recipients AND IRR_ResponseMessage__c = TRUE'
      )
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      );
    List<IRR_CommunicationLog__c> communicationLogs = Database.query(
      queryFactory.toSOQL()
    );
    Map<String, IRR_CommunicationLog__c> comLogByRecipient = new Map<String, IRR_CommunicationLog__c>();
    for (IRR_CommunicationLog__c cl : communicationLogs) {
      if (!comLogByRecipient.containsKey(cl.IRR_Recipient__c)) {
        comLogByRecipient.put(cl.IRR_Recipient__c, cl);
      }
    }
    return comLogByRecipient;
  }

  public Database.QueryLocator getGDPRLogsQueryLocator(
    DateTime lastRetentionDate
  ) {
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setCondition('CreatedDate <= :lastRetentionDate');
    return Database.getQueryLocator(queryFactory.toSOQL());
  }

  public Database.QueryLocator getCommunicationLogByDateQueryLocator() {
    DateTime lastRetentionDate = System.Today().addDays(-90);
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setCondition('CreatedDate <= :lastRetentionDate');
    return Database.getQueryLocator(queryFactory.toSOQL());
  }

  public List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(
    Set<String> contactKeys,
    DateTime lastRetentionDate
  ) {
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setCondition(
        'CreatedDate > :lastRetentionDate AND IRR_ContactKey__c IN :contactKeys'
      );
    return Database.query(queryFactory.toSOQL());
  }

  public List<IRR_CommunicationLog__c> getCommunicationLogsByEBAccount(
    Set<String> euroBonusNumbers
  ) {
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      )
      .setCondition('IRR_EBNumber__c IN :euroBonusNumbers');
    return Database.query(queryFactory.toSOQL());
  }

  public List<IRR_CommunicationLog__c> getCommunicationLogsByBookingReference(
    Set<String> bookingReferences
  ) {
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      )
      .setCondition('IRR_BookingReference__c IN :bookingReferences');
    return Database.query(queryFactory.toSOQL());
  }

  public List<IRR_CommunicationLog__c> getCommunicationLogsByBoardingSequencesIcoupon(
    Set<Integer> boardingSequences,String flightId
  ) {

    fflib_QueryFactory queryFactory = newQueryFactory()
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      )
      .setCondition('IRR_BoardingSequence__c IN :boardingSequences AND IRR_CouponBatchId__c != Null AND IRR_FlightId__c =:flightId');
    return Database.query(queryFactory.toSOQL());
  }

  public List<IRR_CommunicationLog__c> getCommunicationLogsByFlightIdIcoupon(
  String flightId,
  List<Integer> boardingSeqNo
  ) {
    String channel = 'SMS';
    List<String> msgType = new List<String>{'Manual - Icoupon' ,'Icoupon' };
    fflib_QueryFactory queryFactory = newQueryFactory()
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      )
      .setCondition('IRR_CouponBatchId__c != Null AND IRR_FlightId__c =:flightId AND IRR_Channel__c =:channel AND IRR_BoardingSequence__c IN : boardingSeqNo AND IRR_MessageType__c IN :msgType');
    return Database.query(queryFactory.toSOQL());
  }


  public List<IRR_CommunicationLog__c> getCommunicationLogsByFlightIdAndMsgType(
    Set<String> flightIds,String messageType
  ) {

    fflib_QueryFactory queryFactory = newQueryFactory()
      .setOrdering(
        IRR_CommunicationLog__c.CreatedDate,
        fflib_QueryFactory.SortOrder.DESCENDING
      )
      .setCondition('IRR_FlightId__c  IN :flightIds AND IRR_MessageType__c =: messageType');
    return Database.query(queryFactory.toSOQL());
  }
}