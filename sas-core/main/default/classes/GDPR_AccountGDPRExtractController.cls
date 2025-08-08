/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Controller for LWC gdpr_AccountGDPRExtract component.
 */
public with sharing class GDPR_AccountGDPRExtractController {
    /**
     * Used to generate an extract file of personal data connected to the account. The method calls a service to
     * retrieve the data and but is then responsible for creating and returning the JSON file.
     * @param accountId Id of account to generate an extract for
     * @return
     */
    @AuraEnabled
    public static ContentVersion generateExtractFile(Id accountId){
        String[] jsonExtract = GDPR_DataExtractService.extractAccountPersonalData(new Id[]{accountId}, null, null);

        ContentVersion extractFile = new ContentVersion();
        extractFile.Description = 'Extract of Personal Identifiable Information.';
        extractFile.ContentLocation = 'S';
        extractFile.PathOnClient = 'GDPR extract ' + Date.today().format() + '.json';
        extractFile.Title = 'GDPR extract ' + Date.today().format() + '.json ';
        extractFile.VersionData = Blob.valueOf(jsonExtract[0]);
        extractFile.IsGDPRExtract__c = true;
        insert extractFile;

        return [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :extractFile.Id];
    }
}