public class IRR_SEL_AutomatedMessagesSelector extends fflib_SObjectSelector implements IRR_SEL_IAutomatedMessagesSelector  {
    
    public static IRR_SEL_IAutomatedMessagesSelector newInstance() 
    {

        return (IRR_SEL_IAutomatedMessagesSelector) IRR_Application.Selector.newInstance(
            IRR_AutomatedMessage__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_AutomatedMessage__mdt.DeveloperName,
            IRR_AutomatedMessage__mdt.MasterLabel,
            IRR_AutomatedMessage__mdt.IRR_Departure_Country__c,
            IRR_AutomatedMessage__mdt.IRR_Arrival_Country__C,
            IRR_AutomatedMessage__mdt.IRR_Template_Name__c,
            IRR_AutomatedMessage__mdt.IRR_Duration__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_AutomatedMessage__mdt.SobjectType ;
    }

    public Database.QueryLocator selectAutomatedMessages(){

         return Database.getQueryLocator(newQueryFactory().toSOQL());
               
    }

}
