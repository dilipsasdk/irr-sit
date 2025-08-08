/**
    Service used to privde the ability to fully wipe a customer
    from the system. Only the system fields of the accouint will remain as well
    as the wiped case information.
    @author Peter Södergren
*/
global with sharing class GDPR_WipeAccountService {
    /**
        Retrieves the account fields to clear based where the fields 
        stored in the general setting group AWRF are removed
        @param keepReference Whether to keep a reference to account to be able to refetch data at a later point
        @return The list fo fields which should be wiped from the case
    */
    global static String[] getAccountFieldsToClear(Boolean keepReference){
        Set<String> retainedFields = new Set<String>();
        //TODO When issue related to retrieving multiple field definitions in on transaction os solved, remove Case filted from this query
        FieldDefinition[] fdList = [SELECT QualifiedAPIName,ComplianceGroup, EntityDefinitionId FROM FieldDefinition WHERE (EntityDefinitionId ='Account' OR EntityDefinitionId ='Case') AND ComplianceGroup!=null];
        for(FieldDefinition fd : fdList){
            if(fd.EntityDefinitionId == 'Account' && fd.ComplianceGroup.split(';').contains('WipeRetain'))retainedFields.add(fd.QualifiedAPIName);
        }
        //Add fields for which compliance cannot be set
        retainedFields.add('MasterRecordId');
        retainedFields.add('RecordTypeId');
        //Name is not removed since it cannot be edited for person accounts
        retainedFields.add('Name');
        if(keepReference)retainedFields.add(Account.FCS_CodsId__c+'');

        List<String> fieldsToClear = new List<String>();
        Map<String,Schema.SObjectField> fMap = Account.getSObjectType().getDescribe().fields.getMap();
        for(String k : fMap.keySet()){
            Schema.SObjectField f = fMap.get(k);
            if(!retainedFields.contains(f+'')){
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(dfr.isNillable() && dfr.getType()!=Schema.DisplayType.ADDRESS && dfr.isUpdateable())fieldsToClear.add(k);
            }
        }
        return fieldsToClear;
    }

    /**
        Retrieves the wiped account name from the GDPR settings
        @return The name to use for wiped accounts
    */
    global static String getWipedAccountName(){
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        return sg.get('AccountDataWipeName');
    }
    /**
        Wipes the provided customer ids from the system clearing the account data.
        @param accIds The account ids to wipe
        @param fieldsToClear The fields to wipe on the account
        @param wipedAccountName The name to give the account after wiping the account
        @param hardWipe Whether the wiped information is removed in such a way that the identity of the account cannot be recovered
        @param wipeRelated Whether to wipe related case and communication data in addition to the account data
    */
    global static void wipeAccounts(Id[] accIds, String[] fieldsToClear, String wipedAccountName, Boolean hardWipe, Boolean wipeRelated){
        Integer sz = accIds.size();
        Account[] accList = new Account[sz];
        for(Integer i=0;i<sz;i++){
            Account acc = new Account(Id=accIds[i]);
            for(Integer j=0,jSz=fieldsToClear.size();j<jSz;j++){
                acc.put(fieldsToClear[j],null);
            }
            acc.GDPR_WipedSoft__c = true;
            if(hardWipe)acc.GDPR_Wiped__c = true;
            acc.FirstName = null;
            acc.LastName = wipedAccountName;
            accList[i] = acc;
        }
        update accList;
        if(wipeRelated){
            Case[] cList = [SELECT Id FROM Case WHERE AccountId IN :accIds];
            if(!cList.isEmpty())GDPR_WipeCaseService.wipeCases(cList);
        }
    }

    /**
        Wipes the provided customer ids from the system clearing the account data
        and wiping the cases.
        @param accIds The account ids to wipe
    */
    global static void wipeAccounts(Id[] accIds){
        wipeAccounts(accIds, getAccountFieldsToClear(false),getWipedAccountName(),true, true);
    }
}