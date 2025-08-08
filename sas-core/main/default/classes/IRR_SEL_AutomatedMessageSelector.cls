/**
* @author Gaurav, Coforge
* @date 2024
*
* @description Selector class for the IRR Automated Message metadata object.
*/
public class IRR_SEL_AutomatedMessageSelector extends fflib_SObjectSelector implements IRR_SEL_IAutomatedMessageSelector  {
    public static IRR_SEL_IAutomatedMessageSelector newInstance() 
    {

        return (IRR_SEL_IAutomatedMessageSelector) IRR_Application.Selector.newInstance(
            Automated_Message_Outbound__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            Automated_Message_Outbound__mdt.DeveloperName,
            Automated_Message_Outbound__mdt.MasterLabel,
            Automated_Message_Outbound__mdt.Days_Before_Comm_Need_to_Send__c ,
            Automated_Message_Outbound__mdt.Comment__c,
            Automated_Message_Outbound__mdt.Is_Active__c,
            Automated_Message_Outbound__mdt.Is_Send_Email__c,
            Automated_Message_Outbound__mdt.Is_Send_SMS__c,
            Automated_Message_Outbound__mdt.Type__c,
            Automated_Message_Outbound__mdt.Station_Arrival__c,
            Automated_Message_Outbound__mdt.Station_Departure__c,
            Automated_Message_Outbound__mdt.Outbound_Station_Arrival__c,
            Automated_Message_Outbound__mdt.Outbound_Station_Departure__c,
            Automated_Message_Outbound__mdt.Email_Template_Name__c,
            Automated_Message_Outbound__mdt.Sms_Template_Name__c

           


        };

    }

    public Schema.SObjectType getSObjectType() {

        return Automated_Message_Outbound__mdt.SobjectType ;
    }

    public Database.QueryLocator getAutomatedMessage(){
        Boolean isActive =true;
        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('Is_Active__c =: isActive');
         return Database.getQueryLocator(queryFactory.toSOQL());
               
    }
}