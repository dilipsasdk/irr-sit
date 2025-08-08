/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for RendererEnhanced (and TemplateCache)
*/

@IsTest
private class MSG_RendererEnhanced_Test {

    /**
        Email template id index for creating virtual email template ids
    */
    static Integer ET_ID_IDX=0;

    /**
    Sets up the template cache to utilize mock templates and create the referenced
*/
    static void setupTemplates(){
        //Mock documents since the documents will never actually be retrieved
        String d0CData = '<![CDATA[/servlet/servlet.ImageServer?id=0153N000000DEPJQA4&oid='+UserInfo.getOrganizationId()+']]>';
        String d1CData = '<![CDATA[/servlet/servlet.ImageServer?id=0153N000000DKWMQA4&oid='+UserInfo.getOrganizationId()+']]>';
        String btPart1 = '<body class="setupTab" ><style background-color="#FFFFFF" bEditID="b1st1" bLabel="body" ></style><center ><table cellpadding="0" width="500" cellspacing="0" id="topTable" height="450" ><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r1st1" bLabel="header" vertical-align="middle" height="0" text-align="left" ></style><img border="0" bEditID="r1sp1" bLabel="headerImage" id="r1sp1">';
        String btPart2 = '</img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r2st1" bLabel="accent1" height="0" ></style><![CDATA[]]></td></tr><tr valign="top" ><td styleInsert="1" height="300" ><style background-color="#FFFFFF" color="#000000" bEditID="r3st1" bLabel="main" font-size="12pt" font-family="arial" ></style><![CDATA[]]></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r4st1" bLabel="accent2" height="0" ></style><![CDATA[]]></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r5st1" bLabel="footer" vertical-align="middle" height="0" text-align="left" ></style><img border="0" bEditID="r5sp1" bLabel="footerImage" id="r5sp1">';
        String btPart3 = '</img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r6st1" bLabel="accent3" height="0" ></style><![CDATA[]]></td></tr></table></center></body>';
        BrandTemplate[] btList = new BrandTemplate[]{
                new BrandTemplate(Id='0163N0000000000QAC',DeveloperName='TEST_MSGSERVICE_BT0',Value=btPart1+d0CData+btPart2+d1CData+btPart3),
                new BrandTemplate(Id='0163N0000000001QAC',DeveloperName='TEST_MSGSERVICE_BT1',Value=btPart1+'<![CDATA[]]>'+btPart2+d1CData+btPart3)
        };
        MSG_TemplateCache.BT_LIST_OVERRIDE = btList;

        EnhancedLetterhead[] elList = new EnhancedLetterhead[]{
                new EnhancedLetterhead(Id='0Rn000000000000SAA',Name='TEST_MSGSERVICE_EL0',LetterheadHeader='TEST HEADER',LetterheadFooter='TEST FOOTER')
        };
        MSG_TemplateCache.EL_LIST_OVERRIDE = elList;

        EmailTemplate[] etList = new EmailTemplate[]{
                new EmailTemplate(Id='00X000000000000EAW',DeveloperName='TEST_MSGSERVICE_ET_CLASSIC_0',Name = 'TEST_MSGSERVICE_ET_CLASSIC_0', UiType='Aloha',TemplateType='html',BrandTemplateId='0163N0000000000QAC',EnhancedLetterheadId=null,Subject='TestCLASSIC0',Body='BODY_CLASSIC_0',HtmlValue='<p>BODY_CLASSIC_0</p>'),
                new EmailTemplate(Id='00X000000000001EAW',DeveloperName='TEST_MSGSERVICE_ET_CLASSIC_1',Name = 'TEST_MSGSERVICE_ET_CLASSIC_1', UiType='Aloha',TemplateType='html',BrandTemplateId='0163N0000000001QAC',EnhancedLetterheadId=null,Subject='TestCLASSIC1',Body='BODY_CLASSIC_1',HtmlValue='<p>BODY_CLASSIC_1</p>'),
                new EmailTemplate(Id='00X000000000002EAW',DeveloperName='TEST_MSGSERVICE_ET_CLASSIC_2',Name = 'TEST_MSGSERVICE_ET_CLASSIC_2', UiType='Aloha',TemplateType='html',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestCLASSIC2',Body='BODY_CLASSIC_2',HtmlValue='<p>BODY_CLASSIC_2</p>'),

                new EmailTemplate(Id='00X000000000000UAA',DeveloperName='TEST_MSGSERVICE_ET_LEX_0',Name = 'TEST_MSGSERVICE_ET_LEX_0', UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId='0Rn000000000000SAA',Subject='TestLEX0',Body=null,HtmlValue='<html style="overflow-y: hidden;"><head>	<title></title></head><body style="height: auto; min-height: auto;">BODY_LEX_0</body></html>'),
                new EmailTemplate(Id='00X000000000001UAA',DeveloperName='TEST_MSGSERVICE_ET_LEX_1',Name = 'TEST_MSGSERVICE_ET_LEX_1', UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestLEX1',Body=null,HtmlValue='<html style="overflow-y: hidden;"><head>	<title></title></head><body style="height: auto; min-height: auto;">BODY_LEX_1</body></html>'),
                new EmailTemplate(Id='00X000000000002UAA',DeveloperName='TEST_MSGSERVICE_ET_LEX_2',Name = 'TEST_MSGSERVICE_ET_LEX_2', UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestLEX1',Body=null,HtmlValue='<html style="overflow-y: hidden;"><head>	<title></title></head><body style="height: auto; min-height: auto;">{{{Case.BADMERGEFIELD.Name}}}</body></html>')
        };
        MSG_TemplateCache.ET_LIST_OVERRIDE = etList;

        //Cannot test files due to how Salesforce works
        ContentDocumentLink[] cdlList = new ContentDocumentLink[]{
                (ContentDocumentLink)JSON.deserialize('{"attributes":{"type":"ContentDocumentLink","url":"/services/data/v47.0/sobjects/ContentDocumentLink/06A3E000001JGzRUAW"},"Id":"06A3E000001JGzRUAW","LinkedEntityId":"00X000000000002UAA","ContentDocumentId":"0693E000000b2VUQAY","ContentDocument":{"attributes":{"type":"ContentDocument","url":"/services/data/v47.0/sobjects/ContentDocument/0693E000000b2VUQAY"},"Id":"0693E000000b2VUQAY","LatestPublishedVersionId":"0683E000000auwmQAA","LatestPublishedVersion":{"attributes":{"type":"ContentVersion","url":"/services/data/v47.0/sobjects/ContentVersion/0683E000000auwmQAA"},"Id":"0683E000000auwmQAA","Title":"1x1-000000ff","FileType":"PNG"}}}', ContentDocumentLink.class)
        };
        cdlList[0].ContentDocument.LatestPublishedVersion.VersionData = EncodingUtil.base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
        MSG_TemplateCache.CDL_LIST_OVERRIDE = cdlList;

        Attachment[] aList = new Attachment[]{
                (Attachment)JSON.deserialize('{"attributes":{"type":"Attachment","url":"/services/data/v47.0/sobjects/Attachment/00P3E000008LCLEUA4"},"ParentId":"00X000000000002EAW","ContentType":"image/png","Id":"00P3E000008LCLEUA4","Name":"1x1-000000ff.png"}',Attachment.class)
        };
        aList[0].Body = EncodingUtil.base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
        MSG_TemplateCache.A_LIST_OVERRIDE = aList;
    }


    /**
        Adds a LEX template to the template cache
        @param name Both the developer name and name (label) of the email template
        @param subject The subject of the email template
        @param htmlValue The body of the email template
        @return The virtual id of the email template
    */
    static Id addLEXTemplate(String name,String subject,String htmlValue){
        if(MSG_TemplateCache.ET_LIST_OVERRIDE==null)MSG_TemplateCache.ET_LIST_OVERRIDE = new List<EmailTemplate>();
        Id etId = '00X0000000010'+(ET_ID_IDX<10?'0':'')+ET_ID_IDX;
        ET_ID_IDX++;
        MSG_TemplateCache.ET_LIST_OVERRIDE.add(new EmailTemplate(Id=etId,DeveloperName=name, Name = name, UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject=subject,Body=null,HtmlValue=htmlValue));
        return etId;
    }

    /**
        Adds a classic template to the template cache
        @param name Both the developer name and name (label) of the email template
        @param subject The subject of the email template
        @param htmlValue The body of the email template
        @param textValue The body of the email template
        @return The virtual id of the email template
    */
    static Id addClassicTemplate(String name,String subject,String htmlValue,String textValue){
        if(MSG_TemplateCache.ET_LIST_OVERRIDE==null)MSG_TemplateCache.ET_LIST_OVERRIDE = new List<EmailTemplate>();
        Id etId = '00X0000000010'+(ET_ID_IDX<10?'0':'')+ET_ID_IDX;
        ET_ID_IDX++;
        MSG_TemplateCache.ET_LIST_OVERRIDE.add(new EmailTemplate(Id=etId,DeveloperName=name,Name = name, UiType='Aloha',TemplateType='html',BrandTemplateId=null,EnhancedLetterheadId=null,Subject=subject,Body=textValue,HtmlValue=htmlValue));
        return etId;
    }


    /**
        Tests rendering classic email template using the enhanced renderer
    */
    @IsTest
    static void enhancedRendererClassicTemplate(){
        setupTemplates();
        String baseUrl = 'https://'+Url.getSalesforceBaseUrl().getHost();
        Set<String> templateNameSet = new Set<String>{
                'TEST_MSGSERVICE_ET_CLASSIC_0',
                'TEST_MSGSERVICE_ET_CLASSIC_1',
                'TEST_MSGSERVICE_ET_CLASSIC_2'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNameSet);
        MSG_TemplateCache.TemplateContent t0 = tc.getTemplate('00X000000000000EAW');
        MSG_TemplateCache.TemplateContent t1 = tc.getTemplate('00X000000000001EAW');
        MSG_TemplateCache.TemplateContent t2 = tc.getTemplate('00X000000000002EAW');
        System.assertEquals('TestCLASSIC0',t0.subject);
        System.assertEquals('TestCLASSIC1',t1.subject);
        System.assertEquals('TestCLASSIC2',t2.subject);
        System.assertNotEquals(null, t0.letterhead);
        System.assertNotEquals(null, t0.letterheadId);
        System.assertNotEquals(null, t1.letterhead);
        System.assertNotEquals(null, t1.letterheadId);
        System.assertEquals(null, t2.letterhead);
        System.assertEquals(null, t2.letterheadId);
        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].template = 'TEST_MSGSERVICE_ET_CLASSIC_0';
        messages[1].template = 'TEST_MSGSERVICE_ET_CLASSIC_1';
        messages[2].template = 'TEST_MSGSERVICE_ET_CLASSIC_2';
        MSG_RendererEnhanced r = new MSG_RendererEnhanced((MSG_ITemplateCache) tc);
        r.renderMessage(messages[0]);
        r.renderMessage(messages[1]);
        r.renderMessage(messages[2]);
        System.assertEquals('TestCLASSIC0',messages[0].subject);
        System.assertEquals('TestCLASSIC1',messages[1].subject);
        System.assertEquals('TestCLASSIC2',messages[2].subject);

        //Validating message 0
        Dom.XmlNode r0 = getRootElement(messages[0].content.replaceAll('<!-- </img> -->','</img>'));
        System.assertEquals('body',r0.getName());
        System.assertEquals('background-color:#FFFFFF; bEditID:b1st1; bLabel:body;',r0.getAttributeValue('style', null).trim());
        Dom.XmlNode table0 = r0.getChildElement('center', null).getChildElement('table', null);
        Dom.XmlNode[] tr0 = table0.getChildElements();
        validateClassicRowContent(
                tr0[0],
                'background-color:#FFFFFF; bEditID:r1st1; bLabel:header; vertical-align:middle; height:0; text-align:left;',
                baseUrl+'/servlet/servlet.ImageServer?id=0153N000000DEPJQA4&oid='+UserInfo.getOrganizationId()
        );
        validateClassicRowContent(
                tr0[1],
                'background-color:#FFFFFF; bEditID:r2st1; bLabel:accent1; height:0;',
                null
        );
        Dom.XmlNode[] body0 = validateAndGetClassicBodyRow(tr0[2],'background-color:#FFFFFF; color:#000000; bEditID:r3st1; bLabel:main; font-size:12pt; font-family:arial;');
        System.assertEquals(1,body0.size());
        System.assertEquals('p',body0[0].getName());
        validateClassicRowContent(
                tr0[3],
                'background-color:#FFFFFF; bEditID:r4st1; bLabel:accent2; height:0;',
                null
        );
        validateClassicRowContent(
                tr0[4],
                'background-color:#FFFFFF; bEditID:r5st1; bLabel:footer; vertical-align:middle; height:0; text-align:left;',
                baseUrl+'/servlet/servlet.ImageServer?id=0153N000000DKWMQA4&oid='+UserInfo.getOrganizationId()
        );
        validateClassicRowContent(
                tr0[5],
                'background-color:#FFFFFF; bEditID:r6st1; bLabel:accent3; height:0;',
                null
        );

        //Validating message 1
        Dom.XmlNode r1 = getRootElement(messages[1].content.replaceAll('<!-- </img> -->','</img>'));
        System.assertEquals('body',r1.getName());
        System.assertEquals('background-color:#FFFFFF; bEditID:b1st1; bLabel:body;',r1.getAttributeValue('style', null).trim());
        Dom.XmlNode table1 = r1.getChildElement('center', null).getChildElement('table', null);
        Dom.XmlNode[] tr1 = table1.getChildElements();
        validateClassicRowContent(
                tr1[0],
                'background-color:#FFFFFF; bEditID:r1st1; bLabel:header; vertical-align:middle; height:0; text-align:left;',
                null
        );
        validateClassicRowContent(
                tr1[1],
                'background-color:#FFFFFF; bEditID:r2st1; bLabel:accent1; height:0;',
                null
        );
        Dom.XmlNode[] body1 = validateAndGetClassicBodyRow(tr1[2],'background-color:#FFFFFF; color:#000000; bEditID:r3st1; bLabel:main; font-size:12pt; font-family:arial;');
        System.assertEquals(1,body1.size());
        System.assertEquals('p',body1[0].getName());
        validateClassicRowContent(
                tr1[3],
                'background-color:#FFFFFF; bEditID:r4st1; bLabel:accent2; height:0;',
                null
        );
        validateClassicRowContent(
                tr1[4],
                'background-color:#FFFFFF; bEditID:r5st1; bLabel:footer; vertical-align:middle; height:0; text-align:left;',
                baseUrl+'/servlet/servlet.ImageServer?id=0153N000000DKWMQA4&oid='+UserInfo.getOrganizationId()
        );
        validateClassicRowContent(
                tr1[5],
                'background-color:#FFFFFF; bEditID:r6st1; bLabel:accent3; height:0;',
                null
        );

        //Validating message 2
        System.assertEquals('<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head><p>BODY_CLASSIC_2</p></html>',messages[2].content);



        //Testing text variants
        List<IRR_MOD_Message> messagesText = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messagesText[0].template='TEST_MSGSERVICE_ET_CLASSIC_0';
        messagesText[1].template='TEST_MSGSERVICE_ET_CLASSIC_1';
        messagesText[2].template='TEST_MSGSERVICE_ET_CLASSIC_2';
        messagesText[0].channel = IRR_MOD_Message.MessageChannel.SMS;
        messagesText[1].channel = IRR_MOD_Message.MessageChannel.SMS;
        messagesText[2].channel = IRR_MOD_Message.MessageChannel.SMS;
        r.renderMessage(messagesText[0]);
        r.renderMessage(messagesText[1]);
        r.renderMessage(messagesText[2]);
        System.assertEquals('TestCLASSIC0',messagesText[0].subject);
        System.assertEquals('TestCLASSIC1',messagesText[1].subject);
        System.assertEquals('TestCLASSIC2',messagesText[2].subject);
        System.assertEquals('BODY_CLASSIC_0',messagesText[0].content);
        System.assertEquals('BODY_CLASSIC_1',messagesText[1].content);
        System.assertEquals('BODY_CLASSIC_2',messagesText[2].content);
    }

    /**
        Tests rendering LEX email template using the enhanced renderer
    */
    @IsTest
    static void enhancedRendererLEXTemplate(){
        setupTemplates();
        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].template='TEST_MSGSERVICE_ET_LEX_0';
        messages[1].template='TEST_MSGSERVICE_ET_LEX_1';
        
        Set<String> templateNames = new Set<String>{
                'TEST_MSGSERVICE_ET_LEX_0',
                'TEST_MSGSERVICE_ET_LEX_1'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNames);

        MSG_TemplateCache.TemplateContent t0 = tc.getTemplate('00X000000000000UAA');
        MSG_TemplateCache.TemplateContent t1 = tc.getTemplate('00X000000000001UAA');
        System.assertEquals('TestLEX0',t0.subject);
        System.assertEquals('TestLEX1',t1.subject);

        MSG_RendererEnhanced r = new MSG_RendererEnhanced((MSG_ITemplateCache) tc);
        r.renderMessage(messages[0]);
        r.renderMessage(messages[1]);
        System.assertEquals('TestLEX0',messages[0].subject);
        System.assertEquals('TestLEX1',messages[1].subject);

        String elHeader = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><table border="0" cellpadding="1" width="100%" cellspacing="5" height="100%"><tbody><tr><td>TEST HEADER</td></tr><tr><td><div id="htmlValue">';
        String elFooter = '</div></td></tr><tr><td>TEST FOOTER</td></tr></tbody></table>';
        String elBody0 = '<html style="overflow-y: hidden;"><head>	<title></title></head><body style="height: auto; min-height: auto;">BODY_LEX_0</body></html>';
        String elBody1 = '<html style="overflow-y: hidden;"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">	<title></title></head><body style="height: auto; min-height: auto;">BODY_LEX_1</body></html>';
        System.assertEquals(elHeader,messages[0].content.substring(0,elHeader.length()));
        System.assertEquals(elFooter,messages[0].content.substring(messages[0].content.length()-elFooter.length()));
        System.assertEquals(elHeader+elBody0+elFooter,messages[0].content);
        System.assertEquals(elBody1,messages[1].content);
    }



    /**
        Tests implementation of files and attachments
    */
    @IsTest
    static void filesAndAttachment(){
        User u = new User(Id=UserInfo.getUserId());
        EmailTemplate[] etList = new EmailTemplate[]{
                new EmailTemplate(DeveloperName='TEST_MSGSERVICE_FA_CLASSIC_0',Name='TEST_MSGSERVICE_FA_CLASSIC_0',FolderId=UserInfo.getUserId(),UiType='Aloha',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestClassic0',Body='TestClassic0',HtmlValue='<p>TestClassic0</p>'),
                new EmailTemplate(DeveloperName='TEST_MSGSERVICE_FA_LEX_0',Name='TEST_MSGSERVICE_FA_LEX_0',FolderId=UserInfo.getUserId(),UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestLEX0',Body=null,HtmlValue='<p>TestLEX0</p>'),
                new EmailTemplate(DeveloperName='TEST_MSGSERVICE_FA_CLASSIC_1',Name='TEST_MSGSERVICE_FA_CLASSIC_1',FolderId=UserInfo.getUserId(),UiType='Aloha',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestClassic1',Body='TestClassic1',HtmlValue='<p>TestClassic1</p>'),
                new EmailTemplate(DeveloperName='TEST_MSGSERVICE_FA_LEX_1',Name='TEST_MSGSERVICE_FA_LEX_1',FolderId=UserInfo.getUserId(),UiType='SFX',TemplateType='custom',BrandTemplateId=null,EnhancedLetterheadId=null,Subject='TestLEX1',Body=null,HtmlValue='<p>TestLEX1</p>')
        };
        System.runAs(u){
            insert etList;
        }
        ContentVersion cv = new ContentVersion(Title='TESTFile',PathOnClient='TESTFile.png',FirstPublishLocationId=etList[1].Id,VersionData=EncodingUtil.base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='));
        insert cv;

        Attachment a = new Attachment(Name='TestAttachment.png',ParentId=etList[0].Id,Body=EncodingUtil.base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII='));
        insert a;


        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].template='TEST_MSGSERVICE_FA_CLASSIC_0';
        messages[1].template='TEST_MSGSERVICE_FA_CLASSIC_1';
        messages[2].template='TEST_MSGSERVICE_FA_LEX_0';
        messages[3].template='TEST_MSGSERVICE_FA_LEX_1';

        Set<String> templateNames = new Set<String>{
                'TEST_MSGSERVICE_FA_CLASSIC_0',
                'TEST_MSGSERVICE_FA_CLASSIC_1',
                'TEST_MSGSERVICE_FA_LEX_0',
                'TEST_MSGSERVICE_FA_LEX_1'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNames);

        MSG_TemplateCache.TemplateContent t0 = tc.getTemplateByName(messages[0].template);
        MSG_TemplateCache.TemplateContent t1 = tc.getTemplateByName(messages[1].template);
        MSG_TemplateCache.TemplateContent t2 = tc.getTemplateByName(messages[2].template);
        MSG_TemplateCache.TemplateContent t3 = tc.getTemplateByName(messages[3].template);
        System.assertEquals(1,t0.attachments.size());
        System.assertEquals(0,t1.attachments.size());
        System.assertEquals(1,t2.attachments.size());
        System.assertEquals(0,t3.attachments.size());
        System.assertEquals('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',EncodingUtil.base64Encode(t0.attachments[0].data));
        System.assertEquals('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',EncodingUtil.base64Encode(t2.attachments[0].data));
    }



    /**
        Tests classic email templates with expressions
    */
    @IsTest
    static void enhancedRendererClassicExpressions(){

        addClassicTemplate('TEST_EXPR_0', 'TEST TO {!Recipient.lastName}', '<p>STARTPOS{!Sender.UserName} TEST TO {!Receiving_User.UserName} - {!Case.Subject}ENDPOS</p>','{!Receiving_User.UserName} - {!Case.Subject}');
        addClassicTemplate('TEST_EXPR_1', 'TEST TO {!Recipient.lastName}', '<p>STARTPOS{!Sender.UserName} TEST TO {!Lead.FirstName} - {!Case.Subject}ENDPOS</p>','{!Lead.FirstName} - {!Case.Subject}');
        addClassicTemplate('TEST_EXPR_2', 'TEST TO {!Recipient.lastName}', '<p>STARTPOS{!Sender.UserName} TEST TO {!Contact.FirstName} - {!Case.Account.Name}ENDPOS</p>','TEST TO {!Contact.FirstName} - {!Case.Account.Name}');

        List<Map<String, Object>> variableList = new List<Map<String, Object>>{
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'ULN1'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Receiving_User' => new Map<String, Object>{'UserName' => 'test2@test.com'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT'}
                },
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'LLN0'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT'}
                },
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'CLN0'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Contact' => new Map<String, Object>{'FirstName' => 'CFN0'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT', 'Account' => new Map<String,Object> {'Name' => 'ACCNAME0'}}
                }
        };

        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].variables = variableList[0];
        messages[1].variables = variableList[1];
        messages[2].variables = variableList[2];
        messages[0].template='TEST_EXPR_0';
        messages[1].template='TEST_EXPR_1';
        messages[2].template='TEST_EXPR_2';

        Set<String> templateNames = new Set<String>{
                'TEST_EXPR_0',
                'TEST_EXPR_1',
                'TEST_EXPR_2'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNames);

        MSG_RendererEnhanced r = new MSG_RendererEnhanced((MSG_ITemplateCache) tc);
        r.renderMessage(messages[0]);
        r.renderMessage(messages[1]);
        r.renderMessage(messages[2]);

        System.assertEquals('TEST TO ULN1',messages[0].subject);
        System.assertEquals('TEST TO LLN0',messages[1].subject);
        System.assertEquals('TEST TO CLN0',messages[2].subject);

        String b0 = messages[0].content.substring(messages[0].content.indexOf('STARTPOS')+8,messages[0].content.indexOf('ENDPOS'));
        String b1 = messages[1].content.substring(messages[1].content.indexOf('STARTPOS')+8,messages[1].content.indexOf('ENDPOS'));
        String b2 = messages[2].content.substring(messages[2].content.indexOf('STARTPOS')+8,messages[2].content.indexOf('ENDPOS'));

        System.assertEquals('test@test.com TEST TO test2@test.com - TEST SUBJECT',b0);
        System.assertEquals('test@test.com TEST TO  - TEST SUBJECT',b1);
        System.assertEquals('test@test.com TEST TO CFN0 - ACCNAME0',b2);
    }

    /**
        Tests lightning email templates with expressions
    */
    @IsTest
    static void enhancedRendererLexExpressions(){
        addLEXTemplate('TEST_EXPR_0', 'TEST TO {{{Recipient.lastName}}}', '<p>STARTPOS{{{Sender.UserName}}} TEST TO {{{Receiving_User.UserName}}} - {{{Case.Subject}}}ENDPOS</p>');
        addLEXTemplate('TEST_EXPR_1', 'TEST TO {{{Recipient.lastName}}}', '<p>STARTPOS{{{Sender.UserName}}} TEST TO {{{Lead.FirstName}}} - {{{Case.Subject}}}ENDPOS</p>');
        addLEXTemplate('TEST_EXPR_2', 'TEST TO {{{Recipient.lastName}}}', '<p>STARTPOS{{{Sender.UserName}}} TEST TO {{{Contact.FirstName}}} - {{{Case.Account.Name}}}ENDPOS</p>');
        addLEXTemplate('TEST_FMT_DATE', 'TEST TO {{{Recipient.lastName}}}', '<p>STARTPOSNEW DEPARTURE TIME: [[[formatDatetimeUTC(flight.delayedTime, "HH:mm")]]]ENDPOS</p>');
        addLEXTemplate('TEST_CONTAINS', 'TEST CONTAINS', '<p>STARTPOS[[[LOOP(Recipients, "rec")]]][[[DISPLAYIF(contains(rec.lastName, DisplayRecipients))]]][[[rec.value]]][[[ENDDISPLAYIF()]]][[[ENDLOOP()]]]ENDPOS</p>');

        Datetime delayedTime = Datetime.newInstanceGmt(2020, 5, 28, 14, 35, 0);
        //Renderer expects serialized Datetime
        String serializedDelayedTime = JSON.serialize(delayedTime).replace('"', '');

        List<Map<String, Object>> variableList = new List<Map<String, Object>>{
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'ULN1'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Receiving_User' => new Map<String, Object>{'UserName' => 'test2@test.com'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT'}
                },
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'LLN0'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT'}
                },
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'CLN0'},
                        'Sender' => new Map<String, Object>{'UserName' => 'test@test.com'},
                        'Contact' => new Map<String, Object>{'FirstName' => 'CFN0'},
                        'Case' => new Map<String, Object>{'Subject' => 'TEST SUBJECT', 'Account' => new Map<String,Object> {'Name' => 'ACCNAME0'}}
                },
                new Map<String, Object>{
                        'Recipient' => new Map<String, Object>{'lastName' => 'DATENAME'},
                        'flight' => new Map<String, Object>{'delayedTime' => serializedDelayedTime}
                },
                new Map<String, Object>{
                        'DisplayRecipients' => new List<String>{'EXISTS', 'ALSO_EXISTS'},
                        'Recipients' => new List<Map<String, Object>> {
                                new Map<String, Object>{'lastName' => 'EXISTS', 'value' => 'EXISTS_VALUE'},
                                new Map<String, Object>{'lastName' => 'NOT_EXISTS', 'value' => 'NOT_EXISTS_VALUE'},
                                new Map<String, Object>{'lastName' => 'ALSO_EXISTS', 'value' => 'ALSO_EXISTS_VALUE'}
                        }
                }
        };

        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].variables = variableList[0];
        messages[1].variables = variableList[1];
        messages[2].variables = variableList[2];
        messages[3].variables = variableList[3];
        messages[4].variables = variableList[4];
        messages[0].template='TEST_EXPR_0';
        messages[1].template='TEST_EXPR_1';
        messages[2].template='TEST_EXPR_2';
        messages[3].template='TEST_FMT_DATE';
        messages[4].template='TEST_CONTAINS';

        Set<String> templateNames = new Set<String>{
                'TEST_EXPR_0',
                'TEST_EXPR_1',
                'TEST_EXPR_2',
                'TEST_FMT_DATE',
                'TEST_CONTAINS'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNames);

        MSG_RendererEnhanced r = new MSG_RendererEnhanced((MSG_ITemplateCache) tc);
        r.renderMessage(messages[0]);
        r.renderMessage(messages[1]);
        r.renderMessage(messages[2]);
        r.renderMessage(messages[3]);
        r.renderMessage(messages[4]);

        System.assertEquals('TEST TO ULN1',messages[0].subject);
        System.assertEquals('TEST TO LLN0',messages[1].subject);
        System.assertEquals('TEST TO CLN0',messages[2].subject);
        System.assertEquals('TEST TO DATENAME',messages[3].subject);
        System.assertEquals('TEST CONTAINS',messages[4].subject);

        String b0 = messages[0].content.substring(messages[0].content.indexOf('STARTPOS')+8,messages[0].content.indexOf('ENDPOS'));
        String b1 = messages[1].content.substring(messages[1].content.indexOf('STARTPOS')+8,messages[1].content.indexOf('ENDPOS'));
        String b2 = messages[2].content.substring(messages[2].content.indexOf('STARTPOS')+8,messages[2].content.indexOf('ENDPOS'));
        String b3 = messages[3].content.substring(messages[3].content.indexOf('STARTPOS')+8,messages[3].content.indexOf('ENDPOS'));
        String b4 = messages[4].content.substring(messages[4].content.indexOf('STARTPOS')+8,messages[4].content.indexOf('ENDPOS'));

        System.assertEquals('test@test.com TEST TO test2@test.com - TEST SUBJECT',b0);
        System.assertEquals('test@test.com TEST TO  - TEST SUBJECT',b1);
        System.assertEquals('test@test.com TEST TO CFN0 - ACCNAME0',b2);
        System.assertEquals('NEW DEPARTURE TIME: 14:35', b3);
        System.assertEquals('EXISTS_VALUEALSO_EXISTS_VALUE', b4);
    }



    /**
     * Tests that control functions used for conditional display and loopping works properly
     */
    @IsTest
    static void enhancedRendererControlFunctions(){
        addLEXTemplate('TEST_CTRL_0', 'TEST', '<p>STARTPOS{{{DISPLAYIF(!Contact.HasOptedOutOfEmail)}}}{{{Contact.LastName}}} {{{ENDDISPLAYIF()}}}ENDPOS</p>');
        addLEXTemplate('TEST_CTRL_1', 'TEST', '<p>STARTPOS{{{LOOP(Account.Contacts,"con")}}}{{{con.LastName}}} {{{ENDLOOP()}}}ENDPOS</p>');
        addLEXTemplate('TEST_CTRL_2', 'TEST', '<p>STARTPOS{{{LOOP(Account.Contacts,"con")}}}{{{DISPLAYIF(!con.HasOptedOutOfEmail)}}}{{{con.LastName}}} {{{ENDDISPLAYIF()}}}{{{ENDLOOP()}}}ENDPOS</p>');

        List<Map<String, Object>> variableList = new List<Map<String, Object>>{
                new Map<String, Object>{
                        'Contact' => new Map<String, Object>{
                                'HasOptedOutOfEmail' => false,
                                'LastName' => 'CLN4'
                        }
                },
                new Map<String, Object>{
                        'Account' => new Map<String, Object>{
                                'Contacts' => new List<Map<String, Object>>{
                                        new Map<String, Object>{'LastName' => 'CLN4'},
                                        new Map<String, Object>{'LastName' => 'CLN5'},
                                        new Map<String, Object>{'LastName' => 'CLN6'}
                                }
                        }
                },
                new Map<String, Object>{
                        'Account' => new Map<String, Object>{
                                'Contacts' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                                'HasOptedOutOfEmail' => false,
                                                'LastName' => 'CLN4'
                                        },
                                        new Map<String, Object>{
                                                'HasOptedOutOfEmail' => true,
                                                'LastName' => 'CLN5'
                                        },
                                        new Map<String, Object>{
                                                'HasOptedOutOfEmail' => false,
                                                'LastName' => 'CLN6'
                                        }
                                }
                        }
                }
        };

        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>{
                new IRR_MOD_Message(),
                new IRR_MOD_Message(),
                new IRR_MOD_Message()
        };
        messages[0].variables = variableList[0];
        messages[1].variables = variableList[1];
        messages[2].variables = variableList[2];
        messages[0].template='TEST_CTRL_0';
        messages[1].template='TEST_CTRL_1';
        messages[2].template='TEST_CTRL_2';

        Set<String> templateNames = new Set<String>{
                'TEST_CTRL_0',
                'TEST_CTRL_1',
                'TEST_CTRL_2'
        };

        MSG_TemplateCache tc = new MSG_TemplateCache();
        tc.loadTemplates(templateNames);

        MSG_RendererEnhanced r = new MSG_RendererEnhanced((MSG_ITemplateCache) tc);
        r.renderMessage(messages[0]);
        r.renderMessage(messages[1]);
        r.renderMessage(messages[2]);

        System.assertEquals('TEST',messages[0].subject);
        System.assertEquals('TEST',messages[1].subject);
        System.assertEquals('TEST',messages[2].subject);

        String b0 = messages[0].content.substring(messages[0].content.indexOf('STARTPOS')+8,messages[0].content.indexOf('ENDPOS'));
        String b1 = messages[1].content.substring(messages[1].content.indexOf('STARTPOS')+8,messages[1].content.indexOf('ENDPOS'));
        String b2 = messages[2].content.substring(messages[2].content.indexOf('STARTPOS')+8,messages[2].content.indexOf('ENDPOS'));

        System.assertEquals('CLN4 ',b0);
        System.assertEquals('CLN4 CLN5 CLN6 ',b1);
        System.assertEquals('CLN4 CLN6 ',b2);
    }




    /**
        Validates the table row in classic email template
        @param tr The table row xml node
        @param tdStyle The style of the table data cell
        @param imgSrc The image source attribute or null if no image should be present
    */
    static void validateClassicRowContent(Dom.XmlNode tr,String tdStyle,String imgSrc){
        Dom.XmlNode td = tr.getChildElement('td', null);
        System.assertEquals(tdStyle,td.getAttributeValue('style', null).trim());
        Dom.XmlNode[] img = td.getChildElements();
        System.assertEquals(imgSrc!=null ? 1 : 0, img.size());
        if(imgSrc!=null){
            System.assertEquals(imgSrc,img[0].getAttributeValue('src', null));
        }
    }
    /**
        Validates the body table wor in classic email templates and returns the content node
        @param tr The table row xml node
        @param tdStyle The style of the table data cell
        @return The child nodes representing the content of the body
    */
    static Dom.XmlNode[] validateAndGetClassicBodyRow(Dom.XmlNode tr,String tdStyle){
        Dom.XmlNode td = tr.getChildElement('td', null);
        System.assertEquals(tdStyle,td.getAttributeValue('style', null).trim());
        return td.getChildElements();
    }

    /**
        Retrieves the root element by parsing the provided xml string
        @param xmlStr The xml string to parse
        @return The root element
    */
    static Dom.XmlNode getRootElement(String xmlStr){
        Dom.Document d = new Dom.Document();
        d.load(xmlStr);
        return d.getRootElement();
    }
}