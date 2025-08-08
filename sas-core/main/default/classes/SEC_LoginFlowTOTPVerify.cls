/**
    Invocable action to verify TOTP for the current running user
    Used for login flows
*/
global with sharing class SEC_LoginFlowTOTPVerify {
    /**
        Invocable actions to verify totp tokens for the current running users
        @param totpCodeList The list of totp codes to check
        @return Whether each corresponding totp token was valid for the current running user
    */
    @InvocableMethod(label='Verify TOTP' description='Verifies the provided TOTP for the current running user')
    global static Boolean[] verifyTotp(String[] totpCodeList) {
        Integer sz = totpCodeList.size();
        Boolean[] res = new Boolean[sz];
        for(Integer i=0;i<sz;i++){
            try{
                res[i] = Auth.SessionManagement.validateTotpTokenForUser(totpCodeList[i],'Non SSO Login');
            }
            catch(Exception e){res[i] = false;}
        }
        return res;
    }
}
