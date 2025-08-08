/**
    Tests methods for TOTP Login Flow invocable actions
*/
@isTest 
private class SEC_LoginFlowTOTP_Test {
    /**
        The user email and federation Id used for the test user 
    */
    private static final String USER_EMAIL = 'Test.TestLoginFlow@sas.se.test';
    /**

        Creates the test user used to test the solution
    */
    @testSetup static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String uName = USER_EMAIL + C_Util.generateUUID();
        User u = new User(
            FirstName = 'TEST',
            LastName = 'TESTLoginFlow',
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
        Checks that the login flow actions works when the user has a TOTP method
    */
    @isTest static void checkTotp(){
        User u = [SELECT Id FROM User WHERE FederationIdentifier=:USER_EMAIL];
        System.runAs(u){
            //Base32 encoded string "aaaaaaaaaaaaaaaaaaaa"
            TwoFactorInfo tfi = new TwoFactorInfo(SharedKey='MFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLB',Type='TOTP',UserId=u.Id);
            insert tfi;

            Boolean[] isAvailableList = SEC_LoginFlowTOTPAvailability.isAvailable(new Id[]{u.Id});
            System.assertEquals(1,isAvailableList.size());
            System.assertEquals(true,isAvailableList[0]);
            //Tests correct token
            String token = computeTOTPAuthToken('aaaaaaaaaaaaaaaaaaaa');
            System.assertEquals(true,Auth.SessionManagement.validateTotpTokenForUser(token),'Token not accepted: '+token);
            Boolean[] verifyList = SEC_LoginFlowTOTPVerify.verifyTotp(new String[]{token});
            System.assertEquals(1,verifyList.size());
            System.assertEquals(true,verifyList[0],'Token not accepted: '+token);
            //Tests incorrect token
            verifyList = SEC_LoginFlowTOTPVerify.verifyTotp(new String[]{'000000'});
            System.assertEquals(1,verifyList.size());
            System.assertEquals(false,verifyList[0]);
            //Tests token with incorrect format
            verifyList = SEC_LoginFlowTOTPVerify.verifyTotp(new String[]{'asq1n2ecwq'});
            System.assertEquals(1,verifyList.size());
            System.assertEquals(false,verifyList[0]);
            //Tests empty token
            verifyList = SEC_LoginFlowTOTPVerify.verifyTotp(new String[]{''});
            System.assertEquals(1,verifyList.size());
            System.assertEquals(false,verifyList[0]);
            //Tests null token
            verifyList = SEC_LoginFlowTOTPVerify.verifyTotp(new String[]{null});
            System.assertEquals(1,verifyList.size());
            System.assertEquals(false,verifyList[0]);
        }
    }

    /**
        Checks that the login flow actions failes when no TOTP is registered
    */
    @isTest static void checkTempCode(){
        User u = [SELECT Id FROM User WHERE FederationIdentifier=:USER_EMAIL];
        System.runAs(u){
            Boolean[] isAvailableList = SEC_LoginFlowTOTPAvailability.isAvailable(new Id[]{u.Id});
            System.assertEquals(1,isAvailableList.size());
            System.assertEquals(false,isAvailableList[0]);
        }
    }

    /** 
        Tests that generating verification urls works
    */
    @isTest static void checkGenerateVerificationUrl(){
        User u = [SELECT Id FROM User WHERE FederationIdentifier=:USER_EMAIL];
        System.runAs(u){
            String[] urls = SEC_LoginFlowTOTPUrl.getVerificationUrls(new String[]{'/TESTRETURN'});
            System.assertEquals(1,urls.size());
            System.assert(!String.isBlank(urls[0]));
            System.assert(urls[0].contains('TESTRETURN'));
        }
    }


    /**
        Computes the TOTP token for the current time
        @param k The secret key
        @return The TOTP Auth Token
    */
    private static String computeTOTPAuthToken(String k){
        //Calculate the time interval index from epoch using 30s intervals
        Integer t = (Integer)(System.currentTimeMillis()/30000);
        return computeHOTPAuthToken(k,t);
    }
    /**
        Computes the HOTP Auth token
        @param k The secret key
        @param c The counter value
        @return THe HOTP Auth Token
    */
    private static String computeHOTPAuthToken(String k, Integer c){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.CHARS);
        //Converting counter integer to 8 byte blob
        Blob cb = EncodingUtil.convertFromHex('00000000'+String.fromCharArray(hb.set(c)));
        //Calculating HMAC SHA1 Hash of counter and the secret key
        Blob data = Crypto.generateMac('HmacSHA1', cb, Blob.valueOf(k));
        Integer[] dataHexChars = EncodingUtil.convertToHex(data).getChars();
        //Least significant nibble used as offset to extract the key
        Integer offset = hb.set(dataHexChars,39,1);
        //Extract the value using 4 bytes from the offset byte (1 hex char = 1/2 byte)
        Integer val = hb.set(dataHexChars,offset*2,8);
        //First bit must be set to 0 (no negative numbers)
        val = val & ((-1) ^ (1<<31));
        //Last 6 digits used as auth token (zero pad to ensure at least 6 characters)
        String s = '00000'+val;
        String authToken = s.substring(s.length()-6);
        return authToken;
    }
}
