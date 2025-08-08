/**
    Test methods for the SAML JIT handler responsible
    for creating and updating users upon login
*/
@isTest
private class AD_SamlJitHandler_Test {
    /**
        The entity id used for SAML assertions
    */
    private static final String ENTITY_ID = 'https://flysas.my.salesforce.com';
    /**
        The user email and federation Id used for the test user 
    */
    private static final String USER_EMAIL = 'Test.Test@sas.se.test';
    /**
        The GUID of the admin role
    */
    private static final String ROLE_ADMIN = 'b3b4e9a4-ef89-4969-96b4-ba8e93783965';
    /**
        The GUID of the business user role
    */
    private static final String ROLE_BUSINESS_USER = '539a3c0a-7707-4a91-b777-be00323b43c2';
    /**
        The role associated with Sykes team lead
    */
    private static final String SYKES_TEAM_LEAD_ROLE = '4a821bd2-f4bb-4cf8-ae51-0e3f11e6ace2';
    /**
        Setup which creates the test users which the tests are authenticating against
    */
    @testSetup static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String uName = USER_EMAIL + C_Util.generateUUID();
        User u = new User(
            FirstName = 'TEST',
            LastName = 'TEST',
            Email = USER_EMAIL,
            Username = uName,
            EmailEncodingKey = 'ISO-8859-1',
            Alias = uName.substring(uName.length()-6),
            TimeZoneSidKey = 'Europe/Berlin',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = USER_EMAIL,
            ProfileId = p.Id
        );
        insert u;
    }
    /**
        Tests creating a new Saml user 
    */
    @isTest static void newSamlUser(){
        String email = USER_EMAIL+'.com';
        SamlAssertion sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_ADMIN});
        AD_SamlJitHandler sjh = new AD_SamlJitHandler();
        User u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        Profile p = [SELECT Id,Name FROM Profile WHERE Id=:u.ProfileId];
        System.assertEquals('System Administrator',p.Name);
        System.assertEquals('TFIRST',u.FirstName);
        System.assertEquals('TLAST',u.LastName);
        System.assertEquals('UTF-8',u.EmailEncodingKey);
        System.assertEquals('Europe/Berlin',u.TimeZoneSidKey);
        System.assertEquals('sv_SE',u.LocaleSidKey);
        System.assertEquals('en_US',u.LanguageLocaleKey);
        System.assertEquals(email.toLowerCase(),u.Email.toLowerCase());
        System.assertEquals(email,u.FederationIdentifier);
        System.assertEquals(true,u.UserPermissionsSupportUser);
        System.assert(u.Alias.startsWith('TTLAST'));
        System.assertEquals(null,u.FCS_Vendor__c);
    }

    /**
        Tests updating an existing user 
    */
    @isTest static void existingSamlUser(){
        String email = USER_EMAIL+'.com';
        SamlAssertion sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_BUSINESS_USER});
        AD_SamlJitHandler sjh = new AD_SamlJitHandler();
        User u = [SELECT Id FROM User WHERE FederationIdentifier=:USER_EMAIL];
        sjh.updateUser(u.Id,null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        Profile p = [SELECT Id,Name FROM Profile WHERE Id=:u.ProfileId];
        System.assertEquals('Business User',p.Name);
        System.assertEquals('TFIRST',u.FirstName);
        System.assertEquals('TLAST',u.LastName);
        System.assertEquals('UTF-8',u.EmailEncodingKey);
        System.assertEquals('Europe/Berlin',u.TimeZoneSidKey);
        System.assertEquals('sv_SE',u.LocaleSidKey);
        System.assertEquals('en_US',u.LanguageLocaleKey);
        System.assertEquals(email.toLowerCase(),u.Email.toLowerCase());
        System.assertEquals(email,u.FederationIdentifier);
        System.assertEquals(true,u.UserPermissionsSupportUser);
        System.assert(u.Alias.startsWith('TTLAST'));
        System.assertEquals('SAS',u.FCS_Vendor__c);
    }
    
    /** 
        Tests a user with no matching ad role
    */
    @isTest static void testNoMatch(){
        String email = USER_EMAIL+'.com';
        Boolean error = false;
        try{
            SamlAssertion sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{});
            AD_SamlJitHandler sjh = new AD_SamlJitHandler();
            User u = [SELECT Id FROM User WHERE FederationIdentifier=:USER_EMAIL];
            sjh.updateUser(u.Id,null,null,null,email,sa.attributes,sa.assertion);
        }
        catch(AD_SamlJitHandler.JitException e){
            error = true;
        }
        System.assertEquals(true, error);
        
    }

    /**
        Tests assigning the user the Sykes team lead role which links to the Sykes role
        thus giving the user the Sykes Vendor property and agent profile
    */
   
    @isTest static void testParentRole(){
        String email = USER_EMAIL+'.com';
        SamlAssertion sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{SYKES_TEAM_LEAD_ROLE});
        AD_SamlJitHandler sjh = new AD_SamlJitHandler();
        User u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,FCS_Vendor__c,ProfileId,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        Profile p = [SELECT Id,Name FROM Profile WHERE Id=:u.ProfileId];
        System.assertEquals('Vendor',p.Name);
        System.assertEquals('Sykes',u.FCS_Vendor__c);
    }
    

    /**
        Tests that customers with duplicated aliases are managed correctly
    */
    @isTest static void testAliasDuplication(){
        String email = USER_EMAIL+'.com';
        SamlAssertion sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_ADMIN});
        AD_SamlJitHandler sjh = new AD_SamlJitHandler();
        User u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        System.assert(u.Alias.startsWith('TTLAST'));

        email = USER_EMAIL+'.com.se';
        sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_ADMIN});
        sjh = new AD_SamlJitHandler();
        u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        System.assert(u.Alias.startsWith('TTLAST'));

        email = USER_EMAIL+'.com.no';
        sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_ADMIN});
        sjh = new AD_SamlJitHandler();
        u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        System.assert(u.Alias.startsWith('TTLAST'));

        email = USER_EMAIL+'.com.dk';
        sa = generateAssertion('TFIRST', 'TLAST', email, new String[]{ROLE_ADMIN});
        sjh = new AD_SamlJitHandler();
        u = sjh.createUser(null,null,null,email,sa.attributes,sa.assertion);
        System.assertNotEquals(null,u.Id);
        u = [SELECT Id,ProfileId,FCS_Vendor__c,FirstName,LastName,Username,EmailEncodingKey,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,Email,FederationIdentifier,UserPermissionsSupportUser FROM User WHERE Id=:u.Id];
        System.assert(u.Alias.startsWith('TTLAST'));
    }


    /**
        The SAML assertion
    */
    private class SamlAssertion{
        /**
            The base 64 encodes XML assertion
        */
        String assertion;
        /**
            The attributes of the user
        */
        Map<String,String> attributes;
    }
    
    /**
        Generates a SAML assertion and attributes
        @param firstName The first name of the user
        @param lastName The last name of the user
        @param emailAddress The email address of the user
        @param groupIds The list of group ids to assign for the user
        @return The SAML assertion including the XML and attribute map
    */
    private static SamlAssertion generateAssertion(String firstName, String lastName, String emailAddress,String[] groupIds){
        SamlAssertion sa = new SamlAssertion();
        sa.attributes = new Map<String,String>{
            'http://schemas.microsoft.com/identity/claims/tenantid' => '5581c9a8-168b-45f0-abd4-d375da99bf9f',
            'http://schemas.microsoft.com/identity/claims/objectidentifier' => '37768f22-a73e-4215-848d-b2610fb2e592',
            'http://schemas.microsoft.com/identity/claims/displayname' => lastName+', '+firstName,
            'http://schemas.microsoft.com/identity/claims/identityprovider' => 'https://sts.windows.net/5581c9a8-168b-45f0-abd4-d375da99bf9f/',
            'http://schemas.microsoft.com/claims/authnmethodsreferences' => 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname' => firstName,
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' => lastName,
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress' => emailAddress,
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name' => emailAddress
        };

        DateTime issueDate = DateTime.now();
        String xml = '<samlp:Response ID="REDACTEDSAMLRESPONSEID" Version="2.0" IssueInstant="{{ISSUEDATE}}" Destination="{{ENTITYID}}" InResponseTo="REDACTEDSAMLREQUESTID" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"><Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">REDACTEDISSUERID</Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><Assertion ID="REDACTEDASSERTIONID" IssueInstant="{{ISSUEDATE}}" Version="2.0" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"><Issuer>REDACTEDISSUERID</Issuer><Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/><Reference URI="#REDACTEDASSERTIONID"><Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></Transforms><DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/><DigestValue>I1yQxXmzwLG8vvZJgIShpdSOSIag9fT1gD+XhXuy2Uw=</DigestValue></Reference></SignedInfo><SignatureValue>REDACTSIGNVAL</SignatureValue><KeyInfo><X509Data><X509Certificate>REDACTCERT</X509Certificate></X509Data></KeyInfo></Signature><Subject><NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">{{NAME}}</NameID><SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><SubjectConfirmationData InResponseTo="REDACTEDSAMLREQUESTID" NotOnOrAfter="{{ASSETIONVALIDTO}}" Recipient="{{ENTITYID}}"/></SubjectConfirmation></Subject><Conditions NotBefore="{{ASSETIONVALIDFROM}}" NotOnOrAfter="{{ASSETIONVALIDTO}}"><AudienceRestriction><Audience>{{ENTITYID}}</Audience></AudienceRestriction></Conditions><AttributeStatement><Attribute Name="http://schemas.microsoft.com/identity/claims/tenantid"><AttributeValue>REDACTEDTENANTID</AttributeValue></Attribute><Attribute Name="http://schemas.microsoft.com/identity/claims/objectidentifier"><AttributeValue>REDACTEDOBJECTID</AttributeValue></Attribute><Attribute Name="http://schemas.microsoft.com/identity/claims/displayname"><AttributeValue>{{DISPLAYNAME}}</AttributeValue></Attribute>{{GROUPCLAIMS}}<Attribute Name="http://schemas.microsoft.com/identity/claims/identityprovider"><AttributeValue>REDACTEDISSUERID</AttributeValue></Attribute><Attribute Name="http://schemas.microsoft.com/claims/authnmethodsreferences"><AttributeValue>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</AttributeValue></Attribute><Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"><AttributeValue>{{FIRSTNAME}}</AttributeValue></Attribute><Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"><AttributeValue>{{LASTNAME}}</AttributeValue></Attribute><Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"><AttributeValue>{{EMAIL}}</AttributeValue></Attribute><Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"><AttributeValue>{{NAME}}</AttributeValue></Attribute></AttributeStatement><AuthnStatement AuthnInstant="{{ISSUEDATE}}" SessionIndex="REDACTEDASSERTIONID"><AuthnContext><AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</AuthnContextClassRef></AuthnContext></AuthnStatement></Assertion></samlp:Response>';
        xml = xml.replaceAll('\\{\\{ENTITYID\\}\\}',ENTITY_ID);
        xml = xml.replaceAll('\\{\\{ISSUEDATE\\}\\}',JSON.serialize(issueDate).replaceAll('\\"',''));
        xml = xml.replaceAll('\\{\\{ASSETIONVALIDFROM\\}\\}',JSON.serialize(issueDate.addMinutes(-5)).replaceAll('\\"',''));
        xml = xml.replaceAll('\\{\\{ASSETIONVALIDTO\\}\\}',JSON.serialize(issueDate.addMinutes(5)).replaceAll('\\"',''));
        xml = xml.replaceAll('\\{\\{DISPLAYNAME\\}\\}',lastName+', '+firstName);
        xml = xml.replaceAll('\\{\\{NAME\\}\\}',emailAddress);
        xml = xml.replaceAll('\\{\\{FIRSTNAME\\}\\}',firstName);
        xml = xml.replaceAll('\\{\\{LASTNAME\\}\\}',lastName);
        xml = xml.replaceAll('\\{\\{EMAIL\\}\\}',emailAddress);
        
        String xmlGroups = '';
        if(groupIds.size()>0){
            xmlGroups = '<Attribute Name="http://schemas.microsoft.com/ws/2008/06/identity/claims/groups">';
            for(String groupId : groupIds){
                xmlGroups += '<AttributeValue>'+groupId+'</AttributeValue>';
            }
            xmlGroups += '</Attribute>';
        }
        xml = xml.replaceAll('\\{\\{GROUPCLAIMS\\}\\}',xmlGroups);
        sa.assertion = EncodingUtil.base64Encode(Blob.valueOf(xml));

        return sa;
        
    }
}