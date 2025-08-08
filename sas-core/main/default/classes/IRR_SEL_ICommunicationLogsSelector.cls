/**
 * @author Ludvig Wäilmaa, Deloitte
 * @date 2020
 *
 */

public interface IRR_SEL_ICommunicationLogsSelector extends fflib_ISObjectSelector {
  Map<String, IRR_CommunicationLog__c> getLatestResponseMessageByRecipients(
    Set<String> recipients
  );
  Database.QueryLocator getGDPRLogsQueryLocator(DateTime lastRetentionDate);
  List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(
    Set<String> contactKeys,
    DateTime lastRetentionDate
  );
  List<IRR_CommunicationLog__c> getCommunicationLogsByEBAccount(
    Set<String> euroBonusNumbers
  );
  List<IRR_CommunicationLog__c> getCommunicationLogsByBookingReference(
    Set<String> bookingReferences
  );
  List<IRR_CommunicationLog__c> getCommunicationLogsByBoardingSequencesIcoupon(
    Set<Integer> boardingSequences,String flightId
  );
  List<IRR_CommunicationLog__c> getCommunicationLogsByFlightIdIcoupon(
    String flightId,
    List<Integer> boardingSeqNo
  );

  List<IRR_CommunicationLog__c> getCommunicationLogsByFlightIdAndMsgType(
    Set<String> flightIds,String messageType

  );

  Database.QueryLocator getCommunicationLogByDateQueryLocator();

}