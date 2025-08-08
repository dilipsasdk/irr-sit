/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Selector for the EmailTemplates object.
*/

public class IRR_SEL_EmailTemplatesSelector extends fflib_SObjectSelector implements IRR_SEL_IEmailTemplatesSelector {

    public static IRR_SEL_IEmailTemplatesSelector newInstance()
    {
        return (IRR_SEL_IEmailTemplatesSelector) IRR_Application.Selector.newInstance(EmailTemplate.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>
        {
                EmailTemplate.Id,
                EmailTemplate.Name,
                EmailTemplate.FolderId,
                EmailTemplate.DeveloperName,
                EmailTemplate.Body,
                EmailTemplate.HtmlValue,
                EmailTemplate.Subject
        };
    }

    public Schema.SObjectType getSObjectType() {
        return EmailTemplate.SObjectType;
    }

    public Map<String, EmailTemplate> selectEmailTemplatesByName(Set<String> templateNames) {
        String accessPublic = 'Public';
        Id orgId = IRR_SEL_OrganizationSelector.newInstance().selectOrganization().Id;
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('Name IN :templateNames AND (FolderId = :orgId OR Folder.AccessType = :accessPublic)')
                .setOrdering(EmailTemplate.CreatedDate, fflib_QueryFactory.SortOrder.ASCENDING);
        List<EmailTemplate> emailTemplates = Database.query(queryFactory.toSOQL());
        Map<String, EmailTemplate> emailTemplateByNames = new Map<String, EmailTemplate>();
        for (EmailTemplate emailTemplate : emailTemplates) {
            if (!emailTemplateByNames.containsKey(emailTemplate.Name)) {
                emailTemplateByNames.put(emailTemplate.Name.toLowerCase(), emailTemplate);
            }
        }
        return emailTemplateByNames;
    }
}