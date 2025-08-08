/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector for the Organization object.
*/

public class IRR_SEL_OrganizationSelector extends fflib_SObjectSelector implements IRR_SEL_IOrganizationSelector {

    public static IRR_SEL_IOrganizationSelector newInstance()
    {
        return (IRR_SEL_IOrganizationSelector) IRR_Application.Selector.newInstance(Organization.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
                Organization.Id,
                Organization.IsSandbox
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Organization.SObjectType;
    }

    public Organization selectOrganization() {
        List<Organization> organizations = Database.query(newQueryFactory().toSOQL());
        return organizations[0];
    }
}