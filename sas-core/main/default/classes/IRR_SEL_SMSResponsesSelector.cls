/**
* @author Ludvig Wälimaa, Deloitte
* @date 2020
*
*/

public class IRR_SEL_SMSResponsesSelector extends fflib_SObjectSelector
        implements IRR_SEL_ISMSResponsesSelector {

    public static IRR_SEL_ISMSResponsesSelector newInstance() {
        return (IRR_SEL_ISMSResponsesSelector)
                IRR_Application.Selector.newInstance(IRR_SMSResponse__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                IRR_SMSResponse__c.Id,
                IRR_SMSResponse__c.IRR_CommunicationLog__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_SMSResponse__c.SObjectType;
    }

    public Database.QueryLocator getGDPRLogsQueryLocator(DateTime lastRetentionDate) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('CreatedDate <= :lastRetentionDate');
        return Database.getQueryLocator(queryFactory.toSOQL());
    }
    
    public List<IRR_SMSResponse__c> selectSMSResponsesWithCommunicationLogs(Set<Id> comIds) {
        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('IRR_CommunicationLog__c IN :comIds');
        System.debug(queryFactory.toSOQL());
        return Database.query(queryFactory.toSOQL());
    }
}