/**
    Retrieves settings in key value format from settings metadata
    @author Peter Södergren
*/
public with sharing class C_Settings {
    /**
        Map of all loaded groups of settings
    */
    static final Map<String,SettingsGroup> sgMap = new Map<String,SettingsGroup>();
    /**
        Variable used for testing to enable overriding the settings retrieved from custom metadata
    */
    @TestVisible static C_GeneralSetting__mdt[] SETTINGS_OVERRIDE;

    /**
        Retrieves a collection of settings for the provided group name
        @param groupName The name of the group for whic to retrieve the settings
        @return The group of settings for the group name
    */
    public static SettingsGroup getSettings(String groupName){
        SettingsGroup sg = sgMap.get(groupName);
        if(sg==null){
            sg = new SettingsGroup(SETTINGS_OVERRIDE!=null ? SETTINGS_OVERRIDE : [SELECT MasterLabel,Value__c FROM C_GeneralSetting__mdt WHERE Group__c=:groupName]);
            sgMap.put(groupName,sg);
        }
        return sg;
    }

    /**
        Represents the settings associated with a group
    */
    public class SettingsGroup{
        /**
            Map of values for the settings
        */
        Map<String,String> valMap;
        /**
            Creates a group of settings
            @param settingsList The list of settings for the group
        */
        private SettingsGroup(C_GeneralSetting__mdt[] settingsList){
            valMap = new Map<String,String>();
            for(Integer i=0,sz=settingsList.size();i<sz;i++){
                C_GeneralSetting__mdt s = settingsList[i];
                valMap.put(s.MasterLabel,s.Value__c);
            }
        }
        /**
            Retrieves the value of the specified setting
            @param name The name of setting to fetch
            @return The setting value
        */
        public String get(String name){
            return valMap.get(name);
        }

        /**
            Retrieves the integer value of the specified setting
            @param name The name of setting to fetch
            @return The setting value
        */
        public Integer getInt(String name){
            String s = valMap.get(name);
            return s!=null ? Integer.valueOf(s) : null;
        }

        /**
            Retrieves the boolean value of the specified setting
            @param name The name of setting to fetch
            @param defaultVal The default value to return in case no value is defined
            @return The setting value
        */
        public Boolean getBool(String name,Boolean defaultVal){
            String s = valMap.get(name);
            return s!=null ? s=='true' : defaultVal;
        }

        /**
            Sets a setting value for the current transaction
            @param name The name of the setting which should be set
            @param val The value to set for the setting
        */
        public void set(String name,String val){
            valMap.put(name,val);
        }

        /**
            @return The keys present in the settings group
        */
        public Set<String> keySet(){
            return valMap.keySet();
        }
    }
}
