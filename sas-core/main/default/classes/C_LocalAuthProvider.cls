/**
 * @author Peter Södergren/Anton Norell
 * @description Auth Provider to support username and password oauth flow where the
 *              acesstoken is retrieved using an API call and refresh token supported
 *              by storing the authentication details.
 *              The local auth provider redirects to a local page to capture the username
 *              and password of the service and requires a connector class to implement the
 *              authentication method to the underlying system.
 */
global class C_LocalAuthProvider extends Auth.AuthProviderPluginClass{
    /**
        @return The customer metadata type storing the settings of the auth provider
    */
    global String getCustomMetadataType() {
        return 'LocalAuthProvider__mdt';
    }

    /**
        Redirects the user to the local page used to capture username and password.
        @param authProviderConfiguration The information of the auth provider custom metadata record
        @param stateToPropagate The state holding the authentication session details
        @return The page reference to the authentication page
    */
    global PageReference initiate(Map<String,String> authProviderConfiguration, String stateToPropagate) {
        System.debug(authProviderConfiguration);
        PageReference ref = Page.C_LocalAuth;
        Map<String,String> pMap = ref.getParameters();
        pMap.put('authProviderName',authProviderConfiguration.get('DeveloperName__c'));
        pMap.put('authConnector',authProviderConfiguration.get('AuthConnector__c'));
        pMap.put('state',stateToPropagate);
        pMap.put('redirectUri',Url.getOrgDomainUrl().toExternalForm() +
                '/services/authcallback/' +
                authProviderConfiguration.get('DeveloperName__c'));
        return ref;
    }

    /**
        Constructs the authentication provider token response based upon the values received from the local authentication page
        The refresh token is generated to store the username and password to enable their later use when the access token expires
        @param authProviderConfigurtion The information of the auth provider custom metadata record
        @param callbackState The infomration received from the local authentication page
        @return The token information
    */
    global Auth.AuthProviderTokenResponse handleCallback(Map<String,String> authProviderConfiguration, Auth.AuthProviderCallbackState callbackState){
        String uname = callbackState.queryParameters.get('username');
        String pw = callbackState.queryParameters.get('password');
        String param1 = callbackState.queryParameters.get('param1');
        String param2 = callbackState.queryParameters.get('param2');

        String unameLen = (uname.length()+'').leftPad(3,'0');
        String pwLen = (pw.length()+'').leftPad(3,'0');
        String param1Len = (param1.length()+'').leftPad(3,'0');
        String refreshToken = unameLen+pwLen+param1Len+uname+pw+param1+param2;

        return new Auth.AuthProviderTokenResponse(
                authProviderConfiguration.get('DeveloperName__c'),
                callbackState.queryParameters.get('accessToken'),
                refreshToken,callbackState.queryParameters.get('state'));
    }
    /**
        Not implemented fully since this auth provider is intended to use as named credentials for integration purposes.
        @param authProviderConfigurtion The information of the auth provider custom metadata record
        @param response The access token
        @return A placeholder user info based on the auth provider information
    */
    global Auth.UserData getUserInfo(Map<String,String> authProviderConfiguration, Auth.AuthProviderTokenResponse response){
        Integer unameLen = Integer.valueOf(response.oauthSecretOrRefreshToken.substring(0,3));
        String uname = response.oauthSecretOrRefreshToken.substring(3,3+unameLen);
        return new Auth.UserData(uname,
                null,
                null,
                null,
                null,
                null,uname,
                'en_US',
                authProviderConfiguration.get('DeveloperName__c'),
                null,
                null);
    }

    /**
        Refreshes the access token using the username and password encoded in the refresh token
        @param authProviderConfigurtion The information of the auth provider custom metadata record
        @param refreshToken The refresh token
        @return The refresh result containing the new access token
    */
    global override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken){
        String accessToken = null;
        String errMsg = null;
        try{
            RefreshTokenAuthInfo authInfo = new RefreshTokenAuthInfo(refreshToken);
            C_LocalAuthConnector ac = (C_LocalAuthConnector)Type.forName(authProviderConfiguration.get('AuthConnector__c')).newInstance();
            accessToken = ac.authenticate(authInfo.userName, authInfo.password, authInfo.param1, authInfo.param2);
        }
        catch(Exception e){
            errMsg = e.getMessage();
        }
        return new Auth.OAuthRefreshResult(accessToken,refreshToken,errMsg);
    }

    private class RefreshTokenAuthInfo{
        public String userName {get; private set;}
        public String password {get; private set;}
        public String param1 {get; private set;}
        public String param2 {get; private set;}

        public RefreshTokenAuthInfo(String refreshToken){
            Integer unameLen = Integer.valueOf(refreshToken.substring(0,3));
            Integer pwLen = Integer.valueOf(refreshToken.substring(3,6));
            Integer param1Len = Integer.valueOf(refreshToken.substring(6,9));

            this.userName = refreshToken.substring(9,9+ unameLen);
            this.password = refreshToken.substring(9+ unameLen, 9+ unameLen + pwLen);
            this.param1 = refreshToken.substring(9+ unameLen + pwLen, 9+ unameLen + pwLen + param1Len);
            this.param2 = refreshToken.substring(9+ unameLen + pwLen + param1Len);
        }
    }
}
