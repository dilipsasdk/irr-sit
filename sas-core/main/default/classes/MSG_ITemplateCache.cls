/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface MSG_ITemplateCache {
    void loadTemplates(Set<String> tDevNameSet);
    MSG_TemplateCache.TemplateContent getTemplateByName(String templateName);
}