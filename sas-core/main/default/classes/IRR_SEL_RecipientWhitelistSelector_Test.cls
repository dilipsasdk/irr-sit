/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit test class for the Recipient Whitelist selector class.
*/

@IsTest
private class IRR_SEL_RecipientWhitelistSelector_Test {

    @IsTest
    static void testSelectAllWhitelistedRecipients() {
        Set<String> whitelistedRecipients = IRR_SEL_RecipientWhitelistSelector.newInstance()
                .getAllWhitelistedRecipients();
        List<IRR_RecipientWhitelist__mdt> recipientWhitelists = [SELECT IRR_Recipient__c FROM IRR_RecipientWhitelist__mdt];
        for (IRR_RecipientWhitelist__mdt whitelist : recipientWhitelists) {
            System.assert(whitelistedRecipients.contains(whitelist.IRR_Recipient__c));
        }
        System.assertEquals(recipientWhitelists.size(), whitelistedRecipients.size());
    }
}