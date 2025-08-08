/**
 * @author Anton Norell
 * @date 2019-12-19
 * @description Test class for AccountGDPRExtractController
 */
@IsTest
private class GDPR_AccountGDPRExtractController_Test {
    /**
     * Asserts that a file is generated for the customer when using the GDPR_DataExtractService. Scope for test is limited
     * to ContentVersion creation, not the file content, which is tested in the service generating the file.
     */
    @IsTest
    static void shouldGenerateContentVersion() {
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;

        ContentVersion contentVersion = GDPR_AccountGDPRExtractController.generateExtractFile(acc.Id);

        System.assertNotEquals(null, contentVersion, 'No ContentVersion record was returned');
        System.assertEquals('GDPR extract ' + Date.today().format() + '.json', contentVersion.Title);
    }
}