public class IRR_SEL_AutomatedNoHandBagSelector extends fflib_SObjectSelector implements IRR_SEL_IAutomatedNoHandBagSelector  {


    public static IRR_SEL_IAutomatedNoHandBagSelector newInstance() 
    {

        return (IRR_SEL_IAutomatedNoHandBagSelector) IRR_Application.Selector.newInstance(
            IRR_AutomatedNoHandBag__mdt.SObjectType);
    }
    

    public List<Schema.SObjectField> getSObjectFieldList() {

        return new List<Schema.SObjectField> 
        { 

            IRR_AutomatedNoHandBag__mdt.DeveloperName,
            IRR_AutomatedNoHandBag__mdt.MasterLabel,
            IRR_AutomatedNoHandBag__mdt.IRR_Departure_Country__c,
            IRR_AutomatedNoHandBag__mdt.IRR_Arrival_Country__C,
            IRR_AutomatedNoHandBag__mdt.IRR_Template_Name__c,
            IRR_AutomatedNoHandBag__mdt.IRR_Duration__c

        };
    }

    public Schema.SobjectType getSObjectType() {

        return IRR_AutomatedNoHandBag__mdt.SobjectType ;

    }

    public Database.QueryLocator selectAutomatedNoHandBagMessages() {

        return Database.getQueryLocator(newQueryFactory().toSOQL());
    }

   
    public Database.QueryLocator selectAutomatedSecurityMessagesParis() {
        List<String> departureCountry = new List<String>{'MUC'} ;
        List<String> arrivalCountry = new List<String>{'CPH'} ;
    
        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('(IRR_Departure_Country__c  IN :departureCountry AND IRR_Arrival_Country__c  IN :arrivalCountry)');
         return Database.getQueryLocator(queryFactory.toSOQL());
        }
}
