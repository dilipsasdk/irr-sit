
/**
    Class used to load and hold a cache of message templates
    @author Peter Södergren
*/
global with sharing class MSG_TemplateCache implements MSG_ITemplateCache {
    /**
        Exceptio thrown on unexpected issues with templates
    */
    class TemplateException extends Exception{}
    /**
        Map of email templates by template Id
    */
    Map<Id,TemplateContent> tcMap;

    /**
     * Map of email templates by template name
     */
    Map<String, TemplateContent> templateContentByTemplateNames;
    /**
        Map of letterheads by id
    */
    Map<Id,TemplateLetterhead> lhMap;
    /**
        Map of attachments by id
    */
    Map<Id,TemplateAttachment> taMap;
    /**
        Referenced letterhead ids not yet loaded
    */
    Set<Id> pendingLetterheadIds;
    /**
        Referenced brand template ids not yet loaded
    */
    Set<Id> pendingBrandTemplateIds;
    /**
        List of template content with pending letterhead load
    */
    List<TemplateContent> tcPendingLhList;
    /**
        List used by testing to override the email templates retrieved by the template cache
    */
    @TestVisible static EmailTemplate[] ET_LIST_OVERRIDE;
    /**
        List used by testing to override the enhanced letterheads retrieved by the template cache
    */
    @TestVisible static EnhancedLetterhead[] EL_LIST_OVERRIDE;
    /**
        List used by testing to override the brand templates retrieved by the template cache
    */
    @TestVisible static BrandTemplate[] BT_LIST_OVERRIDE;
    /**
        List used by testing to override the files retrieved by the template cache
    */
    @TestVisible static ContentDocumentLink[] CDL_LIST_OVERRIDE;
    /**
        List used by testing to override the attachments retrieved by the template cache
    */
    @TestVisible static Attachment[] A_LIST_OVERRIDE;
    /**
        Map from file type to the appropriate content type
    */
    static Map<String,String> FT_CT_MAP = new Map<String,String>{
        'PDF'=>'application/pdf',
        'WORD_X'=>'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'EXCEL_X'=>'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'POWER_POINT_X'=>'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'PNG'=>'image/png',
        'JPG'=>'image/jpeg',
        'GIF'=>'image/gif',
        'SVG'=>'image/svg+xml',
        'TEXT'=>'text/plain'
    };

    /**
        Creates an empty template cache instance
    */
    global MSG_TemplateCache(){
        tcMap = new Map<Id,TemplateContent>();
        lhMap = new Map<Id,TemplateLetterhead>();
        taMap = new Map<Id,TemplateAttachment>();
        templateContentByTemplateNames = new Map<String, MSG_TemplateCache.TemplateContent>();
        pendingLetterheadIds = new Set<Id>();
        pendingBrandTemplateIds = new Set<Id>();
        tcPendingLhList = new List<TemplateContent>();
    }

    /**
        Loads letterheads referenced by loaded email templates but where the letterhead has yet to be loaded
    */
    private void loadPendingLetterheads(){
        if(!pendingLetterheadIds.isEmpty()){
            EnhancedLetterhead[] elList = EL_LIST_OVERRIDE!=null ? EL_LIST_OVERRIDE : [SELECT Id,LetterheadHeader,LetterheadFooter FROM EnhancedLetterhead WHERE Id IN :pendingLetterheadIds];
            for(Integer i=0,sz=elList.size();i<sz;i++){
                EnhancedLetterhead el = elList[i];
                lhMap.put(el.Id,new TemplateLetterhead(el.Id,el.LetterheadHeader,el.LetterheadFooter));
            }
            pendingLetterheadIds.clear();
        }
        if(!pendingBrandTemplateIds.isEmpty()){
            BrandTemplate[] btList = BT_LIST_OVERRIDE!=null ? BT_LIST_OVERRIDE : [SELECT Id,Value FROM BrandTemplate WHERE Id IN :pendingBrandTemplateIds];
            for(Integer i=0,sz=btList.size();i<sz;i++){
                BrandTemplate bt = btList[i];
                lhMap.put(bt.Id,createLetterhead(bt));
            }
            pendingBrandTemplateIds.clear();
        }

        for(Integer i=0,sz=tcPendingLhList.size();i<sz;i++){
            TemplateContent tc = tcPendingLhList[i];
            tc.letterhead = lhMap.get(tc.letterheadId);
        }
        tcPendingLhList.clear();
    }

    /**
        Creates a letterhead from a brand template
        @param bt The brand template from which to create the letterhead
        @return The letterhead
    */
    private static TemplateLetterhead createLetterhead(BrandTemplate bt){
        String s = bt.Value;
        String h = null;
        String o = '';
        Integer cdCnt = 0;
        Integer idx = 0;
        Integer sIdx = s.indexOf('<style');
        Integer cdIdx = s.indexOf('<![CDATA[');
        while(sIdx!=-1 || cdIdx!=-1){
            if(sIdx!=-1 && (sIdx<cdIdx || cdIdx==-1)){
                Integer toIdx = s.indexOf('>',sIdx);
                String css = s.substring(sIdx+6,toIdx);
                css = css.replaceAll('\\=\\"', ':');
                css = css.replaceAll('\\"',';');
                o+=s.substring(idx,s.lastIndexOf('>', sIdx))+' style="'+css+'">';
                idx = s.indexOf('</style>',idx)+8;
                sIdx = s.indexOf('<style',idx);
            }
            else {
                cdCnt++;
                Integer toIdx = s.indexOf(']]>',cdIdx+9);
                Integer lastTagStart = s.lastIndexOf('<', cdIdx-1);
                if(s.substring(lastTagStart,lastTagStart+5)=='<img '){
                    String d = s.substring(cdIdx+9,toIdx).replaceAll('&','&amp;');
                    if(!String.isBlank(d)){
                        o+=s.substring(idx,s.lastIndexOf('>', cdIdx))+' src="https://'+URL.getSalesforceBaseUrl().getHost()+d+'"><!-- </img> -->';
                    }
                    else {
                        o+=s.substring(idx,lastTagStart);
                    }
                    idx=s.indexOf('</img>',toIdx)+6;
                }
                else {
                    o+=s.substring(idx,cdIdx);
                    idx=toIdx+3;
                }
                if(cdCnt==3){
                    h = o;
                    o = '';
                }
                cdIdx = s.indexOf('<![CDATA[',idx);
            }
        }
        o+=s.substring(idx);
        if(cdCnt!=6)throw new TemplateException('Unexpected structure in brand template with id: '+bt.Id);
        return new TemplateLetterhead(bt.Id,h,o);
    }

    /**
        Loads templates using the set of provided template developer names
        @param tNameSet The names (labels) of the email templates to load
    */
    public void loadTemplates(Set<String> tNameSet){
        Set<String> lowerCaseNames = new Set<String>();
        for(String tDevName : tNameSet){
            lowerCaseNames.add(tDevName.toLowerCase());
        }
        EmailTemplate[] etList = ET_LIST_OVERRIDE!=null ? ET_LIST_OVERRIDE : [SELECT Id,BrandTemplateId,DeveloperName,Name,EnhancedLetterheadId,UiType,TemplateType,Subject,Body,HtmlValue FROM EmailTemplate WHERE Name IN :tNameSet ORDER BY CreatedDate];
        List<Id> etClassicIds = new List<Id>();
        List<Id> etLEXIds = new List<Id>();
        for(Integer i=0,etSz=etList.size();i<etSz;i++){
            EmailTemplate et = etList[i];
            if (templateContentByTemplateNames.containsKey(et.Name.toLowerCase())) continue;
            TemplateContent tc = new TemplateContent(et);
            templateContentByTemplateNames.put(et.Name.toLowerCase(), tc);
            tcMap.put(et.Id,tc);
            if(tc.letterheadId!=null){
                tc.letterhead = lhMap.get(tc.letterheadId);
                if(tc.letterhead==null){
                    if(tc.letterheadId.getSobjectType()==EnhancedLetterhead.SObjectType)pendingLetterheadIds.add(tc.letterheadId);
                    if(tc.letterheadId.getSobjectType()==BrandTemplate.SObjectType)pendingBrandTemplateIds.add(tc.letterheadId);
                    tcPendingLhList.add(tc);
                }
            }
            if(tc.isUiTypeLEX())etLEXIds.add(et.Id);
            else if(tc.isUiTypeClassic())etClassicIds.add(et.Id);
            else throw new TemplateException('Unknown Email Template UI Type: '+et.UiType);
        }
        if(!etLEXIds.isEmpty()){
            ContentDocumentLink[] cdlList = CDL_LIST_OVERRIDE!=null ? CDL_LIST_OVERRIDE : [SELECT Id,LinkedEntityId,ContentDocument.LatestPublishedVersion.Id,ContentDocument.LatestPublishedVersion.Title,ContentDocument.LatestPublishedVersion.FileType,ContentDocument.LatestPublishedVersion.VersionData FROM ContentDocumentLink WHERE LinkedEntityId IN :etLEXIds];
            for(Integer i=0,cdlSz=cdlList.size();i<cdlSz;i++){
                ContentDocumentLink cdl = cdlList[i];
                //Try to reuse existing template attachment to reduce memory footprint of attachment bodies
                TemplateAttachment ta = taMap.get(cdl.ContentDocument.LatestPublishedVersion.Id);
                if(ta==null){
                    ta = new TemplateAttachment(cdl.ContentDocument.LatestPublishedVersion);
                    taMap.put(ta.id,ta);
                }
                tcMap.get(cdl.LinkedEntityId).attachments.add(ta);
                
            }
        }
        if(!etClassicIds.isEmpty()){
            Attachment[] aList = A_LIST_OVERRIDE!=null ? A_LIST_OVERRIDE : [SELECT Id,Name,ParentId,ContentType,Body FROM Attachment WHERE ParentId IN :etClassicIds];
            for(Integer i=0,aSz=aList.size();i<aSz;i++){
                Attachment a = aList[i];
                //Try to reuse existing template attachment to reduce memory footprint of attachment bodies
                TemplateAttachment ta = taMap.get(a.Id);
                if(ta==null){
                    ta = new TemplateAttachment(a);
                    taMap.put(ta.id,ta);
                }
                tcMap.get(a.ParentId).attachments.add(ta);
            }

        }
        loadPendingLetterheads();
    }

    /**
        Retrieves the template content for the provided template id
        @param templateId The template id of the template to retrieve from the cache
        @return The template content including letterhead and attachments (if not in cache, then null is returned)
    */
    global TemplateContent getTemplate(Id templateId){
        return tcMap.get(templateId);
    }

    public TemplateContent getTemplateByName(String templateName) {
        return templateContentByTemplateNames.get(templateName.toLowerCase());
    }

    /**
        Class representing an email template and its corresponding letterhead
    */
    global class TemplateContent{
        /**
            The id of the template record
        */
        global Id id{get;private set;}
        /**
            The id of the letterhead connected to the template
        */
        global Id letterheadId{get;private set;}
        /**
             The ui type of the template
        */
        global String uiType{get;private set;}
        /**
            The primary type of the template content
        */
        global String templateType{get;private set;}
        /**
            The subject of the template
        */
        global String subject{get;private set;}
        /**
            The text version of the template
        */
        global String textVersion{get;private set;}
        /**
            The html version of the template
        */
        global String htmlVersion{get;private set;}
        /**
            The letterhead containing the header and footer to use for the template
        */
        global TemplateLetterhead letterhead{get;private set;}
        /**
            The list of attachments for the template
        */
        global List<TemplateAttachment> attachments{get;private set;}

        /**
            Creates a template content using the supplied email template
            @param et The email template from which to retrieve the main cointent of the template
        */
        TemplateContent(EmailTemplate et){
            this.id = et.Id;
            this.letterheadId = et.EnhancedLetterheadId!=null ? et.EnhancedLetterheadId : et.BrandTemplateId;
            this.uiType = et.UiType;
            this.templateType = et.TemplateType;
            this.subject = et.Subject;
            this.textVersion = et.Body;
            this.htmlVersion = et.HtmlValue;
            if(isUiTypeClassic() && !String.isBlank(this.htmlVersion))this.htmlVersion = this.htmlVersion.replaceAll('\\<!\\[CDATA\\[','').replaceAll('\\]\\]\\>','');
            attachments = new List<TemplateAttachment>();
        }

        /**
            @return Whether the provided template is an html template
        */
        global Boolean isHtml(){
            return templateType!='text';
        }

        /**
            Retrieves the template content appropriate for the template when the channel can accept
            both html and text content. If a text template should be generated but no text version exists
            the method strips the html tags from the html output
            @param isHtml Whether to use the html version of the template
            @return Retrieves the data to use depending on appropriate html and text versions
        */
        global String getData(Boolean isHtml){
            return isHtml ? htmlVersion : (String.isBlank(textVersion) && !String.isBlank(htmlVersion) ? htmlVersion.stripHtmlTags().replace('\n ', '\n') : textVersion);
        }

        /**
            @return Whether the ui type is a type of classic email template
        */
        global Boolean isUiTypeClassic(){
            return uiType=='Aloha';
        }
        /**
            @return Whether the ui type is a type of LEX email template
        */
        global Boolean isUiTypeLEX(){
            return uiType=='SFX' || uiType=='SFX_Sample';
        }
        
    }
    /**
        Represents a letterhead
    */
    global class TemplateLetterhead{
        /**
            The id of the letterhead
        */
        global Id id{get;private set;}
        /**
            The header to use for the template
        */
        global String header{get;private set;}
        /**
            The footer to use for the template
        */
        global String footer{get;private set;}

        /**
            Creates a letterhead instance
            @param id The id of the letterhead
            @param header The header to use for the template
            @param footer The footer to use for the template
        */
        TemplateLetterhead(Id id,String header,String footer){
            this.id = id;
            this.header=header;
            this.footer=footer;
        }

        /**
            @return Whether the ui type is a type of classic email template
        */
        global Boolean isUiTypeClassic(){
            return id.getSobjectType()==BrandTemplate.SObjectType;
        }
        /**
            @return Whether the ui type is a type of LEX email template
        */
        global Boolean isUiTypeLEX(){
            return id.getSobjectType()==EnhancedLetterhead.SObjectType;
        }
    }

    /**
        Represents an attachment for an email template
    */
    global class TemplateAttachment{
        /**
            The id of the record which holds the attachment data
        */
        global String id{get;private set;}
        /**
            The name of the attachment
        */
        global String name{get;private set;}
        /**
            The content type of the attachment
        */
        global String contentType{get;private set;}
        /**
            The binary data of the attachment
        */
        global Blob data{get;private set;}

        /**
            Creates a template attachment
            @param id The id of the record which holds the attachment data
            @param name The name of the attachment
            @param contentType The content type of the attachment
            @param data The binary data of the attachment
        */
        TemplateAttachment(Id id,String name,String contentType,Blob data){
            this.id=id;
            this.name=name;
            this.contentType=contentType;
            this.data=data;
        }

        /**
            Creates a template attachment from a file
            @param cv The content version record of the file
        */
        TemplateAttachment(ContentVersion cv){
            this(cv.Id,cv.Title,FT_CT_MAP.get(cv.FileType),cv.VersionData);
        }

        /**
            Creates a template attachment from an attachment
            @param a The attachment record
        */
        TemplateAttachment(Attachment a){
            this(a.Id,a.Name,a.ContentType,a.Body);
        }
    }
}
