/**
    Unit tests for the utility class
*/
@isTest 
private class C_Util_Test {
    /**
        Tests that the is sandbox method returns the correct results
    */
    @isTest static void isSandbox(){
        Organization org = [SELECT Id,IsSandbox FROM Organization];
        System.assertEquals(org.IsSandbox,C_Util.isSandbox());
    }

    /**
        Tests the generation of UUIDs
    */
    @isTest static void testUUIDs(){
        String s1 = C_Util.generateUUID();
        String s2 = C_Util.generateUUID();
        Pattern p = Pattern.compile('[0-9a-f]{8}\\-[0-9a-f]{4}\\-4[0-9a-f]{3}\\-[8-9a-b][0-9a-f]{3}\\-[0-9a-f]{12}');
        System.assertEquals(true, p.matcher(s1).matches());
        System.assertEquals(true, p.matcher(s2).matches());
        System.assertNotEquals(s1, s2);
        String t1 = C_Util.getUUID();
        String t2 = C_Util.getUUID();
        System.assertEquals(true, p.matcher(t1).matches());
        System.assertEquals(true, p.matcher(t2).matches());
        System.assertEquals(t1, t2);
        C_Util.setUUID(s1);
        String t3 = C_Util.getUUID();
        System.assertEquals(s1,t3);
        System.assertNotEquals(t1,t3);
        System.assertNotEquals(t2,t3);
    }
}
