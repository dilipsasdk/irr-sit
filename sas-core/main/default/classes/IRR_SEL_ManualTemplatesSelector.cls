/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector class for the Manual Templates custom metadata object.
*/

public class IRR_SEL_ManualTemplatesSelector extends fflib_SObjectSelector implements IRR_SEL_IManualTemplatesSelector {

    public static IRR_SEL_IManualTemplatesSelector newInstance()
    {
        return (IRR_SEL_IManualTemplatesSelector) IRR_Application.Selector.newInstance(
                IRR_ManualCommunicationTemplate__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
                IRR_ManualCommunicationTemplate__mdt.DeveloperName,
                IRR_ManualCommunicationTemplate__mdt.MasterLabel,
                IRR_ManualCommunicationTemplate__mdt.IRR_DefaultSendEmail__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_DefaultSendSMS__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_EmailTemplate__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_Priority__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_ResponseTemplate__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_SendMode__c,
                IRR_ManualCommunicationTemplate__mdt.IRR_SMSTemplate__c

        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_ManualCommunicationTemplate__mdt.SObjectType;
    }

    public List<IRR_ManualCommunicationTemplate__mdt> selectAllManualCommunicationTemplates() {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setOrdering(IRR_ManualCommunicationTemplate__mdt.IRR_Priority__c,
                        fflib_QueryFactory.SortOrder.ASCENDING);
        return Database.query(queryFactory.toSOQL());
    }
}