/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector class for the SMS Definition custom metadata object.
*/

public class IRR_SEL_SMSDefinitionsSelector extends fflib_SObjectSelector
        implements IRR_SEL_ISMSDefinitionsSelector {

    public static IRR_SEL_ISMSDefinitionsSelector newInstance() {
        return (IRR_SEL_ISMSDefinitionsSelector)
                IRR_Application.Selector.newInstance(SFMC_SMSDefinition__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
                SFMC_SMSDefinition__mdt.fields.SFMC_CountryPrefix__c,
                SFMC_SMSDefinition__mdt.fields.SFMC_DefinitionKey__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return SFMC_SMSDefinition__mdt.SObjectType;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves all SMS Definitions ordered by the CountryPrefix with nulls last.
     *
     * @return All SMS Definitions
     */
    public List<SFMC_SMSDefinition__mdt> getAllSMSDefinitions() {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setOrdering(SFMC_SMSDefinition__mdt.fields.SFMC_CountryPrefix__c,
                        fflib_QueryFactory.SortOrder.ASCENDING, true);
        return Database.query(queryFactory.toSOQL());
    }
}