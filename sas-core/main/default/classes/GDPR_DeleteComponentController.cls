/**
 * @author Anton Norell
 * @date 2020-01-08
 * @description Controller for LWC gdpr_GDPRExtract component.
 */
public with sharing class GDPR_DeleteComponentController {

    /**
     * Checks object type based on record Id and calls the correct method to wipe data on record according to GDPR
     * @param recordId Id of record to wipe data for
     */
    @AuraEnabled
    public static void deleteRecordData(Id recordId){
        if(!FeatureManagement.checkPermission('Manual_GDPR_Delete')) throw new NoAccessException();

        if(recordId.getSobjectType() == Account.SObjectType){
            GDPR_WipeAccountService.wipeAccounts(new Id[]{recordId});
        } else if (recordId.getSobjectType() == Case.SObjectType){
            GDPR_WipeCaseService.wipeCases(new Id[]{recordId});
        }
    }
}