/**
 * @author Anton Norell
 * @date 2019-01-09
 * @description Test class for GDPR_DeleteExtractFiles_Batch
 */
@IsTest
public with sharing class GDPR_DeleteExtractFiles_Batch_Test {
    /**
     * Asserts that batch used to remove generated extract files removes only those files on not other files.
     */
    @IsTest
    static void shouldOnlyDeleteExtractFiles(){
        ContentVersion extractFile = new ContentVersion();
        extractFile.ContentLocation = 'S';
        extractFile.PathOnClient = 'GDPR extract ' + Date.today().format() + '.json';
        extractFile.Title = 'GDPR extract ' + Date.today().format() + '.json ';
        extractFile.VersionData = Blob.valueOf('Customer data');
        extractFile.IsGDPRExtract__c = true;
        insert extractFile;
        ContentVersion otherFile = new ContentVersion();
        otherFile.ContentLocation = 'S';
        otherFile.PathOnClient = 'Other file.json';
        otherFile.Title = 'Other file.json';
        otherFile.VersionData = Blob.valueOf('Other data');
        insert otherFile;

        Test.startTest();
        Database.executeBatch(new GDPR_DeleteExtractFiles_Batch());
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM ContentVersion WHERE Id = :extractFile.Id].size());
        System.assertEquals(1, [SELECT Id FROM ContentVersion WHERE Id = :otherFile.Id].size());
    }
}