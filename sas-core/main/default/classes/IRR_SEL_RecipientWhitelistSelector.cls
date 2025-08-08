/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_SEL_RecipientWhitelistSelector extends fflib_SObjectSelector
        implements IRR_SEL_IRecipientWhitelistSelector {

    public static IRR_SEL_IRecipientWhitelistSelector newInstance()
    {
        return (IRR_SEL_IRecipientWhitelistSelector) IRR_Application.Selector.newInstance(
                IRR_RecipientWhitelist__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
                IRR_RecipientWhitelist__mdt.DeveloperName,
                IRR_RecipientWhitelist__mdt.IRR_Recipient__c

        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_RecipientWhitelist__mdt.SObjectType;
    }


    public Set<String> getAllWhitelistedRecipients() {
        List<IRR_RecipientWhitelist__mdt> recipientWhitelists = Database.query(newQueryFactory().toSOQL());
        Set<String> recipients = new Set<String>();
        for (IRR_RecipientWhitelist__mdt whitelist : recipientWhitelists) {
            recipients.add(whitelist.IRR_Recipient__c);
        }
        return recipients;
    }
}