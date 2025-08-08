/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Email Templates selector.
*/

@IsTest
private class IRR_SEL_EmailTemplatesSelector_Test {

    @IsTest
    static void testSelectEmailTemplatesByName() {
        Id orgId = IRR_SEL_OrganizationSelector.newInstance().selectOrganization().Id;
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>{
                new EmailTemplate(FolderId = orgId, Name = 'ET_1', DeveloperName = 'ET_1',Subject = 'Test', UiType='SFX', TemplateType='custom'),
                new EmailTemplate(FolderId = orgId, Name = 'ET_2', DeveloperName = 'ET_2',Subject = 'Test', UiType='SFX', TemplateType='custom'),
                new EmailTemplate(FolderId = orgId, Name = 'ET_3', DeveloperName = 'ET_3',Subject = 'Test', UiType='SFX', TemplateType='custom')
        };
        insert emailTemplates;

        Set<String> templateNames = new Set<String>{'ET_1', 'ET_2'};
        Map<String, EmailTemplate> emailTemplateByName =IRR_SEL_EmailTemplatesSelector.newInstance()
                .selectEmailTemplatesByName(templateNames);

        System.assertEquals(2, emailTemplateByName.size());
        System.assert(emailTemplateByName.containsKey('et_1'), 'Expected template ET_1 in lowercase in Map');
        System.assert(emailTemplateByName.containsKey('et_2'), 'Expected template ET_1 in lowercase in Map');
        System.assertEquals(emailTemplates[0].Id, emailTemplateByName.get('et_1').Id);
        System.assertEquals(emailTemplates[1].Id, emailTemplateByName.get('et_2').Id);
    }
}