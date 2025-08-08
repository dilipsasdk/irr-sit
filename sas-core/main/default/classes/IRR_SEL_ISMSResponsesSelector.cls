/**
* @author Ludvig Wäilmaa, Deloitte
* @date 2020
*
*/

public interface IRR_SEL_ISMSResponsesSelector extends fflib_ISObjectSelector {
    Database.QueryLocator getGDPRLogsQueryLocator(DateTime lastRetentionDate);
    List<IRR_SMSResponse__C> selectSMSResponsesWithCommunicationLogs(Set<Id> comIds);
}