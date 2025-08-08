/**
    Utility class containing utility methods shared by multiple classes
*/
public with sharing class C_Util {
    /**
        Cached value for the organization record
    */
    static Organization org;
    /**
        The UUID of the transaction
    */
    static String uuid;

    /**
        Retrieves the organization record into the cache
    */
    private static void getOrg(){
        org = [SELECT Id,Name,InstanceName,IsSandbox FROM Organization];
    }
    /**
        Return whether the current environment is a sandbox, i.e. not a production ord
        @return Whether the current org is a sandbox org
    */
    public static Boolean isSandbox(){
        if(org==null)getOrg();
        return org.IsSandbox;
    }

    /**
        Retrieves the UUID generated for this transaction
        THh UUID is generated upon the first call of the method in the transaction
        @see generateUUID for details on the UUID
        @return The transaction UUID
    */
    public static String getUUID(){
        return uuid!=null ? uuid : (uuid = generateUUID());
    }

    /**
        Sets the UUID for the transaction
        The ability to set the UUID should be used in cases where the UUID
        is provided by the calling party.
        @param uuid The UUID to use for the transacton
    */
    public static void setUUID(String uuid){
        C_Util.uuid = uuid;
    }
    
    /**
        Generates a universally unique identifier using crypto random integers
        The method generates a UUID of version 4
        The UUID is a 128 bt Id in the hex string with in the following format
        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        @return The generated UUID
    */
    public static String generateUUID(){
        Integer i1 = Crypto.getRandomInteger();
        Integer i2 = Crypto.getRandomInteger();
        Integer i3 = Crypto.getRandomInteger();
        Integer i4 = Crypto.getRandomInteger();

        //Setting version number 4 (5th nibble set to 4)
        i2 = (4<<12) | (i2 & ((-1)^(15<<12)));
        //Setting variant (high two bits of 1st nibble set to 0x8)
        i3 = (8<<28) | (i3 & ((-1)^(12<<28)));

        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.CHARS);
        Integer[] ch = new Integer[36];
        hb.set(i1);
        hb.copy(ch,0);
        ch[8]=45;
        hb.set(i2);
        hb.copyHighShort(ch, 9);
        ch[13]=45;
        hb.copyLowShort(ch, 14);
        ch[18]=45;
        hb.set(i3);
        hb.copyHighShort(ch, 19);
        ch[23]=45;
        hb.copyLowShort(ch, 24);
        hb.set(i4);
        hb.copy(ch, 28);

        return String.fromCharArray(ch);
    }

    /**
        Generates a set of ids from the list of sobjects
        @param soList The list of SObjects
        @return The set of ids of the sobjects in the list
    */
    public static Set<Id> getIdSet(SObject[] soList){
        Set<Id> s = new Set<Id>();
        for(Integer i=0,sz=soList.size();i<sz;i++){
            s.add(soList[i].Id);
        }
        return s;
    }
}
