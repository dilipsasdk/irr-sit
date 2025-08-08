/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for SMS definitions selector.
*/

@IsTest
private class IRR_SEL_SMSDefinitionsSelector_Test {

    @IsTest
    static void testGetAllSMSDefinitions() {
        //When
        List<SFMC_SMSDefinition__mdt> smsDefinitions = IRR_SEL_SMSDefinitionsSelector.newInstance()
                .getAllSMSDefinitions();

        //Then
        System.assertEquals([SELECT COUNT() FROM SFMC_SMSDefinition__mdt], smsDefinitions.size());
        Boolean nullLast = true;
        for (Integer i = 0; i < smsDefinitions.size(); i++) {
            SFMC_SMSDefinition__mdt smsDefinition = smsDefinitions[i];
            if (smsDefinition.SFMC_CountryPrefix__c == null && i+1 != smsDefinitions.size()) nullLast = false;
        }
        System.assert(nullLast, 'Null Country Prefix should be last in list');
    }
}