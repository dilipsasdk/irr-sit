/**
    Invocable action to render a link for the current user to
    raise the session and thus enabling TOTP registration
*/
global with sharing class SEC_LoginFlowTOTPUrl {
    /**
        Generates verification urls with the provided return urls
        @param retUrls The return urls for the verification urls
        @return A corresponding list of verification urls
    */
    @InvocableMethod(label='Get Verification Url' description='Generates verification urls')
    global static String[] getVerificationUrls(String[] retUrls) {
        Integer sz = retUrls.size();
        String[] urls = new String[sz];
        for(Integer i=0;i<sz;i++){
            urls[i] = Auth.SessionManagement.generateVerificationUrl(Auth.VerificationPolicy.HIGH_ASSURANCE, 'Identity Verification', retUrls[i]);
        }
        return urls;
    }
}
