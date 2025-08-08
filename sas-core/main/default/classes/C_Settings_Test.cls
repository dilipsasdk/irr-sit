/**
    Test class for C_Settings class operations
    @author Peter Södergren
*/
@isTest 
private class C_Settings_Test {
    /**
        Tests retrieving differnt types of values to test conversion of values
    */
    @isTest static void testValues(){
        String groupName = 'TestGroup';
        C_Settings.SETTINGS_OVERRIDE = new C_GeneralSetting__mdt[]{
            new C_GeneralSetting__mdt(MasterLabel='TestStr',Value__c='str',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestInt',Value__c='5',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBadInt',Value__c='a',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBoolTrue',Value__c='true',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBoolFalse',Value__c='false',Group__c=groupName)
        };

        C_Settings.SettingsGroup sg = C_Settings.getSettings(groupName);
        System.assertEquals('str', sg.get('TestStr'));
        System.assertEquals(5, sg.getInt('TestInt'));
        System.assertEquals(true, sg.getBool('TestBoolTrue',null));
        System.assertEquals(false, sg.getBool('TestBoolFalse',null));
        Boolean error = false;
        try{
            Integer t = sg.getInt('TestBadInt');
        }
        catch(Exception e){
            error = true;
        }

        System.assertEquals(true,error);

        Set<String> keys = sg.keySet();
        System.assertEquals(5,keys.size());
        System.assert(keys.containsAll(new String[]{'TestStr','TestInt','TestBadInt','TestBoolTrue','TestBoolFalse'}));


    }

    /**
        Tests setting values to ensure that they are seen by others
    */
    @isTest static void testSetValues(){
        String groupName = 'TestGroup';
        C_Settings.SETTINGS_OVERRIDE = new C_GeneralSetting__mdt[]{
            new C_GeneralSetting__mdt(MasterLabel='TestStr',Value__c='str',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestInt',Value__c='5',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBadInt',Value__c='a',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBoolTrue',Value__c='true',Group__c=groupName),
            new C_GeneralSetting__mdt(MasterLabel='TestBoolFalse',Value__c='false',Group__c=groupName)
        };

        C_Settings.SettingsGroup sgPre = C_Settings.getSettings(groupName);
        C_Settings.SettingsGroup sg = C_Settings.getSettings(groupName);
        sg.set('TestStr','abc');
        sg.set('TestInt','6');
        sg.set('TestBool','true');
        C_Settings.SettingsGroup sgPost = C_Settings.getSettings(groupName);

        System.assertEquals('abc',sgPre.get('TestStr'));
        System.assertEquals(6,sgPre.getInt('TestInt'));
        System.assertEquals(true,sgPre.getBool('TestBool',null));

        System.assertEquals('abc',sgPost.get('TestStr'));
        System.assertEquals(6,sgPost.getInt('TestInt'));
        System.assertEquals(true,sgPost.getBool('TestBool',null));

        Set<String> keys = sgPre.keySet();
        System.assertEquals(6,keys.size());
        System.assert(keys.containsAll(new String[]{'TestStr','TestInt','TestBadInt','TestBoolTrue','TestBoolFalse','TestBool'}));

        keys = sg.keySet();
        System.assertEquals(6,keys.size());
        System.assert(keys.containsAll(new String[]{'TestStr','TestInt','TestBadInt','TestBoolTrue','TestBoolFalse','TestBool'}));

        keys = sgPost.keySet();
        System.assertEquals(6,keys.size());
        System.assert(keys.containsAll(new String[]{'TestStr','TestInt','TestBadInt','TestBoolTrue','TestBoolFalse','TestBool'}));
    }
}
