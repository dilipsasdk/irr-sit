/**
    Invocable action to check whether TOTP is available for the currently runnign user
    Used for login flows
*/
global with sharing class SEC_LoginFlowTOTPAvailability {
    /**
        Checks whether a TOTP secret is registered for each of the provided user ids
        Also returns true when the suer has an associated temp code
        @param userIds The users for which to check
        @return A corresponding list of booleans which indicate whether a totp secret has been registered for each of the provided users
    */
    @InvocableMethod(label='Get TOTP Availability' description='Returns whether the provided users has a registered TOTP secret')
    global static Boolean[] isAvailable(Id[] userIds) {
        Set<Id> hasTotpSet = new Set<Id>();
        TwoFactorInfo[] tfiList = [SELECT Id,UserId FROM TwoFactorInfo WHERE UserId IN :userIds AND Type='TOTP'];
        for(TwoFactorInfo tfi : tfiList){
            hasTotpSet.add(tfi.UserId);
        }
        TwoFactorMethodsInfo[] tfmiList = [SELECT Id,HasSalesforceAuthenticator,UserId FROM TwoFactorMethodsInfo WHERE UserId IN :userIds];
        for(TwoFactorMethodsInfo tfmi : tfmiList){
            if(tfmi.HasSalesforceAuthenticator)hasTotpSet.add(tfmi.UserId);
        }
        TwoFactorTempCode[] tcList = [SELECT Id,UserId FROM TwoFactorTempCode WHERE UserId IN :userIds AND Expiration>:DateTime.now()];
        for(TwoFactorTempCode tc : tcList){
            hasTotpSet.add(tc.UserId);
        }
        Integer sz = userIds.size();
        Boolean[] res = new Boolean[sz];
        for(Integer i=0;i<sz;i++){
            res[i] = hasTotpSet.contains(userIds[i]);
        }
        return res;
    }
}
