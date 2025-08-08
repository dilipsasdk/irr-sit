/**
 * Trigger for the IRR_SMSResponse__c object
 * @author Peter Södergren
 */
trigger IRR_SMSResponseTrigger on IRR_SMSResponse__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(IRR_DOM_SMSResponses.class);
}