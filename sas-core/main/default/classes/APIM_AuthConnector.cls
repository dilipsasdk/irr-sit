/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Implementation of C:LocalAuthConnector used to authenticate to APIM with OAuth2.0
 */
global with sharing class APIM_AuthConnector extends C_LocalAuthConnector {
    /**
     * Authenticates against the service
     * @param username The username to use when authenticating
     * @param password he password used when authenticating
     * @param param1 Subscription key
     * @param param2 Resource for call
     * @return The oauth access token
     */
    global override String authenticate(String username, String password, String param1, String param2){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SAS_APIM_Auth');
        request.setMethod('POST');
        request.setBody(
                'Client_Id=' + username +
                '&Client_Secret=' + password +
                '&resource=' +
                param2 +
                '&grant_type=client_credentials');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Ocp-Apim-Subscription-Key', param1);

        HttpResponse res = http.send(request);
        AuthResult ar = (AuthResult)JSON.deserialize(res.getBody(), AuthResult.class);
        if(res.getStatusCode()!=200){
            throw new APIMAuthException('Error authenticating to APIM: '+res.getStatusCode()+': '+ar.error);
        }
        return ar.access_token;
    }

    /**
        JSON structure for the authentication result
    */
    private class AuthResult{
        String access_token;
        String error;
        String error_description;
    }

    /**
     * Custom exception class for APIM auth exceptions
     */
    public class APIMAuthException extends Exception{}
}