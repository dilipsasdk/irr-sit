/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SEL_IEmailTemplatesSelector extends fflib_ISObjectSelector {
    Map<String, EmailTemplate> selectEmailTemplatesByName(Set<String> templateNames);
}